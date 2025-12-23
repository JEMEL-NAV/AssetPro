codeunit 50111 "JML AP Component Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";
        TestLibrary: Codeunit "JML AP Test Library";
        IsInitialized: Boolean;

    [Test]
    procedure TestPostComponentInstall_Success()
    var
        Asset: Record "JML AP Asset";
        Item: Record Item;
        ComponentJnlBatch: Record "JML AP Component Jnl. Batch";
        ComponentJnlLine: Record "JML AP Component Journal Line";
        ComponentEntry: Record "JML AP Component Entry";
        ComponentJnlPost: Codeunit "JML AP Component Jnl.-Post";
    begin
        // [FEATURE] Component Ledger Posting
        // [SCENARIO] Post component journal line with Install entry type
        TestLibrary.Initialize();

        // [GIVEN] Asset, Item, and Component Journal Line with Install type and positive quantity
        Asset := TestLibrary.CreateTestAsset('Test Asset');
        Item := TestLibrary.CreateTestItem('Test Item');
        CreateTestJournalBatch(ComponentJnlBatch);
        CreateComponentJournalLine(ComponentJnlLine, ComponentJnlBatch."Name", Asset."No.", Item."No.", ComponentJnlLine."Entry Type"::Install, 1);

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
        ComponentJnlLine.SetRange("Journal Batch", ComponentJnlBatch."Name");
        LibraryAssert.RecordIsEmpty(ComponentJnlLine);
    end;

    [Test]
    procedure TestPostComponentRemove_Success()
    var
        Asset: Record "JML AP Asset";
        Item: Record Item;
        ComponentJnlBatch: Record "JML AP Component Jnl. Batch";
        ComponentJnlLine: Record "JML AP Component Journal Line";
        ComponentEntry: Record "JML AP Component Entry";
        ComponentJnlPost: Codeunit "JML AP Component Jnl.-Post";
    begin
        // [SCENARIO] Post component journal line with Remove entry type
        TestLibrary.Initialize();

        // [GIVEN] Asset, Item, and Component Journal Line with Remove type and negative quantity
        Asset := TestLibrary.CreateTestAsset('Test Asset');
        Item := TestLibrary.CreateTestItem('Test Item');
        CreateTestJournalBatch(ComponentJnlBatch);
        CreateComponentJournalLine(ComponentJnlLine, ComponentJnlBatch."Name", Asset."No.", Item."No.", ComponentJnlLine."Entry Type"::Remove, -1);

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
        ComponentJnlBatch: Record "JML AP Component Jnl. Batch";
        ComponentJnlLine: Record "JML AP Component Journal Line";
        ComponentJnlPost: Codeunit "JML AP Component Jnl.-Post";
    begin
        // [SCENARIO] Posting fails when Asset does not exist
        TestLibrary.Initialize();

        // [GIVEN] Item and Component Journal Line with non-existent Asset
        Item := TestLibrary.CreateTestItem('Test Item');
        CreateTestJournalBatch(ComponentJnlBatch);
        CreateComponentJournalLine(ComponentJnlLine, ComponentJnlBatch."Name", 'NONEXIST', Item."No.", ComponentJnlLine."Entry Type"::Install, 1);

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
        ComponentJnlBatch: Record "JML AP Component Jnl. Batch";
        ComponentJnlLine: Record "JML AP Component Journal Line";
        ComponentJnlPost: Codeunit "JML AP Component Jnl.-Post";
    begin
        // [SCENARIO] Posting fails when Item does not exist
        TestLibrary.Initialize();

        // [GIVEN] Asset and Component Journal Line with non-existent Item
        Asset := TestLibrary.CreateTestAsset('Test Asset');
        CreateTestJournalBatch(ComponentJnlBatch);
        CreateComponentJournalLine(ComponentJnlLine, ComponentJnlBatch."Name", Asset."No.", 'NONEXIST', ComponentJnlLine."Entry Type"::Install, 1);

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
        ComponentJnlBatch: Record "JML AP Component Jnl. Batch";
        ComponentJnlLine: Record "JML AP Component Journal Line";
        ComponentJnlPost: Codeunit "JML AP Component Jnl.-Post";
    begin
        // [SCENARIO] Posting fails when Install has negative quantity
        TestLibrary.Initialize();

        // [GIVEN] Component Journal Line with Install type and negative quantity
        Asset := TestLibrary.CreateTestAsset('Test Asset');
        Item := TestLibrary.CreateTestItem('Test Item');
        CreateTestJournalBatch(ComponentJnlBatch);
        CreateComponentJournalLine(ComponentJnlLine, ComponentJnlBatch."Name", Asset."No.", Item."No.", ComponentJnlLine."Entry Type"::Install, -1);

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
        ComponentJnlBatch: Record "JML AP Component Jnl. Batch";
        ComponentJnlLine: Record "JML AP Component Journal Line";
        ComponentJnlPost: Codeunit "JML AP Component Jnl.-Post";
    begin
        // [SCENARIO] Posting fails when Remove has positive quantity
        TestLibrary.Initialize();

        // [GIVEN] Component Journal Line with Remove type and positive quantity
        Asset := TestLibrary.CreateTestAsset('Test Asset');
        Item := TestLibrary.CreateTestItem('Test Item');
        CreateTestJournalBatch(ComponentJnlBatch);
        CreateComponentJournalLine(ComponentJnlLine, ComponentJnlBatch."Name", Asset."No.", Item."No.", ComponentJnlLine."Entry Type"::Remove, 1);

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
        ComponentJnlBatch: Record "JML AP Component Jnl. Batch";
        ComponentJnlLine: Record "JML AP Component Journal Line";
        ComponentEntry: Record "JML AP Component Entry";
        ComponentJnlPost: Codeunit "JML AP Component Jnl.-Post";
    begin
        // [SCENARIO] Transaction No. is assigned and increments correctly
        TestLibrary.Initialize();

        // [GIVEN] Two component journal lines
        Asset := TestLibrary.CreateTestAsset('Test Asset');
        Item := TestLibrary.CreateTestItem('Test Item');
        CreateTestJournalBatch(ComponentJnlBatch);
        CreateComponentJournalLine(ComponentJnlLine, ComponentJnlBatch."Name", Asset."No.", Item."No.", ComponentJnlLine."Entry Type"::Install, 1);
        CreateComponentJournalLine(ComponentJnlLine, ComponentJnlBatch."Name", Asset."No.", Item."No.", ComponentJnlLine."Entry Type"::Remove, -1);

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
        ComponentJnlBatch: Record "JML AP Component Jnl. Batch";
        ComponentJnlLine: Record "JML AP Component Journal Line";
        ComponentEntry: Record "JML AP Component Entry";
        ComponentJnlPost: Codeunit "JML AP Component Jnl.-Post";
    begin
        // [SCENARIO] Entry No. is assigned sequentially using BC pattern
        TestLibrary.Initialize();

        // [GIVEN] Three component journal lines
        Asset := TestLibrary.CreateTestAsset('Test Asset');
        Item := TestLibrary.CreateTestItem('Test Item');
        CreateTestJournalBatch(ComponentJnlBatch);
        CreateComponentJournalLine(ComponentJnlLine, ComponentJnlBatch."Name", Asset."No.", Item."No.", ComponentJnlLine."Entry Type"::Install, 1);
        CreateComponentJournalLine(ComponentJnlLine, ComponentJnlBatch."Name", Asset."No.", Item."No.", ComponentJnlLine."Entry Type"::Install, 2);
        CreateComponentJournalLine(ComponentJnlLine, ComponentJnlBatch."Name", Asset."No.", Item."No.", ComponentJnlLine."Entry Type"::Remove, -1);

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

    local procedure CreateTestJournalBatch(var ComponentJnlBatch: Record "JML AP Component Jnl. Batch")
    begin
        // Try to get existing batch first, create if doesn't exist
        if ComponentJnlBatch.Get('TESTBATCH') then
            exit;

        ComponentJnlBatch.Init();
        ComponentJnlBatch."Name" := 'TESTBATCH';
        ComponentJnlBatch.Insert(true);
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
