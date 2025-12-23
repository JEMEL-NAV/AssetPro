codeunit 50110 "JML AP Manual Holder Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        TestLibrary: Codeunit "JML AP Test Library";

    [Test]
    procedure TestManualHolderChange_CreatesJournalEntries()
    var
        Asset: Record "JML AP Asset";
        Customer: Record Customer;
        Location: Record Location;
        HolderEntry: Record "JML AP Holder Entry";
        AssetSetup: Record "JML AP Asset Setup";
        AssetJnlPost: Codeunit "JML AP Asset Jnl.-Post";
    begin
        // [FEATURE] Manual Holder Change via Journal (R8)
        // [SCENARIO] User changes holder on Asset Card via Change Holder Dialog, journal entries created automatically

        // [GIVEN] Setup allows manual changes
        TestLibrary.Initialize();
        AssetSetup.GetRecordOnce();
        AssetSetup."Block Manual Holder Change" := false;
        AssetSetup.Modify();

        // [GIVEN] Asset at Location
        Location := TestLibrary.CreateTestLocation(CopyStr(TestLibrary.GetNextTestNumber('LOC'), 1, 10));
        Asset := TestLibrary.CreateAssetAtLocation('Test Asset', Location.Code);

        // [WHEN] User changes holder to Customer via Change Holder Dialog
        Customer := TestLibrary.CreateTestCustomer('Test Customer');
        Asset.Get(Asset."No.");
        AssetJnlPost.SetSuppressConfirmation(true);
        AssetJnlPost.SetSuppressSuccessMessage(true);
        AssetJnlPost.CreateAndPostManualChange(
            Asset,
            Asset."Current Holder Type"::Location,
            Location.Code,
            '',  // Old address code
            Asset."Current Holder Type"::Customer,
            Customer."No.",
            '');  // New address code

        // [THEN] Two holder entries created (Transfer Out + Transfer In)
        HolderEntry.SetRange("Asset No.", Asset."No.");
        Assert.AreEqual(2, HolderEntry.Count, 'Should create 2 holder entries');

        // [THEN] Document Type is Journal
        HolderEntry.FindFirst();
        Assert.AreEqual(HolderEntry."Document Type"::Journal, HolderEntry."Document Type", 'Document Type should be Journal');

        // [THEN] Document No starts with MAN-
        Assert.IsTrue(StrPos(HolderEntry."Document No.", 'MAN-') = 1, 'Document No should start with MAN-');

        // [THEN] Asset holder updated
        Asset.Get(Asset."No.");
        Assert.AreEqual(Asset."Current Holder Type"::Customer, Asset."Current Holder Type", 'Holder type should be Customer');
        Assert.AreEqual(Customer."No.", Asset."Current Holder Code", 'Holder code should match');
    end;

    [Test]
    procedure TestManualHolderChange_BlockedBySetup_ThrowsError()
    var
        Asset: Record "JML AP Asset";
        Customer: Record Customer;
        Location: Record Location;
        AssetSetup: Record "JML AP Asset Setup";
        AssetJnlPost: Codeunit "JML AP Asset Jnl.-Post";
    begin
        // [FEATURE] Manual Holder Change Control (R7)
        // [SCENARIO] Setup blocks manual changes, error thrown

        // [GIVEN] Setup blocks manual changes
        TestLibrary.Initialize();
        AssetSetup.GetRecordOnce();
        AssetSetup."Block Manual Holder Change" := true;
        AssetSetup.Modify();

        // [GIVEN] Asset at Location
        Location := TestLibrary.CreateTestLocation(CopyStr(TestLibrary.GetNextTestNumber('LOC'), 1, 10));
        Asset := TestLibrary.CreateAssetAtLocation('Test Asset', Location.Code);

        // [WHEN] User tries to change holder via Change Holder Dialog
        Customer := TestLibrary.CreateTestCustomer('Test Customer');
        Asset.Get(Asset."No.");
        AssetJnlPost.SetSuppressConfirmation(true);
        AssetJnlPost.SetSuppressSuccessMessage(true);
        asserterror AssetJnlPost.CreateAndPostManualChange(
            Asset,
            Asset."Current Holder Type"::Location,
            Location.Code,
            '',
            Asset."Current Holder Type"::Customer,
            Customer."No.",
            '');

        // [THEN] Error thrown
        Assert.ExpectedError('Manual holder changes are blocked');
    end;

    [Test]
    procedure TestManualHolderChange_TransfersChildren()
    var
        ParentAsset: Record "JML AP Asset";
        ChildAsset1: Record "JML AP Asset";
        ChildAsset2: Record "JML AP Asset";
        Customer: Record Customer;
        Location: Record Location;
        HolderEntry: Record "JML AP Holder Entry";
        AssetSetup: Record "JML AP Asset Setup";
        AssetJnlPost: Codeunit "JML AP Asset Jnl.-Post";
    begin
        // [FEATURE] Manual Holder Change with Children (R4 + R8)
        // [SCENARIO] Manual change transfers all children automatically

        // [GIVEN] Setup allows manual changes
        TestLibrary.Initialize();
        AssetSetup.GetRecordOnce();
        AssetSetup."Block Manual Holder Change" := false;
        AssetSetup.Modify();

        // [GIVEN] Parent asset with 2 children at Location
        Location := TestLibrary.CreateTestLocation(CopyStr(TestLibrary.GetNextTestNumber('LOC'), 1, 10));
        ParentAsset := TestLibrary.CreateAssetAtLocation('Parent Asset', Location.Code);
        CreateChildAssetAtHolder(ChildAsset1, ParentAsset."No.", Location);
        CreateChildAssetAtHolder(ChildAsset2, ParentAsset."No.", Location);

        // [WHEN] User changes parent holder to Customer via Change Holder Dialog
        Customer := TestLibrary.CreateTestCustomer('Test Customer');
        ParentAsset.Get(ParentAsset."No.");
        AssetJnlPost.SetSuppressConfirmation(true);
        AssetJnlPost.SetSuppressSuccessMessage(true);
        AssetJnlPost.CreateAndPostManualChange(
            ParentAsset,
            ParentAsset."Current Holder Type"::Location,
            Location.Code,
            '',
            ParentAsset."Current Holder Type"::Customer,
            Customer."No.",
            '');

        // [THEN] 6 holder entries created (2 per asset: parent + 2 children)
        HolderEntry.SetFilter("Asset No.", '%1|%2|%3', ParentAsset."No.", ChildAsset1."No.", ChildAsset2."No.");
        Assert.AreEqual(6, HolderEntry.Count, 'Should create 6 holder entries (2 per asset)');

        // [THEN] All assets at Customer
        ParentAsset.Get(ParentAsset."No.");
        Assert.AreEqual(ParentAsset."Current Holder Type"::Customer, ParentAsset."Current Holder Type", 'Parent should be at Customer');

        ChildAsset1.Get(ChildAsset1."No.");
        Assert.AreEqual(ChildAsset1."Current Holder Type"::Customer, ChildAsset1."Current Holder Type", 'Child 1 should be at Customer');

        ChildAsset2.Get(ChildAsset2."No.");
        Assert.AreEqual(ChildAsset2."Current Holder Type"::Customer, ChildAsset2."Current Holder Type", 'Child 2 should be at Customer');
    end;

    [Test]
    procedure TestManualHolderChange_BlockedForSubasset()
    var
        ParentAsset: Record "JML AP Asset";
        ChildAsset: Record "JML AP Asset";
        Customer: Record Customer;
        Location: Record Location;
        AssetSetup: Record "JML AP Asset Setup";
        AssetJnlPost: Codeunit "JML AP Asset Jnl.-Post";
    begin
        // [FEATURE] Subasset Movement Restriction (R6)
        // [SCENARIO] Cannot manually change holder of attached subasset

        // [GIVEN] Setup allows manual changes
        TestLibrary.Initialize();
        AssetSetup.GetRecordOnce();
        AssetSetup."Block Manual Holder Change" := false;
        AssetSetup.Modify();

        // [GIVEN] Child asset attached to parent at Location
        Location := TestLibrary.CreateTestLocation(CopyStr(TestLibrary.GetNextTestNumber('LOC'), 1, 10));
        ParentAsset := TestLibrary.CreateAssetAtLocation('Parent Asset', Location.Code);
        CreateChildAssetAtHolder(ChildAsset, ParentAsset."No.", Location);

        // [WHEN] User tries to change child holder directly via Change Holder Dialog
        Customer := TestLibrary.CreateTestCustomer('Test Customer');
        ChildAsset.Get(ChildAsset."No.");
        AssetJnlPost.SetSuppressConfirmation(true);
        AssetJnlPost.SetSuppressSuccessMessage(true);
        asserterror AssetJnlPost.CreateAndPostManualChange(
            ChildAsset,
            ChildAsset."Current Holder Type"::Location,
            Location.Code,
            '',
            ChildAsset."Current Holder Type"::Customer,
            Customer."No.",
            '');

        // [THEN] Error thrown (cannot transfer subasset)
        Assert.ExpectedError('Cannot transfer subasset');
    end;

    [Test]
    procedure TestManualHolderChange_InitialHolderAssignment_CreatesEntries()
    var
        Asset: Record "JML AP Asset";
        Location: Record Location;
        HolderEntry: Record "JML AP Holder Entry";
        AssetSetup: Record "JML AP Asset Setup";
        AssetJnlPost: Codeunit "JML AP Asset Jnl.-Post";
    begin
        // [FEATURE] Manual Holder Change - Initial Assignment
        // [SCENARIO] Initial holder assignment creates holder entries

        // [GIVEN] Setup allows manual changes
        TestLibrary.Initialize();
        AssetSetup.GetRecordOnce();
        AssetSetup."Block Manual Holder Change" := false;
        AssetSetup.Modify();

        // [GIVEN] New asset with no holder
        Asset := TestLibrary.CreateTestAsset('Test Asset');
        Assert.AreEqual(Asset."Current Holder Type"::" ", Asset."Current Holder Type", 'Initial holder type should be blank');

        // [WHEN] User sets initial holder via Change Holder Dialog
        Location := TestLibrary.CreateTestLocation(CopyStr(TestLibrary.GetNextTestNumber('LOC'), 1, 10));
        Asset.Get(Asset."No.");
        AssetJnlPost.SetSuppressConfirmation(true);
        AssetJnlPost.SetSuppressSuccessMessage(true);
        AssetJnlPost.CreateAndPostManualChange(
            Asset,
            Asset."Current Holder Type"::" ",  // From blank
            '',
            '',
            Asset."Current Holder Type"::Location,
            Location.Code,
            '');

        // [THEN] Holder entries created (even for initial assignment)
        HolderEntry.SetRange("Asset No.", Asset."No.");
        Assert.AreEqual(2, HolderEntry.Count, 'Should create 2 holder entries for initial assignment');

        // [THEN] Asset holder set correctly
        Asset.Get(Asset."No.");
        Assert.AreEqual(Asset."Current Holder Type"::Location, Asset."Current Holder Type", 'Holder type should be Location');
    end;

    // TODO: Add test for manual holder change with Ship-to Address
    // [Test]
    // procedure TestManualHolderChange_WithShipToAddress_SavesAddressCode()
    // Test that address code is preserved when manually changing holder to customer with ship-to address

    // TODO: Add test for manual holder change with Order Address
    // [Test]
    // procedure TestManualHolderChange_WithOrderAddress_SavesAddressCode()
    // Test that address code is preserved when manually changing holder to vendor with order address

    local procedure CreateChildAssetAtHolder(var ChildAsset: Record "JML AP Asset"; ParentAssetNo: Code[20]; Location: Record Location)
    begin
        ChildAsset := TestLibrary.CreateTestAsset('Child Asset');
        ChildAsset."Parent Asset No." := ParentAssetNo;
        ChildAsset."Current Holder Type" := ChildAsset."Current Holder Type"::Location;
        ChildAsset."Current Holder Code" := Location.Code;
        ChildAsset."Current Holder Since" := WorkDate();
        ChildAsset.Modify(true);
    end;
}
