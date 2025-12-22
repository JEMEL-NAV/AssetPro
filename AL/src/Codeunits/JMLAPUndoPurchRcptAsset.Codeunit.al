codeunit 70182404 "JML AP Undo Purch Rcpt Asset"
{
    TableNo = "JML AP Pstd Purch Rcpt Ast Ln";

    trigger OnRun()
    begin
        if not Confirm(StrSubstNo(UndoReceiptQst, Rec."Asset No."), false) then
            exit;

        PostedAssetLine.Copy(Rec);
        Code();
        Rec := PostedAssetLine;
    end;

    var
        PostedAssetLine: Record "JML AP Pstd Purch Rcpt Ast Ln";
        UndoReceiptQst: Label 'Do you really want to undo the receipt for asset %1?\This will reverse the asset transfer and allow you to modify the Purchase Order.', Comment = '%1 = Asset No.';
        AlreadyReversedErr: Label 'This asset receipt has already been reversed.';
        Text002: Label 'There is not enough space to insert correction lines.';
        AssetBlockedErr: Label 'Asset %1 is blocked.', Comment = '%1 = Asset No.';
        PurchOrderNotFoundErr: Label 'Purchase Order %1 line %2 not found. Cannot undo receipt.', Comment = '%1 = Order No., %2 = Line No.';
        HolderMismatchErr: Label 'Cannot undo receipt. Asset %1 current holder does not match the receipt location.\Expected: Location %2\Actual: %3 %4', Comment = '%1 = Asset No., %2 = Location Code, %3 = Holder Type, %4 = Holder Code';
        CheckingReceiptLineMsg: Label 'Checking asset receipt line...';
        UndoingReceiptMsg: Label 'Undoing asset receipt...';
        ReceiptUndoneSuccessMsg: Label 'Asset receipt undone successfully.';
        UndoReceiptDescTxt: Label 'Undo Receipt %1', Comment = '%1 = Document No.';

    local procedure Code()
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        WindowDialog: Dialog;
    begin
        PostedAssetLine.SetRange("Document No.", PostedAssetLine."Document No.");
        PostedAssetLine.SetRange("Line No.", PostedAssetLine."Line No.");
        PostedAssetLine.FindFirst();

        WindowDialog.Open(CheckingReceiptLineMsg);
        CheckPostedAssetLine(PostedAssetLine);
        WindowDialog.Close();

        WindowDialog.Open(UndoingReceiptMsg);
        PurchRcptHeader.Get(PostedAssetLine."Document No.");
        UndoAssetReceipt(PostedAssetLine, PurchRcptHeader);
        WindowDialog.Close();

        Message(ReceiptUndoneSuccessMsg);
    end;

    local procedure CheckPostedAssetLine(var PostedAssetLine2: Record "JML AP Pstd Purch Rcpt Ast Ln")
    var
        Asset: Record "JML AP Asset";
        PurchAssetLine: Record "JML AP Purch. Asset Line";
    begin
        // Check if already undone
        if PostedAssetLine2.Correction then
            Error(AlreadyReversedErr);

        // Check asset exists and not blocked
        if not Asset.Get(PostedAssetLine2."Asset No.") then
            Error(AssetBlockedErr, PostedAssetLine2."Asset No.");

        if Asset.Blocked then
            Error(AssetBlockedErr, PostedAssetLine2."Asset No.");

        // Check Purchase Order line still exists
        if not PurchAssetLine.Get(
            PurchAssetLine."Document Type"::Order,
            GetPurchaseOrderNo(PostedAssetLine2),
            GetPurchaseOrderLineNo(PostedAssetLine2))
        then
            Error(PurchOrderNotFoundErr, GetPurchaseOrderNo(PostedAssetLine2), GetPurchaseOrderLineNo(PostedAssetLine2));

        // Check asset current holder matches expected (location from receipt)
        if (Asset."Current Holder Type" <> Asset."Current Holder Type"::Location) or
           (Asset."Current Holder Code" <> PostedAssetLine2."Location Code")
        then
            Error(HolderMismatchErr,
                PostedAssetLine2."Asset No.",
                PostedAssetLine2."Location Code",
                Asset."Current Holder Type",
                Asset."Current Holder Code");
    end;

    local procedure UndoAssetReceipt(var OldPostedAssetLine: Record "JML AP Pstd Purch Rcpt Ast Ln"; PurchRcptHeader: Record "Purch. Rcpt. Header")
    var
        Asset: Record "JML AP Asset";
        PurchAssetLine: Record "JML AP Purch. Asset Line";
        NewTransactionNo: Integer;
        DocLineNo: Integer;
    begin
        Asset.Get(OldPostedAssetLine."Asset No.");

        // Calculate correction line number
        DocLineNo := GetCorrectionLineNo(OldPostedAssetLine);

        // Reverse holder entries (asset back to vendor)
        NewTransactionNo := ReverseHolderEntries(Asset, OldPostedAssetLine, PurchRcptHeader);

        // Insert correction line in posted receipt
        InsertCorrectionLine(OldPostedAssetLine, DocLineNo, NewTransactionNo);

        // Mark original line as corrected
        OldPostedAssetLine.Correction := true;
        OldPostedAssetLine.Modify();

        // Update Purchase Order asset line (reduce Qty Received)
        UpdatePurchaseAssetLine(OldPostedAssetLine);
    end;

    local procedure GetCorrectionLineNo(PostedAssetLine2: Record "JML AP Pstd Purch Rcpt Ast Ln"): Integer
    var
        PostedAssetLine3: Record "JML AP Pstd Purch Rcpt Ast Ln";
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

    local procedure ReverseHolderEntries(var Asset: Record "JML AP Asset"; PostedAssetLine2: Record "JML AP Pstd Purch Rcpt Ast Ln"; PurchRcptHeader: Record "Purch. Rcpt. Header"): Integer
    var
        HolderEntry: Record "JML AP Holder Entry";
        TempAssetJournalLine: Record "JML AP Asset Journal Line" temporary;
        AssetJnlPostLine: Codeunit "JML AP Asset Jnl.-Post Line";
        OriginalVendorNo: Code[20];
    begin
        // Find original vendor from the Transfer Out entry
        HolderEntry.SetRange("Transaction No.", PostedAssetLine2."Transaction No.");
        HolderEntry.SetRange("Entry Type", HolderEntry."Entry Type"::"Transfer Out");
        HolderEntry.SetRange("Asset No.", PostedAssetLine2."Asset No.");
        if HolderEntry.FindFirst() then
            OriginalVendorNo := HolderEntry."Holder Code"
        else
            OriginalVendorNo := PostedAssetLine2."Buy-from Vendor No."; // Fallback

        // Create journal line to reverse the transfer (Location → Vendor)
        TempAssetJournalLine.Init();
        TempAssetJournalLine."Line No." := 10000;
        TempAssetJournalLine."Posting Date" := WorkDate(); // Use today's date for undo
        TempAssetJournalLine."Document No." := PostedAssetLine2."Document No." + '-UNDO';
        TempAssetJournalLine."Asset No." := Asset."No.";
        TempAssetJournalLine."New Holder Type" := TempAssetJournalLine."New Holder Type"::Vendor;
        TempAssetJournalLine."New Holder Code" := OriginalVendorNo;
        TempAssetJournalLine."Reason Code" := PostedAssetLine2."Reason Code";
        TempAssetJournalLine.Description := StrSubstNo(UndoReceiptDescTxt, PostedAssetLine2."Document No.");

        // Post journal to create reverse holder entries
        AssetJnlPostLine.Run(TempAssetJournalLine);
        exit(AssetJnlPostLine.GetTransactionNo());
    end;

    local procedure InsertCorrectionLine(OldPostedAssetLine: Record "JML AP Pstd Purch Rcpt Ast Ln"; DocLineNo: Integer; NewTransactionNo: Integer)
    var
        NewPostedAssetLine: Record "JML AP Pstd Purch Rcpt Ast Ln";
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

    local procedure UpdatePurchaseAssetLine(PostedAssetLine2: Record "JML AP Pstd Purch Rcpt Ast Ln")
    var
        PurchAssetLine: Record "JML AP Purch. Asset Line";
    begin
        if PurchAssetLine.Get(
            PurchAssetLine."Document Type"::Order,
            GetPurchaseOrderNo(PostedAssetLine2),
            GetPurchaseOrderLineNo(PostedAssetLine2))
        then begin
            PurchAssetLine."Quantity Received" -= 1;
            if PurchAssetLine."Quantity Received" < 0 then
                PurchAssetLine."Quantity Received" := 0;
            PurchAssetLine.Modify(true);
        end;
    end;

    local procedure GetPurchaseOrderNo(PostedAssetLine2: Record "JML AP Pstd Purch Rcpt Ast Ln"): Code[20]
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        if PurchRcptHeader.Get(PostedAssetLine2."Document No.") then
            exit(PurchRcptHeader."Order No.");
        exit('');
    end;

    local procedure GetPurchaseOrderLineNo(PostedAssetLine2: Record "JML AP Pstd Purch Rcpt Ast Ln"): Integer
    var
        PurchAssetLine: Record "JML AP Purch. Asset Line";
    begin
        // Find matching purchase asset line by asset number and document
        PurchAssetLine.SetRange("Document Type", PurchAssetLine."Document Type"::Order);
        PurchAssetLine.SetRange("Document No.", GetPurchaseOrderNo(PostedAssetLine2));
        PurchAssetLine.SetRange("Asset No.", PostedAssetLine2."Asset No.");
        if PurchAssetLine.FindFirst() then
            exit(PurchAssetLine."Line No.");
        exit(0);
    end;

    procedure UndoPostedAssetLine(var PostedAssetLine2: Record "JML AP Pstd Purch Rcpt Ast Ln")
    begin
        PostedAssetLine.Copy(PostedAssetLine2);
        Code();
        PostedAssetLine2 := PostedAssetLine;
    end;
}
