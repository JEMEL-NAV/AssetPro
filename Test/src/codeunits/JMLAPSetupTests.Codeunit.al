codeunit 50100 "JML AP Setup Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        IsInitialized: Boolean;

    [Test]
    procedure Test_SetupWizardCreatesDefaultConfiguration()
    var
        AssetSetup: Record "JML AP Asset Setup";
        SetupWizard: Codeunit "JML AP Setup Wizard";
    begin
        // [GIVEN] Clean setup state
        Initialize();

        // [WHEN] Run setup wizard
        SetupWizard.RunSetupWizard();

        // [THEN] Setup record created with default values
        AssetSetup.GetRecordOnce();
        Assert.AreNotEqual('', AssetSetup."Asset Nos.", 'Asset Nos. should be assigned');
        Assert.IsTrue(AssetSetup."Enable Attributes", 'Attributes should be enabled by default');
    end;

    [Test]
    procedure Test_NumberSeriesAssignment()
    var
        AssetSetup: Record "JML AP Asset Setup";
        Asset: Record "JML AP Asset";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        // [GIVEN] Setup with number series configured
        Initialize();
        CreateTestNumberSeries(NoSeries, NoSeriesLine);

        AssetSetup.GetRecordOnce();
        AssetSetup."Asset Nos." := NoSeries.Code;
        AssetSetup.Modify();

        // [WHEN] Create asset without No.
        Asset.Init();
        Asset.Validate(Description, 'Test Asset');
        Asset.Insert(true);

        // [THEN] No. assigned from series
        Assert.AreNotEqual('', Asset."No.", 'Asset No. should be assigned from series');
        Assert.AreEqual(NoSeries.Code, Asset."No. Series", 'No. Series should match setup');
    end;

    [Test]
    procedure Test_GetRecordOnceSingleton()
    var
        AssetSetup: Record "JML AP Asset Setup";
        RecordCount: Integer;
    begin
        // [GIVEN] Clean state
        Initialize();

        // [WHEN] Call GetRecordOnce multiple times
        AssetSetup.GetRecordOnce();
        AssetSetup.GetRecordOnce();
        AssetSetup.GetRecordOnce();

        // [THEN] Only one setup record exists
        AssetSetup.Reset();
        RecordCount := AssetSetup.Count();
        Assert.AreEqual(1, RecordCount, 'Only one setup record should exist');
    end;

    local procedure Initialize()
    var
        AssetSetup: Record "JML AP Asset Setup";
        Asset: Record "JML AP Asset";
        HolderEntry: Record "JML AP Holder Entry";
    begin
        if IsInitialized then
            exit;

        // Clean test data
        HolderEntry.DeleteAll();
        Asset.DeleteAll();
        AssetSetup.DeleteAll();

        IsInitialized := true;
        Commit();
    end;

    local procedure CreateTestNumberSeries(var NoSeries: Record "No. Series"; var NoSeriesLine: Record "No. Series Line")
    begin
        NoSeries.Init();
        NoSeries.Code := 'ASSET-TEST';
        NoSeries.Description := 'Test Asset Numbers';
        NoSeries."Default Nos." := true;
        NoSeries."Manual Nos." := true;
        if NoSeries.Insert() then;

        NoSeriesLine.Init();
        NoSeriesLine."Series Code" := NoSeries.Code;
        NoSeriesLine."Line No." := 10000;
        NoSeriesLine."Starting No." := 'AT-0001';
        NoSeriesLine."Ending No." := 'AT-9999';
        NoSeriesLine."Increment-by No." := 1;
        if NoSeriesLine.Insert() then;
    end;
}
