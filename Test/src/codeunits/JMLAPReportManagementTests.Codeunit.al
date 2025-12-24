codeunit 50131 "JML AP Report Mgmt Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        TestLibrary: Codeunit "JML AP Test Library";
        ReportMgt: Codeunit "JML AP Report Management";

    // ============================================
    // BuildClassificationPath Tests
    // ============================================

    [Test]
    procedure BuildClassificationPath_EmptyClassification_ReturnsEmpty()
    var
        Result: Text[250];
    begin
        // [GIVEN] Empty classification code
        // [WHEN] Building classification path
        Result := ReportMgt.BuildClassificationPath('', '');

        // [THEN] Returns empty text
        Assert.AreEqual('', Result, 'Empty classification should return empty path');
    end;

    [Test]
    procedure BuildClassificationPath_SingleLevelClassification_ReturnsSingleValue()
    var
        Industry: Record "JML AP Asset Industry";
        ClassLevel: Record "JML AP Classification Lvl";
        ClassValue: Record "JML AP Classification Val";
        Result: Text[250];
    begin
        TestLibrary.Initialize();

        // [GIVEN] A single-level classification
        Industry := TestLibrary.CreateIndustry('IND01', 'Test Industry');
        ClassLevel := TestLibrary.CreateClassificationLevel(Industry.Code, 1, 'Level 1');
        ClassValue := TestLibrary.CreateClassificationValue(Industry.Code, ClassLevel."Level Number", 'VAL01', 'Value 1', '', 0);

        // [WHEN] Building classification path
        Result := ReportMgt.BuildClassificationPath(Industry.Code, ClassValue.Code);

        // [THEN] Returns single value description
        Assert.AreEqual('Value 1', Result, 'Single-level should return just the value description');
    end;

    [Test]
    procedure BuildClassificationPath_MultiLevelClassification_ReturnsFullPath()
    var
        Industry: Record "JML AP Asset Industry";
        ClassLevel1, ClassLevel2, ClassLevel3: Record "JML AP Classification Lvl";
        ClassValue1, ClassValue2, ClassValue3: Record "JML AP Classification Val";
        Result: Text[250];
        ExpectedPath: Text[250];
    begin
        TestLibrary.Initialize();

        // [GIVEN] A three-level classification hierarchy
        Industry := TestLibrary.CreateIndustry('IND02', 'Maritime');
        ClassLevel1 := TestLibrary.CreateClassificationLevel(Industry.Code, 1, 'Category');
        ClassLevel2 := TestLibrary.CreateClassificationLevel(Industry.Code, 2, 'Type');
        ClassLevel3 := TestLibrary.CreateClassificationLevel(Industry.Code, 3, 'SubType');

        ClassValue1 := TestLibrary.CreateClassificationValue(Industry.Code, 1, 'COMM', 'Commercial', '', 0);
        ClassValue2 := TestLibrary.CreateClassificationValue(Industry.Code, 2, 'CARGO', 'Cargo Ship', 'COMM', 1);
        ClassValue3 := TestLibrary.CreateClassificationValue(Industry.Code, 3, 'PANAMAX', 'Panamax', 'CARGO', 2);

        // [WHEN] Building classification path for leaf node
        Result := ReportMgt.BuildClassificationPath(Industry.Code, ClassValue3.Code);

        // [THEN] Returns full path from root to leaf
        ExpectedPath := 'Commercial / Cargo Ship / Panamax';
        Assert.AreEqual(ExpectedPath, Result, 'Multi-level should return full path with separators');
    end;

    // ============================================
    // FormatHolderAddress Tests
    // ============================================

    [Test]
    procedure FormatHolderAddress_Customer_FormatsCorrectly()
    var
        Customer: Record Customer;
        AddrArray: array[8] of Text[100];
    begin
        TestLibrary.Initialize();

        // [GIVEN] A customer with address
        Customer := TestLibrary.CreateCustomer();

        // [WHEN] Formatting holder address for Customer
        ReportMgt.FormatHolderAddress("JML AP Holder Type"::Customer, Customer."No.", Customer.Name, '', AddrArray);

        // [THEN] Address array contains customer name and address
        Assert.AreNotEqual('', AddrArray[1], 'First line should contain name or address info');
    end;

    [Test]
    procedure FormatHolderAddress_Location_FormatsWithLocationAddress()
    var
        Location: Record Location;
        AddrArray: array[8] of Text[100];
    begin
        TestLibrary.Initialize();

        // [GIVEN] A location with address
        Location := TestLibrary.CreateTestLocation('LOC01');

        // [WHEN] Formatting holder address for Location
        ReportMgt.FormatHolderAddress("JML AP Holder Type"::Location, Location.Code, Location.Name, '', AddrArray);

        // [THEN] Address array contains location info
        Assert.AreNotEqual('', AddrArray[1], 'First line should contain location name or address');
    end;

    [Test]
    procedure FormatHolderAddress_EmptyHolder_ReturnsEmptyArray()
    var
        AddrArray: array[8] of Text[100];
        i: Integer;
    begin
        // [GIVEN] Empty holder code
        // [WHEN] Formatting holder address with empty code
        ReportMgt.FormatHolderAddress("JML AP Holder Type"::Customer, '', '', '', AddrArray);

        // [THEN] All array elements should be empty
        for i := 1 to 8 do
            Assert.AreEqual('', AddrArray[i], StrSubstNo('Address line %1 should be empty for empty holder', i));
    end;

    // ============================================
    // GetHolderContactInfo Tests
    // ============================================

    [Test]
    procedure GetHolderContactInfo_Customer_ReturnsContactInfo()
    var
        Customer: Record Customer;
        ContactInfo: Text[250];
    begin
        TestLibrary.Initialize();

        // [GIVEN] A customer with contact information
        Customer := TestLibrary.CreateCustomer();
        Customer."Phone No." := '555-1234';
        Customer."E-Mail" := 'test@example.com';
        Customer.Modify();

        // [WHEN] Getting holder contact info
        ContactInfo := ReportMgt.GetHolderContactInfo("JML AP Holder Type"::Customer, Customer."No.");

        // [THEN] Returns correct contact information
        Assert.IsTrue(StrPos(ContactInfo, '555-1234') > 0, 'Should contain phone number');
        Assert.IsTrue(StrPos(ContactInfo, 'test@example.com') > 0, 'Should contain email');
    end;

    [Test]
    procedure GetHolderContactInfo_Location_ReturnsEmpty()
    var
        ContactInfo: Text[250];
    begin
        TestLibrary.Initialize();

        // [GIVEN] A location holder (locations don't have contact info)
        // [WHEN] Getting holder contact info for Location
        ContactInfo := ReportMgt.GetHolderContactInfo("JML AP Holder Type"::Location, 'LOC01');

        // [THEN] Returns empty contact information
        Assert.AreEqual('', ContactInfo, 'Contact info should be empty for Location');
    end;

    // ============================================
    // FormatDateRange Tests
    // ============================================

    [Test]
    procedure FormatDateRange_BothDatesProvided_ReturnsRange()
    var
        StartDate, EndDate: Date;
        Result: Text[100];
    begin
        // [GIVEN] Start and end dates
        StartDate := 20250101D;
        EndDate := 20250131D;

        // [WHEN] Formatting date range
        Result := ReportMgt.FormatDateRange(StartDate, EndDate);

        // [THEN] Returns formatted date range
        Assert.AreNotEqual('', Result, 'Should return formatted date range');
        Assert.IsTrue(StrPos(Result, '01/01/2025') > 0, 'Should contain start date');
        Assert.IsTrue(StrPos(Result, '01/31/2025') > 0, 'Should contain end date');
    end;

    [Test]
    procedure FormatDateRange_OnlyStartDate_ReturnsFromDate()
    var
        StartDate: Date;
        Result: Text[100];
    begin
        // [GIVEN] Only start date
        StartDate := 20250101D;

        // [WHEN] Formatting date range with no end date
        Result := ReportMgt.FormatDateRange(StartDate, 0D);

        // [THEN] Returns "From: [date]" format
        Assert.AreNotEqual('', Result, 'Should return formatted start date');
    end;

    [Test]
    procedure FormatDateRange_NoDates_ReturnsAllDates()
    var
        Result: Text[100];
    begin
        // [GIVEN] No dates provided
        // [WHEN] Formatting date range with both dates empty
        Result := ReportMgt.FormatDateRange(0D, 0D);

        // [THEN] Returns "All Dates" or similar
        Assert.AreNotEqual('', Result, 'Should return indication of all dates');
    end;

    // ============================================
    // CountDistinctHolders Tests
    // ============================================

    [Test]
    procedure CountDistinctHolders_NoAssets_ReturnsZero()
    var
        Asset: Record "JML AP Asset";
        Count: Integer;
    begin
        TestLibrary.Initialize();

        // [GIVEN] No assets in the system
        Asset.DeleteAll();

        // [WHEN] Counting distinct holders
        Count := ReportMgt.CountDistinctHolders(Asset);

        // [THEN] Returns zero
        Assert.AreEqual(0, Count, 'Should return zero for no assets');
    end;

    [Test]
    procedure CountDistinctHolders_MultipleDifferentHolders_ReturnsCorrectCount()
    var
        Asset: Record "JML AP Asset";
        Asset1, Asset2, Asset3: Record "JML AP Asset";
        Location1, Location2: Record Location;
        Count: Integer;
    begin
        TestLibrary.Initialize();

        // [GIVEN] Assets at different locations
        Location1 := TestLibrary.CreateTestLocation('LOC01');
        Location2 := TestLibrary.CreateTestLocation('LOC02');
        Asset1 := TestLibrary.CreateAssetAtLocation('Asset 1', Location1.Code);
        Asset2 := TestLibrary.CreateAssetAtLocation('Asset 2', Location1.Code);
        Asset3 := TestLibrary.CreateAssetAtLocation('Asset 3', Location2.Code);

        // [WHEN] Counting distinct holders
        Asset.SetRange("Current Holder Type", Asset."Current Holder Type"::Location);
        Count := ReportMgt.CountDistinctHolders(Asset);

        // [THEN] Returns 2 (two distinct locations)
        Assert.AreEqual(2, Count, 'Should return 2 for two distinct locations');
    end;

    [Test]
    procedure CountDistinctHolders_SameHolderMultipleAssets_ReturnsOne()
    var
        Asset: Record "JML AP Asset";
        Asset1, Asset2, Asset3: Record "JML AP Asset";
        Location: Record Location;
        Count: Integer;
    begin
        TestLibrary.Initialize();

        // [GIVEN] Multiple assets at the same location
        Location := TestLibrary.CreateTestLocation('LOC01');
        Asset1 := TestLibrary.CreateAssetAtLocation('Asset 1', Location.Code);
        Asset2 := TestLibrary.CreateAssetAtLocation('Asset 2', Location.Code);
        Asset3 := TestLibrary.CreateAssetAtLocation('Asset 3', Location.Code);

        // [WHEN] Counting distinct holders
        Asset.SetRange("Current Holder Type", Asset."Current Holder Type"::Location);
        Asset.SetRange("Current Holder Code", Location.Code);
        Count := ReportMgt.CountDistinctHolders(Asset);

        // [THEN] Returns 1 (single location)
        Assert.AreEqual(1, Count, 'Should return 1 for single location with multiple assets');
    end;
}
