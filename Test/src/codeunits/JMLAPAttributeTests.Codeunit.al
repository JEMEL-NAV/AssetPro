codeunit 50104 "JML AP Attribute Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        IsInitialized: Boolean;

    [Test]
    procedure Test_CreateTextAttribute()
    var
        AttrDefn: Record "JML AP Attribute Defn";
        AttrValue: Record "JML AP Attribute Value";
        Asset: Record "JML AP Asset";
        Industry: Record "JML AP Asset Industry";
    begin
        // [GIVEN] Text attribute definition
        Initialize();
        CreateTestIndustry(Industry, 'FLEET');
        CreateAttributeDefinition(AttrDefn, Industry.Code, 0, 'SERIAL', 'Serial Number', AttrDefn."Data Type"::Text, '', false);
        CreateTestAsset(Asset, 'Test Asset');

        // [WHEN] Set attribute value
        CreateAttributeValue(AttrValue, Asset."No.", AttrDefn."Attribute Code");
        AttrValue.Validate("Value Text", 'ABC123');
        AttrValue.Modify();

        // [THEN] Value stored correctly
        Assert.AreEqual('ABC123', AttrValue."Value Text", 'Text value should be stored');
    end;

    [Test]
    procedure Test_CreateIntegerAttribute()
    var
        AttrDefn: Record "JML AP Attribute Defn";
        AttrValue: Record "JML AP Attribute Value";
        Asset: Record "JML AP Asset";
        Industry: Record "JML AP Asset Industry";
    begin
        // [GIVEN] Integer attribute definition
        Initialize();
        CreateTestIndustry(Industry, 'FLEET');
        CreateAttributeDefinition(AttrDefn, Industry.Code, 0, 'YEAR', 'Year', AttrDefn."Data Type"::Integer, '', false);
        CreateTestAsset(Asset, 'Test Asset');

        // [WHEN] Set attribute value
        CreateAttributeValue(AttrValue, Asset."No.", AttrDefn."Attribute Code");
        AttrValue.Validate("Value Integer", 2025);
        AttrValue.Modify();

        // [THEN] Value stored correctly
        Assert.AreEqual(2025, AttrValue."Value Integer", 'Integer value should be stored');
    end;

    [Test]
    procedure Test_CreateBooleanAttribute()
    var
        AttrDefn: Record "JML AP Attribute Defn";
        AttrValue: Record "JML AP Attribute Value";
        Asset: Record "JML AP Asset";
        Industry: Record "JML AP Asset Industry";
    begin
        // [GIVEN] Boolean attribute definition
        Initialize();
        CreateTestIndustry(Industry, 'FLEET');
        CreateAttributeDefinition(AttrDefn, Industry.Code, 0, 'WARRANTY', 'Under Warranty', AttrDefn."Data Type"::Boolean, '', false);
        CreateTestAsset(Asset, 'Test Asset');

        // [WHEN] Set attribute value
        CreateAttributeValue(AttrValue, Asset."No.", AttrDefn."Attribute Code");
        AttrValue.Validate("Value Boolean", true);
        AttrValue.Modify();

        // [THEN] Value stored correctly
        Assert.IsTrue(AttrValue."Value Boolean", 'Boolean value should be true');
    end;

    local procedure Initialize()
    var
        Asset: Record "JML AP Asset";
        Industry: Record "JML AP Asset Industry";
        AttrDefn: Record "JML AP Attribute Defn";
        AttrValue: Record "JML AP Attribute Value";
        HolderEntry: Record "JML AP Holder Entry";
        AssetSetup: Record "JML AP Asset Setup";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        if IsInitialized then
            exit;

        // Clean test data
        AttrValue.DeleteAll();
        AttrDefn.DeleteAll();
        HolderEntry.DeleteAll();
        Asset.DeleteAll();
        Industry.DeleteAll();
        NoSeriesLine.DeleteAll();
        NoSeries.DeleteAll();
        AssetSetup.DeleteAll();

        // Create basic setup
        CreateTestNumberSeries(NoSeries, NoSeriesLine);

        AssetSetup.Init();
        AssetSetup."Asset Nos." := NoSeries.Code;
        AssetSetup."Enable Attributes" := true;
        AssetSetup.Insert();

        IsInitialized := true;
        Commit();
    end;

    local procedure CreateTestIndustry(var Industry: Record "JML AP Asset Industry"; IndustryCode: Code[20])
    begin
        if not Industry.Get(IndustryCode) then begin
            Industry.Init();
            Industry.Code := IndustryCode;
            Industry.Name := IndustryCode;
            Industry.Insert();
        end;
    end;

    local procedure CreateAttributeDefinition(var AttrDefn: Record "JML AP Attribute Defn"; IndustryCode: Code[20]; LevelNo: Integer; AttrCode: Code[20]; AttrName: Text[50]; DataType: Enum "JML AP Attribute Type"; DefaultValue: Text[250]; IsMandatory: Boolean)
    begin
        AttrDefn.Init();
        AttrDefn."Industry Code" := IndustryCode;
        AttrDefn."Level Number" := LevelNo;
        AttrDefn."Attribute Code" := AttrCode;
        AttrDefn."Attribute Name" := AttrName;
        AttrDefn."Data Type" := DataType;
        AttrDefn."Default Value" := DefaultValue;
        AttrDefn.Mandatory := IsMandatory;
        AttrDefn.Insert();
    end;

    local procedure CreateAttributeValue(var AttrValue: Record "JML AP Attribute Value"; AssetNo: Code[20]; AttrCode: Code[20])
    begin
        AttrValue.Init();
        AttrValue."Asset No." := AssetNo;
        AttrValue."Attribute Code" := AttrCode;
        AttrValue.Insert();
    end;

    local procedure CreateTestAsset(var Asset: Record "JML AP Asset"; Description: Text[100])
    begin
        Asset.Init();
        Asset.Validate(Description, Description);
        Asset.Insert(true);
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
