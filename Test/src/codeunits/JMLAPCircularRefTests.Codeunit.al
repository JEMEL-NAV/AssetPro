codeunit 50103 "JML AP Circular Ref Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        IsInitialized: Boolean;

    [Test]
    procedure Test_CannotBeOwnParent()
    var
        Asset: Record "JML AP Asset";
        AssetValidation: Codeunit "JML AP Asset Validation";
    begin
        // [GIVEN] Asset A-001
        Initialize();
        CreateTestAsset(Asset, 'Asset A-001');

        // [WHEN] Set Parent = own No.
        Asset."Parent Asset No." := Asset."No.";

        // [THEN] Validation should prevent circular reference
        asserterror AssetValidation.ValidateParentAssignment(Asset);
        Assert.ExpectedError('Asset AT-0001 cannot be its own parent.');
    end;

    [Test]
    procedure Test_TwoLevelCircularReference()
    var
        AssetA, AssetB: Record "JML AP Asset";
        AssetValidation: Codeunit "JML AP Asset Validation";
    begin
        // [GIVEN] Asset A → Asset B
        Initialize();
        CreateTestAsset(AssetA, 'Asset A');
        CreateTestAsset(AssetB, 'Asset B');

        AssetB."Parent Asset No." := AssetA."No.";
        AssetB.Modify();

        // [WHEN] Set A.Parent = B (creates circle)
        AssetA."Parent Asset No." := AssetB."No.";

        // [THEN] Error expected
        asserterror AssetValidation.ValidateParentAssignment(AssetA);
        Assert.ExpectedError('Circular reference detected: Asset AT-0001 appears in its own parent chain.');
    end;

    [Test]
    procedure Test_ValidThreeLevelHierarchy()
    var
        AssetA, AssetB, AssetC: Record "JML AP Asset";
    begin
        // [GIVEN] Initialize
        Initialize();

        // [WHEN] Create A → B → C
        CreateTestAsset(AssetA, 'Vessel');

        CreateTestAsset(AssetB, 'Engine');
        AssetB.Validate("Parent Asset No.", AssetA."No.");
        AssetB.Modify();

        CreateTestAsset(AssetC, 'Turbocharger');
        AssetC.Validate("Parent Asset No.", AssetB."No.");
        AssetC.Modify();

        // [THEN] Hierarchy levels correct
        AssetA.Get(AssetA."No.");
        AssetB.Get(AssetB."No.");
        AssetC.Get(AssetC."No.");

        Assert.AreEqual(1, AssetA."Hierarchy Level", 'Asset A should be level 1');
        Assert.AreEqual(2, AssetB."Hierarchy Level", 'Asset B should be level 2');
        Assert.AreEqual(3, AssetC."Hierarchy Level", 'Asset C should be level 3');

        Assert.AreEqual(AssetA."No.", AssetC."Root Asset No.", 'Root should be Asset A');
    end;

    [Test]
    procedure Test_CanRemoveParent()
    var
        AssetParent, AssetChild: Record "JML AP Asset";
    begin
        // [GIVEN] Parent-child relationship
        Initialize();
        CreateTestAsset(AssetParent, 'Parent Asset');
        CreateTestAsset(AssetChild, 'Child Asset');

        AssetChild.Validate("Parent Asset No.", AssetParent."No.");
        AssetChild.Modify();

        // [WHEN] Clear parent
        AssetChild.Validate("Parent Asset No.", '');
        AssetChild.Modify();

        // [THEN] Hierarchy level reset to 1
        Assert.AreEqual('', AssetChild."Parent Asset No.", 'Parent should be cleared');
        Assert.AreEqual(1, AssetChild."Hierarchy Level", 'Level should be 1');
        Assert.AreEqual('', AssetChild."Root Asset No.", 'Root should be cleared');
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

        // Create basic setup with number series
        CreateTestNumberSeries(NoSeries, NoSeriesLine);

        AssetSetup.Init();
        AssetSetup."Asset Nos." := NoSeries.Code;
        AssetSetup."Enable Attributes" := true;
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
}
