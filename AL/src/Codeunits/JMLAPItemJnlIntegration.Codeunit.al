codeunit 70182397 "JML AP Item Jnl. Integration"
{
    // Event subscriber for Item Journal posting integration with Component Ledger
    // When Item Journal is posted with Asset No. populated, automatically creates component entries

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnAfterInsertItemLedgEntry', '', false, false)]
    local procedure OnAfterInsertItemLedgEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line"; var ItemLedgEntryNo: Integer; var ValueEntryNo: Integer; var ItemApplnEntryNo: Integer; GlobalValueEntry: Record "Value Entry"; TransferItem: Boolean; var InventoryPostingToGL: Codeunit "Inventory Posting To G/L"; var OldItemLedgerEntry: Record "Item Ledger Entry")
    var
        ItemJnlLineWithAsset: Record "Item Journal Line";
    begin
        // Get the extended record with Asset No. field
        if not ItemJnlLineWithAsset.Get(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name", ItemJournalLine."Line No.") then
            exit;

        // Check if component entry should be created
        if not ShouldCreateComponentEntry(ItemJnlLineWithAsset, ItemLedgerEntry) then
            exit;

        // Create and post component entry
        CreateAndPostComponentEntry(ItemJnlLineWithAsset, ItemLedgerEntry);
    end;

    local procedure ShouldCreateComponentEntry(ItemJnlLine: Record "Item Journal Line"; ItemLedgerEntry: Record "Item Ledger Entry"): Boolean
    var
        ItemLedgerEntryType: Enum "Item Ledger Entry Type";
    begin
        // Must have Asset No. populated
        if ItemJnlLine."JML AP Asset No." = '' then
            exit(false);

        // Must have Item No.
        if ItemJnlLine."Item No." = '' then
            exit(false);

        // Only process specific entry types
        case ItemLedgerEntry."Entry Type" of
            ItemLedgerEntryType::Sale,
            ItemLedgerEntryType::"Positive Adjmt.",
            ItemLedgerEntryType::"Negative Adjmt.",
            ItemLedgerEntryType::Consumption:
                exit(true);
            else
                exit(false);
        end;
    end;

    local procedure CreateAndPostComponentEntry(ItemJnlLine: Record "Item Journal Line"; ItemLedgerEntry: Record "Item Ledger Entry")
    var
        ComponentJnlLine: Record "JML AP Component Journal Line";
        ComponentJnlBatch: Record "JML AP Component Jnl. Batch";
        ComponentJnlPost: Codeunit "JML AP Component Jnl.-Post";
        BatchName: Code[20];
    begin
        // Get or create system batch for posting
        BatchName := 'ITEM-JNL';
        if not ComponentJnlBatch.Get(BatchName) then begin
            ComponentJnlBatch.Init();
            ComponentJnlBatch.Name := BatchName;
            ComponentJnlBatch.Description := 'Item Journal Integration';
            ComponentJnlBatch.Insert(true);
        end;

        // Create component journal line
        ComponentJnlLine.Init();
        ComponentJnlLine."Journal Batch" := BatchName;
        ComponentJnlLine."Line No." := GetNextLineNo(BatchName);
        ComponentJnlLine."Asset No." := ItemJnlLine."JML AP Asset No.";
        ComponentJnlLine."Item No." := ItemJnlLine."Item No.";
        ComponentJnlLine."Variant Code" := ItemJnlLine."Variant Code";
        ComponentJnlLine."Entry Type" := MapItemEntryTypeToComponentType(ItemLedgerEntry."Entry Type", ItemLedgerEntry.Quantity);
        ComponentJnlLine.Quantity := MapQuantitySign(ItemLedgerEntry."Entry Type", ItemLedgerEntry.Quantity);
        ComponentJnlLine."Unit of Measure Code" := ItemJnlLine."Unit of Measure Code";
        ComponentJnlLine."Serial No." := ItemJnlLine."Serial No.";
        ComponentJnlLine."Lot No." := ItemJnlLine."Lot No.";
        ComponentJnlLine."Posting Date" := ItemJnlLine."Posting Date";
        ComponentJnlLine."Reason Code" := ItemJnlLine."Reason Code";
        ComponentJnlLine."Document No." := Format(ItemLedgerEntry."Entry No."); // Link to Item Ledger Entry
        ComponentJnlLine."External Document No." := ItemJnlLine."External Document No.";
        ComponentJnlLine."Item Ledger Entry No." := ItemLedgerEntry."Entry No."; // Direct link for traceability
        ComponentJnlLine.Insert(true);

        // Post component journal (suppress UI dialogs)
        ComponentJnlPost.SetSuppressConfirmation(true);
        ComponentJnlPost.SetSuppressSuccessMessage(true);
        ComponentJnlLine.SetRange("Journal Batch", BatchName);
        ComponentJnlPost.Run(ComponentJnlLine);
    end;

    local procedure MapItemEntryTypeToComponentType(ItemEntryType: Enum "Item Ledger Entry Type"; Quantity: Decimal) ComponentEntryType: Enum "JML AP Component Entry Type"
    var
        ItemLedgerEntryType: Enum "Item Ledger Entry Type";
        ComponentType: Enum "JML AP Component Entry Type";
    begin
        // Inventory-centric logic: When stock decreases, component goes INTO asset (Install)
        // When stock increases, component is removed FROM asset (Remove)
        case ItemEntryType of
            ItemLedgerEntryType::Sale,              // Stock decreases → Install in asset
            ItemLedgerEntryType::"Negative Adjmt.", // Stock decreases → Install in asset
            ItemLedgerEntryType::Consumption:        // Stock consumed → Install in asset
                exit(ComponentType::Install);
            ItemLedgerEntryType::"Positive Adjmt.":  // Stock increases → Remove from asset
                exit(ComponentType::Remove);
            else
                exit(ComponentType::Install); // Default fallback
        end;
    end;

    local procedure MapQuantitySign(ItemEntryType: Enum "Item Ledger Entry Type"; Quantity: Decimal): Decimal
    var
        ItemLedgerEntryType: Enum "Item Ledger Entry Type";
    begin
        // Component Entry Type validation requires:
        // - Install: Positive quantity
        // - Remove: Negative quantity

        case ItemEntryType of
            ItemLedgerEntryType::Sale,              // Already negative → make positive for Install
            ItemLedgerEntryType::"Negative Adjmt.", // Already negative → make positive for Install
            ItemLedgerEntryType::Consumption:        // Already negative → make positive for Install
                exit(Abs(Quantity)); // Ensure positive for Install
            ItemLedgerEntryType::"Positive Adjmt.":  // Already positive → make negative for Remove
                exit(-Abs(Quantity)); // Ensure negative for Remove
            else
                exit(Quantity); // Preserve original sign
        end;
    end;

    local procedure GetNextLineNo(BatchName: Code[20]): Integer
    var
        ComponentJnlLine: Record "JML AP Component Journal Line";
    begin
        ComponentJnlLine.SetRange("Journal Batch", BatchName);
        if ComponentJnlLine.FindLast() then
            exit(ComponentJnlLine."Line No." + 10000)
        else
            exit(10000);
    end;
}
