codeunit 70182400 "JML AP Transfer Integration"
{
    // Event subscribers for Transfer posting integration with Asset Holder Transfer
    // Follows Sales (70182398) and Purchase (70182399) integration patterns

    // ========================================
    // Asset Holder Transfer Integration
    // ========================================

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Shipment", 'OnAfterInsertTransShptHeader', '', false, false)]
    local procedure OnAfterInsertTransShptHeader(var TransferHeader: Record "Transfer Header"; var TransferShipmentHeader: Record "Transfer Shipment Header")
    begin
        // Post asset holder transfers for shipment (location-to-location transfer)
        PostTransferShipmentAssets(TransferHeader, TransferShipmentHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", 'OnAfterInsertTransRcptHeader', '', false, false)]
    local procedure OnAfterInsertTransRcptHeader(var TransRcptHeader: Record "Transfer Receipt Header"; var TransHeader: Record "Transfer Header")
    begin
        // Receipt posting: No asset movement (assets already transferred at shipment)
        // Just update quantity received on source lines
        UpdateReceiptQuantities(TransHeader, TransRcptHeader);
    end;

    local procedure PostTransferShipmentAssets(TransferHeader: Record "Transfer Header"; TransShptHeader: Record "Transfer Shipment Header")
    var
        TransferAssetLine: Record "JML AP Transfer Asset Line";
        Asset: Record "JML AP Asset";
        TransactionNo: Integer;
    begin
        // Get asset lines to ship
        TransferAssetLine.SetRange("Document No.", TransferHeader."No.");
        TransferAssetLine.SetFilter("Quantity to Ship", '>0');

        if TransferAssetLine.IsEmpty() then
            exit;

        // Get next transaction number for this shipment
        TransactionNo := GetNextTransactionNo();

        // Post each asset transfer via Asset Journal
        if TransferAssetLine.FindSet(true) then
            repeat
                Asset.Get(TransferAssetLine."Asset No.");

                // Transfer asset from Transfer-from to Transfer-to Location using journal pattern
                PostAssetTransferViaJournal(
                    Asset,
                    "JML AP Holder Type"::Location,
                    TransferHeader."Transfer-to Code",
                    TransShptHeader."No.",
                    TransferAssetLine."Reason Code",
                    TransShptHeader."Posting Date",
                    TransactionNo);

                // Create posted shipment asset line
                CreatePostedShipmentAssetLine(TransferAssetLine, TransShptHeader, TransferHeader, TransactionNo);

                // Update source line
                TransferAssetLine."Quantity Shipped" += TransferAssetLine."Quantity to Ship";
                TransferAssetLine."Quantity to Ship" := 0;
                TransferAssetLine."Quantity to Receive" := 1; // Ready for receipt
                TransferAssetLine.Modify();
            until TransferAssetLine.Next() = 0;
    end;

    local procedure UpdateReceiptQuantities(TransferHeader: Record "Transfer Header"; TransRcptHeader: Record "Transfer Receipt Header")
    var
        TransferAssetLine: Record "JML AP Transfer Asset Line";
    begin
        // Update quantity received on asset lines
        // No actual asset transfer happens at receipt (already done at shipment)
        TransferAssetLine.SetRange("Document No.", TransferHeader."No.");
        TransferAssetLine.SetFilter("Quantity to Receive", '>0');

        if TransferAssetLine.FindSet(true) then
            repeat
                TransferAssetLine."Quantity Received" += TransferAssetLine."Quantity to Receive";
                TransferAssetLine."Quantity to Receive" := 0;
                TransferAssetLine.Modify();
            until TransferAssetLine.Next() = 0;
    end;

    local procedure PostAssetTransferViaJournal(var Asset: Record "JML AP Asset"; NewHolderType: Enum "JML AP Holder Type"; NewHolderCode: Code[20]; DocumentNo: Code[20]; ReasonCode: Code[10]; PostingDate: Date; TransactionNo: Integer)
    var
        AssetJournalBatch: Record "JML AP Asset Journal Batch";
        AssetJournalLine: Record "JML AP Asset Journal Line";
        AssetJnlPost: Codeunit "JML AP Asset Jnl.-Post";
    begin
        // Get or create system journal batch
        if not AssetJournalBatch.Get('TRANS-POST') then begin
            AssetJournalBatch.Init();
            AssetJournalBatch.Name := 'TRANS-POST';
            AssetJournalBatch.Description := 'System batch for transfer document posting';
            AssetJournalBatch.Insert();
        end;

        // Delete any existing lines
        AssetJournalLine.SetRange("Journal Batch Name", AssetJournalBatch.Name);
        AssetJournalLine.DeleteAll();

        // Create journal line
        AssetJournalLine.Init();
        AssetJournalLine."Journal Batch Name" := AssetJournalBatch.Name;
        AssetJournalLine."Line No." := 10000;
        AssetJournalLine."Posting Date" := PostingDate;
        AssetJournalLine."Document No." := DocumentNo;
        AssetJournalLine."Asset No." := Asset."No.";
        AssetJournalLine."New Holder Type" := NewHolderType;
        AssetJournalLine."New Holder Code" := NewHolderCode;
        AssetJournalLine."Reason Code" := ReasonCode;
        AssetJournalLine.Insert(true);

        // Post journal
        AssetJnlPost.Run(AssetJournalLine);
    end;

    local procedure CreatePostedShipmentAssetLine(TransferAssetLine: Record "JML AP Transfer Asset Line"; TransShptHeader: Record "Transfer Shipment Header"; TransferHeader: Record "Transfer Header"; TransactionNo: Integer)
    var
        PostedAssetLine: Record "JML AP Pstd Trans Shpt Ast Ln";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LineNo: Integer;
    begin
        // Get next line number
        PostedAssetLine.SetRange("Document No.", TransShptHeader."No.");
        if PostedAssetLine.FindLast() then
            LineNo := PostedAssetLine."Line No." + 10000
        else
            LineNo := 10000;

        // Get location names
        if LocationFrom.Get(TransferHeader."Transfer-from Code") then;
        if LocationTo.Get(TransferHeader."Transfer-to Code") then;

        // Create posted line
        PostedAssetLine.Init();
        PostedAssetLine."Document No." := TransShptHeader."No.";
        PostedAssetLine."Line No." := LineNo;
        PostedAssetLine."Asset No." := TransferAssetLine."Asset No.";
        PostedAssetLine."Asset Description" := TransferAssetLine."Asset Description";
        PostedAssetLine."Transfer-from Code" := TransferHeader."Transfer-from Code";
        PostedAssetLine."Transfer-from Name" := LocationFrom.Name;
        PostedAssetLine."Transfer-to Code" := TransferHeader."Transfer-to Code";
        PostedAssetLine."Transfer-to Name" := LocationTo.Name;
        PostedAssetLine."Reason Code" := TransferAssetLine."Reason Code";
        PostedAssetLine.Description := TransferAssetLine.Description;
        PostedAssetLine."Posting Date" := TransShptHeader."Posting Date";
        PostedAssetLine."Transaction No." := TransactionNo;
        PostedAssetLine.Insert(true);
    end;

    local procedure GetNextTransactionNo(): Integer
    var
        HolderEntry: Record "JML AP Holder Entry";
    begin
        HolderEntry.LockTable();
        if HolderEntry.FindLast() then
            exit(HolderEntry."Transaction No." + 1)
        else
            exit(1);
    end;
}
