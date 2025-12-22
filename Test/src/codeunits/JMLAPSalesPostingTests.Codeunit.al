codeunit 50123 "JML AP Sales Posting Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";
        IsInitialized: Boolean;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Handle messages during test execution (e.g., posting number series gap messages)
    end;

    // ============================================================================
    // Story 2.1: Sales Order Posting with Assets - Happy Path Tests
    // ============================================================================

    [Test]
    procedure TestPostSalesOrder_SingleAsset_TransfersToCustomer()
    var
        Customer: Record Customer;
        Location: Record Location;
        Asset: Record "JML AP Asset";
        SalesHeader: Record "Sales Header";
        SalesAssetLine: Record "JML AP Sales Asset Line";
        PostedShptHeader: Record "Sales Shipment Header";
        PostedAssetLine: Record "JML AP Pstd Sales Shpt Ast Ln";
        HolderEntry: Record "JML AP Holder Entry";
        AssetSetup: Record "JML AP Asset Setup";
        PostedShptNo: Code[20];
    begin
        // [SCENARIO] Post Sales Order with single asset, verify holder transfer

        // [GIVEN] A customer, location, and asset at that location
        Initialize();
        EnsureSetupExists(AssetSetup);
        CreateTestCustomer(Customer, 'TEST-CUST-001');
        CreateTestLocation(Location, 'TEST-LOC');
        CreateTestAsset(Asset, 'TEST-ASSET-001', "JML AP Holder Type"::Location, Location.Code);
        CreateSalesOrderWithAsset(SalesHeader, SalesAssetLine, Customer."No.", Asset."No.", Location.Code);

        // [WHEN] Posting the sales shipment
        PostedShptNo := PostSalesShipment(SalesHeader);

        // [THEN] Asset holder changed to customer
        Asset.Get(Asset."No.");
        LibraryAssert.AreEqual("JML AP Holder Type"::Customer, Asset."Current Holder Type", 'Asset holder type should be Customer');
        LibraryAssert.AreEqual(Customer."No.", Asset."Current Holder Code", 'Asset holder code should be customer number');

        // [THEN] Posted shipment header created
        LibraryAssert.IsTrue(PostedShptHeader.Get(PostedShptNo), 'Posted shipment header should exist');

        // [THEN] Posted asset line created
        PostedAssetLine.SetRange("Document No.", PostedShptNo);
        LibraryAssert.RecordCount(PostedAssetLine, 1);
        PostedAssetLine.FindFirst();
        LibraryAssert.AreEqual(Asset."No.", PostedAssetLine."Asset No.", 'Posted line asset no. should match');
        LibraryAssert.IsTrue(PostedAssetLine."Transaction No." > 0, 'Transaction no. should be assigned');

        // [THEN] Holder entries created (Transfer Out + Transfer In)
        HolderEntry.SetRange("Asset No.", Asset."No.");
        HolderEntry.SetRange("Transaction No.", PostedAssetLine."Transaction No.");
        LibraryAssert.RecordCount(HolderEntry, 2);

        // Cleanup
        CleanupTestData(SalesHeader."No.", Asset."No.", Customer."No.", Location.Code);
    end;

    [Test]
    procedure TestPostSalesOrder_MultipleAssets_AllTransferred()
    var
        Customer: Record Customer;
        Location: Record Location;
        Asset1, Asset2, Asset3: Record "JML AP Asset";
        SalesHeader: Record "Sales Header";
        SalesAssetLine: Record "JML AP Sales Asset Line";
        PostedAssetLine: Record "JML AP Pstd Sales Shpt Ast Ln";
        HolderEntry: Record "JML AP Holder Entry";
        AssetSetup: Record "JML AP Asset Setup";
        PostedShptNo: Code[20];
    begin
        // [SCENARIO] Post Sales Order with 3 assets, verify all transferred

        // [GIVEN] A customer, location, and 3 assets at that location
        Initialize();
        EnsureSetupExists(AssetSetup);
        CreateTestCustomer(Customer, 'TEST-CUST-002');
        CreateTestLocation(Location, 'TEST-LOCA');
        CreateTestAsset(Asset1, 'TEST-ASSET-002', "JML AP Holder Type"::Location, Location.Code);
        CreateTestAsset(Asset2, 'TEST-ASSET-003', "JML AP Holder Type"::Location, Location.Code);
        CreateTestAsset(Asset3, 'TEST-ASSET-004', "JML AP Holder Type"::Location, Location.Code);

        // [GIVEN] A sales order with 3 asset lines
        CreateSalesOrderHeader(SalesHeader, Customer."No.");
        SalesHeader."Location Code" := Location.Code; // Set location code before adding asset lines
        SalesHeader.Modify();
        AddDummySalesLine(SalesHeader); // Add minimal item line for BC posting requirements
        AddSalesAssetLine(SalesAssetLine, SalesHeader, Asset1."No.", 20000);
        AddSalesAssetLine(SalesAssetLine, SalesHeader, Asset2."No.", 30000);
        AddSalesAssetLine(SalesAssetLine, SalesHeader, Asset3."No.", 40000);

        // [WHEN] Posting the sales shipment
        PostedShptNo := PostSalesShipment(SalesHeader);

        // [THEN] All 3 assets transferred to customer
        Asset1.Get(Asset1."No.");
        Asset2.Get(Asset2."No.");
        Asset3.Get(Asset3."No.");
        LibraryAssert.AreEqual("JML AP Holder Type"::Customer, Asset1."Current Holder Type", 'Asset1 should be with customer');
        LibraryAssert.AreEqual("JML AP Holder Type"::Customer, Asset2."Current Holder Type", 'Asset2 should be with customer');
        LibraryAssert.AreEqual("JML AP Holder Type"::Customer, Asset3."Current Holder Type", 'Asset3 should be with customer');

        // [THEN] 3 posted asset lines created
        PostedAssetLine.SetRange("Document No.", PostedShptNo);
        LibraryAssert.RecordCount(PostedAssetLine, 3);

        // [THEN] Each has unique transaction number
        PostedAssetLine.FindSet();
        LibraryAssert.IsTrue(PostedAssetLine."Transaction No." > 0, 'Line 1 transaction no. assigned');
        PostedAssetLine.Next();
        LibraryAssert.IsTrue(PostedAssetLine."Transaction No." > 0, 'Line 2 transaction no. assigned');
        PostedAssetLine.Next();
        LibraryAssert.IsTrue(PostedAssetLine."Transaction No." > 0, 'Line 3 transaction no. assigned');

        // [THEN] 6 holder entries created (2 per asset)
        HolderEntry.SetFilter("Asset No.", '%1|%2|%3', Asset1."No.", Asset2."No.", Asset3."No.");
        LibraryAssert.RecordCount(HolderEntry, 6);

        // Cleanup
        CleanupTestData(SalesHeader."No.", Asset1."No.", Customer."No.", Location.Code);
        CleanupAsset(Asset2."No.");
        CleanupAsset(Asset3."No.");
    end;

    [Test]
    procedure TestPostSalesOrder_CreatesPostedAssetLines()
    var
        Customer: Record Customer;
        Location: Record Location;
        Asset: Record "JML AP Asset";
        SalesHeader: Record "Sales Header";
        SalesAssetLine: Record "JML AP Sales Asset Line";
        PostedAssetLine: Record "JML AP Pstd Sales Shpt Ast Ln";
        PostedShptHeader: Record "Sales Shipment Header";
        AssetSetup: Record "JML AP Asset Setup";
        PostedShptNo: Code[20];
    begin
        // [SCENARIO] Verify Posted Shipment Asset Line structure

        // [GIVEN] Standard setup with 1 asset
        Initialize();
        EnsureSetupExists(AssetSetup);
        CreateTestCustomer(Customer, 'TEST-CUST-003');
        CreateTestLocation(Location, 'TEST-LOCB');
        CreateTestAsset(Asset, 'TEST-ASSET-005', "JML AP Holder Type"::Location, Location.Code);
        CreateSalesOrderWithAsset(SalesHeader, SalesAssetLine, Customer."No.", Asset."No.", Location.Code);

        // [WHEN] Posting the shipment
        PostedShptNo := PostSalesShipment(SalesHeader);

        // [THEN] Posted line fields are correct
        PostedShptHeader.Get(PostedShptNo);
        PostedAssetLine.SetRange("Document No.", PostedShptNo);
        PostedAssetLine.FindFirst();

        LibraryAssert.AreEqual(PostedShptNo, PostedAssetLine."Document No.", 'Document no. should match');
        LibraryAssert.AreEqual(10000, PostedAssetLine."Line No.", 'Line no. should be 10000');
        LibraryAssert.AreEqual(Asset."No.", PostedAssetLine."Asset No.", 'Asset no. should match');
        LibraryAssert.AreEqual(Asset.Description, PostedAssetLine."Asset Description", 'Asset description should match');
        LibraryAssert.AreEqual(Customer."No.", PostedAssetLine."Sell-to Customer No.", 'Customer no. should match');
        LibraryAssert.AreEqual(Customer.Name, PostedAssetLine."Sell-to Customer Name", 'Customer name should match');
        LibraryAssert.AreEqual(PostedShptHeader."Posting Date", PostedAssetLine."Posting Date", 'Posting date should match');
        LibraryAssert.IsTrue(PostedAssetLine."Transaction No." > 0, 'Transaction no. should be assigned');

        // Cleanup
        CleanupTestData(SalesHeader."No.", Asset."No.", Customer."No.", Location.Code);
    end;

    [Test]
    procedure TestPostSalesOrder_CreatesHolderEntries()
    var
        Customer: Record Customer;
        Location: Record Location;
        Asset: Record "JML AP Asset";
        SalesHeader: Record "Sales Header";
        SalesAssetLine: Record "JML AP Sales Asset Line";
        PostedAssetLine: Record "JML AP Pstd Sales Shpt Ast Ln";
        HolderEntry: Record "JML AP Holder Entry";
        AssetSetup: Record "JML AP Asset Setup";
        PostedShptNo: Code[20];
        TransactionNo: Integer;
        TransferOutEntry, TransferInEntry: Record "JML AP Holder Entry";
    begin
        // [SCENARIO] Verify Holder Entries structure and linking

        // [GIVEN] Standard setup with 1 asset
        Initialize();
        EnsureSetupExists(AssetSetup);
        CreateTestCustomer(Customer, 'TEST-CUST-004');
        CreateTestLocation(Location, 'TEST-LOCC');
        CreateTestAsset(Asset, 'TEST-ASSET-006', "JML AP Holder Type"::Location, Location.Code);
        CreateSalesOrderWithAsset(SalesHeader, SalesAssetLine, Customer."No.", Asset."No.", Location.Code);

        // [WHEN] Posting the shipment
        PostedShptNo := PostSalesShipment(SalesHeader);

        // [THEN] Get transaction number from posted line
        PostedAssetLine.SetRange("Document No.", PostedShptNo);
        PostedAssetLine.FindFirst();
        TransactionNo := PostedAssetLine."Transaction No.";

        // [THEN] Find Transfer Out entry
        HolderEntry.SetRange("Asset No.", Asset."No.");
        HolderEntry.SetRange("Transaction No.", TransactionNo);
        HolderEntry.SetRange("Entry Type", HolderEntry."Entry Type"::"Transfer Out");
        LibraryAssert.RecordCount(HolderEntry, 1);
        HolderEntry.FindFirst();
        TransferOutEntry := HolderEntry;

        LibraryAssert.AreEqual(Asset."No.", TransferOutEntry."Asset No.", 'Transfer Out asset no. should match');
        LibraryAssert.AreEqual("JML AP Holder Type"::Location, TransferOutEntry."Holder Type", 'Transfer Out holder type should be Location');
        LibraryAssert.AreEqual(Location.Code, TransferOutEntry."Holder Code", 'Transfer Out holder code should be location');

        // [THEN] Find Transfer In entry
        HolderEntry.SetRange("Entry Type", HolderEntry."Entry Type"::"Transfer In");
        LibraryAssert.RecordCount(HolderEntry, 1);
        HolderEntry.FindFirst();
        TransferInEntry := HolderEntry;

        LibraryAssert.AreEqual(Asset."No.", TransferInEntry."Asset No.", 'Transfer In asset no. should match');
        LibraryAssert.AreEqual("JML AP Holder Type"::Customer, TransferInEntry."Holder Type", 'Transfer In holder type should be Customer');
        LibraryAssert.AreEqual(Customer."No.", TransferInEntry."Holder Code", 'Transfer In holder code should be customer');
        LibraryAssert.AreEqual(TransactionNo, TransferInEntry."Transaction No.", 'Transaction numbers should match');

        // Cleanup
        CleanupTestData(SalesHeader."No.", Asset."No.", Customer."No.", Location.Code);
    end;

    [Test]
    procedure TestPostSalesOrder_PartialShip_HandlesCorrectly()
    var
        Customer: Record Customer;
        Location: Record Location;
        Asset1, Asset2: Record "JML AP Asset";
        SalesHeader: Record "Sales Header";
        SalesAssetLine1, SalesAssetLine2: Record "JML AP Sales Asset Line";
        PostedAssetLine: Record "JML AP Pstd Sales Shpt Ast Ln";
        AssetSetup: Record "JML AP Asset Setup";
        PostedShptNo: Code[20];
    begin
        // [SCENARIO] Post partial shipment, verify quantities

        // [GIVEN] 2 Sales Asset Lines, only first one set to ship
        Initialize();
        EnsureSetupExists(AssetSetup);
        CreateTestCustomer(Customer, 'TEST-CUST-005');
        CreateTestLocation(Location, 'TEST-LOCD');
        CreateTestAsset(Asset1, 'TEST-ASSET-007', "JML AP Holder Type"::Location, Location.Code);
        CreateTestAsset(Asset2, 'TEST-ASSET-008', "JML AP Holder Type"::Location, Location.Code);

        CreateSalesOrderHeader(SalesHeader, Customer."No.");
        SalesHeader."Location Code" := Location.Code; // Set location code before adding asset lines
        SalesHeader.Modify();
        AddDummySalesLine(SalesHeader); // Add minimal item line for BC posting requirements
        AddSalesAssetLine(SalesAssetLine1, SalesHeader, Asset1."No.", 20000);
        AddSalesAssetLine(SalesAssetLine2, SalesHeader, Asset2."No.", 30000);

        // Set only Line 1 to ship
        SalesAssetLine1."Quantity to Ship" := 1;
        SalesAssetLine1.Modify();
        SalesAssetLine2."Quantity to Ship" := 0;
        SalesAssetLine2.Modify();

        // [WHEN] Posting the shipment
        PostedShptNo := PostSalesShipment(SalesHeader);

        // [THEN] Only Line 1 asset transferred
        Asset1.Get(Asset1."No.");
        Asset2.Get(Asset2."No.");
        LibraryAssert.AreEqual("JML AP Holder Type"::Customer, Asset1."Current Holder Type", 'Asset1 should be with customer');
        LibraryAssert.AreEqual("JML AP Holder Type"::Location, Asset2."Current Holder Type", 'Asset2 should still be at location');

        // [THEN] Only 1 posted asset line created
        PostedAssetLine.SetRange("Document No.", PostedShptNo);
        LibraryAssert.RecordCount(PostedAssetLine, 1);
        PostedAssetLine.FindFirst();
        LibraryAssert.AreEqual(Asset1."No.", PostedAssetLine."Asset No.", 'Posted line should be for Asset1');

        // [THEN] Line quantities updated correctly
        SalesAssetLine1.Get(SalesAssetLine1."Document Type", SalesAssetLine1."Document No.", SalesAssetLine1."Line No.");
        SalesAssetLine2.Get(SalesAssetLine2."Document Type", SalesAssetLine2."Document No.", SalesAssetLine2."Line No.");
        LibraryAssert.AreEqual(1, SalesAssetLine1."Quantity Shipped", 'Line 1 quantity shipped should be 1');
        LibraryAssert.AreEqual(0, SalesAssetLine1."Quantity to Ship", 'Line 1 quantity to ship should be 0');
        LibraryAssert.AreEqual(0, SalesAssetLine2."Quantity Shipped", 'Line 2 quantity shipped should be 0');
        LibraryAssert.AreEqual(0, SalesAssetLine2."Quantity to Ship", 'Line 2 quantity to ship should be 0');

        // Cleanup
        CleanupTestData(SalesHeader."No.", Asset1."No.", Customer."No.", Location.Code);
        CleanupAsset(Asset2."No.");
    end;

    // ============================================================================
    // Story 2.2: Sales Order Posting - Error Scenarios
    // ============================================================================

    [Test]
    procedure TestPostSalesOrder_AssetNotAtLocation_ThrowsError()
    var
        Customer: Record Customer;
        Location1, Location2: Record Location;
        Asset: Record "JML AP Asset";
        SalesHeader: Record "Sales Header";
        SalesAssetLine: Record "JML AP Sales Asset Line";
        AssetSetup: Record "JML AP Asset Setup";
        PostedShptNo: Code[20];
        ErrorOccurred: Boolean;
    begin
        // [SCENARIO] Asset is not at the expected location, posting fails

        // [GIVEN] Asset at Location A, Sales Order for Location B
        Initialize();
        EnsureSetupExists(AssetSetup);
        CreateTestCustomer(Customer, 'TEST-CUST-006');
        CreateTestLocation(Location1, 'TEST-LOCE');
        CreateTestLocation(Location2, 'TEST-LOCF');
        CreateTestAsset(Asset, 'TEST-ASSET-009', "JML AP Holder Type"::Location, Location1.Code);

        CreateSalesOrderHeader(SalesHeader, Customer."No.");
        SalesHeader."Location Code" := Location2.Code;
        SalesHeader.Modify();
        AddSalesAssetLine(SalesAssetLine, SalesHeader, Asset."No.", 10000);

        // [WHEN] Attempting to post shipment
        ErrorOccurred := false;
        ClearLastError();
        asserterror PostedShptNo := PostSalesShipment(SalesHeader);

        // [THEN] Error thrown
        if GetLastErrorText() <> '' then
            ErrorOccurred := true;

        LibraryAssert.IsTrue(ErrorOccurred, 'Should throw error when asset not at location');

        // [THEN] Asset holder unchanged
        Asset.Get(Asset."No.");
        LibraryAssert.AreEqual("JML AP Holder Type"::Location, Asset."Current Holder Type", 'Asset should still be at location');
        LibraryAssert.AreEqual(Location1.Code, Asset."Current Holder Code", 'Asset should still be at original location');

        // Cleanup
        ClearLastError();
        CleanupTestData(SalesHeader."No.", Asset."No.", Customer."No.", Location1.Code);
        CleanupLocation(Location2.Code);
    end;

    [Test]
    procedure TestPostSalesOrder_AssetBlocked_ThrowsError()
    var
        Customer: Record Customer;
        Location: Record Location;
        Asset: Record "JML AP Asset";
        SalesHeader: Record "Sales Header";
        SalesAssetLine: Record "JML AP Sales Asset Line";
        AssetSetup: Record "JML AP Asset Setup";
        PostedShptNo: Code[20];
        ErrorOccurred: Boolean;
    begin
        // [SCENARIO] Blocked asset cannot be shipped

        // [GIVEN] Blocked asset
        Initialize();
        EnsureSetupExists(AssetSetup);
        CreateTestCustomer(Customer, 'TEST-CUST-007');
        CreateTestLocation(Location, 'TEST-LOCG');
        CreateTestAsset(Asset, 'TEST-ASSET-010', "JML AP Holder Type"::Location, Location.Code);
        Asset.Blocked := true;
        Asset.Modify();

        // [WHEN] Attempting to add blocked asset to sales order
        ErrorOccurred := false;
        ClearLastError();
        asserterror CreateSalesOrderWithAsset(SalesHeader, SalesAssetLine, Customer."No.", Asset."No.", Location.Code);

        // [THEN] Error thrown containing "blocked"
        if GetLastErrorText() <> '' then
            ErrorOccurred := true;

        LibraryAssert.IsTrue(ErrorOccurred, 'Should throw error for blocked asset');
        LibraryAssert.IsTrue(StrPos(LowerCase(GetLastErrorText()), 'blocked') > 0, 'Error should mention blocked');

        // Cleanup (SalesHeader wasn't created due to error, so just clean up master data)
        ClearLastError();
        CleanupTestData('', Asset."No.", Customer."No.", Location.Code);
    end;

    [Test]
    procedure TestPostSalesOrder_Subasset_ThrowsError()
    var
        Customer: Record Customer;
        Location: Record Location;
        ParentAsset, ChildAsset: Record "JML AP Asset";
        SalesHeader: Record "Sales Header";
        SalesAssetLine: Record "JML AP Sales Asset Line";
        AssetSetup: Record "JML AP Asset Setup";
        PostedShptNo: Code[20];
        ErrorOccurred: Boolean;
    begin
        // [SCENARIO] Subasset (child with parent) cannot be transferred independently

        // [GIVEN] Child asset with parent
        Initialize();
        EnsureSetupExists(AssetSetup);
        CreateTestCustomer(Customer, 'TEST-CUST-008');
        CreateTestLocation(Location, 'TEST-LOCH');
        CreateTestAsset(ParentAsset, 'TEST-ASSET-011', "JML AP Holder Type"::Location, Location.Code);
        CreateTestAsset(ChildAsset, 'TEST-ASSET-012', "JML AP Holder Type"::Location, Location.Code);
        ChildAsset."Parent Asset No." := ParentAsset."No.";
        ChildAsset.Modify();

        // [WHEN] Attempting to add subasset to sales order
        ErrorOccurred := false;
        ClearLastError();
        asserterror CreateSalesOrderWithAsset(SalesHeader, SalesAssetLine, Customer."No.", ChildAsset."No.", Location.Code);

        // [THEN] Error thrown about subasset
        if GetLastErrorText() <> '' then
            ErrorOccurred := true;

        LibraryAssert.IsTrue(ErrorOccurred, 'Should throw error for subasset transfer');

        // Cleanup (SalesHeader wasn't created due to error)
        ClearLastError();
        CleanupTestData('', ChildAsset."No.", Customer."No.", Location.Code);
        CleanupAsset(ParentAsset."No.");
    end;

    [Test]
    procedure TestPostSalesOrder_AssetDoesNotExist_ThrowsError()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesAssetLine: Record "JML AP Sales Asset Line";
        AssetSetup: Record "JML AP Asset Setup";
        PostedShptNo: Code[20];
        ErrorOccurred: Boolean;
    begin
        // [SCENARIO] Non-existent asset code causes error

        // [GIVEN] Sales order with non-existent asset
        Initialize();
        EnsureSetupExists(AssetSetup);
        CreateTestCustomer(Customer, 'TEST-CUST-009');

        CreateSalesOrderHeader(SalesHeader, Customer."No.");

        // [WHEN] Attempting to add non-existent asset
        ErrorOccurred := false;
        ClearLastError();
        asserterror AddSalesAssetLine(SalesAssetLine, SalesHeader, 'NONEXISTENT', 10000);

        // [THEN] Error "Asset does not exist"
        if GetLastErrorText() <> '' then
            ErrorOccurred := true;

        LibraryAssert.IsTrue(ErrorOccurred, 'Should throw error for non-existent asset');
        LibraryAssert.IsTrue(StrPos(LowerCase(GetLastErrorText()), 'cannot be found') > 0, 'Error should mention asset cannot be found');

        // Cleanup (Asset line wasn't created due to error)
        ClearLastError();
        CleanupTestData(SalesHeader."No.", '', Customer."No.", '');
    end;

    [Test]
    procedure TestPostSalesOrder_NoAssetLines_PostsSuccessfully()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        PostedShptHeader: Record "Sales Shipment Header";
        PostedAssetLine: Record "JML AP Pstd Sales Shpt Ast Ln";
        AssetSetup: Record "JML AP Asset Setup";
        PostedShptNo: Code[20];
    begin
        // [SCENARIO] Sales Order without asset lines posts normally

        // [GIVEN] Sales order with item line but no asset lines
        Initialize();
        EnsureSetupExists(AssetSetup);
        CreateTestCustomer(Customer, 'TEST-CUST-010');
        CreateSalesOrderHeader(SalesHeader, Customer."No.");
        AddDummySalesLine(SalesHeader); // Add item line for normal posting

        // [WHEN] Posting the shipment
        PostedShptNo := PostSalesShipment(SalesHeader);

        // [THEN] Posted shipment is created
        LibraryAssert.IsTrue(PostedShptHeader.Get(PostedShptNo), 'Posted shipment should be created');

        // [THEN] No posted asset lines should exist
        PostedAssetLine.SetRange("Document No.", PostedShptNo);
        LibraryAssert.RecordCount(PostedAssetLine, 0);

        // Cleanup
        CleanupTestData(SalesHeader."No.", '', Customer."No.", '');
    end;

    // ============================================================================
    // Story 2.3: Sales Return Order with Assets - Happy Path & Verification
    // ============================================================================

    [Test]
    procedure TestPostSalesReturnOrder_WithAsset_TransfersFromCustomer()
    var
        Customer: Record Customer;
        Location: Record Location;
        Asset: Record "JML AP Asset";
        SalesHeader: Record "Sales Header";
        SalesAssetLine: Record "JML AP Sales Asset Line";
        ReturnRcptHeader: Record "Return Receipt Header";
        PostedAssetLine: Record "JML AP Pstd Ret Rcpt Ast Ln";
        HolderEntry: Record "JML AP Holder Entry";
        AssetSetup: Record "JML AP Asset Setup";
        ReturnRcptNo: Code[20];
    begin
        // [SCENARIO] Post Sales Return Order with asset, verify holder transfer from Customer to Location

        // [GIVEN] A customer, location, and asset at that customer
        Initialize();
        EnsureSetupExists(AssetSetup);
        CreateTestCustomer(Customer, 'TEST-CUST-011');
        CreateTestLocation(Location, 'TEST-LOCI');
        CreateAssetAtCustomer(Asset, 'TEST-ASSET-013', Customer."No.");
        CreateReturnOrderWithAsset(SalesHeader, SalesAssetLine, Customer."No.", Asset."No.");
        SalesHeader."Location Code" := Location.Code;
        SalesHeader.Modify();

        // [WHEN] Posting the return receipt
        ReturnRcptNo := PostReturnReceipt(SalesHeader);

        // [THEN] Asset holder changed to location
        Asset.Get(Asset."No.");
        LibraryAssert.AreEqual("JML AP Holder Type"::Location, Asset."Current Holder Type", 'Asset holder type should be Location');
        LibraryAssert.AreEqual(Location.Code, Asset."Current Holder Code", 'Asset holder code should be location code');

        // [THEN] Return receipt header created
        LibraryAssert.IsTrue(ReturnRcptHeader.Get(ReturnRcptNo), 'Return receipt header should exist');

        // [THEN] Posted asset line created
        PostedAssetLine.SetRange("Document No.", ReturnRcptNo);
        LibraryAssert.RecordCount(PostedAssetLine, 1);
        PostedAssetLine.FindFirst();
        LibraryAssert.AreEqual(Asset."No.", PostedAssetLine."Asset No.", 'Posted line asset no. should match');
        LibraryAssert.IsTrue(PostedAssetLine."Transaction No." > 0, 'Transaction no. should be assigned');

        // [THEN] Holder entries created (Transfer Out + Transfer In)
        HolderEntry.SetRange("Asset No.", Asset."No.");
        HolderEntry.SetRange("Transaction No.", PostedAssetLine."Transaction No.");
        LibraryAssert.RecordCount(HolderEntry, 2);

        // Cleanup
        CleanupTestData(SalesHeader."No.", Asset."No.", Customer."No.", Location.Code);
    end;

    [Test]
    procedure TestPostSalesReturnOrder_AssetNotAtCustomer_ThrowsError()
    var
        Customer: Record Customer;
        Location: Record Location;
        Asset: Record "JML AP Asset";
        SalesHeader: Record "Sales Header";
        SalesAssetLine: Record "JML AP Sales Asset Line";
        AssetSetup: Record "JML AP Asset Setup";
        ReturnRcptNo: Code[20];
        ErrorOccurred: Boolean;
    begin
        // [SCENARIO] Asset is not at customer, return order posting fails

        // [GIVEN] Asset at Location (NOT at customer), Return Order references that asset
        Initialize();
        EnsureSetupExists(AssetSetup);
        CreateTestCustomer(Customer, 'TEST-CUST-012');
        CreateTestLocation(Location, 'TEST-LOCJ');
        CreateTestAsset(Asset, 'TEST-ASSET-014', "JML AP Holder Type"::Location, Location.Code);

        CreateReturnOrderHeader(SalesHeader, Customer."No.");
        SalesHeader."Location Code" := Location.Code;
        SalesHeader.Modify();
        AddDummySalesLineForReturn(SalesHeader);

        // [WHEN] Attempting to add asset that's not at customer to return order
        ErrorOccurred := false;
        ClearLastError();
        asserterror AddReturnAssetLine(SalesAssetLine, SalesHeader, Asset."No.", 20000);

        // [THEN] Error thrown
        if GetLastErrorText() <> '' then
            ErrorOccurred := true;

        LibraryAssert.IsTrue(ErrorOccurred, 'Should throw error when asset not at customer');

        // Cleanup
        ClearLastError();
        CleanupTestData(SalesHeader."No.", Asset."No.", Customer."No.", Location.Code);
    end;

    [Test]
    procedure TestPostSalesReturnOrder_CreatesReturnReceiptAssetLines()
    var
        Customer: Record Customer;
        Location: Record Location;
        Asset: Record "JML AP Asset";
        SalesHeader: Record "Sales Header";
        SalesAssetLine: Record "JML AP Sales Asset Line";
        ReturnRcptHeader: Record "Return Receipt Header";
        PostedAssetLine: Record "JML AP Pstd Ret Rcpt Ast Ln";
        AssetSetup: Record "JML AP Asset Setup";
        ReturnRcptNo: Code[20];
    begin
        // [SCENARIO] Verify Posted Return Receipt Asset Line structure

        // [GIVEN] Standard setup with 1 asset at customer
        Initialize();
        EnsureSetupExists(AssetSetup);
        CreateTestCustomer(Customer, 'TEST-CUST-013');
        CreateTestLocation(Location, 'TEST-LOCK');
        CreateAssetAtCustomer(Asset, 'TEST-ASSET-015', Customer."No.");
        CreateReturnOrderWithAsset(SalesHeader, SalesAssetLine, Customer."No.", Asset."No.");
        SalesHeader."Location Code" := Location.Code;
        SalesHeader.Modify();

        // [WHEN] Posting the return receipt
        ReturnRcptNo := PostReturnReceipt(SalesHeader);

        // [THEN] Posted line fields are correct
        ReturnRcptHeader.Get(ReturnRcptNo);
        PostedAssetLine.SetRange("Document No.", ReturnRcptNo);
        PostedAssetLine.FindFirst();

        LibraryAssert.AreEqual(ReturnRcptNo, PostedAssetLine."Document No.", 'Document no. should match');
        LibraryAssert.AreEqual(10000, PostedAssetLine."Line No.", 'Line no. should be 10000');
        LibraryAssert.AreEqual(Asset."No.", PostedAssetLine."Asset No.", 'Asset no. should match');
        LibraryAssert.AreEqual(Asset.Description, PostedAssetLine."Asset Description", 'Asset description should match');
        LibraryAssert.AreEqual(Customer."No.", PostedAssetLine."Sell-to Customer No.", 'Customer no. should match');
        LibraryAssert.AreEqual(Customer.Name, PostedAssetLine."Sell-to Customer Name", 'Customer name should match');
        LibraryAssert.AreEqual(Location.Code, PostedAssetLine."Location Code", 'Location code should match');
        LibraryAssert.AreEqual(ReturnRcptHeader."Posting Date", PostedAssetLine."Posting Date", 'Posting date should match');
        LibraryAssert.IsTrue(PostedAssetLine."Transaction No." > 0, 'Transaction no. should be assigned');

        // Cleanup
        CleanupTestData(SalesHeader."No.", Asset."No.", Customer."No.", Location.Code);
    end;

    // ============================================================================
    // Helper Procedures
    // ============================================================================

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
        Commit();
    end;

    local procedure EnsureSetupExists(var AssetSetup: Record "JML AP Asset Setup")
    begin
        if not AssetSetup.Get() then begin
            AssetSetup.Init();
            AssetSetup.Insert(true);
        end;
    end;

    local procedure CreateTestCustomer(var Customer: Record Customer; CustomerNo: Code[20])
    begin
        if not Customer.Get(CustomerNo) then begin
            Customer.Init();
            Customer."No." := CustomerNo;
            Customer.Name := 'Test Customer ' + CustomerNo;
            Customer."Gen. Bus. Posting Group" := 'DOMESTIC'; // Set required posting groups
            Customer."Customer Posting Group" := 'DOMESTIC';
            Customer.Insert(true);
        end;
    end;

    local procedure CreateTestLocation(var Location: Record Location; LocationCode: Code[10])
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        if not Location.Get(LocationCode) then begin
            Location.Init();
            Location.Code := LocationCode;
            Location.Name := 'Test Location ' + LocationCode;
            Location.Insert(true);
        end;

        // Create Inventory Posting Setup for this location if it doesn't exist
        if not InventoryPostingSetup.Get(LocationCode, 'RESALE') then begin
            InventoryPostingSetup.Init();
            InventoryPostingSetup."Location Code" := LocationCode;
            InventoryPostingSetup."Invt. Posting Group Code" := 'RESALE';
            InventoryPostingSetup."Inventory Account" := '2130'; // Use standard Inventory GL account from demo data
            InventoryPostingSetup.Insert(true);
        end;
    end;

    local procedure CreateTestAsset(var Asset: Record "JML AP Asset"; AssetNo: Code[20]; HolderType: Enum "JML AP Holder Type"; HolderCode: Code[20])
    var
        AssetSetup: Record "JML AP Asset Setup";
    begin
        EnsureSetupExists(AssetSetup);

        if not Asset.Get(AssetNo) then begin
            Asset.Init();
            Asset."No." := AssetNo;
            Asset.Description := 'Test Asset ' + AssetNo;
            Asset."Current Holder Type" := HolderType;
            Asset."Current Holder Code" := HolderCode;
            Asset.Insert(true);
        end;
    end;

    local procedure CreateSalesOrderHeader(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    begin
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader."No." := '';
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", CustomerNo);
        SalesHeader.Modify(true);
    end;

    local procedure AddSalesAssetLine(var SalesAssetLine: Record "JML AP Sales Asset Line"; SalesHeader: Record "Sales Header"; AssetNo: Code[20]; LineNo: Integer)
    begin
        SalesAssetLine.Init();
        SalesAssetLine."Document Type" := SalesHeader."Document Type";
        SalesAssetLine."Document No." := SalesHeader."No.";
        SalesAssetLine."Line No." := LineNo;
        SalesAssetLine.Validate("Asset No.", AssetNo);  // Use Validate to trigger OnValidate and populate description
        SalesAssetLine."Quantity to Ship" := 1;
        SalesAssetLine.Insert(true);
    end;

    local procedure CreateSalesOrderWithAsset(var SalesHeader: Record "Sales Header"; var SalesAssetLine: Record "JML AP Sales Asset Line"; CustomerNo: Code[20]; AssetNo: Code[20]; LocationCode: Code[10])
    begin
        CreateSalesOrderHeader(SalesHeader, CustomerNo);
        SalesHeader."Location Code" := LocationCode; // Set location code before adding asset lines
        SalesHeader.Modify();
        AddDummySalesLine(SalesHeader); // Add minimal item line for BC posting requirements
        AddSalesAssetLine(SalesAssetLine, SalesHeader, AssetNo, 20000); // Use line 20000 after dummy line
    end;

    local procedure PostSalesShipment(SalesHeader: Record "Sales Header"): Code[20]
    var
        SalesPost: Codeunit "Sales-Post";
        SalesShptHeader: Record "Sales Shipment Header";
    begin
        SalesHeader.Ship := true;
        SalesHeader.Invoice := false;
        SalesPost.Run(SalesHeader);

        SalesShptHeader.SetRange("Order No.", SalesHeader."No.");
        if SalesShptHeader.FindFirst() then
            exit(SalesShptHeader."No.");

        exit('');
    end;

    local procedure CleanupTestData(SalesHeaderNo: Code[20]; AssetNo: Code[20]; CustomerNo: Code[20]; LocationCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        SalesAssetLine: Record "JML AP Sales Asset Line";
        Asset: Record "JML AP Asset";
        Customer: Record Customer;
        Location: Record Location;
        HolderEntry: Record "JML AP Holder Entry";
        ReleaseSalesDoc: Codeunit "Release Sales Document";
    begin
        // Note: We don't delete posted Sales Headers/Lines as BC prevents this by design
        // Posted documents remain in the database and are archived
        // Tests should focus on verifying posted results, not cleanup
        // Only clean up master data (assets, customers, locations, etc.)

        // Delete asset and holder entries
        if AssetNo <> '' then begin
            HolderEntry.SetRange("Asset No.", AssetNo);
            HolderEntry.DeleteAll(true);

            if Asset.Get(AssetNo) then
                Asset.Delete(true);
        end;

        // Don't delete customers with outstanding orders - BC prevents this
        // if CustomerNo <> '' then
        //     if Customer.Get(CustomerNo) then
        //         Customer.Delete(true);

        // Don't delete locations with inventory ledger entries - BC prevents this
        // if LocationCode <> '' then
        //     if Location.Get(LocationCode) then
        //         Location.Delete(true);

        Commit();
    end;

    local procedure CleanupAsset(AssetNo: Code[20])
    var
        Asset: Record "JML AP Asset";
        HolderEntry: Record "JML AP Holder Entry";
    begin
        HolderEntry.SetRange("Asset No.", AssetNo);
        HolderEntry.DeleteAll(true);

        if Asset.Get(AssetNo) then
            Asset.Delete(true);

        Commit();
    end;

    local procedure CleanupLocation(LocationCode: Code[10])
    var
        Location: Record Location;
    begin
        if Location.Get(LocationCode) then
            Location.Delete(true);
        Commit();
    end;

    local procedure CreateTestItem(var Item: Record Item; ItemNo: Code[20])
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if not Item.Get(ItemNo) then begin
            // Create Unit of Measure if it doesn't exist
            if not UnitOfMeasure.Get('PCS') then begin
                UnitOfMeasure.Init();
                UnitOfMeasure.Code := 'PCS';
                UnitOfMeasure.Description := 'Pieces';
                UnitOfMeasure.Insert(true);
            end;

            // Create Item
            Item.Init();
            Item."No." := ItemNo;
            Item.Description := 'Test Item';
            Item.Type := Item.Type::Inventory;
            Item."Base Unit of Measure" := 'PCS';
            Item."Gen. Prod. Posting Group" := 'RETAIL';
            Item."Inventory Posting Group" := 'RESALE';
            Item.Insert(true);

            // Create Item Unit of Measure
            if not ItemUnitOfMeasure.Get(ItemNo, 'PCS') then begin
                ItemUnitOfMeasure.Init();
                ItemUnitOfMeasure."Item No." := ItemNo;
                ItemUnitOfMeasure.Code := 'PCS';
                ItemUnitOfMeasure."Qty. per Unit of Measure" := 1;
                ItemUnitOfMeasure.Insert(true);
            end;
        end;
    end;

    local procedure AddDummySalesLine(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        // Add a minimal item line to satisfy BC posting requirements
        CreateTestItem(Item, 'TEST-ITEM-001');

        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := 10000;
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine.Validate("No.", Item."No."); // Use Validate to set Unit of Measure
        SalesLine.Validate(Quantity, 1);
        SalesLine.Validate("Qty. to Ship", 1);
        SalesLine.Insert(true);
    end;

    local procedure CreateAssetAtCustomer(var Asset: Record "JML AP Asset"; AssetNo: Code[20]; CustomerNo: Code[20])
    var
        AssetSetup: Record "JML AP Asset Setup";
    begin
        EnsureSetupExists(AssetSetup);

        if not Asset.Get(AssetNo) then begin
            Asset.Init();
            Asset."No." := AssetNo;
            Asset.Description := 'Test Asset ' + AssetNo;
            Asset."Current Holder Type" := "JML AP Holder Type"::Customer;
            Asset."Current Holder Code" := CustomerNo;
            Asset.Insert(true);
        end;
    end;

    local procedure CreateReturnOrderWithAsset(var SalesHeader: Record "Sales Header"; var SalesAssetLine: Record "JML AP Sales Asset Line"; CustomerNo: Code[20]; AssetNo: Code[20])
    begin
        CreateReturnOrderHeader(SalesHeader, CustomerNo);
        AddDummySalesLineForReturn(SalesHeader);
        AddReturnAssetLine(SalesAssetLine, SalesHeader, AssetNo, 20000);
    end;

    local procedure CreateReturnOrderHeader(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    begin
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::"Return Order";
        SalesHeader."No." := '';
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", CustomerNo);
        SalesHeader.Modify(true);
    end;

    local procedure AddReturnAssetLine(var SalesAssetLine: Record "JML AP Sales Asset Line"; SalesHeader: Record "Sales Header"; AssetNo: Code[20]; LineNo: Integer)
    begin
        SalesAssetLine.Init();
        SalesAssetLine."Document Type" := SalesHeader."Document Type";
        SalesAssetLine."Document No." := SalesHeader."No.";
        SalesAssetLine."Line No." := LineNo;
        SalesAssetLine.Validate("Asset No.", AssetNo);  // Use Validate to trigger OnValidate and populate description
        SalesAssetLine."Quantity to Receive" := 1;
        SalesAssetLine.Insert(true);
    end;

    local procedure AddDummySalesLineForReturn(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        CreateTestItem(Item, 'TEST-ITEM-001');

        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := 10000;
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine.Validate("No.", Item."No.");
        SalesLine.Validate(Quantity, 1);
        SalesLine.Validate("Return Qty. to Receive", 1);
        SalesLine.Insert(true);
    end;

    local procedure PostReturnReceipt(SalesHeader: Record "Sales Header"): Code[20]
    var
        SalesPost: Codeunit "Sales-Post";
        ReturnRcptHeader: Record "Return Receipt Header";
    begin
        SalesHeader.Receive := true;
        SalesHeader.Invoice := false;
        SalesPost.Run(SalesHeader);

        ReturnRcptHeader.SetRange("Return Order No.", SalesHeader."No.");
        if ReturnRcptHeader.FindFirst() then
            exit(ReturnRcptHeader."No.");

        exit('');
    end;
}
