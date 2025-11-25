codeunit 50101 "JML AP Classification Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        IsInitialized: Boolean;

    [Test]
    procedure Test_CannotCreateLevel2BeforeLevel1()
    var
        Industry: Record "JML AP Asset Industry";
        Level2: Record "JML AP Classification Lvl";
    begin
        // [GIVEN] Industry without Level 1
        Initialize();
        CreateTestIndustry(Industry, 'FLEET', 'Fleet Management');

        // [WHEN] Create Level 2 directly
        // [THEN] Error expected
        asserterror CreateClassificationLevel(Level2, Industry.Code, 2, 'Type');
        Assert.ExpectedError('Level 1 must exist before creating Level 2.');
    end;

    [Test]
    procedure Test_ParentValueValidation()
    var
        Industry: Record "JML AP Asset Industry";
        Level1: Record "JML AP Classification Lvl";
        Level2: Record "JML AP Classification Lvl";
        Value1: Record "JML AP Classification Val";
        Value2: Record "JML AP Classification Val";
    begin
        // [GIVEN] Two-level classification
        Initialize();
        CreateTestIndustry(Industry, 'FLEET', 'Fleet Management');
        CreateClassificationLevel(Level1, Industry.Code, 1, 'Category');
        CreateClassificationLevel(Level2, Industry.Code, 2, 'Type');

        CreateClassificationValue(Value1, Industry.Code, 1, 'COMM', '', 'Commercial');

        // [WHEN] Create Level 2 value with invalid parent
        // [THEN] Error expected
        asserterror CreateClassificationValue(Value2, Industry.Code, 2, 'CARGO', 'INVALID', 'Cargo Ship');
        Assert.ExpectedError('Parent value INVALID does not exist at Level 1.');
    end;

    [Test]
    procedure Test_CanCreateUpTo10Levels()
    var
        Industry: Record "JML AP Asset Industry";
        ClassLevel: Record "JML AP Classification Lvl";
        i: Integer;
    begin
        // [GIVEN] Industry
        Initialize();
        CreateTestIndustry(Industry, 'DEEP', 'Deep Hierarchy');

        // [WHEN] Create 10 levels
        for i := 1 to 10 do
            CreateClassificationLevel(ClassLevel, Industry.Code, i, 'Level ' + Format(i));

        // [THEN] All levels created successfully
        ClassLevel.SetRange("Industry Code", Industry.Code);
        Assert.AreEqual(10, ClassLevel.Count(), '10 levels should be created');
    end;

    [Test]
    procedure Test_ValidThreeLevelHierarchy()
    var
        Industry: Record "JML AP Asset Industry";
        Level1, Level2, Level3: Record "JML AP Classification Lvl";
        Value1, Value2, Value3: Record "JML AP Classification Val";
    begin
        // [GIVEN] Three-level classification structure
        Initialize();
        CreateTestIndustry(Industry, 'FLEET', 'Fleet Management');
        CreateClassificationLevel(Level1, Industry.Code, 1, 'Category');
        CreateClassificationLevel(Level2, Industry.Code, 2, 'Type');
        CreateClassificationLevel(Level3, Industry.Code, 3, 'Size');

        // [WHEN] Create hierarchical values
        CreateClassificationValue(Value1, Industry.Code, 1, 'COMM', '', 'Commercial');
        CreateClassificationValue(Value2, Industry.Code, 2, 'CARGO', 'COMM', 'Cargo Ship');
        CreateClassificationValue(Value3, Industry.Code, 3, 'PANA', 'CARGO', 'Panamax');

        // [THEN] All values created with correct parent links
        Assert.AreEqual('', Value1."Parent Value Code", 'Level 1 has no parent');
        Assert.AreEqual('COMM', Value2."Parent Value Code", 'Level 2 parent is COMM');
        Assert.AreEqual('CARGO', Value3."Parent Value Code", 'Level 3 parent is CARGO');
    end;

    local procedure Initialize()
    var
        Asset: Record "JML AP Asset";
        Industry: Record "JML AP Asset Industry";
        ClassLevel: Record "JML AP Classification Lvl";
        ClassValue: Record "JML AP Classification Val";
        HolderEntry: Record "JML AP Holder Entry";
        AssetSetup: Record "JML AP Asset Setup";
    begin
        if IsInitialized then
            exit;

        // Clean test data
        HolderEntry.DeleteAll();
        Asset.DeleteAll();
        ClassValue.DeleteAll();
        ClassLevel.DeleteAll();
        Industry.DeleteAll();
        AssetSetup.DeleteAll();

        // Create basic setup
        AssetSetup.Init();
        AssetSetup."Asset Nos." := 'ASSET-TEST';
        AssetSetup."Enable Attributes" := true;
        AssetSetup."Enable Holder History" := true;
        AssetSetup.Insert();

        IsInitialized := true;
        Commit();
    end;

    local procedure CreateTestIndustry(var Industry: Record "JML AP Asset Industry"; IndustryCode: Code[20]; IndustryName: Text[100])
    begin
        if not Industry.Get(IndustryCode) then begin
            Industry.Init();
            Industry.Code := IndustryCode;
            Industry.Name := IndustryName;
            Industry.Insert();
        end;
    end;

    local procedure CreateClassificationLevel(var ClassLevel: Record "JML AP Classification Lvl"; IndustryCode: Code[20]; LevelNo: Integer; LevelName: Text[50])
    begin
        ClassLevel.Init();
        ClassLevel."Industry Code" := IndustryCode;
        ClassLevel."Level Number" := LevelNo;
        ClassLevel."Level Name" := LevelName;
        ClassLevel.Insert(true);
    end;

    local procedure CreateClassificationValue(var ClassValue: Record "JML AP Classification Val"; IndustryCode: Code[20]; LevelNo: Integer; ValueCode: Code[20]; ParentCode: Code[20]; ValueDesc: Text[100])
    begin
        if not ClassValue.Get(IndustryCode, LevelNo, ValueCode) then begin
            ClassValue.Init();
            ClassValue."Industry Code" := IndustryCode;
            ClassValue."Level Number" := LevelNo;
            ClassValue.Code := ValueCode;
            ClassValue."Parent Value Code" := ParentCode;
            ClassValue.Description := ValueDesc;
            ClassValue.Insert(true);
        end;
    end;
}
