codeunit 50109 "JML AP Relationship Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        TestLibrary: Codeunit "JML AP Test Library";

    [Test]
    procedure TestLogAttachEvent_CreatesEntryWithCorrectFields()
    var
        ParentAsset: Record "JML AP Asset";
        ChildAsset: Record "JML AP Asset";
        RelationshipEntry: Record "JML AP Asset Relation Entry";
        RelationshipMgt: Codeunit "JML AP Relationship Mgt";
        EntryNo: Integer;
        TestPostingDate: Date;
    begin
        // [SCENARIO] LogAttachEvent creates a relationship entry with correct field values

        // [GIVEN] A parent asset and a child asset
        ParentAsset := TestLibrary.CreateTestAsset('Parent Asset for Test');
        ChildAsset := TestLibrary.CreateTestAsset('Child Asset for Test');
        TestPostingDate := WorkDate();

        // [WHEN] LogAttachEvent is called
        EntryNo := RelationshipMgt.LogAttachEvent(ChildAsset."No.", ParentAsset."No.", 'TEST', TestPostingDate);

        // [THEN] A relationship entry is created with correct values
        Assert.IsTrue(RelationshipEntry.Get(EntryNo), 'Relationship entry should be created');
        Assert.AreEqual(RelationshipEntry."Entry Type"::Attach, RelationshipEntry."Entry Type", 'Entry type should be Attach');
        Assert.AreEqual(ChildAsset."No.", RelationshipEntry."Asset No.", 'Asset No. should match');
        Assert.AreEqual(ParentAsset."No.", RelationshipEntry."Parent Asset No.", 'Parent Asset No. should match');
        Assert.AreEqual(TestPostingDate, RelationshipEntry."Posting Date", 'Posting Date should match');
        Assert.AreEqual('TEST', RelationshipEntry."Reason Code", 'Reason Code should match');
        Assert.AreEqual(ChildAsset."Current Holder Type", RelationshipEntry."Holder Type at Entry", 'Holder Type should be captured');
        Assert.AreEqual(ChildAsset."Current Holder Code", RelationshipEntry."Holder Code at Entry", 'Holder Code should be captured');
        Assert.AreNotEqual(0, RelationshipEntry."Transaction No.", 'Transaction No. should be assigned');

    end;

    [Test]
    procedure TestLogDetachEvent_CreatesEntryWithCorrectFields()
    var
        ParentAsset: Record "JML AP Asset";
        ChildAsset: Record "JML AP Asset";
        RelationshipEntry: Record "JML AP Asset Relation Entry";
        RelationshipMgt: Codeunit "JML AP Relationship Mgt";
        EntryNo: Integer;
        TestPostingDate: Date;
    begin
        // [SCENARIO] LogDetachEvent creates a relationship entry with correct field values

        // [GIVEN] A parent asset and a child asset
        ParentAsset := TestLibrary.CreateTestAsset('Parent Asset for Test');
        ChildAsset := TestLibrary.CreateTestAsset('Child Asset for Test');
        TestPostingDate := WorkDate();

        // [WHEN] LogDetachEvent is called
        EntryNo := RelationshipMgt.LogDetachEvent(ChildAsset."No.", ParentAsset."No.", 'DETACH', TestPostingDate);

        // [THEN] A relationship entry is created with correct values
        Assert.IsTrue(RelationshipEntry.Get(EntryNo), 'Relationship entry should be created');
        Assert.AreEqual(RelationshipEntry."Entry Type"::Detach, RelationshipEntry."Entry Type", 'Entry type should be Detach');
        Assert.AreEqual(ChildAsset."No.", RelationshipEntry."Asset No.", 'Asset No. should match');
        Assert.AreEqual(ParentAsset."No.", RelationshipEntry."Parent Asset No.", 'Parent Asset No. should match');
        Assert.AreEqual(TestPostingDate, RelationshipEntry."Posting Date", 'Posting Date should match');
        Assert.AreEqual('DETACH', RelationshipEntry."Reason Code", 'Reason Code should match');
        Assert.AreNotEqual(0, RelationshipEntry."Transaction No.", 'Transaction No. should be assigned');

    end;

    [Test]
    procedure TestMultipleAttachDetachCycles_MaintainsCompleteHistory()
    var
        ParentAsset: Record "JML AP Asset";
        ChildAsset: Record "JML AP Asset";
        RelationshipEntry: Record "JML AP Asset Relation Entry";
        RelationshipMgt: Codeunit "JML AP Relationship Mgt";
        EntryCount: Integer;
    begin
        // [SCENARIO] Multiple attach/detach cycles create complete audit history

        // [GIVEN] A parent asset and a child asset
        ParentAsset := TestLibrary.CreateTestAsset('Parent Asset for Test');
        ChildAsset := TestLibrary.CreateTestAsset('Child Asset for Test');

        // [WHEN] Multiple attach and detach events occur
        RelationshipMgt.LogAttachEvent(ChildAsset."No.", ParentAsset."No.", 'INITIAL', WorkDate());
        RelationshipMgt.LogDetachEvent(ChildAsset."No.", ParentAsset."No.", 'MAINT', WorkDate() + 10);
        RelationshipMgt.LogAttachEvent(ChildAsset."No.", ParentAsset."No.", 'REATTACH', WorkDate() + 20);
        RelationshipMgt.LogDetachEvent(ChildAsset."No.", ParentAsset."No.", 'FINAL', WorkDate() + 30);

        // [THEN] All four entries exist in the history
        RelationshipMgt.GetRelationshipHistory(ChildAsset."No.", RelationshipEntry);
        EntryCount := RelationshipEntry.Count();
        Assert.AreEqual(4, EntryCount, 'Should have 4 relationship entries in history');

        // [THEN] Entries are in correct order
        RelationshipEntry.FindFirst();
        Assert.AreEqual(RelationshipEntry."Entry Type"::Attach, RelationshipEntry."Entry Type", 'First entry should be Attach');
        Assert.AreEqual('INITIAL', RelationshipEntry."Reason Code", 'First entry reason should be INITIAL');

        RelationshipEntry.Next();
        Assert.AreEqual(RelationshipEntry."Entry Type"::Detach, RelationshipEntry."Entry Type", 'Second entry should be Detach');

        RelationshipEntry.Next();
        Assert.AreEqual(RelationshipEntry."Entry Type"::Attach, RelationshipEntry."Entry Type", 'Third entry should be Attach');

        RelationshipEntry.Next();
        Assert.AreEqual(RelationshipEntry."Entry Type"::Detach, RelationshipEntry."Entry Type", 'Fourth entry should be Detach');

    end;

    [Test]
    procedure TestHolderCapturedAtMomentOfChange()
    var
        ParentAsset: Record "JML AP Asset";
        ChildAsset: Record "JML AP Asset";
        Customer: Record Customer;
        Location: Record Location;
        RelationshipEntry: Record "JML AP Asset Relation Entry";
        RelationshipMgt: Codeunit "JML AP Relationship Mgt";
        EntryNo1: Integer;
        EntryNo2: Integer;
    begin
        // [SCENARIO] Holder information is captured at the moment of each relationship change

        // [GIVEN] A parent asset, child asset, customer, and location
        ParentAsset := TestLibrary.CreateTestAsset('Parent Asset for Test');
        ChildAsset := TestLibrary.CreateTestAsset('Child Asset for Test');
        Customer := TestLibrary.CreateTestCustomer('Test Customer');
        Location := TestLibrary.CreateTestLocation('Test Location');

        // [GIVEN] Child asset is initially at customer
        ChildAsset."Current Holder Type" := ChildAsset."Current Holder Type"::Customer;
        ChildAsset."Current Holder Code" := Customer."No.";
        ChildAsset.Modify(true);

        // [WHEN] First attach event occurs while at customer
        EntryNo1 := RelationshipMgt.LogAttachEvent(ChildAsset."No.", ParentAsset."No.", 'ATTACH1', WorkDate());

        // [THEN] First entry captures customer holder
        RelationshipEntry.Get(EntryNo1);
        Assert.AreEqual(RelationshipEntry."Holder Type at Entry"::Customer, RelationshipEntry."Holder Type at Entry", 'Should capture Customer holder type');
        Assert.AreEqual(Customer."No.", RelationshipEntry."Holder Code at Entry", 'Should capture customer code');

        // [GIVEN] Child asset holder changes to location
        ChildAsset."Current Holder Type" := ChildAsset."Current Holder Type"::Location;
        ChildAsset."Current Holder Code" := Location.Code;
        ChildAsset.Modify(true);

        // [WHEN] Detach event occurs while at location
        EntryNo2 := RelationshipMgt.LogDetachEvent(ChildAsset."No.", ParentAsset."No.", 'DETACH1', WorkDate() + 10);

        // [THEN] Second entry captures location holder
        RelationshipEntry.Get(EntryNo2);
        Assert.AreEqual(RelationshipEntry."Holder Type at Entry"::Location, RelationshipEntry."Holder Type at Entry", 'Should capture Location holder type');
        Assert.AreEqual(Location.Code, RelationshipEntry."Holder Code at Entry", 'Should capture location code');

    end;

    [Test]
    procedure TestGetComponentsAtDate_ReturnsCorrectChildren()
    var
        ParentAsset: Record "JML AP Asset";
        Child1: Record "JML AP Asset";
        Child2: Record "JML AP Asset";
        Child3: Record "JML AP Asset";
        TempChildAssets: Record "JML AP Asset" temporary;
        RelationshipMgt: Codeunit "JML AP Relationship Mgt";
        Date1: Date;
        Date2: Date;
        Date3: Date;
    begin
        // [SCENARIO] GetComponentsAtDate returns children that were attached on a specific date

        // [GIVEN] A parent asset and three children with different attach/detach dates
        ParentAsset := TestLibrary.CreateTestAsset('Parent Asset for Test');
        Child1 := TestLibrary.CreateTestAsset('Child 1 for Test');
        Child2 := TestLibrary.CreateTestAsset('Child 2 for Test');
        Child3 := TestLibrary.CreateTestAsset('Child 3 for Test');

        Date1 := WorkDate();
        Date2 := WorkDate() + 10;
        Date3 := WorkDate() + 20;

        // Child1: Attached on Date1, never detached
        RelationshipMgt.LogAttachEvent(Child1."No.", ParentAsset."No.", 'ATTACH', Date1);

        // Child2: Attached on Date1, detached on Date2
        RelationshipMgt.LogAttachEvent(Child2."No.", ParentAsset."No.", 'ATTACH', Date1);
        RelationshipMgt.LogDetachEvent(Child2."No.", ParentAsset."No.", 'DETACH', Date2);

        // Child3: Attached on Date3
        RelationshipMgt.LogAttachEvent(Child3."No.", ParentAsset."No.", 'ATTACH', Date3);

        // [WHEN] Querying components at Date1 + 5
        RelationshipMgt.GetComponentsAtDate(ParentAsset."No.", Date1 + 5, TempChildAssets);

        // [THEN] Should have Child1 and Child2 (both attached, neither detached yet)
        Assert.AreEqual(2, TempChildAssets.Count(), 'Should have 2 children at Date1+5');

        // [WHEN] Querying components at Date2 + 5
        TempChildAssets.Reset();
        TempChildAssets.DeleteAll();
        RelationshipMgt.GetComponentsAtDate(ParentAsset."No.", Date2 + 5, TempChildAssets);

        // [THEN] Should have only Child1 (Child2 was detached, Child3 not attached yet)
        Assert.AreEqual(1, TempChildAssets.Count(), 'Should have 1 child at Date2+5');
        TempChildAssets.FindFirst();
        Assert.AreEqual(Child1."No.", TempChildAssets."No.", 'Should be Child1');

        // [WHEN] Querying components at Date3 + 5
        TempChildAssets.Reset();
        TempChildAssets.DeleteAll();
        RelationshipMgt.GetComponentsAtDate(ParentAsset."No.", Date3 + 5, TempChildAssets);

        // [THEN] Should have Child1 and Child3
        Assert.AreEqual(2, TempChildAssets.Count(), 'Should have 2 children at Date3+5');

    end;

    [Test]
    procedure TestAttachViaFieldValidation_CreatesRelationshipEntry()
    var
        ParentAsset: Record "JML AP Asset";
        ChildAsset: Record "JML AP Asset";
        RelationshipEntry: Record "JML AP Asset Relation Entry";
    begin
        // [SCENARIO] Setting Parent Asset No. field creates attach relationship entry

        // [GIVEN] Two assets with no parent relationship
        ParentAsset := TestLibrary.CreateTestAsset('Parent Asset for Field Test');
        ChildAsset := TestLibrary.CreateTestAsset('Child Asset for Field Test');

        // [WHEN] Set Parent Asset No. field on child asset
        ChildAsset.Get(ChildAsset."No."); // Refresh to ensure xRec is set correctly
        ChildAsset.Validate("Parent Asset No.", ParentAsset."No.");
        ChildAsset.Modify(true);

        // [THEN] Attach entry created with holder captured
        RelationshipEntry.SetRange("Asset No.", ChildAsset."No.");
        RelationshipEntry.SetRange("Parent Asset No.", ParentAsset."No.");
        RelationshipEntry.SetRange("Entry Type", RelationshipEntry."Entry Type"::Attach);
        Assert.RecordIsNotEmpty(RelationshipEntry);

        RelationshipEntry.FindFirst();
        Assert.AreEqual(ChildAsset."Current Holder Type", RelationshipEntry."Holder Type at Entry", 'Holder type should be captured at attach');
        Assert.AreEqual(ChildAsset."Current Holder Code", RelationshipEntry."Holder Code at Entry", 'Holder code should be captured at attach');

    end;

    [Test]
    procedure TestDetachViaFieldClear_CreatesDetachEntry()
    var
        ParentAsset: Record "JML AP Asset";
        ChildAsset: Record "JML AP Asset";
        RelationshipEntry: Record "JML AP Asset Relation Entry";
        AttachEntryNo: Integer;
    begin
        // [SCENARIO] Clearing Parent Asset No. field creates detach relationship entry

        // [GIVEN] Asset with parent relationship
        ParentAsset := TestLibrary.CreateTestAsset('Parent Asset for Detach Test');
        ChildAsset := TestLibrary.CreateTestAsset('Child Asset for Detach Test');
        ChildAsset.Get(ChildAsset."No.");
        ChildAsset.Validate("Parent Asset No.", ParentAsset."No.");
        ChildAsset.Modify(true);

        // Record the attach entry count
        RelationshipEntry.SetRange("Asset No.", ChildAsset."No.");
        AttachEntryNo := RelationshipEntry.Count();

        // [WHEN] Clear Parent Asset No. field
        ChildAsset.Get(ChildAsset."No."); // Refresh xRec
        ChildAsset.Validate("Parent Asset No.", '');
        ChildAsset.Modify(true);

        // [THEN] Detach entry created
        RelationshipEntry.SetRange("Entry Type", RelationshipEntry."Entry Type"::Detach);
        Assert.RecordIsNotEmpty(RelationshipEntry);

        // [THEN] Both attach and detach entries exist
        RelationshipEntry.Reset();
        RelationshipEntry.SetRange("Asset No.", ChildAsset."No.");
        Assert.AreEqual(AttachEntryNo + 1, RelationshipEntry.Count(), 'Should have both attach and detach entries');

    end;

    [Test]
    procedure TestSubassetTransferValidation_BlockedThenAllowed()
    var
        ParentAsset: Record "JML AP Asset";
        ChildAsset: Record "JML AP Asset";
        Location1: Record Location;
        Location2: Record Location;
        AssetJournalLine: Record "JML AP Asset Journal Line";
        AssetJnlPost: Codeunit "JML AP Asset Jnl.-Post";
    begin
        // [SCENARIO] Subasset transfer blocked when attached, allowed when detached

        // Clean up any leftover test data
        CleanupTestData();

        // [GIVEN] Asset with parent (subasset)
        ParentAsset := TestLibrary.CreateTestAsset('Parent Asset for Transfer Test');
        ChildAsset := TestLibrary.CreateTestAsset('Child Asset for Transfer Test');
        Location1 := TestLibrary.CreateTestLocation('Location 008A');
        Location2 := TestLibrary.CreateTestLocation('Location 008B');

        ChildAsset.Get(ChildAsset."No.");
        ChildAsset.Validate("Parent Asset No.", ParentAsset."No.");
        ChildAsset."Current Holder Type" := ChildAsset."Current Holder Type"::Location;
        ChildAsset."Current Holder Code" := Location1.Code;
        ChildAsset.Modify(true);

        // Commit to ensure assets are persisted before validation
        Commit();

        // [WHEN] Attempting to use subasset in journal line
        // [THEN] Validation error raised (TableRelation blocks subassets)
        AssetJournalLine.Init();
        AssetJournalLine."Journal Batch Name" := 'TEST';
        AssetJournalLine."Line No." := 10000;
        asserterror AssetJournalLine.Validate("Asset No.", ChildAsset."No.");
        Assert.ExpectedError('cannot be found in the related table');

        // [WHEN] Detach from parent
        ChildAsset.Get(ChildAsset."No."); // Refresh xRec
        ChildAsset.Validate("Parent Asset No.", '');
        ChildAsset.Modify(true);

        // [THEN] Create journal line after detach (should succeed)
        CreateTestJournalLine(AssetJournalLine, ChildAsset."No.", Location1.Code, Location2.Code);

        // [THEN] Transfer succeeds
        AssetJnlPost.SetSuppressConfirmation(true);
        AssetJnlPost.SetSuppressSuccessMessage(true);
        AssetJnlPost.Run(AssetJournalLine);

        // Verify asset holder changed
        ChildAsset.Get(ChildAsset."No.");
        Assert.AreEqual(Location2.Code, ChildAsset."Current Holder Code", 'Asset should be transferred to new location after detach');

    end;

    local procedure CreateTestJournalLine(var AssetJournalLine: Record "JML AP Asset Journal Line"; AssetNo: Code[20]; FromLocationCode: Code[10]; ToLocationCode: Code[10])
    var
        AssetJournalBatch: Record "JML AP Asset Journal Batch";
    begin
        // Get or create test journal batch
        if not AssetJournalBatch.Get('TEST') then begin
            AssetJournalBatch.Init();
            AssetJournalBatch.Name := 'TEST';
            AssetJournalBatch.Description := 'Test Batch';
            AssetJournalBatch.Insert(true);
        end;

        AssetJournalLine.Init();
        AssetJournalLine."Journal Batch Name" := AssetJournalBatch.Name;
        AssetJournalLine."Line No." := 10000;
        AssetJournalLine."Document No." := 'TEST-001'; // Add required Document No.
        AssetJournalLine.Validate("Asset No.", AssetNo);
        AssetJournalLine.Validate("New Holder Type", AssetJournalLine."New Holder Type"::Location);
        AssetJournalLine.Validate("New Holder Code", ToLocationCode);
        AssetJournalLine."Posting Date" := WorkDate();
        AssetJournalLine.Insert(true);
    end;
}
