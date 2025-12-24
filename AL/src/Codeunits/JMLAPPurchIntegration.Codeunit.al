codeunit 70182399 "JML AP Purch. Integration"
{
    // Event subscribers for Purchase posting integration with Asset Holder Transfer
    // Mirrors Sales Integration pattern (codeunit 70182398)

    // ========================================
    // Asset Holder Transfer Integration
    // ========================================

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPurchRcptHeaderInsert', '', false, false)]
    local procedure OnAfterPurchRcptHeaderInsert(var PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchaseHeader: Record "Purchase Header")
    begin
        // Post asset holder transfers for receipt (delivery from vendor to location)
        PostPurchaseReceiptAssets(PurchaseHeader, PurchRcptHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPurchInvHeaderInsert', '', false, false)]
    local procedure OnAfterPurchInvHeaderInsert(var PurchInvHeader: Record "Purch. Inv. Header"; var PurchHeader: Record "Purchase Header")
    begin
        // Post asset holder transfers for invoice (if no prior receipt)
        // This supports invoice-only scenarios
        PostPurchaseInvoiceAssets(PurchHeader, PurchInvHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterReturnShptHeaderInsert', '', false, false)]
    local procedure OnAfterReturnShptHeaderInsert(var ReturnShptHeader: Record "Return Shipment Header"; var PurchHeader: Record "Purchase Header")
    begin
        // Post asset returns (returning assets from location to vendor)
        PostReturnShipmentAssets(PurchHeader, ReturnShptHeader);
    end;

    local procedure PostPurchaseReceiptAssets(PurchHeader: Record "Purchase Header"; PurchRcptHeader: Record "Purch. Rcpt. Header")
    var
        PurchAssetLine: Record "JML AP Purch. Asset Line";
        Asset: Record "JML AP Asset";
        JMLAPGeneral: Codeunit "JML AP General";
        TransactionNo: Integer;
        LocationCode: Code[10];
    begin
        // License check
        if not JMLAPGeneral.IsAllowedToUse(true) then
            error('');

        // Get asset lines to receive
        PurchAssetLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchAssetLine.SetRange("Document No.", PurchHeader."No.");
        PurchAssetLine.SetFilter("Quantity to Receive", '>0');

        if PurchAssetLine.IsEmpty() then
            exit;

        // Determine location (from header Location Code)
        LocationCode := PurchHeader."Location Code";

        // Post each asset transfer via Asset Journal
        if PurchAssetLine.FindSet(true) then
            repeat
                Asset.Get(PurchAssetLine."Asset No.");

                // Transfer asset from vendor to location using journal pattern
                PostAssetTransferViaJournal(
                    Asset,
                    "JML AP Holder Type"::Location,
                    LocationCode,
                    PurchRcptHeader."No.",
                    PurchAssetLine."Reason Code",
                    PurchRcptHeader."Posting Date",
                    TransactionNo);

                // Create posted receipt asset line
                CreatePostedReceiptAssetLine(PurchAssetLine, PurchRcptHeader, PurchHeader, LocationCode, TransactionNo);

                // Update source line
                PurchAssetLine."Quantity Received" += PurchAssetLine."Quantity to Receive";
                PurchAssetLine."Quantity to Receive" := 0;
                PurchAssetLine.Modify();
            until PurchAssetLine.Next() = 0;
    end;

    local procedure PostPurchaseInvoiceAssets(PurchHeader: Record "Purchase Header"; PurchInvHeader: Record "Purch. Inv. Header")
    var
        PurchAssetLine: Record "JML AP Purch. Asset Line";
        Asset: Record "JML AP Asset";
        JMLAPGeneral: Codeunit "JML AP General";
        TransactionNo: Integer;
        LocationCode: Code[10];
    begin
        // License check
        if not JMLAPGeneral.IsAllowedToUse(true) then
            error('');

        // Only post if no prior receipt exists (invoice-only scenario)
        PurchAssetLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchAssetLine.SetRange("Document No.", PurchHeader."No.");
        PurchAssetLine.SetFilter("Quantity Received", '=0'); // Not yet received

        if PurchAssetLine.IsEmpty() then
            exit;

        LocationCode := PurchHeader."Location Code";

        if PurchAssetLine.FindSet(true) then
            repeat
                Asset.Get(PurchAssetLine."Asset No.");

                // Transfer asset from vendor to location
                PostAssetTransferViaJournal(
                    Asset,
                    "JML AP Holder Type"::Location,
                    LocationCode,
                    PurchInvHeader."No.",
                    PurchAssetLine."Reason Code",
                    PurchInvHeader."Posting Date",
                    TransactionNo);

                // Mark as received
                PurchAssetLine."Quantity Received" := 1;
                PurchAssetLine."Quantity to Receive" := 0;
                PurchAssetLine.Modify();
            until PurchAssetLine.Next() = 0;
    end;

    local procedure PostReturnShipmentAssets(PurchHeader: Record "Purchase Header"; ReturnShptHeader: Record "Return Shipment Header")
    var
        PurchAssetLine: Record "JML AP Purch. Asset Line";
        Asset: Record "JML AP Asset";
        JMLAPGeneral: Codeunit "JML AP General";
        TransactionNo: Integer;
    begin
        // License check
        if not JMLAPGeneral.IsAllowedToUse(true) then
            error('');

        // Get asset lines to ship (return to vendor)
        PurchAssetLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchAssetLine.SetRange("Document No.", PurchHeader."No.");
        PurchAssetLine.SetFilter("Quantity to Ship", '>0');

        if PurchAssetLine.IsEmpty() then
            exit;

        // Post each asset return
        if PurchAssetLine.FindSet(true) then
            repeat
                Asset.Get(PurchAssetLine."Asset No.");

                // Transfer asset from location to vendor
                PostAssetTransferViaJournal(
                    Asset,
                    "JML AP Holder Type"::Vendor,
                    PurchHeader."Buy-from Vendor No.",
                    ReturnShptHeader."No.",
                    PurchAssetLine."Reason Code",
                    ReturnShptHeader."Posting Date",
                    TransactionNo);

                // Create posted return shipment asset line
                CreatePostedReturnShipmentAssetLine(PurchAssetLine, ReturnShptHeader, PurchHeader, TransactionNo);

                // Update source line
                PurchAssetLine."Quantity Shipped" += PurchAssetLine."Quantity to Ship";
                PurchAssetLine."Quantity to Ship" := 0;
                PurchAssetLine.Modify();
            until PurchAssetLine.Next() = 0;
    end;

    local procedure PostAssetTransferViaJournal(var Asset: Record "JML AP Asset"; NewHolderType: Enum "JML AP Holder Type"; NewHolderCode: Code[20]; DocumentNo: Code[20]; ReasonCode: Code[10]; PostingDate: Date; var TransactionNo: Integer)
    var
        TempAssetJournalLine: Record "JML AP Asset Journal Line" temporary;
        AssetJnlPostLine: Codeunit "JML AP Asset Jnl.-Post Line";
    begin
        // Create journal line
        TempAssetJournalLine.Init();
        TempAssetJournalLine."Journal Batch Name" := '';
        TempAssetJournalLine."Line No." := 10000;
        TempAssetJournalLine."Posting Date" := PostingDate;
        TempAssetJournalLine."Document No." := DocumentNo;
        TempAssetJournalLine."Asset No." := Asset."No.";
        TempAssetJournalLine."New Holder Type" := NewHolderType;
        TempAssetJournalLine."New Holder Code" := NewHolderCode;
        TempAssetJournalLine."Reason Code" := ReasonCode;

        // Post journal
        AssetJnlPostLine.Run(TempAssetJournalLine);
        TransactionNo := AssetJnlPostLine.GetTransactionNo();
    end;

    local procedure CreatePostedReceiptAssetLine(PurchAssetLine: Record "JML AP Purch. Asset Line"; PurchRcptHeader: Record "Purch. Rcpt. Header"; PurchHeader: Record "Purchase Header"; LocationCode: Code[10]; TransactionNo: Integer)
    var
        PostedAssetLine: Record "JML AP Pstd Purch Rcpt Ast Ln";
        Vendor: Record Vendor;
        LineNo: Integer;
    begin
        // Get next line number
        PostedAssetLine.SetRange("Document No.", PurchRcptHeader."No.");
        if PostedAssetLine.FindLast() then
            LineNo := PostedAssetLine."Line No." + 10000
        else
            LineNo := 10000;

        // Get vendor name
        if Vendor.Get(PurchHeader."Buy-from Vendor No.") then;

        // Create posted line
        PostedAssetLine.Init();
        PostedAssetLine."Document No." := PurchRcptHeader."No.";
        PostedAssetLine."Line No." := LineNo;
        PostedAssetLine."Asset No." := PurchAssetLine."Asset No.";
        PostedAssetLine."Asset Description" := PurchAssetLine."Asset Description";
        PostedAssetLine."Buy-from Vendor No." := PurchHeader."Buy-from Vendor No.";
        PostedAssetLine."Buy-from Vendor Name" := Vendor.Name;
        PostedAssetLine."Location Code" := LocationCode;
        PostedAssetLine."Reason Code" := PurchAssetLine."Reason Code";
        PostedAssetLine.Description := PurchAssetLine.Description;
        PostedAssetLine."Posting Date" := PurchRcptHeader."Posting Date";
        PostedAssetLine."Transaction No." := TransactionNo;
        PostedAssetLine.Insert(true);
    end;

    local procedure CreatePostedReturnShipmentAssetLine(PurchAssetLine: Record "JML AP Purch. Asset Line"; ReturnShptHeader: Record "Return Shipment Header"; PurchHeader: Record "Purchase Header"; TransactionNo: Integer)
    var
        PostedAssetLine: Record "JML AP Pstd Ret Shpt Ast Ln";
        Vendor: Record Vendor;
        LineNo: Integer;
    begin
        // Get next line number
        PostedAssetLine.SetRange("Document No.", ReturnShptHeader."No.");
        if PostedAssetLine.FindLast() then
            LineNo := PostedAssetLine."Line No." + 10000
        else
            LineNo := 10000;

        // Get vendor name
        if Vendor.Get(PurchHeader."Buy-from Vendor No.") then;

        // Create posted line
        PostedAssetLine.Init();
        PostedAssetLine."Document No." := ReturnShptHeader."No.";
        PostedAssetLine."Line No." := LineNo;
        PostedAssetLine."Asset No." := PurchAssetLine."Asset No.";
        PostedAssetLine."Asset Description" := PurchAssetLine."Asset Description";
        PostedAssetLine."Buy-from Vendor No." := PurchHeader."Buy-from Vendor No.";
        PostedAssetLine."Buy-from Vendor Name" := Vendor.Name;
        PostedAssetLine."Location Code" := PurchHeader."Location Code";
        PostedAssetLine."Reason Code" := PurchAssetLine."Reason Code";
        PostedAssetLine.Description := PurchAssetLine.Description;
        PostedAssetLine."Posting Date" := ReturnShptHeader."Posting Date";
        PostedAssetLine."Transaction No." := TransactionNo;
        PostedAssetLine.Insert(true);
    end;
}
