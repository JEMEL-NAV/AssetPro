codeunit 50106 "JML AP Parent-Child Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        IsInitialized: Boolean;
        CannotDeleteAssetWithChildrenErr: Label 'Cannot delete asset %1 because it has child assets.', Comment = '%1 = Asset No.';

    [Test]
    procedure Test_CreateSimpleParentChild()
    var
        Vessel, Engine: Record "JML AP Asset";
    begin
        // [GIVEN] Initialize
        Initialize();

        // [WHEN] Create Vessel, then Engine with Parent=Vessel
        CreateTestAsset(Vessel, 'MV Prosperity');
        CreateTestAsset(Engine, 'Main Engine');

        Engine.Validate("Parent Asset No.", Vessel."No.");
        Engine.Modify();

        // [THEN] Hierarchy correct
        Engine.Get(Engine."No.");
        Assert.AreEqual(2, Engine."Hierarchy Level", 'Engine should be level 2');
        Assert.AreEqual(Vessel."No.", Engine."Root Asset No.", 'Root should be Vessel');
    end;

    [Test]
    procedure Test_CreateThreeLevelHierarchy()
    var
        Vessel, Engine, Turbocharger: Record "JML AP Asset";
    begin
        // [GIVEN] Initialize
        Initialize();

        // [WHEN] Create Vessel ? Engine ? Turbocharger
        CreateTestAsset(Vessel, 'MV Prosperity');

        CreateTestAsset(Engine, 'Main Engine');
        Engine.Validate("Parent Asset No.", Vessel."No.");
        Engine.Modify();

        CreateTestAsset(Turbocharger, 'Turbocharger');
        Turbocharger.Validate("Parent Asset No.", Engine."No.");
        Turbocharger.Modify();

        // [THEN] Hierarchy levels correct
        Vessel.Get(Vessel."No.");
        Engine.Get(Engine."No.");
        Turbocharger.Get(Turbocharger."No.");

        Assert.AreEqual(1, Vessel."Hierarchy Level", 'Vessel should be level 1');
        Assert.AreEqual(2, Engine."Hierarchy Level", 'Engine should be level 2');
        Assert.AreEqual(3, Turbocharger."Hierarchy Level", 'Turbocharger should be level 3');

        Assert.AreEqual(Vessel."No.", Turbocharger."Root Asset No.", 'Root should be Vessel');
    end;

    [Test]
    procedure Test_CannotDeleteParentWithChildren()
    var
        Vessel, Engine1, Engine2: Record "JML AP Asset";
    begin
        // [GIVEN] Vessel with 2 engines
        Initialize();
        CreateTestAsset(Vessel, 'MV Prosperity');

        CreateTestAsset(Engine1, 'Main Engine 1');
        Engine1.Validate("Parent Asset No.", Vessel."No.");
        Engine1.Modify();

        CreateTestAsset(Engine2, 'Main Engine 2');
        Engine2.Validate("Parent Asset No.", Vessel."No.");
        Engine2.Modify();

        // [WHEN] Delete Vessel
        // [THEN] Error expected
        asserterror Vessel.Delete(true);
        Assert.ExpectedError(StrSubstNo(CannotDeleteAssetWithChildrenErr, Vessel."No."));
    end;

    [Test]
    procedure Test_RemoveParent()
    var
        Parent, Child: Record "JML AP Asset";
    begin
        // [GIVEN] Parent-child relationship
        Initialize();
        CreateTestAsset(Parent, 'Parent Asset');
        CreateTestAsset(Child, 'Child Asset');

        Child.Validate("Parent Asset No.", Parent."No.");
        Child.Modify();

        // [WHEN] Remove parent
        Child.Validate("Parent Asset No.", '');
        Child.Modify();

        // [THEN] Hierarchy reset
        Child.Get(Child."No.");
        Assert.AreEqual('', Child."Parent Asset No.", 'Parent should be cleared');
        Assert.AreEqual(1, Child."Hierarchy Level", 'Level should be 1');
        Assert.AreEqual('', Child."Root Asset No.", 'Root should be cleared');
    end;

    [Test]
    procedure Test_MultipleChildrenSameParent()
    var
        Parent, Child1, Child2, Child3: Record "JML AP Asset";
        ChildAsset: Record "JML AP Asset";
        ChildCount: Integer;
    begin
        // [GIVEN] One parent
        Initialize();
        CreateTestAsset(Parent, 'Parent Vessel');

        // [WHEN] Create 3 children
        CreateTestAsset(Child1, 'Engine 1');
        Child1.Validate("Parent Asset No.", Parent."No.");
        Child1.Modify();

        CreateTestAsset(Child2, 'Engine 2');
        Child2.Validate("Parent Asset No.", Parent."No.");
        Child2.Modify();

        CreateTestAsset(Child3, 'Propeller');
        Child3.Validate("Parent Asset No.", Parent."No.");
        Child3.Modify();

        // [THEN] All children linked to parent
        ChildAsset.SetRange("Parent Asset No.", Parent."No.");
        ChildCount := ChildAsset.Count();
        Assert.AreEqual(3, ChildCount, '3 children should exist');
    end;

    [Test]
    procedure Test_AssignParent_SameHolderRequired_ErrorThrown()
    var
        Parent, Child: Record "JML AP Asset";
        Location1, Location2 : Record Location;
    begin
        // [SCENARIO] Cannot assign parent if assets are at different holders
        // [GIVEN] Parent at Location 1, Child at Location 2
        Initialize();
        CreateLocation(Location1);
        CreateLocation(Location2);
        CreateAssetAtLocation(Parent, 'Parent Asset', Location1.Code);
        CreateAssetAtLocation(Child, 'Child Asset', Location2.Code);

        // [WHEN] Attempting to assign parent
        // [THEN] Error thrown - different holders
        asserterror Child.Validate("Parent Asset No.", Parent."No.");
        Assert.ExpectedError('must be at same location');
    end;

    [Test]
    procedure Test_AssignParent_SameHolder_Success()
    var
        Parent, Child: Record "JML AP Asset";
        Location: Record Location;
    begin
        // [SCENARIO] Can assign parent when both assets at same holder
        // [GIVEN] Parent and Child both at Location 1
        Initialize();
        CreateLocation(Location);
        CreateAssetAtLocation(Parent, 'Parent Asset', Location.Code);
        CreateAssetAtLocation(Child, 'Child Asset', Location.Code);

        // [WHEN] Assigning parent
        Child.Validate("Parent Asset No.", Parent."No.");
        Child.Modify();

        // [THEN] Assignment succeeds
        Child.Get(Child."No.");
        Assert.AreEqual(Parent."No.", Child."Parent Asset No.", 'Parent should be assigned');
        Assert.AreEqual(2, Child."Hierarchy Level", 'Child should be level 2');
    end;

    [Test]
    procedure Test_AssignParent_WrongLevel_ErrorThrown()
    var
        Parent, Child: Record "JML AP Asset";
        Industry: Record "JML AP Asset Industry";
        Level1, Level2, Level3: Record "JML AP Classification Lvl";
        ClassValue1, ClassValue2, ClassValue3: Record "JML AP Classification Val";
        Location: Record Location;
    begin
        // [SCENARIO] Cannot assign parent if classification levels incorrect
        // [GIVEN] Industry and classifications (proper hierarchy)
        Initialize();
        CreateIndustry(Industry);

        // Create classification levels first
        CreateClassificationLevel(Level1, Industry.Code, 1, 'Level 1');
        CreateClassificationLevel(Level2, Industry.Code, 2, 'Level 2');
        CreateClassificationLevel(Level3, Industry.Code, 3, 'Level 3');

        // Create classification values
        CreateClassification(ClassValue1, Industry.Code, 1, '', 'Value Level 1');
        CreateClassification(ClassValue2, Industry.Code, 2, ClassValue1.Code, 'Value Level 2');
        CreateClassification(ClassValue3, Industry.Code, 3, ClassValue2.Code, 'Value Level 3');

        // [GIVEN] Parent at Level 3, Child at Level 3 (same level - wrong!)
        CreateLocation(Location);
        CreateAssetWithClassification(Parent, 'Parent', Location.Code, Industry.Code, ClassValue3.Code);
        CreateAssetWithClassification(Child, 'Child', Location.Code, Industry.Code, ClassValue3.Code);

        // [WHEN] Attempting to assign parent
        // [THEN] Error thrown - parent must be Level 2 for Level 3 child
        asserterror Child.Validate("Parent Asset No.", Parent."No.");
        Assert.ExpectedError('must be exactly one level above');
    end;

    [Test]
    procedure Test_AssignParent_CorrectLevel_Success()
    var
        Parent, Child: Record "JML AP Asset";
        Industry: Record "JML AP Asset Industry";
        Level1, Level2, Level3: Record "JML AP Classification Lvl";
        ClassValue1, ClassValue2, ClassValue3: Record "JML AP Classification Val";
        Location: Record Location;
    begin
        // [SCENARIO] Can assign parent when levels are correct (parent = child - 1)
        // [GIVEN] Industry and classifications (proper hierarchy)
        Initialize();
        CreateIndustry(Industry);

        // Create classification levels first
        CreateClassificationLevel(Level1, Industry.Code, 1, 'Level 1');
        CreateClassificationLevel(Level2, Industry.Code, 2, 'Level 2');
        CreateClassificationLevel(Level3, Industry.Code, 3, 'Level 3');

        // Create classification values
        CreateClassification(ClassValue1, Industry.Code, 1, '', 'Value Level 1');
        CreateClassification(ClassValue2, Industry.Code, 2, ClassValue1.Code, 'Value Level 2');
        CreateClassification(ClassValue3, Industry.Code, 3, ClassValue2.Code, 'Value Level 3');

        // [GIVEN] Parent at Level 2, Child at Level 3 (correct!)
        CreateLocation(Location);
        CreateAssetWithClassification(Parent, 'Parent', Location.Code, Industry.Code, ClassValue2.Code);
        CreateAssetWithClassification(Child, 'Child', Location.Code, Industry.Code, ClassValue3.Code);

        // [WHEN] Assigning parent
        Child.Validate("Parent Asset No.", Parent."No.");
        Child.Modify();

        // [THEN] Assignment succeeds
        Child.Get(Child."No.");
        Assert.AreEqual(Parent."No.", Child."Parent Asset No.", 'Parent should be assigned');
    end;

    local procedure Initialize()
    var
        Asset: Record "JML AP Asset";
        HolderEntry: Record "JML AP Holder Entry";
        AssetSetup: Record "JML AP Asset Setup";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        if IsInitialized then
            exit;

        // Clean test data
        HolderEntry.DeleteAll();
        Asset.DeleteAll();
        NoSeriesLine.DeleteAll();
        NoSeries.DeleteAll();
        AssetSetup.DeleteAll();

        // Create basic setup
        CreateTestNumberSeries(NoSeries, NoSeriesLine);

        AssetSetup.Init();
        AssetSetup."Asset Nos." := NoSeries.Code;
        AssetSetup."Enable Attributes" := true;
        AssetSetup."Enable Holder History" := true;
        AssetSetup.Insert();

        IsInitialized := true;
        Commit();
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

    local procedure CreateLocation(var Location: Record Location)
    begin
        Location.Init();
        Location.Code := 'L' + Format(CreateGuid()).Substring(1, 9);
        Location.Name := 'Test Location ' + Location.Code;
        Location.Insert(true);
    end;

    local procedure CreateAssetAtLocation(var Asset: Record "JML AP Asset"; Description: Text[100]; LocationCode: Code[10])
    begin
        Asset.Init();
        Asset.Validate(Description, Description);
        Asset."Current Holder Type" := Asset."Current Holder Type"::Location;
        Asset."Current Holder Code" := LocationCode;
        Asset."Current Holder Since" := WorkDate();
        Asset.Insert(true);
    end;

    local procedure CreateIndustry(var Industry: Record "JML AP Asset Industry")
    begin
        Industry.Init();
        Industry.Code := 'IND-' + Format(CreateGuid()).Substring(1, 8);
        Industry.Description := 'Test Industry';
        Industry.Insert(true);
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

    local procedure CreateClassification(
        var ClassVal: Record "JML AP Classification Val";
        IndustryCode: Code[20];
        LevelNo: Integer;
        ParentCode: Code[20];
        Description: Text[100])
    begin
        if not ClassVal.Get(IndustryCode, LevelNo, 'CL' + Format(LevelNo) + '-' + Format(CreateGuid()).Substring(1, 6)) then begin
            ClassVal.Init();
            ClassVal."Industry Code" := IndustryCode;
            ClassVal."Level Number" := LevelNo;
            ClassVal.Code := 'CL' + Format(LevelNo) + '-' + Format(CreateGuid()).Substring(1, 6);
            ClassVal.Description := Description;
            ClassVal."Parent Value Code" := ParentCode;
            ClassVal.Insert(true);
        end;
    end;

    local procedure CreateAssetWithClassification(
        var Asset: Record "JML AP Asset";
        Description: Text[100];
        LocationCode: Code[10];
        IndustryCode: Code[20];
        ClassificationCode: Code[20])
    begin
        Asset.Init();
        Asset.Validate(Description, Description);
        Asset."Industry Code" := IndustryCode;
        Asset."Classification Code" := ClassificationCode;
        Asset."Current Holder Type" := Asset."Current Holder Type"::Location;
        Asset."Current Holder Code" := LocationCode;
        Asset."Current Holder Since" := WorkDate();
        Asset.Insert(true);
    end;
}