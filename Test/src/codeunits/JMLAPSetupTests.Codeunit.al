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

    // ============================================================================
    // Story 5.1: Setup Wizard Complete Flow Tests
    // ============================================================================

    [Test]
    procedure TestSetupWizard_CompleteFlow_AllStepsExecute()
    var
        AssetSetup: Record "JML AP Asset Setup";
        SetupWizard: Codeunit "JML AP Setup Wizard";
        NoSeries: Record "No. Series";
    begin
        // [GIVEN] Clean setup state
        CleanSetupData();

        // [WHEN] Run complete setup wizard
        SetupWizard.RunSetupWizard();

        // [THEN] Setup record created with default values
        AssetSetup.GetRecordOnce();
        Assert.AreNotEqual('', AssetSetup."Asset Nos.", 'Asset Nos. should be assigned');
        Assert.AreNotEqual('', AssetSetup."Transfer Order Nos.", 'Transfer Order Nos. should be assigned');
        Assert.AreNotEqual('', AssetSetup."Posted Transfer Nos.", 'Posted Transfer Nos. should be assigned');
        Assert.IsTrue(AssetSetup."Enable Attributes", 'Attributes should be enabled by default');

        // [THEN] All 3 number series created
        Assert.IsTrue(NoSeries.Get(AssetSetup."Asset Nos."), 'Asset number series should exist');
        Assert.IsTrue(NoSeries.Get(AssetSetup."Transfer Order Nos."), 'Transfer number series should exist');
        Assert.IsTrue(NoSeries.Get(AssetSetup."Posted Transfer Nos."), 'Posted Transfer number series should exist');

        // [THEN] All series allow manual numbers
        NoSeries.Get(AssetSetup."Asset Nos.");
        Assert.IsTrue(NoSeries."Manual Nos.", 'Asset series should allow manual numbers');
    end;

    [Test]
    procedure TestSetupWizard_CreatesNumberSeries_AllThreeAssigned()
    var
        AssetSetup: Record "JML AP Asset Setup";
        SetupWizard: Codeunit "JML AP Setup Wizard";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        // [GIVEN] Clean setup state
        CleanSetupData();

        // Ensure setup record exists
        AssetSetup.GetRecordOnce();

        // [WHEN] Create number series with custom configuration
        SetupWizard.CreateNumberSeriesWithConfig(
            'TESTASSET', 'TA-001', 'Test Assets',
            'TESTTRANS', 'TT-001', 'Test Transfers',
            'TESTPOSTED', 'TP-001', 'Test Posted Transfers');

        // [THEN] Asset Setup updated with all 3 codes
        AssetSetup.Get();
        Assert.AreEqual('TESTASSET', AssetSetup."Asset Nos.", 'Asset Nos. should be TESTASSET');
        Assert.AreEqual('TESTTRANS', AssetSetup."Transfer Order Nos.", 'Transfer Order Nos. should be TESTTRANS');
        Assert.AreEqual('TESTPOSTED', AssetSetup."Posted Transfer Nos.", 'Posted Transfer Nos. should be TESTPOSTED');

        // [THEN] All 3 No. Series records exist
        Assert.IsTrue(NoSeries.Get('TESTASSET'), 'TESTASSET series should exist');
        Assert.IsTrue(NoSeries.Get('TESTTRANS'), 'TESTTRANS series should exist');
        Assert.IsTrue(NoSeries.Get('TESTPOSTED'), 'TESTPOSTED series should exist');

        // [THEN] Each series has correct configuration
        ValidateNumberSeries('TESTASSET', 'TA-001', 'TA-999');
        ValidateNumberSeries('TESTTRANS', 'TT-001', 'TT-999');
        ValidateNumberSeries('TESTPOSTED', 'TP-001', 'TP-999');
    end;

    [Test]
    procedure TestSetupWizard_CreatesDemoIndustry_FleetManagement()
    var
        SetupWizard: Codeunit "JML AP Setup Wizard";
        Industry: Record "JML AP Asset Industry";
        ClassLevel: Record "JML AP Classification Lvl";
        ClassValue: Record "JML AP Classification Val";
    begin
        // [GIVEN] Clean state
        CleanSetupData();

        // [WHEN] Create demo industry
        SetupWizard.CreateSampleIndustry();

        // [THEN] Industry record created
        Assert.IsTrue(Industry.Get('FLEET'), 'FLEET industry should exist');
        Assert.AreEqual('Fleet Management', Industry.Name, 'Industry name should be Fleet Management');

        // [THEN] 2 Classification Levels created
        Assert.IsTrue(ClassLevel.Get('FLEET', 1), 'Level 1 should exist');
        Assert.AreEqual('Fleet Type', ClassLevel."Level Name", 'Level 1 name should be Fleet Type');
        Assert.IsTrue(ClassLevel.Get('FLEET', 2), 'Level 2 should exist');
        Assert.AreEqual('Vessel Type', ClassLevel."Level Name", 'Level 2 name should be Vessel Type');

        // [THEN] 2 Classification Values created with parent-child relationship
        Assert.IsTrue(ClassValue.Get('FLEET', 1, 'COMM'), 'COMM value should exist');
        Assert.AreEqual('Commercial', ClassValue.Description, 'COMM description should be Commercial');
        Assert.AreEqual('', ClassValue."Parent Value Code", 'COMM should have no parent');

        Assert.IsTrue(ClassValue.Get('FLEET', 2, 'CARGO'), 'CARGO value should exist');
        Assert.AreEqual('Cargo Ship', ClassValue.Description, 'CARGO description should be Cargo Ship');
        Assert.AreEqual('COMM', ClassValue."Parent Value Code", 'CARGO parent should be COMM');
    end;

    [Test]
    procedure TestSetupWizard_CreatesDemoData_AssetsCreated()
    var
        SetupWizard: Codeunit "JML AP Setup Wizard";
        AssetSetup: Record "JML AP Asset Setup";
        AssetJnlBatch: Record "JML AP Asset Journal Batch";
        ComponentJnlBatch: Record "JML AP Component Jnl. Batch";
    begin
        // [GIVEN] Clean state
        CleanSetupData();

        AssetSetup.GetRecordOnce();

        // [WHEN] Create demo data
        SetupWizard.CreateSampleIndustry();
        SetupWizard.CreateDefaultJournalBatches();

        // Update setup with industry
        AssetSetup."Default Industry Code" := 'FLEET';
        AssetSetup."Block Manual Holder Change" := true;
        AssetSetup.Modify();

        // [THEN] DEFAULT Asset Journal Batch exists
        Assert.IsTrue(AssetJnlBatch.Get('DEFAULT'), 'DEFAULT Asset Journal Batch should exist');
        Assert.AreEqual('Default Asset Journal', AssetJnlBatch.Description, 'Asset batch description should match');

        // [THEN] DEFAULT Component Journal Batch exists
        Assert.IsTrue(ComponentJnlBatch.Get('DEFAULT'), 'DEFAULT Component Journal Batch should exist');
        Assert.AreEqual('Default Component Journal', ComponentJnlBatch.Description, 'Component batch description should match');

        // [THEN] Asset Setup configured correctly
        AssetSetup.Get();
        Assert.AreEqual('FLEET', AssetSetup."Default Industry Code", 'Default Industry Code should be FLEET');
        Assert.IsTrue(AssetSetup."Enable Attributes", 'Attributes should be enabled');
        Assert.IsTrue(AssetSetup."Block Manual Holder Change", 'Block Manual Holder Change should be true');
    end;

    [Test]
    procedure TestSetupWizard_RunTwice_DoesNotDuplicate()
    var
        AssetSetup: Record "JML AP Asset Setup";
        SetupWizard: Codeunit "JML AP Setup Wizard";
        NoSeries: Record "No. Series";
        SetupCount: Integer;
        NoSeriesCount: Integer;
        FirstAssetNos: Code[20];
    begin
        // [GIVEN] Clean state
        CleanSetupData();

        // [WHEN] Run setup wizard twice
        SetupWizard.RunSetupWizard();
        AssetSetup.GetRecordOnce();
        FirstAssetNos := AssetSetup."Asset Nos.";

        SetupWizard.RunSetupWizard();

        // [THEN] Only 1 Asset Setup record exists
        AssetSetup.Reset();
        SetupCount := AssetSetup.Count();
        Assert.AreEqual(1, SetupCount, 'Only one setup record should exist after running twice');

        // [THEN] Number series not duplicated (still only 3)
        NoSeries.Reset();
        NoSeries.SetFilter(Code, '%1|%2|%3', 'ASSET', 'TRANSFER', 'P-TRANSFER');
        NoSeriesCount := NoSeries.Count();
        Assert.AreEqual(3, NoSeriesCount, 'Only 3 number series should exist after running twice');

        // [THEN] Setup field values unchanged
        AssetSetup.GetRecordOnce();
        Assert.AreEqual(FirstAssetNos, AssetSetup."Asset Nos.", 'Asset Nos. should remain unchanged');
        Assert.IsTrue(AssetSetup."Enable Attributes", 'Enable Attributes should still be true');
    end;

    // ============================================================================
    // Story 5.2: Setup Wizard with AI Tests
    // ============================================================================

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestSetupWizard_AIGeneratedConfig_ValidatesSuccessfully()
    var
        SetupWizard: Codeunit "JML AP Setup Wizard";
        Industry: Record "JML AP Asset Industry";
        ClassLevel: Record "JML AP Classification Lvl";
        ClassValue: Record "JML AP Classification Val";
        AttributeDefn: Record "JML AP Attribute Defn";
        MockConfigJson: Text;
        IndustryCode: Code[20];
    begin
        // [GIVEN] Clean state and mock AI-generated JSON
        CleanSetupData();
        MockConfigJson := CreateMockAIConfigJson();

        // [WHEN] Create industry from mock JSON
        Assert.IsTrue(SetupWizard.CreateIndustryFromJSON(MockConfigJson, IndustryCode), 'CreateIndustryFromJSON should succeed');

        // [THEN] Industry code returned matches JSON
        Assert.AreEqual('TESTIND', IndustryCode, 'Industry code should be TESTIND from JSON');

        // [THEN] Industry record created
        Assert.IsTrue(Industry.Get(IndustryCode), 'Industry should exist');
        Assert.AreEqual('Test Industry Complete', Industry.Name, 'Industry name should match JSON');

        // [THEN] 3 classification levels created
        ClassLevel.Reset();
        ClassLevel.SetRange("Industry Code", IndustryCode);
        Assert.AreEqual(3, ClassLevel.Count(), 'Should have 3 classification levels');

        // [THEN] 5 classification values created
        ClassValue.Reset();
        ClassValue.SetRange("Industry Code", IndustryCode);
        Assert.AreEqual(5, ClassValue.Count(), 'Should have 5 classification values');

        // [THEN] 3 attributes created
        AttributeDefn.Reset();
        AttributeDefn.SetRange("Industry Code", IndustryCode);
        Assert.AreEqual(3, AttributeDefn.Count(), 'Should have 3 attributes');

        // [THEN] Configuration is valid (parent-child relationships intact)
        Assert.IsTrue(ClassValue.Get(IndustryCode, 2, 'TYPE1'), 'TYPE1 should exist');
        Assert.AreEqual('CAT1', ClassValue."Parent Value Code", 'TYPE1 parent should be CAT1');
    end;

    [Test]
    procedure TestSetupWizard_AIFails_FallbackToDemoData()
    var
        SetupWizard: Codeunit "JML AP Setup Wizard";
        AIHelper: Codeunit "JML AP AI Helper";
        Industry: Record "JML AP Asset Industry";
        ConfigJson: Text;
        AISuccess: Boolean;
    begin
        // [GIVEN] Clean state
        CleanSetupData();

        // Skip test if AI not configured (will fail anyway)
        if not AIHelper.IsConfigured() then begin
            // [WHEN] AI not configured, fallback to demo data directly
            SetupWizard.CreateSampleIndustry();

            // [THEN] Fallback demo industry created successfully
            Assert.IsTrue(Industry.Get('FLEET'), 'FLEET industry should exist as fallback');
            exit;
        end;

        // [WHEN] Attempt AI generation with empty description (expected to throw error)
        asserterror AISuccess := SetupWizard.GenerateIndustryFromAI('', ConfigJson);

        // [THEN] Error thrown as expected (graceful handling would be to check error message)
        Assert.AreNotEqual('', GetLastErrorText(), 'Should throw error with empty description');

        // [THEN] AI generation would have failed
        // In real scenario, UI would catch error and fallback

        // [WHEN] Fallback to demo data after error
        ClearLastError();
        SetupWizard.CreateSampleIndustry();

        // [THEN] Fallback demo industry created successfully
        Assert.IsTrue(Industry.Get('FLEET'), 'FLEET industry should exist as fallback');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestSetupWizard_WithAI_GeneratesIndustryFromDescription()
    var
        SetupWizard: Codeunit "JML AP Setup Wizard";
        AIHelper: Codeunit "JML AP AI Helper";
        Industry: Record "JML AP Asset Industry";
        JsonObject: JsonObject;
        ConfigJson: Text;
        IndustryCode: Code[20];
        AISuccess: Boolean;
    begin
        // [GIVEN] Clean state and valid business description
        CleanSetupData();

        // Skip test if AI not configured
        if not AIHelper.IsConfigured() then
            exit;

        // [WHEN] Generate industry from AI with business description
        AISuccess := SetupWizard.GenerateIndustryFromAI('I manage a fleet of commercial vessels including cargo ships and tankers', ConfigJson);

        // [THEN] If AI call succeeds, validate results
        if AISuccess then begin
            // ConfigJson should not be empty
            Assert.AreNotEqual('', ConfigJson, 'ConfigJson should not be empty');

            // ConfigJson should be valid JSON
            Assert.IsTrue(JsonObject.ReadFrom(ConfigJson), 'ConfigJson should be valid JSON');

            // Create industry from JSON
            Assert.IsTrue(SetupWizard.CreateIndustryFromJSON(ConfigJson, IndustryCode), 'CreateIndustryFromJSON should succeed');

            // Verify industry created
            Assert.IsTrue(Industry.Get(IndustryCode), 'Industry should be created from AI JSON');
        end;
        // If AI fails, test passes gracefully (expected in CI without credentials)
    end;

    // ============================================================================
    // Helper Procedures
    // ============================================================================

    local procedure CleanSetupData()
    var
        AssetSetup: Record "JML AP Asset Setup";
        Industry: Record "JML AP Asset Industry";
        ClassLevel: Record "JML AP Classification Lvl";
        ClassValue: Record "JML AP Classification Val";
        AttributeDefn: Record "JML AP Attribute Defn";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        AssetJnlBatch: Record "JML AP Asset Journal Batch";
        ComponentJnlBatch: Record "JML AP Component Jnl. Batch";
    begin
        // Delete test data for idempotent tests
        AttributeDefn.DeleteAll();
        ClassValue.DeleteAll();
        ClassLevel.DeleteAll();
        Industry.DeleteAll();

        // Delete test number series
        NoSeriesLine.SetFilter("Series Code", '%1|%2|%3|%4|%5|%6', 'ASSET', 'TRANSFER', 'P-TRANSFER', 'TESTASSET', 'TESTTRANS', 'TESTPOSTED');
        NoSeriesLine.DeleteAll();

        NoSeries.SetFilter(Code, '%1|%2|%3|%4|%5|%6', 'ASSET', 'TRANSFER', 'P-TRANSFER', 'TESTASSET', 'TESTTRANS', 'TESTPOSTED');
        NoSeries.DeleteAll();

        // Delete journal batches
        if AssetJnlBatch.Get('DEFAULT') then
            AssetJnlBatch.Delete();
        if ComponentJnlBatch.Get('DEFAULT') then
            ComponentJnlBatch.Delete();

        // Reset setup
        AssetSetup.DeleteAll();

        Commit();
    end;

    local procedure ValidateNumberSeries(SeriesCode: Code[20]; ExpectedStarting: Code[20]; ExpectedEnding: Code[20])
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        // Validate No. Series header
        Assert.IsTrue(NoSeries.Get(SeriesCode), StrSubstNo('Series %1 should exist', SeriesCode));
        Assert.IsTrue(NoSeries."Default Nos.", StrSubstNo('Series %1 should have Default Nos. = true', SeriesCode));
        Assert.IsTrue(NoSeries."Manual Nos.", StrSubstNo('Series %1 should have Manual Nos. = true', SeriesCode));

        // Validate No. Series Line
        NoSeriesLine.SetRange("Series Code", SeriesCode);
        Assert.AreEqual(1, NoSeriesLine.Count(), StrSubstNo('Series %1 should have exactly 1 line', SeriesCode));

        NoSeriesLine.FindFirst();
        Assert.AreEqual(ExpectedStarting, NoSeriesLine."Starting No.", StrSubstNo('Series %1 starting no. should be %2', SeriesCode, ExpectedStarting));
        Assert.AreEqual(ExpectedEnding, NoSeriesLine."Ending No.", StrSubstNo('Series %1 ending no. should be %2', SeriesCode, ExpectedEnding));
        Assert.AreEqual(1, NoSeriesLine."Increment-by No.", StrSubstNo('Series %1 should increment by 1', SeriesCode));
    end;

    local procedure CreateMockAIConfigJson(): Text
    var
        ConfigJson: Text;
    begin
        // Reuse pattern from JML AP AI Setup Wizard Tests (Codeunit 50122)
        ConfigJson := '{';
        ConfigJson += '"industryCode":"TESTIND",';
        ConfigJson += '"industryName":"Test Industry Complete",';
        ConfigJson += '"classificationLevels":[';
        ConfigJson += '{"levelNumber":1,"levelName":"Category"},';
        ConfigJson += '{"levelNumber":2,"levelName":"Type"},';
        ConfigJson += '{"levelNumber":3,"levelName":"Subtype"}';
        ConfigJson += '],';
        ConfigJson += '"classificationValues":[';
        ConfigJson += '{"levelNumber":1,"code":"CAT1","description":"Category 1","parentCode":""},';
        ConfigJson += '{"levelNumber":1,"code":"CAT2","description":"Category 2","parentCode":""},';
        ConfigJson += '{"levelNumber":2,"code":"TYPE1","description":"Type 1","parentCode":"CAT1"},';
        ConfigJson += '{"levelNumber":2,"code":"TYPE2","description":"Type 2","parentCode":"CAT1"},';
        ConfigJson += '{"levelNumber":3,"code":"SUB1","description":"Subtype 1","parentCode":"TYPE1"}';
        ConfigJson += '],';
        ConfigJson += '"attributes":[';
        ConfigJson += '{"code":"ATTR1","description":"Attribute 1","dataType":"Text","mandatory":true,"textLength":50},';
        ConfigJson += '{"code":"ATTR2","description":"Attribute 2","dataType":"Integer","mandatory":false},';
        ConfigJson += '{"code":"ATTR3","description":"Attribute 3","dataType":"Boolean","mandatory":false}';
        ConfigJson += ']';
        ConfigJson += '}';

        exit(ConfigJson);
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Suppress success messages during wizard execution
    end;
}
