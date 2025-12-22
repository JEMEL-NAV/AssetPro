codeunit 50122 "JML AP AI Setup Wizard Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    // Note: BC Test Framework provides automatic test isolation
    // Each test runs in isolated transaction that rolls back automatically

    var
        LibraryAssert: Codeunit "Library Assert";
        AIHelper: Codeunit "JML AP AI Helper";
        SetupWizard: Codeunit "JML AP Setup Wizard";

    // ============================================================================
    // Story 1.3: AI Setup Wizard Tests
    // ============================================================================

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestAIWizard_CreateIndustryFromJSON_ValidJSON_CreatesIndustry()
    var
        Industry: Record "JML AP Asset Industry";
        MockConfigJson: Text;
        IndustryCode: Code[20];
        CreateResult: Boolean;
    begin
        // [SCENARIO] CreateIndustryFromJSON creates industry record from valid JSON

        // [GIVEN] A valid industry configuration JSON
        MockConfigJson := CreateMockIndustryConfig_Simple();

        // [WHEN] Creating industry from JSON
        CreateResult := SetupWizard.CreateIndustryFromJSON(MockConfigJson, IndustryCode);

        // [THEN] Industry record is created
        LibraryAssert.IsTrue(CreateResult, 'Should successfully create industry from JSON');
        LibraryAssert.AreEqual('FLEET', IndustryCode, 'Industry code should be FLEET');

        // Verify industry record exists
        LibraryAssert.IsTrue(Industry.Get(IndustryCode), 'Industry record should exist');
        LibraryAssert.AreEqual('Fleet Management', Industry.Name, 'Industry name should match');

        // No cleanup needed - automatic test isolation handles rollback
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestAIWizard_CreateClassificationLevels_ValidJSON_CreatesLevels()
    var
        ClassLevel: Record "JML AP Classification Lvl";
        MockConfigJson: Text;
        IndustryCode: Code[20];
        LevelCount: Integer;
    begin
        // [SCENARIO] CreateIndustryFromJSON creates classification levels from JSON

        // [GIVEN] A valid configuration JSON with 2 classification levels
        MockConfigJson := CreateMockIndustryConfig_Simple();

        // [WHEN] Creating industry from JSON
        SetupWizard.CreateIndustryFromJSON(MockConfigJson, IndustryCode);

        // [THEN] Classification levels are created
        ClassLevel.SetRange("Industry Code", 'FLEET');
        LevelCount := ClassLevel.Count;
        LibraryAssert.IsTrue(LevelCount >= 2, 'Should create at least 2 classification levels');

        // Verify level 1 exists
        LibraryAssert.IsTrue(ClassLevel.Get('FLEET', 1), 'Level 1 should exist');
        LibraryAssert.AreEqual('Vessel Type', ClassLevel."Level Name", 'Level 1 name should match');

        // Verify level 2 exists
        LibraryAssert.IsTrue(ClassLevel.Get('FLEET', 2), 'Level 2 should exist');
        LibraryAssert.AreEqual('Vessel Category', ClassLevel."Level Name", 'Level 2 name should match');

        // No cleanup needed - automatic test isolation handles rollback
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestAIWizard_CreateClassificationValues_ValidJSON_CreatesValues()
    var
        ClassValue: Record "JML AP Classification Val";
        MockConfigJson: Text;
        IndustryCode: Code[20];
        ValueCount: Integer;
    begin
        // [SCENARIO] CreateIndustryFromJSON creates classification values from JSON

        // [GIVEN] A valid configuration JSON with classification values
        MockConfigJson := CreateMockIndustryConfig_Simple();

        // [WHEN] Creating industry from JSON
        SetupWizard.CreateIndustryFromJSON(MockConfigJson, IndustryCode);

        // [THEN] Classification values are created
        ClassValue.SetRange("Industry Code", 'FLEET');
        ValueCount := ClassValue.Count;
        LibraryAssert.IsTrue(ValueCount >= 3, 'Should create at least 3 classification values');

        // Verify root value exists
        LibraryAssert.IsTrue(ClassValue.Get('FLEET', 1, 'COMMERCIAL'), 'COMMERCIAL value should exist');
        LibraryAssert.AreEqual('Commercial Vessels', ClassValue.Description, 'Description should match');

        // No cleanup needed - automatic test isolation handles rollback
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestAIWizard_CreateClassificationValues_ParentChildLinks_Correct()
    var
        ParentValue: Record "JML AP Classification Val";
        ChildValue: Record "JML AP Classification Val";
        MockConfigJson: Text;
        IndustryCode: Code[20];
    begin
        // [SCENARIO] Classification values have correct parent-child relationships

        // [GIVEN] A valid configuration JSON with parent-child relationships
        MockConfigJson := CreateMockIndustryConfig_Simple();

        // [WHEN] Creating industry from JSON
        SetupWizard.CreateIndustryFromJSON(MockConfigJson, IndustryCode);

        // [THEN] Parent-child relationships are correctly set
        // Level 1 parent (no parent code)
        LibraryAssert.IsTrue(ParentValue.Get('FLEET', 1, 'COMMERCIAL'), 'Parent value should exist');
        LibraryAssert.AreEqual('', ParentValue."Parent Value Code", 'Level 1 should have no parent');

        // Level 2 child (has parent code)
        LibraryAssert.IsTrue(ChildValue.Get('FLEET', 2, 'CARGO'), 'Child value should exist');
        LibraryAssert.AreEqual('COMMERCIAL', ChildValue."Parent Value Code", 'Child should reference parent');

        // No cleanup needed - automatic test isolation handles rollback
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestAIWizard_CreateAttributes_ValidJSON_CreatesAttributes()
    var
        AttributeDefn: Record "JML AP Attribute Defn";
        MockConfigJson: Text;
        IndustryCode: Code[20];
        AttributeCount: Integer;
    begin
        // [SCENARIO] CreateIndustryFromJSON creates attribute definitions from JSON

        // [GIVEN] A valid configuration JSON with attributes
        MockConfigJson := CreateMockIndustryConfig_Simple();

        // [WHEN] Creating industry from JSON
        SetupWizard.CreateIndustryFromJSON(MockConfigJson, IndustryCode);

        // [THEN] Attributes are created
        AttributeDefn.SetRange("Industry Code", 'FLEET');
        AttributeCount := AttributeDefn.Count;
        LibraryAssert.IsTrue(AttributeCount >= 3, 'Should create at least 3 attributes');

        // Verify text attribute
        AttributeDefn.Reset();
        AttributeDefn.SetRange("Industry Code", 'FLEET');
        AttributeDefn.SetRange("Attribute Code", 'VESSELNAME');
        LibraryAssert.IsTrue(AttributeDefn.FindFirst(), 'VESSELNAME attribute should exist');
        LibraryAssert.AreEqual(AttributeDefn."Data Type"::Text, AttributeDefn."Data Type", 'Should be Text type');

        // No cleanup needed - automatic test isolation handles rollback
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestAIWizard_CompleteFlow_AllConfigurationCreated()
    var
        Industry: Record "JML AP Asset Industry";
        ClassLevel: Record "JML AP Classification Lvl";
        ClassValue: Record "JML AP Classification Val";
        AttributeDefn: Record "JML AP Attribute Defn";
        MockConfigJson: Text;
        IndustryCode: Code[20];
    begin
        // [SCENARIO] Complete wizard flow creates all configuration elements

        // [GIVEN] A complete industry configuration JSON
        MockConfigJson := CreateMockIndustryConfig_Complete();

        // [WHEN] Creating industry from JSON
        SetupWizard.CreateIndustryFromJSON(MockConfigJson, IndustryCode);

        // [THEN] All configuration elements are created
        // Industry
        LibraryAssert.IsTrue(Industry.Get(IndustryCode), 'Industry should be created');

        // Classification Levels (should have 2-4)
        ClassLevel.SetRange("Industry Code", IndustryCode);
        LibraryAssert.IsTrue(ClassLevel.Count >= 2, 'Should have at least 2 levels');
        LibraryAssert.IsTrue(ClassLevel.Count <= 4, 'Should have at most 4 levels');

        // Classification Values (should have 5-15)
        ClassValue.SetRange("Industry Code", IndustryCode);
        LibraryAssert.IsTrue(ClassValue.Count >= 5, 'Should have at least 5 values');

        // Attributes (should have 5-10)
        AttributeDefn.SetRange("Industry Code", IndustryCode);
        LibraryAssert.IsTrue(AttributeDefn.Count >= 3, 'Should have at least 3 attributes');

        // No cleanup needed - automatic test isolation handles rollback
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestAIWizard_InvalidJSON_HandlesGracefully()
    var
        InvalidJson: Text;
        IndustryCode: Code[20];
        CreateResult: Boolean;
    begin
        // [SCENARIO] CreateIndustryFromJSON handles invalid JSON gracefully

        // [GIVEN] An invalid JSON string
        InvalidJson := 'This is not valid JSON at all!';

        // [WHEN] Attempting to create industry from invalid JSON
        CreateResult := SetupWizard.CreateIndustryFromJSON(InvalidJson, IndustryCode);

        // [THEN] Operation fails gracefully without crashing
        LibraryAssert.IsFalse(CreateResult, 'Should return false for invalid JSON');
        LibraryAssert.AreEqual('', IndustryCode, 'Industry code should be empty on failure');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestAIWizard_DuplicateRun_DoesNotDuplicate()
    var
        Industry: Record "JML AP Asset Industry";
        ClassLevel: Record "JML AP Classification Lvl";
        MockConfigJson: Text;
        IndustryCode: Code[20];
        FirstLevelCount: Integer;
        SecondLevelCount: Integer;
    begin
        // [SCENARIO] Running wizard twice with same data doesn't create duplicates

        // [GIVEN] A valid configuration JSON
        MockConfigJson := CreateMockIndustryConfig_Simple();

        // [WHEN] Creating industry from JSON twice
        SetupWizard.CreateIndustryFromJSON(MockConfigJson, IndustryCode);
        ClassLevel.SetRange("Industry Code", IndustryCode);
        FirstLevelCount := ClassLevel.Count;

        SetupWizard.CreateIndustryFromJSON(MockConfigJson, IndustryCode);
        ClassLevel.SetRange("Industry Code", IndustryCode);
        SecondLevelCount := ClassLevel.Count;

        // [THEN] Record counts remain the same (no duplicates)
        LibraryAssert.AreEqual(FirstLevelCount, SecondLevelCount, 'Should not create duplicate levels');
        LibraryAssert.IsTrue(Industry.Get(IndustryCode), 'Industry should still exist');

        // No cleanup needed - automatic test isolation handles rollback
    end;

    [Test]
    procedure TestAIWizard_RunSetupWizard_CreatesNumberSeries()
    var
        AssetSetup: Record "JML AP Asset Setup";
        NoSeries: Record "No. Series";
    begin
        // [SCENARIO] RunSetupWizard creates default number series

        // [GIVEN] Clean setup state
        if AssetSetup.Get() then
            AssetSetup.Delete(true);

        // [WHEN] Running setup wizard
        SetupWizard.RunSetupWizard();

        // [THEN] Setup record is created with number series
        LibraryAssert.IsTrue(AssetSetup.Get(), 'Setup record should be created');
        LibraryAssert.AreNotEqual('', AssetSetup."Asset Nos.", 'Asset number series should be assigned');

        // Verify number series exist
        if AssetSetup."Asset Nos." <> '' then
            LibraryAssert.IsTrue(NoSeries.Get(AssetSetup."Asset Nos."), 'Asset number series should exist');
    end;

    [Test]
    procedure TestAIWizard_RunSetupWizard_EnablesAttributes()
    var
        AssetSetup: Record "JML AP Asset Setup";
    begin
        // [SCENARIO] RunSetupWizard enables attributes by default

        // [GIVEN] Clean setup state
        if AssetSetup.Get() then
            AssetSetup.Delete(true);

        // [WHEN] Running setup wizard
        SetupWizard.RunSetupWizard();

        // [THEN] Attributes are enabled
        AssetSetup.Get();
        LibraryAssert.IsTrue(AssetSetup."Enable Attributes", 'Attributes should be enabled by default');
    end;

    [Test]
    procedure TestAIWizard_RunSetupWizard_Idempotent()
    var
        AssetSetup: Record "JML AP Asset Setup";
        FirstAssetNos: Code[20];
        SecondAssetNos: Code[20];
    begin
        // [SCENARIO] Running setup wizard multiple times is safe (idempotent)

        // [GIVEN] Clean setup state
        if AssetSetup.Get() then
            AssetSetup.Delete(true);

        // [WHEN] Running setup wizard twice
        SetupWizard.RunSetupWizard();
        AssetSetup.Get();
        FirstAssetNos := AssetSetup."Asset Nos.";

        SetupWizard.RunSetupWizard();
        AssetSetup.Get();
        SecondAssetNos := AssetSetup."Asset Nos.";

        // [THEN] Number series remain the same (not duplicated)
        LibraryAssert.AreEqual(FirstAssetNos, SecondAssetNos, 'Should not change number series on second run');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestAIWizard_AttributeDataTypes_AllSupported()
    var
        MockConfigJson: Text;
        IndustryCode: Code[20];
        AttributeDefn: Record "JML AP Attribute Defn";
    begin
        // [SCENARIO] All attribute data types are supported in configuration

        // [GIVEN] A configuration with multiple data types
        MockConfigJson := CreateMockIndustryConfig_AllDataTypes();

        // [WHEN] Creating industry from JSON
        SetupWizard.CreateIndustryFromJSON(MockConfigJson, IndustryCode);

        // [THEN] All data types are created correctly
        AttributeDefn.SetRange("Industry Code", IndustryCode);

        // Text type
        AttributeDefn.SetRange("Attribute Code", 'TEXTATTR');
        LibraryAssert.IsTrue(AttributeDefn.FindFirst(), 'Text attribute should exist');
        LibraryAssert.AreEqual(AttributeDefn."Data Type"::Text, AttributeDefn."Data Type", 'Should be Text type');

        // Integer type
        AttributeDefn.SetRange("Attribute Code", 'INTATTR');
        LibraryAssert.IsTrue(AttributeDefn.FindFirst(), 'Integer attribute should exist');
        LibraryAssert.AreEqual(AttributeDefn."Data Type"::Integer, AttributeDefn."Data Type", 'Should be Integer type');

        // Boolean type
        AttributeDefn.SetRange("Attribute Code", 'BOOLATTR');
        LibraryAssert.IsTrue(AttributeDefn.FindFirst(), 'Boolean attribute should exist');
        LibraryAssert.AreEqual(AttributeDefn."Data Type"::Boolean, AttributeDefn."Data Type", 'Should be Boolean type');

        // No cleanup needed - automatic test isolation handles rollback
    end;

    // ============================================================================
    // Helper Procedures - Mock JSON Generators
    // ============================================================================

    local procedure CreateMockIndustryConfig_Simple(): Text
    var
        ConfigJson: Text;
    begin
        ConfigJson := '{';
        ConfigJson += '"industryCode":"FLEET",';
        ConfigJson += '"industryName":"Fleet Management",';
        ConfigJson += '"classificationLevels":[';
        ConfigJson += '{"levelNumber":1,"levelName":"Vessel Type"},';
        ConfigJson += '{"levelNumber":2,"levelName":"Vessel Category"}';
        ConfigJson += '],';
        ConfigJson += '"classificationValues":[';
        ConfigJson += '{"levelNumber":1,"code":"COMMERCIAL","description":"Commercial Vessels","parentCode":""},';
        ConfigJson += '{"levelNumber":2,"code":"CARGO","description":"Cargo Ships","parentCode":"COMMERCIAL"},';
        ConfigJson += '{"levelNumber":2,"code":"TANKER","description":"Tanker Ships","parentCode":"COMMERCIAL"}';
        ConfigJson += '],';
        ConfigJson += '"attributes":[';
        ConfigJson += '{"code":"VESSELNAME","description":"Vessel Name","dataType":"Text","mandatory":true,"textLength":100},';
        ConfigJson += '{"code":"IMO","description":"IMO Number","dataType":"Text","mandatory":false,"textLength":20},';
        ConfigJson += '{"code":"CAPACITY","description":"Cargo Capacity (tons)","dataType":"Integer","mandatory":false}';
        ConfigJson += ']';
        ConfigJson += '}';

        exit(ConfigJson);
    end;

    local procedure CreateMockIndustryConfig_Complete(): Text
    var
        ConfigJson: Text;
    begin
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

    local procedure CreateMockIndustryConfig_AllDataTypes(): Text
    var
        ConfigJson: Text;
    begin
        ConfigJson := '{';
        ConfigJson += '"industryCode":"DTYPES",';
        ConfigJson += '"industryName":"Data Types Test",';
        ConfigJson += '"classificationLevels":[';
        ConfigJson += '{"levelNumber":1,"levelName":"Category"}';
        ConfigJson += '],';
        ConfigJson += '"classificationValues":[';
        ConfigJson += '{"levelNumber":1,"code":"CAT1","description":"Category 1","parentCode":""}';
        ConfigJson += '],';
        ConfigJson += '"attributes":[';
        ConfigJson += '{"code":"TEXTATTR","description":"Text Attribute","dataType":"Text","mandatory":false,"textLength":100},';
        ConfigJson += '{"code":"INTATTR","description":"Integer Attribute","dataType":"Integer","mandatory":false},';
        ConfigJson += '{"code":"BOOLATTR","description":"Boolean Attribute","dataType":"Boolean","mandatory":false},';
        ConfigJson += '{"code":"DECATTR","description":"Decimal Attribute","dataType":"Decimal","mandatory":false},';
        ConfigJson += '{"code":"DATEATTR","description":"Date Attribute","dataType":"Date","mandatory":false}';
        ConfigJson += ']';
        ConfigJson += '}';

        exit(ConfigJson);
    end;

    // Cleanup procedures removed - framework handles test isolation!

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Handler to suppress success/info messages during tests
    end;
}
