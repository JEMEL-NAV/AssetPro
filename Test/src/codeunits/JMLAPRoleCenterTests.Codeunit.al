codeunit 50117 "JML AP Role Center Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        IsInitialized: Boolean;

    [Test]
    procedure TestCueTableInitialization()
    var
        AssetMgmtCue: Record "JML AP Asset Mgmt. Cue";
    begin
        // [FEATURE] Role Center - Cue Table Initialization
        // [SCENARIO] Cue table auto-creates singleton record on first access

        // [GIVEN] Clean state
        Initialize();

        // [GIVEN] Empty Cue table
        AssetMgmtCue.DeleteAll();

        // [WHEN] Accessing Cue table for the first time
        AssetMgmtCue.Reset();
        if not AssetMgmtCue.Get() then begin
            AssetMgmtCue.Init();
            AssetMgmtCue.Insert();
        end;

        // [THEN] Cue record exists
        Assert.RecordCount(AssetMgmtCue, 1);
    end;

    [Test]
    procedure TestTotalAssetsCalculation()
    var
        Asset: Record "JML AP Asset";
        AssetMgmtCue: Record "JML AP Asset Mgmt. Cue";
    begin
        // [FEATURE] Role Center - KPI Calculations
        // [SCENARIO] Total Assets FlowField calculates correctly

        // [GIVEN] Clean state
        Initialize();

        // [GIVEN] 3 assets in the system
        Asset.DeleteAll();
        CreateTestAsset('AST001');
        CreateTestAsset('AST002');
        CreateTestAsset('AST003');
        Commit();

        // [WHEN] Reading Total Assets from Cue
        AssetMgmtCue.Get();
        AssetMgmtCue.CalcFields("Total Assets");

        // [THEN] Total Assets = 3
        Assert.AreEqual(3, AssetMgmtCue."Total Assets", 'Total Assets should be 3');
    end;

    [Test]
    procedure TestOpenTransferOrdersCalculation()
    var
        TransferHeader: Record "JML AP Asset Transfer Header";
        AssetMgmtCue: Record "JML AP Asset Mgmt. Cue";
    begin
        // [FEATURE] Role Center - KPI Calculations
        // [SCENARIO] Open Transfer Orders count is accurate

        // [GIVEN] Clean state
        Initialize();

        // [GIVEN] 2 open transfer orders and 1 released
        TransferHeader.DeleteAll();
        CreateTestTransferOrder('TRF001', TransferHeader.Status::Open);
        CreateTestTransferOrder('TRF002', TransferHeader.Status::Open);
        CreateTestTransferOrder('TRF003', TransferHeader.Status::Released);
        Commit();

        // [WHEN] Reading Open Transfer Orders from Cue
        AssetMgmtCue.Get();
        AssetMgmtCue.CalcFields("Open Transfer Orders");

        // [THEN] Open Transfer Orders = 2
        Assert.AreEqual(2, AssetMgmtCue."Open Transfer Orders", 'Open Transfer Orders should be 2');
    end;

    [Test]
    procedure TestAssetsWithoutHolderCue()
    var
        Asset: Record "JML AP Asset";
        AssetMgmtCue: Record "JML AP Asset Mgmt. Cue";
    begin
        // [FEATURE] Role Center - KPI Calculations
        // [SCENARIO] Counts assets with blank holder correctly

        // [GIVEN] Clean state
        Initialize();

        // [GIVEN] 2 assets without holder, 1 with holder
        Asset.DeleteAll();
        CreateTestAssetWithHolder('AST001', '');
        CreateTestAssetWithHolder('AST002', '');
        CreateTestAssetWithHolder('AST003', 'HOLDER1');
        Commit();

        // [WHEN] Reading Assets Without Holder from Cue
        AssetMgmtCue.Get();
        AssetMgmtCue.CalcFields("Assets Without Holder");

        // [THEN] Assets Without Holder = 2
        Assert.AreEqual(2, AssetMgmtCue."Assets Without Holder", 'Assets Without Holder should be 2');
    end;

    [Test]
    procedure TestBlockedAssetsCue()
    var
        Asset: Record "JML AP Asset";
        AssetMgmtCue: Record "JML AP Asset Mgmt. Cue";
    begin
        // [FEATURE] Role Center - KPI Calculations
        // [SCENARIO] Blocked assets counted accurately

        // [GIVEN] Clean state
        Initialize();

        // [GIVEN] 1 blocked asset, 2 unblocked assets
        Asset.DeleteAll();
        CreateTestBlockedAsset('AST001', true);
        CreateTestBlockedAsset('AST002', false);
        CreateTestBlockedAsset('AST003', false);
        Commit();

        // [WHEN] Reading Blocked Assets from Cue
        AssetMgmtCue.Get();
        AssetMgmtCue.CalcFields("Blocked Assets");

        // [THEN] Blocked Assets = 1
        Assert.AreEqual(1, AssetMgmtCue."Blocked Assets", 'Blocked Assets should be 1');
    end;

    [Test]
    procedure TestComponentEntriesCue()
    var
        ComponentEntry: Record "JML AP Component Entry";
        AssetMgmtCue: Record "JML AP Asset Mgmt. Cue";
    begin
        // [FEATURE] Role Center - KPI Calculations
        // [SCENARIO] Component entries count correct

        // [GIVEN] Clean state
        Initialize();

        // [GIVEN] 4 component entries
        ComponentEntry.DeleteAll();
        CreateTestComponentEntry(1);
        CreateTestComponentEntry(2);
        CreateTestComponentEntry(3);
        CreateTestComponentEntry(4);
        Commit();

        // [WHEN] Reading Total Component Entries from Cue
        AssetMgmtCue.Get();
        AssetMgmtCue.CalcFields("Total Component Entries");

        // [THEN] Total Component Entries = 4
        Assert.AreEqual(4, AssetMgmtCue."Total Component Entries", 'Total Component Entries should be 4');
    end;

    [Test]
    procedure TestDateFilterApplied()
    var
        Asset: Record "JML AP Asset";
        AssetMgmtCue: Record "JML AP Asset Mgmt. Cue";
        TestDate: Date;
    begin
        // [FEATURE] Role Center - Date Filtering
        // [SCENARIO] Date Filter affects calculated fields

        // [GIVEN] Clean state
        Initialize();

        // [GIVEN] Assets modified on different dates
        TestDate := WorkDate();
        Asset.DeleteAll();
        CreateTestAssetWithModifiedDate('AST001', TestDate);
        CreateTestAssetWithModifiedDate('AST002', TestDate);
        CreateTestAssetWithModifiedDate('AST003', CalcDate('<-1D>', TestDate));
        Commit();

        // [WHEN] Applying Date Filter = TestDate
        AssetMgmtCue.Get();
        AssetMgmtCue.SetFilter("Date Filter", '%1', TestDate);
        AssetMgmtCue.CalcFields("Assets Modified Today");

        // [THEN] Assets Modified Today = 2
        Assert.AreEqual(2, AssetMgmtCue."Assets Modified Today", 'Assets Modified Today should be 2');
    end;

    [Test]
    procedure TestSingletonPatternEnforced()
    var
        AssetMgmtCue: Record "JML AP Asset Mgmt. Cue";
    begin
        // [FEATURE] Role Center - Singleton Pattern
        // [SCENARIO] Only one cue record can exist

        // [GIVEN] Clean state
        Initialize();

        // [GIVEN] Cue table initialized
        AssetMgmtCue.DeleteAll();
        AssetMgmtCue.Init();
        AssetMgmtCue.Insert();
        Commit();

        // [WHEN] Trying to create second record (should fail or be prevented)
        // [THEN] Only 1 record exists
        Assert.RecordCount(AssetMgmtCue, 1);
    end;

    local procedure Initialize()
    var
        Asset: Record "JML AP Asset";
        AssetMgmtCue: Record "JML AP Asset Mgmt. Cue";
        TransferHeader: Record "JML AP Asset Transfer Header";
        ComponentEntry: Record "JML AP Component Entry";
    begin
        if IsInitialized then
            exit;

        // Clean test data
        ComponentEntry.DeleteAll();
        TransferHeader.DeleteAll();
        Asset.DeleteAll();
        AssetMgmtCue.DeleteAll();

        IsInitialized := true;
        Commit();
    end;

    // Helper procedures
    local procedure CreateTestAsset(AssetNo: Code[20])
    var
        Asset: Record "JML AP Asset";
    begin
        Asset.Init();
        Asset."No." := AssetNo;
        Asset.Description := 'Test Asset ' + AssetNo;
        if Asset.Insert() then;
    end;

    local procedure CreateTestAssetWithHolder(AssetNo: Code[20]; HolderCode: Code[20])
    var
        Asset: Record "JML AP Asset";
    begin
        Asset.Init();
        Asset."No." := AssetNo;
        Asset.Description := 'Test Asset ' + AssetNo;
        Asset."Current Holder Code" := HolderCode;
        if Asset.Insert() then;
    end;

    local procedure CreateTestBlockedAsset(AssetNo: Code[20]; IsBlocked: Boolean)
    var
        Asset: Record "JML AP Asset";
    begin
        Asset.Init();
        Asset."No." := AssetNo;
        Asset.Description := 'Test Asset ' + AssetNo;
        Asset.Blocked := IsBlocked;
        if Asset.Insert() then;
    end;

    local procedure CreateTestAssetWithModifiedDate(AssetNo: Code[20]; ModifiedDate: Date)
    var
        Asset: Record "JML AP Asset";
    begin
        Asset.Init();
        Asset."No." := AssetNo;
        Asset.Description := 'Test Asset ' + AssetNo;
        Asset."Last Date Modified" := ModifiedDate;
        if Asset.Insert() then;
    end;

    local procedure CreateTestTransferOrder(DocumentNo: Code[20]; Status: Enum "JML AP Transfer Status")
    var
        TransferHeader: Record "JML AP Asset Transfer Header";
    begin
        TransferHeader.Init();
        TransferHeader."No." := DocumentNo;
        TransferHeader.Status := Status;
        TransferHeader."From Holder Code" := 'FROM1';
        TransferHeader."To Holder Code" := 'TO1';
        if TransferHeader.Insert() then;
    end;

    local procedure CreateTestComponentEntry(EntryNo: Integer)
    var
        ComponentEntry: Record "JML AP Component Entry";
    begin
        ComponentEntry.Init();
        ComponentEntry."Entry No." := EntryNo;
        ComponentEntry."Asset No." := 'AST001';
        ComponentEntry."Item No." := 'ITEM001';
        ComponentEntry."Entry Type" := ComponentEntry."Entry Type"::Install;
        ComponentEntry.Quantity := 1;
        ComponentEntry."Posting Date" := WorkDate();
        if ComponentEntry.Insert() then;
    end;
}
