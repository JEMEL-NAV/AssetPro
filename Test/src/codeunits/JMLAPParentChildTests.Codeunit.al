codeunit 50106 "JML AP Parent-Child Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        TestLibrary: Codeunit "JML AP Test Library";
        IsInitialized: Boolean;
        CannotDeleteAssetWithChildrenErr: Label 'Cannot delete asset %1 because it has child assets.', Comment = '%1 = Asset No.';

    [Test]
    procedure Test_CreateSimpleParentChild()
    var
        Vessel, Engine: Record "JML AP Asset";
    begin
        // [GIVEN] Initialize
        TestLibrary.Initialize();

        // [WHEN] Create Vessel, then Engine with Parent=Vessel
        Vessel := TestLibrary.CreateTestAsset('MV Prosperity');
        Engine := TestLibrary.CreateTestAsset('Main Engine');

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

        Engine := TestLibrary.CreateTestAsset('Main Engine');
        Engine.Validate("Parent Asset No.", Vessel."No.");
        Engine.Modify();

        Turbocharger := TestLibrary.CreateTestAsset('Turbocharger');
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
        TestLibrary.Initialize();
        Vessel := TestLibrary.CreateTestAsset('MV Prosperity');

        Engine1 := TestLibrary.CreateTestAsset('Main Engine 1');
        Engine1.Validate("Parent Asset No.", Vessel."No.");
        Engine1.Modify();

        Engine2 := TestLibrary.CreateTestAsset('Main Engine 2');
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
        Parent := TestLibrary.CreateTestAsset('Parent Asset');
        Child := TestLibrary.CreateTestAsset('Child Asset');

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
        Parent := TestLibrary.CreateTestAsset('Parent Vessel');

        // [WHEN] Create 3 children
        Child1 := TestLibrary.CreateTestAsset('Engine 1');
        Child1.Validate("Parent Asset No.", Parent."No.");
        Child1.Modify();

        Child2 := TestLibrary.CreateTestAsset('Engine 2');
        Child2.Validate("Parent Asset No.", Parent."No.");
        Child2.Modify();

        Child3 := TestLibrary.CreateTestAsset('Propeller');
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
        TestLibrary.Initialize();
        Location1 := TestLibrary.CreateTestLocation('LOC1');
        Location2 := TestLibrary.CreateTestLocation('LOC2');
        Parent := TestLibrary.CreateAssetAtLocation('Parent Asset', Location1.Code);
        Child := TestLibrary.CreateAssetAtLocation('Child Asset', Location2.Code);

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
        TestLibrary.Initialize();
        Location := TestLibrary.CreateTestLocation('LOC1');
        Parent := TestLibrary.CreateAssetAtLocation('Parent Asset', Location.Code);
        Child := TestLibrary.CreateAssetAtLocation('Child Asset', Location.Code);

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
        TestLibrary.Initialize();
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
        Location := TestLibrary.CreateTestLocation('LOC1');
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
        TestLibrary.Initialize();
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
        Location := TestLibrary.CreateTestLocation('LOC1');
        CreateAssetWithClassification(Parent, 'Parent', Location.Code, Industry.Code, ClassValue2.Code);
        CreateAssetWithClassification(Child, 'Child', Location.Code, Industry.Code, ClassValue3.Code);

        // [WHEN] Assigning parent
        Child.Validate("Parent Asset No.", Parent."No.");
        Child.Modify();

        // [THEN] Assignment succeeds
        Child.Get(Child."No.");
        Assert.AreEqual(Parent."No.", Child."Parent Asset No.", 'Parent should be assigned');
    end;


    local procedure CreateIndustry(var Industry: Record "JML AP Asset Industry")
    begin
        Industry.Init();
        Industry.Code := 'IND-' + Format(CreateGuid()).Substring(1, 8);
        Industry.Name := 'Test Industry';
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