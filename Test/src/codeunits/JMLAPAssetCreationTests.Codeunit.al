codeunit 50102 "JML AP Asset Creation Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        TestLibrary: Codeunit "JML AP Test Library";
        IsInitialized: Boolean;

    [Test]
    procedure Test_CreateAssetWithMinimalData()
    var
        Asset: Record "JML AP Asset";
    begin
        // [GIVEN] Basic setup
        TestLibrary.Initialize();

        // [WHEN] Create asset with only Description
        Asset := TestLibrary.CreateTestAsset('Minimal Test Asset');

        // [THEN] Asset created with defaults
        Assert.AreNotEqual('', Asset."No.", 'No. should be assigned');
        Assert.AreEqual(Asset.Status::Active, Asset.Status, 'Default status should be Active');
    end;

    [Test]
    procedure Test_CreateAssetWithFullClassification()
    var
        Industry: Record "JML AP Asset Industry";
        Level1, Level2, Level3: Record "JML AP Classification Lvl";
        Value1, Value2, Value3: Record "JML AP Classification Val";
        Asset: Record "JML AP Asset";
    begin
        // [GIVEN] Three-level classification
        TestLibrary.Initialize();
        CreateTestIndustry(Industry, 'FLEET', 'Fleet Management');
        CreateClassificationLevel(Level1, Industry.Code, 1, 'Category');
        CreateClassificationLevel(Level2, Industry.Code, 2, 'Type');
        CreateClassificationLevel(Level3, Industry.Code, 3, 'Size');

        CreateClassificationValue(Value1, Industry.Code, 1, 'COMM', '', 'Commercial');
        CreateClassificationValue(Value2, Industry.Code, 2, 'CARGO', 'COMM', 'Cargo Ship');
        CreateClassificationValue(Value3, Industry.Code, 3, 'PANA', 'CARGO', 'Panamax');

        // [WHEN] Create asset with full classification
        Asset.Init();
        Asset.Validate("Industry Code", Industry.Code);
        Asset.Validate(Description, 'MV Prosperity');
        Asset.Validate("Classification Code", Value3.Code);
        Asset.Insert(true);

        // [THEN] Asset created with classification
        Assert.AreEqual(Value3.Code, Asset."Classification Code", 'Classification should be set');
        Assert.AreEqual(Industry.Code, Asset."Industry Code", 'Industry should be set');
    end;

    [Test]
    procedure Test_ChangingIndustryClearsClassification()
    var
        Industry1, Industry2: Record "JML AP Asset Industry";
        Level1: Record "JML AP Classification Lvl";
        Value1: Record "JML AP Classification Val";
        Asset: Record "JML AP Asset";
    begin
        // [GIVEN] Asset with classification
        TestLibrary.Initialize();
        CreateTestIndustry(Industry1, 'FLEET', 'Fleet Management');
        CreateClassificationLevel(Level1, Industry1.Code, 1, 'Category');
        CreateClassificationValue(Value1, Industry1.Code, 1, 'COMM', '', 'Commercial');

        Asset.Init();
        Asset.Validate("Industry Code", Industry1.Code);
        Asset.Validate(Description, 'Test Vessel');
        Asset.Insert(true);
        Asset.Validate("Classification Code", Value1.Code);
        Asset.Modify();

        // Create second industry
        CreateTestIndustry(Industry2, 'MEDICAL', 'Medical Equipment');

        // [WHEN] Change industry
        Asset.Validate("Industry Code", Industry2.Code);
        Asset.Modify();

        // [THEN] Classification cleared
        Assert.AreEqual('', Asset."Classification Code", 'Classification should be cleared');
    end;

    [Test]
    procedure Test_AssetNumberSeriesIncrement()
    var
        AssetSetup: Record "JML AP Asset Setup";
        Asset1, Asset2, Asset3: Record "JML AP Asset";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        // [GIVEN] Number series configured
        TestLibrary.Initialize();

        // [WHEN] Create 3 assets
        Asset1 := TestLibrary.CreateTestAsset('Asset 1');
        Asset2 := TestLibrary.CreateTestAsset('Asset 2');
        Asset3 := TestLibrary.CreateTestAsset('Asset 3');

        // [THEN] Numbers increment sequentially
        Assert.AreNotEqual('', Asset1."No.", 'Asset1 No. should be assigned');
        Assert.AreNotEqual('', Asset2."No.", 'Asset2 No. should be assigned');
        Assert.AreNotEqual('', Asset3."No.", 'Asset3 No. should be assigned');
        Assert.AreNotEqual(Asset1."No.", Asset2."No.", 'Asset numbers should be unique');
        Assert.AreNotEqual(Asset2."No.", Asset3."No.", 'Asset numbers should be unique');
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
        if not ClassLevel.Get(IndustryCode, LevelNo) then begin
            ClassLevel.Init();
            ClassLevel."Industry Code" := IndustryCode;
            ClassLevel."Level Number" := LevelNo;
            ClassLevel."Level Name" := LevelName;
            ClassLevel.Insert(true);
        end;
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
