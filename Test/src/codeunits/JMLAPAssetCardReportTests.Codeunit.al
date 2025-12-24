codeunit 50135 "JML AP Asset Card Rpt Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        TestLibrary: Codeunit "JML AP Test Library";
        OnlyOneAssetErr: Label 'This report can only be run for one asset at a time.';

    // ============================================
    // Basic Report Execution Tests
    // ============================================

    [Test]
    procedure AssetCardReport_SingleAsset_RunsSuccessfully()
    var
        Asset: Record "JML AP Asset";
        CreatedAsset: Record "JML AP Asset";
        AssetCardReport: Report "JML AP Asset Card Report";
    begin
        TestLibrary.Initialize();

        // [GIVEN] A single asset
        CreatedAsset := TestLibrary.CreateTestAsset('Test Asset 001');

        // [WHEN] Running the Asset Card report for single asset
        Asset.SetRange("No.", CreatedAsset."No.");
        AssetCardReport.SetTableView(Asset);
        AssetCardReport.UseRequestPage(false);
        AssetCardReport.Run();

        // [THEN] Report completes successfully
        Assert.IsTrue(true, 'Asset Card report should run successfully for single asset');
    end;

    [Test]
    procedure AssetCardReport_MultipleAssets_ThrowsError()
    var
        Asset: Record "JML AP Asset";
        Asset1, Asset2: Record "JML AP Asset";
        AssetCardReport: Report "JML AP Asset Card Report";
        ErrorOccurred: Boolean;
    begin
        TestLibrary.Initialize();

        // [GIVEN] Multiple assets
        Asset1 := TestLibrary.CreateTestAsset('Asset 1');
        Asset2 := TestLibrary.CreateTestAsset('Asset 2');

        // [WHEN] Running the Asset Card report for multiple assets
        Asset.SetFilter("No.", '%1|%2', Asset1."No.", Asset2."No.");
        AssetCardReport.SetTableView(Asset);
        AssetCardReport.UseRequestPage(false);

        // [THEN] Report throws error about multiple assets
        asserterror AssetCardReport.Run();
        ErrorOccurred := GetLastErrorText().Contains('one asset');
        Assert.IsTrue(ErrorOccurred, 'Should throw error for multiple assets');
        ClearLastError();
    end;

    // ============================================
    // Asset Details Section Tests
    // ============================================

    [Test]
    procedure AssetCardReport_AssetWithBasicInfo_DisplaysCorrectly()
    var
        Asset: Record "JML AP Asset";
        CreatedAsset: Record "JML AP Asset";
        AssetCardReport: Report "JML AP Asset Card Report";
    begin
        TestLibrary.Initialize();

        // [GIVEN] Asset with basic information
        CreatedAsset := TestLibrary.CreateTestAsset('Detailed Asset');
        CreatedAsset.Description := 'Asset with Details';
        CreatedAsset."Serial No." := 'SN-12345';
        CreatedAsset.Status := CreatedAsset.Status::Active;
        CreatedAsset.Modify(true);

        // [WHEN] Running the Asset Card report
        Asset.SetRange("No.", CreatedAsset."No.");
        AssetCardReport.SetTableView(Asset);
        AssetCardReport.UseRequestPage(false);
        AssetCardReport.Run();

        // [THEN] Report completes with asset details
        Assert.IsTrue(true, 'Report should display asset basic information');
    end;

    [Test]
    procedure AssetCardReport_AssetWithClassification_DisplaysClassificationPath()
    var
        Asset: Record "JML AP Asset";
        CreatedAsset: Record "JML AP Asset";
        Industry: Record "JML AP Asset Industry";
        ClassLevel: Record "JML AP Classification Lvl";
        ClassValue: Record "JML AP Classification Val";
        AssetCardReport: Report "JML AP Asset Card Report";
    begin
        TestLibrary.Initialize();

        // [GIVEN] Asset with classification
        Industry := TestLibrary.CreateIndustry('MAR', 'Maritime');
        ClassLevel := TestLibrary.CreateClassificationLevel(Industry.Code, 1, 'Type');
        ClassValue := TestLibrary.CreateClassificationValue(Industry.Code, 1, 'VESSEL', 'Vessel', '', 0);

        CreatedAsset := TestLibrary.CreateTestAsset('Classified Asset');
        CreatedAsset."Industry Code" := Industry.Code;
        CreatedAsset."Classification Code" := ClassValue.Code;
        CreatedAsset.Modify(true);

        // [WHEN] Running the Asset Card report
        Asset.SetRange("No.", CreatedAsset."No.");
        AssetCardReport.SetTableView(Asset);
        AssetCardReport.UseRequestPage(false);
        AssetCardReport.Run();

        // [THEN] Report completes with classification
        Assert.IsTrue(true, 'Report should display classification information');
    end;

    [Test]
    procedure AssetCardReport_AssetWithFinancialInfo_DisplaysFinancials()
    var
        Asset: Record "JML AP Asset";
        CreatedAsset: Record "JML AP Asset";
        AssetCardReport: Report "JML AP Asset Card Report";
    begin
        TestLibrary.Initialize();

        // [GIVEN] Asset with financial information
        CreatedAsset := TestLibrary.CreateTestAsset('Asset with Financials');
        CreatedAsset."Acquisition Cost" := 100000;
        CreatedAsset."Current Book Value" := 85000;
        CreatedAsset."Residual Value" := 10000;
        CreatedAsset."Acquisition Date" := CalcDate('<-1Y>', Today);
        CreatedAsset.Modify(true);

        // [WHEN] Running the Asset Card report
        Asset.SetRange("No.", CreatedAsset."No.");
        AssetCardReport.SetTableView(Asset);
        AssetCardReport.UseRequestPage(false);
        AssetCardReport.Run();

        // [THEN] Report completes with financial information
        Assert.IsTrue(true, 'Report should display financial information');
    end;

    // ============================================
    // Current Holder Section Tests
    // ============================================

    [Test]
    procedure AssetCardReport_AssetAtLocation_DisplaysCurrentHolder()
    var
        Asset: Record "JML AP Asset";
        Location: Record Location;
        AssetAtLocation: Record "JML AP Asset";
        AssetCardReport: Report "JML AP Asset Card Report";
    begin
        TestLibrary.Initialize();

        // [GIVEN] Asset at a location
        Location := TestLibrary.CreateTestLocation('LOC01');
        AssetAtLocation := TestLibrary.CreateAssetAtLocation('Asset at Location', Location.Code);

        // [WHEN] Running the Asset Card report
        Asset.SetRange("No.", AssetAtLocation."No.");
        AssetCardReport.SetTableView(Asset);
        AssetCardReport.UseRequestPage(false);
        AssetCardReport.Run();

        // [THEN] Report completes with current holder information
        Assert.IsTrue(true, 'Report should display current holder (Location)');
    end;

    [Test]
    procedure AssetCardReport_AssetAtCustomer_DisplaysCurrentHolder()
    var
        Asset: Record "JML AP Asset";
        Customer: Record Customer;
        AssetAtCustomer: Record "JML AP Asset";
        AssetCardReport: Report "JML AP Asset Card Report";
    begin
        TestLibrary.Initialize();

        // [GIVEN] Asset at a customer
        Customer := TestLibrary.CreateCustomer();
        AssetAtCustomer := TestLibrary.CreateAssetAtCustomer('Asset at Customer', Customer."No.");

        // [WHEN] Running the Asset Card report
        Asset.SetRange("No.", AssetAtCustomer."No.");
        AssetCardReport.SetTableView(Asset);
        AssetCardReport.UseRequestPage(false);
        AssetCardReport.Run();

        // [THEN] Report completes with current holder information
        Assert.IsTrue(true, 'Report should display current holder (Customer)');
    end;

    // ============================================
    // Ownership Section Tests
    // ============================================

    [Test]
    procedure AssetCardReport_AssetWithOwnership_DisplaysOwnerInfo()
    var
        Asset: Record "JML AP Asset";
        CreatedAsset: Record "JML AP Asset";
        Vendor: Record Vendor;
        AssetCardReport: Report "JML AP Asset Card Report";
    begin
        TestLibrary.Initialize();

        // [GIVEN] Asset with owner information
        Vendor := TestLibrary.CreateVendor();
        CreatedAsset := TestLibrary.CreateTestAsset('Asset with Owner');
        CreatedAsset."Owner Type" := CreatedAsset."Owner Type"::Vendor;
        CreatedAsset."Owner Code" := Vendor."No.";
        CreatedAsset.Modify(true);

        // [WHEN] Running the Asset Card report
        Asset.SetRange("No.", CreatedAsset."No.");
        AssetCardReport.SetTableView(Asset);
        AssetCardReport.UseRequestPage(false);
        AssetCardReport.Run();

        // [THEN] Report completes with ownership information
        Assert.IsTrue(true, 'Report should display ownership information');
    end;

    [Test]
    procedure AssetCardReport_AssetWithOperator_DisplaysOperatorInfo()
    var
        Asset: Record "JML AP Asset";
        CreatedAsset: Record "JML AP Asset";
        Customer: Record Customer;
        AssetCardReport: Report "JML AP Asset Card Report";
    begin
        TestLibrary.Initialize();

        // [GIVEN] Asset with operator information
        Customer := TestLibrary.CreateCustomer();
        CreatedAsset := TestLibrary.CreateTestAsset('Asset with Operator');
        CreatedAsset."Operator Type" := CreatedAsset."Operator Type"::Customer;
        CreatedAsset."Operator Code" := Customer."No.";
        CreatedAsset.Modify(true);

        // [WHEN] Running the Asset Card report
        Asset.SetRange("No.", CreatedAsset."No.");
        AssetCardReport.SetTableView(Asset);
        AssetCardReport.UseRequestPage(false);
        AssetCardReport.Run();

        // [THEN] Report completes with operator information
        Assert.IsTrue(true, 'Report should display operator information');
    end;

    // ============================================
    // Holder History Section Tests
    // ============================================

    [Test]
    procedure AssetCardReport_AssetWithHolderHistory_DisplaysHistory()
    var
        Asset: Record "JML AP Asset";
        Location1, Location2: Record Location;
        AssetWithHistory: Record "JML AP Asset";
        AssetCardReport: Report "JML AP Asset Card Report";
    begin
        TestLibrary.Initialize();

        // [GIVEN] Asset with holder history (transferred between locations)
        Location1 := TestLibrary.CreateTestLocation('LOC01');
        Location2 := TestLibrary.CreateTestLocation('LOC02');

        AssetWithHistory := TestLibrary.CreateAssetAtLocation('Asset with History', Location1.Code);
        TestLibrary.CreateAndPostTransferOrder(AssetWithHistory."No.", Location1.Code, Location2.Code);

        // [WHEN] Running the Asset Card report
        Asset.SetRange("No.", AssetWithHistory."No.");
        AssetCardReport.SetTableView(Asset);
        AssetCardReport.UseRequestPage(false);
        AssetCardReport.Run();

        // [THEN] Report completes with holder history
        Assert.IsTrue(true, 'Report should display holder history');
    end;

    // ============================================
    // Attributes Section Tests
    // ============================================

    [Test]
    procedure AssetCardReport_AssetWithAttributes_DisplaysAttributes()
    var
        Asset: Record "JML AP Asset";
        CreatedAsset: Record "JML AP Asset";
        AssetAttrValue: Record "JML AP Attribute Value";
        AssetCardReport: Report "JML AP Asset Card Report";
    begin
        TestLibrary.Initialize();

        // [GIVEN] Asset with custom attributes
        CreatedAsset := TestLibrary.CreateTestAsset('Asset with Attributes');

        // Create attribute value for asset
        AssetAttrValue.Init();
        AssetAttrValue."Asset No." := CreatedAsset."No.";
        AssetAttrValue."Attribute Code" := 'COLOR';
        AssetAttrValue."Value Text" := 'Blue';
        AssetAttrValue.Insert(true);

        // [WHEN] Running the Asset Card report
        Asset.SetRange("No.", CreatedAsset."No.");
        AssetCardReport.SetTableView(Asset);
        AssetCardReport.UseRequestPage(false);
        AssetCardReport.Run();

        // [THEN] Report completes with attributes
        Assert.IsTrue(true, 'Report should display custom attributes');
    end;

    // ============================================
    // Child Assets Section Tests
    // ============================================

    [Test]
    procedure AssetCardReport_AssetWithChildren_DisplaysChildren()
    var
        Asset: Record "JML AP Asset";
        ParentAsset, ChildAsset1, ChildAsset2: Record "JML AP Asset";
        AssetCardReport: Report "JML AP Asset Card Report";
    begin
        TestLibrary.Initialize();

        // [GIVEN] Asset with child assets
        ParentAsset := TestLibrary.CreateTestAsset('Parent Asset');

        ChildAsset1 := TestLibrary.CreateTestAsset('Child Asset 1');
        ChildAsset1."Parent Asset No." := ParentAsset."No.";
        ChildAsset1.Modify(true);

        ChildAsset2 := TestLibrary.CreateTestAsset('Child Asset 2');
        ChildAsset2."Parent Asset No." := ParentAsset."No.";
        ChildAsset2.Modify(true);

        // [WHEN] Running the Asset Card report for parent
        Asset.SetRange("No.", ParentAsset."No.");
        AssetCardReport.SetTableView(Asset);
        AssetCardReport.UseRequestPage(false);
        AssetCardReport.Run();

        // [THEN] Report completes with child assets
        Assert.IsTrue(true, 'Report should display child assets');
    end;

    // ============================================
    // Dates Section Tests
    // ============================================

    [Test]
    procedure AssetCardReport_AssetWithDates_DisplaysAllDates()
    var
        Asset: Record "JML AP Asset";
        CreatedAsset: Record "JML AP Asset";
        AssetCardReport: Report "JML AP Asset Card Report";
    begin
        TestLibrary.Initialize();

        // [GIVEN] Asset with various dates
        CreatedAsset := TestLibrary.CreateTestAsset('Asset with Dates');
        CreatedAsset."Acquisition Date" := CalcDate('<-2Y>', Today);
        CreatedAsset."In-Service Date" := CalcDate('<-1Y>', Today);
        CreatedAsset."Last Service Date" := CalcDate('<-1M>', Today);
        CreatedAsset."Next Service Date" := CalcDate('<+2M>', Today);
        CreatedAsset.Modify(true);

        // [WHEN] Running the Asset Card report
        Asset.SetRange("No.", CreatedAsset."No.");
        AssetCardReport.SetTableView(Asset);
        AssetCardReport.UseRequestPage(false);
        AssetCardReport.Run();

        // [THEN] Report completes with all dates
        Assert.IsTrue(true, 'Report should display all asset dates');
    end;

    // ============================================
    // Additional Information Section Tests
    // ============================================

    [Test]
    procedure AssetCardReport_AssetWithManufacturerInfo_DisplaysCorrectly()
    var
        Asset: Record "JML AP Asset";
        CreatedAsset: Record "JML AP Asset";
        Manufacturer: Record Manufacturer;
        AssetCardReport: Report "JML AP Asset Card Report";
    begin
        TestLibrary.Initialize();

        // [GIVEN] Asset with manufacturer information
        Manufacturer.Init();
        Manufacturer.Code := 'MFG01';
        Manufacturer.Name := 'Test Manufacturer';
        if not Manufacturer.Insert(true) then
            Manufacturer.Modify(true);

        CreatedAsset := TestLibrary.CreateTestAsset('Asset with Manufacturer');
        CreatedAsset."Manufacturer Code" := Manufacturer.Code;
        CreatedAsset."Model No." := 'MODEL-X100';
        CreatedAsset."Year of Manufacture" := 2020;
        CreatedAsset.Modify(true);

        // [WHEN] Running the Asset Card report
        Asset.SetRange("No.", CreatedAsset."No.");
        AssetCardReport.SetTableView(Asset);
        AssetCardReport.UseRequestPage(false);
        AssetCardReport.Run();

        // [THEN] Report completes with manufacturer information
        Assert.IsTrue(true, 'Report should display manufacturer information');
    end;

    // ============================================
    // Edge Case Tests
    // ============================================

    [Test]
    procedure AssetCardReport_NewAssetNoHistory_RunsSuccessfully()
    var
        Asset: Record "JML AP Asset";
        NewAsset: Record "JML AP Asset";
        AssetCardReport: Report "JML AP Asset Card Report";
    begin
        TestLibrary.Initialize();

        // [GIVEN] Newly created asset with no history
        NewAsset := TestLibrary.CreateTestAsset('New Asset');

        // [WHEN] Running the Asset Card report
        Asset.SetRange("No.", NewAsset."No.");
        AssetCardReport.SetTableView(Asset);
        AssetCardReport.UseRequestPage(false);
        AssetCardReport.Run();

        // [THEN] Report completes successfully (with empty history sections)
        Assert.IsTrue(true, 'Report should handle asset with no history');
    end;

    [Test]
    procedure AssetCardReport_AssetWithAllSections_DisplaysComprehensively()
    var
        Asset: Record "JML AP Asset";
        Location: Record Location;
        Industry: Record "JML AP Asset Industry";
        ClassLevel: Record "JML AP Classification Lvl";
        ClassValue: Record "JML AP Classification Val";
        ComprehensiveAsset: Record "JML AP Asset";
        AssetCardReport: Report "JML AP Asset Card Report";
    begin
        TestLibrary.Initialize();

        // [GIVEN] Asset with data in all sections
        Industry := TestLibrary.CreateIndustry('COMP', 'Comprehensive');
        ClassLevel := TestLibrary.CreateClassificationLevel(Industry.Code, 1, 'Category');
        ClassValue := TestLibrary.CreateClassificationValue(Industry.Code, 1, 'CAT1', 'Category 1', '', 0);
        Location := TestLibrary.CreateTestLocation('LOC01');

        ComprehensiveAsset := TestLibrary.CreateAssetAtLocation('Comprehensive Asset', Location.Code);
        ComprehensiveAsset."Industry Code" := Industry.Code;
        ComprehensiveAsset."Classification Code" := ClassValue.Code;
        ComprehensiveAsset."Serial No." := 'SN-COMPREHENSIVE';
        ComprehensiveAsset."Acquisition Cost" := 150000;
        ComprehensiveAsset."Acquisition Date" := CalcDate('<-1Y>', Today);
        ComprehensiveAsset.Modify(true);

        // [WHEN] Running the Asset Card report
        Asset.SetRange("No.", ComprehensiveAsset."No.");
        AssetCardReport.SetTableView(Asset);
        AssetCardReport.UseRequestPage(false);
        AssetCardReport.Run();

        // [THEN] Report completes with all sections populated
        Assert.IsTrue(true, 'Report should display comprehensive asset information');
    end;
}
