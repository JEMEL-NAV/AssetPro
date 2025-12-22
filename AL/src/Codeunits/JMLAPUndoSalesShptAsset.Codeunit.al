codeunit 70182403 "JML AP Undo Sales Shpt Asset"
{
    TableNo = "JML AP Pstd Sales Shpt Ast Ln";

    trigger OnRun()
    begin
        if not Confirm(StrSubstNo(UndoShipmentQst, Rec."Asset No."), false) then
            exit;

        PostedAssetLine.Copy(Rec);
        Code();
        Rec := PostedAssetLine;
    end;

    var
        PostedAssetLine: Record "JML AP Pstd Sales Shpt Ast Ln";
        UndoShipmentQst: Label 'Do you really want to undo the shipment for asset %1?\This will reverse the asset transfer and allow you to modify the Sales Order.', Comment = '%1 = Asset No.';
        AlreadyReversedErr: Label 'This asset shipment has already been reversed.';
        Text002: Label 'There is not enough space to insert correction lines.';
        AssetBlockedErr: Label 'Asset %1 is blocked.', Comment = '%1 = Asset No.';
        SalesOrderNotFoundErr: Label 'Sales Order %1 line %2 not found. Cannot undo shipment.', Comment = '%1 = Order No., %2 = Line No.';
        AlreadyInvoicedErr: Label 'Cannot undo shipment. Asset %1 has already been invoiced on this Sales Order.', Comment = '%1 = Asset No.';
        HolderMismatchErr: Label 'Cannot undo shipment. Asset %1 current holder does not match the shipment customer.\Expected: Customer %2\Actual: %3 %4', Comment = '%1 = Asset No., %2 = Customer No., %3 = Holder Type, %4 = Holder Code';

    local procedure Code()
    var
        SalesShptHeader: Record "Sales Shipment Header";
        WindowDialog: Dialog;
    begin
        PostedAssetLine.SetRange("Document No.", PostedAssetLine."Document No.");
        PostedAssetLine.SetRange("Line No.", PostedAssetLine."Line No.");
        PostedAssetLine.FindFirst();

        WindowDialog.Open('Checking asset shipment line...');
        CheckPostedAssetLine(PostedAssetLine);
        WindowDialog.Close();

        WindowDialog.Open('Undoing asset shipment...');
        SalesShptHeader.Get(PostedAssetLine."Document No.");
        UndoAssetShipment(PostedAssetLine, SalesShptHeader);
        WindowDialog.Close();

        Message('Asset shipment undone successfully.');
    end;

    local procedure CheckPostedAssetLine(var PostedAssetLine2: Record "JML AP Pstd Sales Shpt Ast Ln")
    var
        Asset: Record "JML AP Asset";
        SalesAssetLine: Record "JML AP Sales Asset Line";
    begin
        // Check if already undone
        if PostedAssetLine2.Correction then
            Error(AlreadyReversedErr);

        // Check asset exists and not blocked
        if not Asset.Get(PostedAssetLine2."Asset No.") then
            Error(AssetBlockedErr, PostedAssetLine2."Asset No.");

        if Asset.Blocked then
            Error(AssetBlockedErr, PostedAssetLine2."Asset No.");

        // Check Sales Order line still exists
        // If the order was invoiced and deleted, this check will fail
        if not SalesAssetLine.Get(
            SalesAssetLine."Document Type"::Order,
            GetSalesOrderNo(PostedAssetLine2),
            GetSalesOrderLineNo(PostedAssetLine2))
        then
            Error(SalesOrderNotFoundErr, GetSalesOrderNo(PostedAssetLine2), GetSalesOrderLineNo(PostedAssetLine2));

        // Check asset current holder matches expected (customer from shipment)
        if (Asset."Current Holder Type" <> Asset."Current Holder Type"::Customer) or
           (Asset."Current Holder Code" <> PostedAssetLine2."Sell-to Customer No.")
        then
            Error(HolderMismatchErr,
                PostedAssetLine2."Asset No.",
                PostedAssetLine2."Sell-to Customer No.",
                Asset."Current Holder Type",
                Asset."Current Holder Code");
    end;

    local procedure UndoAssetShipment(var OldPostedAssetLine: Record "JML AP Pstd Sales Shpt Ast Ln"; SalesShptHeader: Record "Sales Shipment Header")
    var
        Asset: Record "JML AP Asset";
        SalesAssetLine: Record "JML AP Sales Asset Line";
        NewTransactionNo: Integer;
        DocLineNo: Integer;
    begin
        Asset.Get(OldPostedAssetLine."Asset No.");

        // Calculate correction line number
        DocLineNo := GetCorrectionLineNo(OldPostedAssetLine);

        // Reverse holder entries (asset back to original location)
        NewTransactionNo := ReverseHolderEntries(Asset, OldPostedAssetLine, SalesShptHeader);

        // Insert correction line in posted shipment
        InsertCorrectionLine(OldPostedAssetLine, DocLineNo, NewTransactionNo);

        // Mark original line as corrected
        OldPostedAssetLine.Correction := true;
        OldPostedAssetLine.Modify();

        // Update Sales Order asset line (reduce Qty Shipped)
        UpdateSalesAssetLine(OldPostedAssetLine);
    end;

    local procedure GetCorrectionLineNo(PostedAssetLine2: Record "JML AP Pstd Sales Shpt Ast Ln"): Integer
    var
        PostedAssetLine3: Record "JML AP Pstd Sales Shpt Ast Ln";
        LineSpacing: Integer;
    begin
        PostedAssetLine3.SetRange("Document No.", PostedAssetLine2."Document No.");
        PostedAssetLine3."Document No." := PostedAssetLine2."Document No.";
        PostedAssetLine3."Line No." := PostedAssetLine2."Line No.";
        PostedAssetLine3.Find('=');
        if PostedAssetLine3.Find('>') then begin
            LineSpacing := (PostedAssetLine3."Line No." - PostedAssetLine2."Line No.") div 2;
            if LineSpacing = 0 then
                Error(Text002);
        end else
            LineSpacing := 10000;

        exit(PostedAssetLine2."Line No." + LineSpacing);
    end;

    local procedure ReverseHolderEntries(var Asset: Record "JML AP Asset"; PostedAssetLine2: Record "JML AP Pstd Sales Shpt Ast Ln"; SalesShptHeader: Record "Sales Shipment Header"): Integer
    var
        HolderEntry: Record "JML AP Holder Entry";
        TempAssetJournalLine: Record "JML AP Asset Journal Line" temporary;
        AssetJnlPostLine: Codeunit "JML AP Asset Jnl.-Post Line";
        OriginalLocationCode: Code[20];
    begin
        // Find original location from the Transfer Out entry
        HolderEntry.SetRange("Transaction No.", PostedAssetLine2."Transaction No.");
        HolderEntry.SetRange("Entry Type", HolderEntry."Entry Type"::"Transfer Out");
        HolderEntry.SetRange("Asset No.", PostedAssetLine2."Asset No.");
        if HolderEntry.FindFirst() then
            OriginalLocationCode := HolderEntry."Holder Code"
        else
            OriginalLocationCode := ''; // Default if not found

        // Create journal line to reverse the transfer
        TempAssetJournalLine.Init();
        TempAssetJournalLine."Line No." := 10000;
        TempAssetJournalLine."Posting Date" := WorkDate(); // Use today's date for undo
        TempAssetJournalLine."Document No." := PostedAssetLine2."Document No." + '-UNDO';
        TempAssetJournalLine."Asset No." := Asset."No.";
        TempAssetJournalLine."New Holder Type" := TempAssetJournalLine."New Holder Type"::Location;
        TempAssetJournalLine."New Holder Code" := OriginalLocationCode;
        TempAssetJournalLine."Reason Code" := PostedAssetLine2."Reason Code";
        TempAssetJournalLine.Description := StrSubstNo('Undo Shipment %1', PostedAssetLine2."Document No.");

        // Post journal to create reverse holder entries
        AssetJnlPostLine.Run(TempAssetJournalLine);
        exit(AssetJnlPostLine.GetTransactionNo());
    end;

    local procedure InsertCorrectionLine(OldPostedAssetLine: Record "JML AP Pstd Sales Shpt Ast Ln"; DocLineNo: Integer; NewTransactionNo: Integer)
    var
        NewPostedAssetLine: Record "JML AP Pstd Sales Shpt Ast Ln";
    begin
        NewPostedAssetLine.Init();
        NewPostedAssetLine.TransferFields(OldPostedAssetLine);
        NewPostedAssetLine."Line No." := DocLineNo;
        NewPostedAssetLine."Appl.-from Asset Line No." := OldPostedAssetLine."Line No.";
        NewPostedAssetLine."Transaction No." := NewTransactionNo;
        NewPostedAssetLine.Correction := true;
        NewPostedAssetLine."Posting Date" := WorkDate(); // Correction uses today's date
        NewPostedAssetLine.Insert(true);
    end;

    local procedure UpdateSalesAssetLine(PostedAssetLine2: Record "JML AP Pstd Sales Shpt Ast Ln")
    var
        SalesAssetLine: Record "JML AP Sales Asset Line";
    begin
        if SalesAssetLine.Get(
            SalesAssetLine."Document Type"::Order,
            GetSalesOrderNo(PostedAssetLine2),
            GetSalesOrderLineNo(PostedAssetLine2))
        then begin
            SalesAssetLine."Quantity Shipped" -= 1;
            if SalesAssetLine."Quantity Shipped" < 0 then
                SalesAssetLine."Quantity Shipped" := 0;
            SalesAssetLine.Modify(true);
        end;
    end;

    local procedure GetSalesOrderNo(PostedAssetLine2: Record "JML AP Pstd Sales Shpt Ast Ln"): Code[20]
    var
        SalesShptHeader: Record "Sales Shipment Header";
    begin
        if SalesShptHeader.Get(PostedAssetLine2."Document No.") then
            exit(SalesShptHeader."Order No.");
        exit('');
    end;

    local procedure GetSalesOrderLineNo(PostedAssetLine2: Record "JML AP Pstd Sales Shpt Ast Ln"): Integer
    var
        SalesShptLine: Record "Sales Shipment Line";
        SalesAssetLine: Record "JML AP Sales Asset Line";
    begin
        // Find matching sales asset line by asset number and document
        SalesAssetLine.SetRange("Document Type", SalesAssetLine."Document Type"::Order);
        SalesAssetLine.SetRange("Document No.", GetSalesOrderNo(PostedAssetLine2));
        SalesAssetLine.SetRange("Asset No.", PostedAssetLine2."Asset No.");
        if SalesAssetLine.FindFirst() then
            exit(SalesAssetLine."Line No.");
        exit(0);
    end;

    procedure UndoPostedAssetLine(var PostedAssetLine2: Record "JML AP Pstd Sales Shpt Ast Ln")
    begin
        PostedAssetLine.Copy(PostedAssetLine2);
        Code();
        PostedAssetLine2 := PostedAssetLine;
    end;
}
