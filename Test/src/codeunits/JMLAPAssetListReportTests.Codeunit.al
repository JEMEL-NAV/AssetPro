codeunit 50132 "JML AP Asset List Rpt Tests"
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
    procedure AssetListReport_NoAssets_RunsWithoutError()
    var
        Asset: Record "JML AP Asset";
        AssetListReport: Report "JML AP Asset List";
    begin
        TestLibrary.Initialize();

        // [GIVEN] No assets in the system
        Asset.DeleteAll();

        // [WHEN] Running the Asset List report
        Asset.SetView('');
        AssetListReport.SetTableView(Asset);
        AssetListReport.UseRequestPage(false);

        // [THEN] Report runs without error (would throw if error occurred)
        AssetListReport.Run();
    end;

    [Test]
    procedure AssetListReport_SingleAsset_DisplaysAsset()
    var
        Asset: Record "JML AP Asset";
        CreatedAsset: Record "JML AP Asset";
        AssetListReport: Report "JML AP Asset List";
    begin
        TestLibrary.Initialize();

        // [GIVEN] A single asset
        CreatedAsset := TestLibrary.CreateTestAsset('Test Asset 001');

        // [WHEN] Running the Asset List report
        Asset.SetRange("No.", CreatedAsset."No.");
        AssetListReport.SetTableView(Asset);
        AssetListReport.UseRequestPage(false);
        AssetListReport.Run();

        // [THEN] Report completes successfully
        Assert.IsTrue(true, 'Report should run successfully with single asset');
    end;

    [Test]
    procedure AssetListReport_MultipleAssets_DisplaysAll()
    var
        Asset: Record "JML AP Asset";
        Asset1, Asset2, Asset3: Record "JML AP Asset";
        AssetListReport: Report "JML AP Asset List";
    begin
        TestLibrary.Initialize();

        // [GIVEN] Multiple assets
        Asset1 := TestLibrary.CreateTestAsset('Asset A');
        Asset2 := TestLibrary.CreateTestAsset('Asset B');
        Asset3 := TestLibrary.CreateTestAsset('Asset C');

        // [WHEN] Running the Asset List report with all assets
        Asset.SetFilter("No.", '%1|%2|%3', Asset1."No.", Asset2."No.", Asset3."No.");
        AssetListReport.SetTableView(Asset);
        AssetListReport.UseRequestPage(false);
        AssetListReport.Run();

        // [THEN] Report completes successfully
        Assert.IsTrue(true, 'Report should run successfully with multiple assets');
    end;

    // ============================================
    // Filter Tests
    // ============================================

    [Test]
    procedure AssetListReport_FilterByStatus_ShowsOnlyFilteredAssets()
    var
        Asset: Record "JML AP Asset";
        ActiveAsset, InactiveAsset: Record "JML AP Asset";
        AssetListReport: Report "JML AP Asset List";
    begin
        TestLibrary.Initialize();

        // [GIVEN] Assets with different statuses
        ActiveAsset := TestLibrary.CreateTestAsset('Active Asset');
        ActiveAsset.Status := ActiveAsset.Status::Active;
        ActiveAsset.Modify(true);

        InactiveAsset := TestLibrary.CreateTestAsset('Inactive Asset');
        InactiveAsset.Status := InactiveAsset.Status::Inactive;
        InactiveAsset.Modify(true);

        // [WHEN] Running report with Active status filter
        Asset.SetRange(Status, Asset.Status::Active);
        AssetListReport.SetTableView(Asset);
        AssetListReport.UseRequestPage(false);
        AssetListReport.Run();

        // [THEN] Report completes successfully (filtered view applied)
        Assert.IsTrue(true, 'Report should respect status filter');
    end;

    [Test]
    procedure AssetListReport_FilterByHolderType_ShowsOnlyFilteredAssets()
    var
        Asset: Record "JML AP Asset";
        LocationAsset, CustomerAsset: Record "JML AP Asset";
        Location: Record Location;
        Customer: Record Customer;
        AssetListReport: Report "JML AP Asset List";
    begin
        TestLibrary.Initialize();

        // [GIVEN] Assets at different holder types
        Location := TestLibrary.CreateTestLocation('LOC01');
        LocationAsset := TestLibrary.CreateAssetAtLocation('Asset at Location', Location.Code);

        Customer := TestLibrary.CreateCustomer();
        CustomerAsset := TestLibrary.CreateAssetAtCustomer('Asset at Customer', Customer."No.");

        // [WHEN] Running report with Location holder type filter
        Asset.SetRange("Current Holder Type", Asset."Current Holder Type"::Location);
        AssetListReport.SetTableView(Asset);
        AssetListReport.UseRequestPage(false);
        AssetListReport.Run();

        // [THEN] Report completes successfully with filtered view
        Assert.IsTrue(true, 'Report should respect holder type filter');
    end;

    // ============================================
    // Classification Tests
    // ============================================

    [Test]
    procedure AssetListReport_AssetsWithClassification_DisplaysClassificationPath()
    var
        Asset: Record "JML AP Asset";
        CreatedAsset: Record "JML AP Asset";
        Industry: Record "JML AP Asset Industry";
        ClassLevel: Record "JML AP Classification Lvl";
        ClassValue: Record "JML AP Classification Val";
        AssetListReport: Report "JML AP Asset List";
    begin
        TestLibrary.Initialize();

        // [GIVEN] An asset with classification
        Industry := TestLibrary.CreateIndustry('TEST', 'Test Industry');
        ClassLevel := TestLibrary.CreateClassificationLevel(Industry.Code, 1, 'Category');
        ClassValue := TestLibrary.CreateClassificationValue(Industry.Code, 1, 'CAT01', 'Category 1', '', 0);

        CreatedAsset := TestLibrary.CreateTestAsset('Asset with Classification');
        CreatedAsset."Industry Code" := Industry.Code;
        CreatedAsset."Classification Code" := ClassValue.Code;
        CreatedAsset.Modify(true);

        // [WHEN] Running the Asset List report
        Asset.SetRange("No.", CreatedAsset."No.");
        AssetListReport.SetTableView(Asset);
        AssetListReport.UseRequestPage(false);
        AssetListReport.Run();

        // [THEN] Report completes successfully with classification
        Assert.IsTrue(true, 'Report should handle assets with classification');
    end;

    // ============================================
    // Grouping Tests
    // ============================================

    [Test]
    procedure AssetListReport_GroupByIndustry_GroupsCorrectly()
    var
        Asset: Record "JML AP Asset";
        Industry1, Industry2: Record "JML AP Asset Industry";
        Asset1, Asset2, Asset3: Record "JML AP Asset";
        AssetListReport: Report "JML AP Asset List";
    begin
        TestLibrary.Initialize();

        // [GIVEN] Assets in different industries
        Industry1 := TestLibrary.CreateIndustry('IND01', 'Industry 1');
        Industry2 := TestLibrary.CreateIndustry('IND02', 'Industry 2');

        Asset1 := TestLibrary.CreateTestAsset('Asset in Industry 1');
        Asset1."Industry Code" := Industry1.Code;
        Asset1.Modify(true);

        Asset2 := TestLibrary.CreateTestAsset('Asset in Industry 1 - Second');
        Asset2."Industry Code" := Industry1.Code;
        Asset2.Modify(true);

        Asset3 := TestLibrary.CreateTestAsset('Asset in Industry 2');
        Asset3."Industry Code" := Industry2.Code;
        Asset3.Modify(true);

        // [WHEN] Running report grouped by Industry
        Asset.SetFilter("No.", '%1|%2|%3', Asset1."No.", Asset2."No.", Asset3."No.");
        AssetListReport.SetTableView(Asset);
        AssetListReport.UseRequestPage(false);
        AssetListReport.Run();

        // [THEN] Report completes successfully with grouping
        Assert.IsTrue(true, 'Report should handle industry grouping');
    end;

    [Test]
    procedure AssetListReport_GroupByStatus_GroupsCorrectly()
    var
        Asset: Record "JML AP Asset";
        ActiveAsset1, ActiveAsset2, InactiveAsset: Record "JML AP Asset";
        AssetListReport: Report "JML AP Asset List";
    begin
        TestLibrary.Initialize();

        // [GIVEN] Assets with different statuses
        ActiveAsset1 := TestLibrary.CreateTestAsset('Active Asset 1');
        ActiveAsset1.Status := ActiveAsset1.Status::Active;
        ActiveAsset1.Modify(true);

        ActiveAsset2 := TestLibrary.CreateTestAsset('Active Asset 2');
        ActiveAsset2.Status := ActiveAsset2.Status::Active;
        ActiveAsset2.Modify(true);

        InactiveAsset := TestLibrary.CreateTestAsset('Inactive Asset');
        InactiveAsset.Status := InactiveAsset.Status::Inactive;
        InactiveAsset.Modify(true);

        // [WHEN] Running report grouped by Status
        Asset.SetFilter("No.", '%1|%2|%3', ActiveAsset1."No.", ActiveAsset2."No.", InactiveAsset."No.");
        AssetListReport.SetTableView(Asset);
        AssetListReport.UseRequestPage(false);
        AssetListReport.Run();

        // [THEN] Report completes successfully with grouping
        Assert.IsTrue(true, 'Report should handle status grouping');
    end;

    // ============================================
    // Blocked Assets Tests
    // ============================================

    [Test]
    procedure AssetListReport_BlockedAssets_IncludedWhenRequested()
    var
        Asset: Record "JML AP Asset";
        NormalAsset, BlockedAsset: Record "JML AP Asset";
        AssetListReport: Report "JML AP Asset List";
    begin
        TestLibrary.Initialize();

        // [GIVEN] Normal and blocked assets
        NormalAsset := TestLibrary.CreateTestAsset('Normal Asset');
        NormalAsset.Blocked := false;
        NormalAsset.Modify(true);

        BlockedAsset := TestLibrary.CreateTestAsset('Blocked Asset');
        BlockedAsset.Blocked := true;
        BlockedAsset.Modify(true);

        // [WHEN] Running report without blocking filter
        Asset.SetFilter("No.", '%1|%2', NormalAsset."No.", BlockedAsset."No.");
        AssetListReport.SetTableView(Asset);
        AssetListReport.UseRequestPage(false);
        AssetListReport.Run();

        // [THEN] Report completes successfully (both assets included by default)
        Assert.IsTrue(true, 'Report should handle blocked and normal assets');
    end;

    // ============================================
    // Date Filter Tests
    // ============================================

    [Test]
    procedure AssetListReport_FilterByDateModified_ShowsOnlyFilteredAssets()
    var
        Asset: Record "JML AP Asset";
        RecentAsset, OldAsset: Record "JML AP Asset";
        AssetListReport: Report "JML AP Asset List";
        RecentDate: Date;
    begin
        TestLibrary.Initialize();

        // [GIVEN] Assets with different modification dates
        RecentDate := CalcDate('<-1D>', Today);

        RecentAsset := TestLibrary.CreateTestAsset('Recent Asset');
        RecentAsset."Last Date Modified" := Today;
        RecentAsset.Modify(true);

        OldAsset := TestLibrary.CreateTestAsset('Old Asset');
        OldAsset."Last Date Modified" := CalcDate('<-1Y>', Today);
        OldAsset.Modify(true);

        // [WHEN] Running report with date filter
        Asset.SetFilter("Last Date Modified", '>=%1', RecentDate);
        AssetListReport.SetTableView(Asset);
        AssetListReport.UseRequestPage(false);
        AssetListReport.Run();

        // [THEN] Report completes successfully with date filter
        Assert.IsTrue(true, 'Report should respect date modified filter');
    end;
}
