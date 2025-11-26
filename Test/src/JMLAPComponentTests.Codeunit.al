codeunit 50111 "JML AP Component Tests"
{
    Subtype = Test;

    var
        LibraryAssert: Codeunit "Library Assert";

    [Test]
    procedure TestPostComponentInstall_Success()
    var
        Asset: Record "JML AP Asset";
        Item: Record Item;
        AssetJnlBatch: Record "JML AP Asset Journal Batch";
        ComponentJnlLine: Record "JML AP Component Journal Line";
        ComponentEntry: Record "JML AP Component Entry";
        ComponentJnlPost: Codeunit "JML AP Component Jnl.-Post";
    begin
        // [FEATURE] Component Ledger Posting
        // [SCENARIO] Post component journal line with Install entry type
        // [GIVEN] Asset, Item, and Component Journal Line with Install type and positive quantity
        CreateTestAsset(Asset);
        CreateTestItem(Item);
        CreateTestJournalBatch(AssetJnlBatch);
        CreateComponentJournalLine(ComponentJnlLine, AssetJnlBatch."Name", Asset."No.", Item."No.", ComponentJnlLine."Entry Type"::Install, 1);

        // [WHEN] Post component journal
        ComponentJnlPost.SetSuppressConfirmation(true);
        ComponentJnlPost.SetSuppressSuccessMessage(true);
        ComponentJnlPost.Run(ComponentJnlLine);

        // [THEN] Component Entry created with correct values
        ComponentEntry.SetRange("Asset No.", Asset."No.");
        ComponentEntry.SetRange("Item No.", Item."No.");
        LibraryAssert.RecordCount(ComponentEntry, 1);
        ComponentEntry.FindFirst();
        LibraryAssert.AreEqual(1, ComponentEntry."Entry No.", 'Entry No. should be 1');
        LibraryAssert.AreEqual(1, ComponentEntry.Quantity, 'Quantity should be 1');
        LibraryAssert.AreEqual(ComponentEntry."Entry Type"::Install, ComponentEntry."Entry Type", 'Entry Type should be Install');

        // [THEN] Journal line deleted
        ComponentJnlLine.SetRange("Journal Batch", AssetJnlBatch."Name");
        LibraryAssert.RecordIsEmpty(ComponentJnlLine);
    end;

    [Test]
    procedure TestPostComponentRemove_Success()
    var
        Asset: Record "JML AP Asset";
        Item: Record Item;
        AssetJnlBatch: Record "JML AP Asset Journal Batch";
        ComponentJnlLine: Record "JML AP Component Journal Line";
        ComponentEntry: Record "JML AP Component Entry";
        ComponentJnlPost: Codeunit "JML AP Component Jnl.-Post";
    begin
        // [SCENARIO] Post component journal line with Remove entry type
        // [GIVEN] Asset, Item, and Component Journal Line with Remove type and negative quantity
        CreateTestAsset(Asset);
        CreateTestItem(Item);
        CreateTestJournalBatch(AssetJnlBatch);
        CreateComponentJournalLine(ComponentJnlLine, AssetJnlBatch."Name", Asset."No.", Item."No.", ComponentJnlLine."Entry Type"::Remove, -1);

        // [WHEN] Post component journal
        ComponentJnlPost.SetSuppressConfirmation(true);
        ComponentJnlPost.SetSuppressSuccessMessage(true);
        ComponentJnlPost.Run(ComponentJnlLine);

        // [THEN] Component Entry created with correct values
        ComponentEntry.SetRange("Asset No.", Asset."No.");
        ComponentEntry.SetRange("Item No.", Item."No.");
        LibraryAssert.RecordCount(ComponentEntry, 1);
        ComponentEntry.FindFirst();
        LibraryAssert.AreEqual(-1, ComponentEntry.Quantity, 'Quantity should be -1');
        LibraryAssert.AreEqual(ComponentEntry."Entry Type"::Remove, ComponentEntry."Entry Type", 'Entry Type should be Remove');
    end;

    [Test]
    procedure TestPostComponentJournal_MissingAsset_Error()
    var
        Item: Record Item;
        AssetJnlBatch: Record "JML AP Asset Journal Batch";
        ComponentJnlLine: Record "JML AP Component Journal Line";
        ComponentJnlPost: Codeunit "JML AP Component Jnl.-Post";
    begin
        // [SCENARIO] Posting fails when Asset does not exist
        // [GIVEN] Item and Component Journal Line with non-existent Asset
        CreateTestItem(Item);
        CreateTestJournalBatch(AssetJnlBatch);
        CreateComponentJournalLine(ComponentJnlLine, AssetJnlBatch."Name", 'NONEXIST', Item."No.", ComponentJnlLine."Entry Type"::Install, 1);

        // [WHEN] Post component journal
        ComponentJnlPost.SetSuppressConfirmation(true);
        ComponentJnlPost.SetSuppressSuccessMessage(true);
        asserterror ComponentJnlPost.Run(ComponentJnlLine);

        // [THEN] Error thrown
        LibraryAssert.ExpectedError('Asset NONEXIST does not exist');
    end;

    [Test]
    procedure TestPostComponentJournal_MissingItem_Error()
    var
        Asset: Record "JML AP Asset";
        AssetJnlBatch: Record "JML AP Asset Journal Batch";
        ComponentJnlLine: Record "JML AP Component Journal Line";
        ComponentJnlPost: Codeunit "JML AP Component Jnl.-Post";
    begin
        // [SCENARIO] Posting fails when Item does not exist
        // [GIVEN] Asset and Component Journal Line with non-existent Item
        CreateTestAsset(Asset);
        CreateTestJournalBatch(AssetJnlBatch);
        CreateComponentJournalLine(ComponentJnlLine, AssetJnlBatch."Name", Asset."No.", 'NONEXIST', ComponentJnlLine."Entry Type"::Install, 1);

        // [WHEN] Post component journal
        ComponentJnlPost.SetSuppressConfirmation(true);
        ComponentJnlPost.SetSuppressSuccessMessage(true);
        asserterror ComponentJnlPost.Run(ComponentJnlLine);

        // [THEN] Error thrown
        LibraryAssert.ExpectedError('Item NONEXIST does not exist');
    end;

    [Test]
    procedure TestPostComponentJournal_InstallNegativeQty_Error()
    var
        Asset: Record "JML AP Asset";
        Item: Record Item;
        AssetJnlBatch: Record "JML AP Asset Journal Batch";
        ComponentJnlLine: Record "JML AP Component Journal Line";
        ComponentJnlPost: Codeunit "JML AP Component Jnl.-Post";
    begin
        // [SCENARIO] Posting fails when Install has negative quantity
        // [GIVEN] Component Journal Line with Install type and negative quantity
        CreateTestAsset(Asset);
        CreateTestItem(Item);
        CreateTestJournalBatch(AssetJnlBatch);
        CreateComponentJournalLine(ComponentJnlLine, AssetJnlBatch."Name", Asset."No.", Item."No.", ComponentJnlLine."Entry Type"::Install, -1);

        // [WHEN] Post component journal
        ComponentJnlPost.SetSuppressConfirmation(true);
        ComponentJnlPost.SetSuppressSuccessMessage(true);
        asserterror ComponentJnlPost.Run(ComponentJnlLine);

        // [THEN] Error thrown about quantity sign
        LibraryAssert.ExpectedError('Quantity must be positive');
    end;

    [Test]
    procedure TestPostComponentJournal_RemovePositiveQty_Error()
    var
        Asset: Record "JML AP Asset";
        Item: Record Item;
        AssetJnlBatch: Record "JML AP Asset Journal Batch";
        ComponentJnlLine: Record "JML AP Component Journal Line";
        ComponentJnlPost: Codeunit "JML AP Component Jnl.-Post";
    begin
        // [SCENARIO] Posting fails when Remove has positive quantity
        // [GIVEN] Component Journal Line with Remove type and positive quantity
        CreateTestAsset(Asset);
        CreateTestItem(Item);
        CreateTestJournalBatch(AssetJnlBatch);
        CreateComponentJournalLine(ComponentJnlLine, AssetJnlBatch."Name", Asset."No.", Item."No.", ComponentJnlLine."Entry Type"::Remove, 1);

        // [WHEN] Post component journal
        ComponentJnlPost.SetSuppressConfirmation(true);
        ComponentJnlPost.SetSuppressSuccessMessage(true);
        asserterror ComponentJnlPost.Run(ComponentJnlLine);

        // [THEN] Error thrown about quantity sign
        LibraryAssert.ExpectedError('Quantity must be negative');
    end;

    [Test]
    procedure TestPostComponentJournal_TransactionNoAssigned()
    var
        Asset: Record "JML AP Asset";
        Item: Record Item;
        AssetJnlBatch: Record "JML AP Asset Journal Batch";
        ComponentJnlLine: Record "JML AP Component Journal Line";
        ComponentEntry: Record "JML AP Component Entry";
        ComponentJnlPost: Codeunit "JML AP Component Jnl.-Post";
    begin
        // [SCENARIO] Transaction No. is assigned and increments correctly
        // [GIVEN] Two component journal lines
        CreateTestAsset(Asset);
        CreateTestItem(Item);
        CreateTestJournalBatch(AssetJnlBatch);
        CreateComponentJournalLine(ComponentJnlLine, AssetJnlBatch."Name", Asset."No.", Item."No.", ComponentJnlLine."Entry Type"::Install, 1);
        CreateComponentJournalLine(ComponentJnlLine, AssetJnlBatch."Name", Asset."No.", Item."No.", ComponentJnlLine."Entry Type"::Remove, -1);

        // [WHEN] Post component journal
        ComponentJnlPost.SetSuppressConfirmation(true);
        ComponentJnlPost.SetSuppressSuccessMessage(true);
        ComponentJnlPost.Run(ComponentJnlLine);

        // [THEN] Two entries created with Transaction Nos. 1 and 2
        ComponentEntry.SetRange("Asset No.", Asset."No.");
        LibraryAssert.RecordCount(ComponentEntry, 2);
        ComponentEntry.FindSet();
        LibraryAssert.AreEqual(1, ComponentEntry."Transaction No.", 'First Transaction No. should be 1');
        ComponentEntry.Next();
        LibraryAssert.AreEqual(2, ComponentEntry."Transaction No.", 'Second Transaction No. should be 2');
    end;

    [Test]
    procedure TestEntryNoAssignment_Sequential()
    var
        Asset: Record "JML AP Asset";
        Item: Record Item;
        AssetJnlBatch: Record "JML AP Asset Journal Batch";
        ComponentJnlLine: Record "JML AP Component Journal Line";
        ComponentEntry: Record "JML AP Component Entry";
        ComponentJnlPost: Codeunit "JML AP Component Jnl.-Post";
    begin
        // [SCENARIO] Entry No. is assigned sequentially using BC pattern
        // [GIVEN] Three component journal lines
        CreateTestAsset(Asset);
        CreateTestItem(Item);
        CreateTestJournalBatch(AssetJnlBatch);
        CreateComponentJournalLine(ComponentJnlLine, AssetJnlBatch."Name", Asset."No.", Item."No.", ComponentJnlLine."Entry Type"::Install, 1);
        CreateComponentJournalLine(ComponentJnlLine, AssetJnlBatch."Name", Asset."No.", Item."No.", ComponentJnlLine."Entry Type"::Install, 2);
        CreateComponentJournalLine(ComponentJnlLine, AssetJnlBatch."Name", Asset."No.", Item."No.", ComponentJnlLine."Entry Type"::Remove, -1);

        // [WHEN] Post component journal
        ComponentJnlPost.SetSuppressConfirmation(true);
        ComponentJnlPost.SetSuppressSuccessMessage(true);
        ComponentJnlPost.Run(ComponentJnlLine);

        // [THEN] Three entries created with Entry Nos. 1, 2, 3
        ComponentEntry.SetRange("Asset No.", Asset."No.");
        LibraryAssert.RecordCount(ComponentEntry, 3);
        ComponentEntry.FindSet();
        LibraryAssert.AreEqual(1, ComponentEntry."Entry No.", 'First Entry No. should be 1');
        ComponentEntry.Next();
        LibraryAssert.AreEqual(2, ComponentEntry."Entry No.", 'Second Entry No. should be 2');
        ComponentEntry.Next();
        LibraryAssert.AreEqual(3, ComponentEntry."Entry No.", 'Third Entry No. should be 3');
    end;

    local procedure CreateTestAsset(var Asset: Record "JML AP Asset")
    begin
        Asset.Init();
        Asset."No." := 'TEST-ASSET-' + Format(CreateGuid());
        Asset.Description := 'Test Asset for Component Tests';
        Asset.Insert(true);
    end;

    local procedure CreateTestItem(var Item: Record Item)
    begin
        Item.Init();
        Item."No." := 'TEST-ITEM-' + Format(CreateGuid());
        Item.Description := 'Test Item for Component Tests';
        Item."Base Unit of Measure" := 'PCS';
        Item.Insert(true);
    end;

    local procedure CreateTestJournalBatch(var AssetJnlBatch: Record "JML AP Asset Journal Batch")
    begin
        AssetJnlBatch.Init();
        AssetJnlBatch."Name" := 'TESTBATCH';
        if AssetJnlBatch.Insert(true) then;
    end;

    local procedure CreateComponentJournalLine(
        var ComponentJnlLine: Record "JML AP Component Journal Line";
        JournalBatch: Code[20];
        AssetNo: Code[20];
        ItemNo: Code[20];
        EntryType: Enum "JML AP Component Entry Type";
        Qty: Decimal)
    var
        NextLineNo: Integer;
    begin
        ComponentJnlLine.SetRange("Journal Batch", JournalBatch);
        if ComponentJnlLine.FindLast() then
            NextLineNo := ComponentJnlLine."Line No." + 10000
        else
            NextLineNo := 10000;

        ComponentJnlLine.Init();
        ComponentJnlLine."Journal Batch" := JournalBatch;
        ComponentJnlLine."Line No." := NextLineNo;
        ComponentJnlLine."Asset No." := AssetNo;
        ComponentJnlLine."Item No." := ItemNo;
        ComponentJnlLine."Entry Type" := EntryType;
        ComponentJnlLine.Quantity := Qty;
        ComponentJnlLine."Posting Date" := WorkDate();
        ComponentJnlLine."Document No." := 'TEST-DOC';
        ComponentJnlLine.Insert(true);
    end;
}
