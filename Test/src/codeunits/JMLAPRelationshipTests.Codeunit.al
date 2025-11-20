codeunit 50109 "JML AP Relationship Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library - Assert";

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
        CreateTestAsset(ParentAsset, 'PARENT-001', 'Parent Asset for Test');
        CreateTestAsset(ChildAsset, 'CHILD-001', 'Child Asset for Test');
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

        // [CLEANUP]
        CleanupTestData();
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
        CreateTestAsset(ParentAsset, 'PARENT-002', 'Parent Asset for Test');
        CreateTestAsset(ChildAsset, 'CHILD-002', 'Child Asset for Test');
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

        // [CLEANUP]
        CleanupTestData();
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
        CreateTestAsset(ParentAsset, 'PARENT-003', 'Parent Asset for Test');
        CreateTestAsset(ChildAsset, 'CHILD-003', 'Child Asset for Test');

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

        // [CLEANUP]
        CleanupTestData();
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
        CreateTestAsset(ParentAsset, 'PARENT-004', 'Parent Asset for Test');
        CreateTestAsset(ChildAsset, 'CHILD-004', 'Child Asset for Test');
        CreateTestCustomer(Customer, 'CUST-001');
        CreateTestLocation(Location, 'LOC-001');

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

        // [CLEANUP]
        CleanupTestData();
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
        CreateTestAsset(ParentAsset, 'PARENT-005', 'Parent Asset for Test');
        CreateTestAsset(Child1, 'CHILD-005A', 'Child 1 for Test');
        CreateTestAsset(Child2, 'CHILD-005B', 'Child 2 for Test');
        CreateTestAsset(Child3, 'CHILD-005C', 'Child 3 for Test');

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

        // [CLEANUP]
        CleanupTestData();
    end;

    local procedure CreateTestAsset(var Asset: Record "JML AP Asset"; AssetNo: Code[20]; Description: Text[100])
    var
        AssetSetup: Record "JML AP Asset Setup";
    begin
        if not AssetSetup.Get() then begin
            AssetSetup.Init();
            AssetSetup.Insert();
        end;

        Asset.Init();
        Asset."No." := AssetNo;
        Asset.Description := Description;
        Asset."Current Holder Type" := Asset."Current Holder Type"::Location;
        Asset."Current Holder Code" := '';
        Asset.Insert(true);
    end;

    local procedure CreateTestCustomer(var Customer: Record Customer; CustomerNo: Code[20])
    begin
        if Customer.Get(CustomerNo) then
            exit;

        Customer.Init();
        Customer."No." := CustomerNo;
        Customer.Name := 'Test Customer ' + CustomerNo;
        Customer.Insert(true);
    end;

    local procedure CreateTestLocation(var Location: Record Location; LocationCode: Code[10])
    begin
        if Location.Get(LocationCode) then
            exit;

        Location.Init();
        Location.Code := LocationCode;
        Location.Name := 'Test Location ' + LocationCode;
        Location.Insert(true);
    end;

    local procedure CleanupTestData()
    var
        Asset: Record "JML AP Asset";
        RelationshipEntry: Record "JML AP Asset Relation Entry";
        Customer: Record Customer;
        Location: Record Location;
    begin
        // Delete test relationship entries
        RelationshipEntry.Reset();
        RelationshipEntry.SetFilter("Asset No.", 'CHILD-*');
        RelationshipEntry.DeleteAll(true);

        // Delete test assets
        Asset.Reset();
        Asset.SetFilter("No.", 'PARENT-*|CHILD-*');
        Asset.DeleteAll(true);

        // Delete test customers
        Customer.Reset();
        Customer.SetFilter("No.", 'CUST-*');
        if Customer.FindSet() then
            repeat
                Customer.Delete(true);
            until Customer.Next() = 0;

        // Delete test locations
        Location.Reset();
        Location.SetFilter(Code, 'LOC-*');
        if Location.FindSet() then
            repeat
                Location.Delete(true);
            until Location.Next() = 0;
    end;
}
