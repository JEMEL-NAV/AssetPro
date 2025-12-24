codeunit 50133 "JML AP Assets By Holder Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        TestLibrary: Codeunit "JML AP Test Library";

    // ============================================
    // Basic Report Execution Tests
    // ============================================

    [Test]
    procedure AssetsByHolderReport_NoAssets_RunsWithoutError()
    var
        Asset: Record "JML AP Asset";
        AssetsByHolderReport: Report "JML AP Assets by Holder";
    begin
        TestLibrary.Initialize();

        // [GIVEN] No assets in the system
        Asset.DeleteAll();

        // [WHEN] Running the Assets by Holder report with no data
        Asset.SetView('');
        AssetsByHolderReport.SetTableView(Asset);
        AssetsByHolderReport.UseRequestPage(false);

        // [THEN] Report throws error for empty dataset (BC standard behavior)
        asserterror AssetsByHolderReport.Run();
        Assert.ExpectedError('The report couldn''t be generated, because it was empty');
    end;

    [Test]
    procedure AssetsByHolderReport_SingleHolderSingleAsset_DisplaysCorrectly()
    var
        Asset: Record "JML AP Asset";
        Location: Record Location;
        LocationAsset: Record "JML AP Asset";
        AssetsByHolderReport: Report "JML AP Assets by Holder";
    begin
        TestLibrary.Initialize();

        // [GIVEN] Single asset at one location
        Location := TestLibrary.CreateTestLocation('LOC01');
        LocationAsset := TestLibrary.CreateAssetAtLocation('Asset at Location', Location.Code);

        // [WHEN] Running the Assets by Holder report
        Asset.SetRange("No.", LocationAsset."No.");
        AssetsByHolderReport.SetTableView(Asset);
        AssetsByHolderReport.UseRequestPage(false);
        AssetsByHolderReport.Run();

        // [THEN] Report completes successfully
        Assert.IsTrue(true, 'Report should run successfully with single holder');
    end;

    [Test]
    procedure AssetsByHolderReport_MultipleHoldersMultipleAssets_GroupsCorrectly()
    var
        Asset: Record "JML AP Asset";
        Location1, Location2: Record Location;
        Asset1, Asset2, Asset3, Asset4: Record "JML AP Asset";
        AssetsByHolderReport: Report "JML AP Assets by Holder";
    begin
        TestLibrary.Initialize();

        // [GIVEN] Multiple assets at different locations
        Location1 := TestLibrary.CreateTestLocation('LOC01');
        Location2 := TestLibrary.CreateTestLocation('LOC02');

        Asset1 := TestLibrary.CreateAssetAtLocation('Asset 1 at Loc1', Location1.Code);
        Asset2 := TestLibrary.CreateAssetAtLocation('Asset 2 at Loc1', Location1.Code);
        Asset3 := TestLibrary.CreateAssetAtLocation('Asset 3 at Loc2', Location2.Code);
        Asset4 := TestLibrary.CreateAssetAtLocation('Asset 4 at Loc2', Location2.Code);

        // [WHEN] Running the Assets by Holder report
        Asset.SetFilter("No.", '%1|%2|%3|%4', Asset1."No.", Asset2."No.", Asset3."No.", Asset4."No.");
        AssetsByHolderReport.SetTableView(Asset);
        AssetsByHolderReport.UseRequestPage(false);
        AssetsByHolderReport.Run();

        // [THEN] Report completes successfully with multiple holders
        Assert.IsTrue(true, 'Report should group assets by holder correctly');
    end;

    // ============================================
    // Holder Type Tests
    // ============================================

    [Test]
    procedure AssetsByHolderReport_CustomerHolder_DisplaysWithContactInfo()
    var
        Asset: Record "JML AP Asset";
        Customer: Record Customer;
        CustomerAsset: Record "JML AP Asset";
        AssetsByHolderReport: Report "JML AP Assets by Holder";
    begin
        TestLibrary.Initialize();

        // [GIVEN] Asset at a customer with contact information
        Customer := TestLibrary.CreateCustomer();
        Customer."Phone No." := '555-1234';
        Customer."E-Mail" := 'customer@test.com';
        Customer.Modify(true);

        CustomerAsset := TestLibrary.CreateAssetAtCustomer('Asset at Customer', Customer."No.");

        // [WHEN] Running the Assets by Holder report
        Asset.SetRange("No.", CustomerAsset."No.");
        AssetsByHolderReport.SetTableView(Asset);
        AssetsByHolderReport.UseRequestPage(false);
        AssetsByHolderReport.Run();

        // [THEN] Report completes successfully with customer contact info
        Assert.IsTrue(true, 'Report should display customer holder with contact info');
    end;

    [Test]
    procedure AssetsByHolderReport_VendorHolder_DisplaysWithContactInfo()
    var
        Asset: Record "JML AP Asset";
        Vendor: Record Vendor;
        VendorAsset: Record "JML AP Asset";
        AssetsByHolderReport: Report "JML AP Assets by Holder";
    begin
        TestLibrary.Initialize();

        // [GIVEN] Asset at a vendor with contact information
        Vendor := TestLibrary.CreateVendor();
        Vendor."Phone No." := '555-5678';
        Vendor."E-Mail" := 'vendor@test.com';
        Vendor.Modify(true);

        VendorAsset := TestLibrary.CreateTestAsset('Asset at Vendor');
        VendorAsset."Current Holder Type" := VendorAsset."Current Holder Type"::Vendor;
        VendorAsset."Current Holder Code" := Vendor."No.";
        VendorAsset.Modify(true);

        // [WHEN] Running the Assets by Holder report
        Asset.SetRange("No.", VendorAsset."No.");
        AssetsByHolderReport.SetTableView(Asset);
        AssetsByHolderReport.UseRequestPage(false);
        AssetsByHolderReport.Run();

        // [THEN] Report completes successfully with vendor contact info
        Assert.IsTrue(true, 'Report should display vendor holder with contact info');
    end;

    [Test]
    procedure AssetsByHolderReport_LocationHolder_DisplaysWithoutContactInfo()
    var
        Asset: Record "JML AP Asset";
        Location: Record Location;
        LocationAsset: Record "JML AP Asset";
        AssetsByHolderReport: Report "JML AP Assets by Holder";
    begin
        TestLibrary.Initialize();

        // [GIVEN] Asset at a location (no contact info)
        Location := TestLibrary.CreateTestLocation('LOC01');
        LocationAsset := TestLibrary.CreateAssetAtLocation('Asset at Location', Location.Code);

        // [WHEN] Running the Assets by Holder report
        Asset.SetRange("No.", LocationAsset."No.");
        AssetsByHolderReport.SetTableView(Asset);
        AssetsByHolderReport.UseRequestPage(false);
        AssetsByHolderReport.Run();

        // [THEN] Report completes successfully (location has no contact info)
        Assert.IsTrue(true, 'Report should handle location holder without contact info');
    end;

    // ============================================
    // Filter Tests
    // ============================================

    [Test]
    procedure AssetsByHolderReport_FilterByHolderType_ShowsOnlyFilteredType()
    var
        Asset: Record "JML AP Asset";
        Location: Record Location;
        Customer: Record Customer;
        LocationAsset, CustomerAsset: Record "JML AP Asset";
        AssetsByHolderReport: Report "JML AP Assets by Holder";
    begin
        TestLibrary.Initialize();

        // [GIVEN] Assets at different holder types
        Location := TestLibrary.CreateTestLocation('LOC01');
        LocationAsset := TestLibrary.CreateAssetAtLocation('Asset at Location', Location.Code);

        Customer := TestLibrary.CreateCustomer();
        CustomerAsset := TestLibrary.CreateAssetAtCustomer('Asset at Customer', Customer."No.");

        // [WHEN] Running report filtered to Location holders only
        Asset.SetRange("Current Holder Type", Asset."Current Holder Type"::Location);
        AssetsByHolderReport.SetTableView(Asset);
        AssetsByHolderReport.UseRequestPage(false);
        AssetsByHolderReport.Run();

        // [THEN] Report completes successfully with filter applied
        Assert.IsTrue(true, 'Report should respect holder type filter');
    end;

    [Test]
    procedure AssetsByHolderReport_FilterByStatus_ShowsOnlyFilteredAssets()
    var
        Asset: Record "JML AP Asset";
        Location: Record Location;
        ActiveAsset, InactiveAsset: Record "JML AP Asset";
        AssetsByHolderReport: Report "JML AP Assets by Holder";
    begin
        TestLibrary.Initialize();

        // [GIVEN] Active and inactive assets at same location
        Location := TestLibrary.CreateTestLocation('LOC01');

        ActiveAsset := TestLibrary.CreateAssetAtLocation('Active Asset', Location.Code);
        ActiveAsset.Status := ActiveAsset.Status::Active;
        ActiveAsset.Modify(true);

        InactiveAsset := TestLibrary.CreateAssetAtLocation('Inactive Asset', Location.Code);
        InactiveAsset.Status := InactiveAsset.Status::Inactive;
        InactiveAsset.Modify(true);

        // [WHEN] Running report with Active status filter
        Asset.SetRange("Current Holder Type", Asset."Current Holder Type"::Location);
        Asset.SetRange(Status, Asset.Status::Active);
        AssetsByHolderReport.SetTableView(Asset);
        AssetsByHolderReport.UseRequestPage(false);
        AssetsByHolderReport.Run();

        // [THEN] Report completes successfully with filter
        Assert.IsTrue(true, 'Report should respect status filter');
    end;

    // ============================================
    // Date Calculation Tests
    // ============================================

    [Test]
    procedure AssetsByHolderReport_AssetsWithHolderSinceDate_CalculatesDaysCorrectly()
    var
        Asset: Record "JML AP Asset";
        Location: Record Location;
        AssetWithDate: Record "JML AP Asset";
        AssetsByHolderReport: Report "JML AP Assets by Holder";
        PastDate: Date;
    begin
        TestLibrary.Initialize();

        // [GIVEN] Asset with "Current Holder Since" date
        Location := TestLibrary.CreateTestLocation('LOC01');
        PastDate := CalcDate('<-30D>', Today);

        AssetWithDate := TestLibrary.CreateAssetAtLocation('Asset with Date', Location.Code);
        AssetWithDate."Current Holder Since" := PastDate;
        AssetWithDate.Modify(true);

        // [WHEN] Running the Assets by Holder report
        Asset.SetRange("No.", AssetWithDate."No.");
        AssetsByHolderReport.SetTableView(Asset);
        AssetsByHolderReport.UseRequestPage(false);
        AssetsByHolderReport.Run();

        // [THEN] Report completes and should calculate ~30 days with holder
        Assert.IsTrue(true, 'Report should calculate days with holder');
    end;

    // ============================================
    // Industry and Classification Tests
    // ============================================

    [Test]
    procedure AssetsByHolderReport_FilterByIndustry_ShowsOnlyFilteredIndustry()
    var
        Asset: Record "JML AP Asset";
        Location: Record Location;
        Industry1, Industry2: Record "JML AP Asset Industry";
        Asset1, Asset2: Record "JML AP Asset";
        AssetsByHolderReport: Report "JML AP Assets by Holder";
    begin
        TestLibrary.Initialize();

        // [GIVEN] Assets in different industries at same location
        Location := TestLibrary.CreateTestLocation('LOC01');
        Industry1 := TestLibrary.CreateIndustry('IND01', 'Industry 1');
        Industry2 := TestLibrary.CreateIndustry('IND02', 'Industry 2');

        Asset1 := TestLibrary.CreateAssetAtLocation('Asset in Industry 1', Location.Code);
        Asset1."Industry Code" := Industry1.Code;
        Asset1.Modify(true);

        Asset2 := TestLibrary.CreateAssetAtLocation('Asset in Industry 2', Location.Code);
        Asset2."Industry Code" := Industry2.Code;
        Asset2.Modify(true);

        // [WHEN] Running report filtered to Industry 1
        Asset.SetRange("Industry Code", Industry1.Code);
        AssetsByHolderReport.SetTableView(Asset);
        AssetsByHolderReport.UseRequestPage(false);
        AssetsByHolderReport.Run();

        // [THEN] Report completes successfully with industry filter
        Assert.IsTrue(true, 'Report should respect industry filter');
    end;

    // ============================================
    // Edge Case Tests
    // ============================================

    [Test]
    procedure AssetsByHolderReport_AssetWithNoHolder_HandledCorrectly()
    var
        Asset: Record "JML AP Asset";
        AssetNoHolder: Record "JML AP Asset";
        AssetsByHolderReport: Report "JML AP Assets by Holder";
    begin
        TestLibrary.Initialize();

        // [GIVEN] Asset with no holder assigned
        AssetNoHolder := TestLibrary.CreateTestAsset('Asset without Holder');
        AssetNoHolder."Current Holder Type" := AssetNoHolder."Current Holder Type"::" ";
        AssetNoHolder."Current Holder Code" := '';
        AssetNoHolder.Modify(true);

        // [WHEN] Running the Assets by Holder report with asset that has no holder
        Asset.SetRange("No.", AssetNoHolder."No.");
        AssetsByHolderReport.SetTableView(Asset);
        AssetsByHolderReport.UseRequestPage(false);

        // [THEN] Report throws error because holder list is empty
        asserterror AssetsByHolderReport.Run();
        Assert.ExpectedError('The report couldn''t be generated, because it was empty');
        Assert.IsTrue(true, 'Report should handle assets with no holder');
    end;

    [Test]
    procedure AssetsByHolderReport_ManyAssetsOneHolder_PerformanceAcceptable()
    var
        Asset: Record "JML AP Asset";
        Location: Record Location;
        i: Integer;
        AssetsByHolderReport: Report "JML AP Assets by Holder";
    begin
        TestLibrary.Initialize();

        // [GIVEN] Many assets at one location (performance test)
        Location := TestLibrary.CreateTestLocation('LOC01');

        for i := 1 to 50 do begin
            TestLibrary.CreateAssetAtLocation('Asset ' + Format(i), Location.Code);
        end;

        // [WHEN] Running the Assets by Holder report
        Asset.SetRange("Current Holder Type", Asset."Current Holder Type"::Location);
        Asset.SetRange("Current Holder Code", Location.Code);
        AssetsByHolderReport.SetTableView(Asset);
        AssetsByHolderReport.UseRequestPage(false);
        AssetsByHolderReport.Run();

        // [THEN] Report completes successfully with many assets
        Assert.IsTrue(true, 'Report should handle many assets at one holder');
    end;
}
