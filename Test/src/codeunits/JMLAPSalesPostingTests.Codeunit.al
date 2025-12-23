codeunit 50123 "JML AP Sales Posting Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    // Note: BC Test Framework provides automatic test isolation
    // Each test runs in isolated transaction that rolls back automatically

    var
        LibraryAssert: Codeunit "Library Assert";
        TestLibrary: Codeunit "JML AP Test Library";
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
        TestLibrary.Initialize();
        Customer := TestLibrary.CreateTestCustomer('TEST-CUST-001');
        Location := TestLibrary.CreateTestLocation('TEST-LOC');
        Asset := TestLibrary.CreateAssetAtLocation('TEST-ASSET-001', Location.Code);

        SalesHeader := TestLibrary.CreateSalesOrderHeader(Customer."No.");
        SalesHeader."Location Code" := Location.Code;
        SalesHeader.Modify();
        TestLibrary.AddDummyItemLine(SalesHeader);
        SalesAssetLine := TestLibrary.AddSalesAssetLine(SalesHeader, Asset."No.", 20000);

        // [WHEN] Posting the sales shipment
        PostedShptNo := TestLibrary.PostSalesShipment(SalesHeader);

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

        // No cleanup needed - automatic test isolation handles rollback
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
        TestLibrary.Initialize();
        Customer := TestLibrary.CreateTestCustomer('TEST-CUST-002');
        Location := TestLibrary.CreateTestLocation('TEST-LOCA');
        Asset1 := TestLibrary.CreateAssetAtLocation('TEST-ASSET-002', Location.Code);
        Asset2 := TestLibrary.CreateAssetAtLocation('TEST-ASSET-003', Location.Code);
        Asset3 := TestLibrary.CreateAssetAtLocation('TEST-ASSET-004', Location.Code);

        // [GIVEN] A sales order with 3 asset lines
        SalesHeader := TestLibrary.CreateSalesOrderHeader(Customer."No.");
        SalesHeader."Location Code" := Location.Code; // Set location code before adding asset lines
        SalesHeader.Modify();
        TestLibrary.AddDummyItemLine(SalesHeader); // Add minimal item line for BC posting requirements
        TestLibrary.AddSalesAssetLine(SalesHeader, Asset1."No.", 20000);
        TestLibrary.AddSalesAssetLine(SalesHeader, Asset2."No.", 30000);
        TestLibrary.AddSalesAssetLine(SalesHeader, Asset3."No.", 40000);

        // [WHEN] Posting the sales shipment
        PostedShptNo := TestLibrary.PostSalesShipment(SalesHeader);

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

        // No cleanup needed - automatic test isolation handles rollback
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
        TestLibrary.Initialize();
        Customer := TestLibrary.CreateTestCustomer('TEST-CUST-003');
        Location := TestLibrary.CreateTestLocation('TEST-LOCB');
        Asset := TestLibrary.CreateAssetAtLocation('TEST-ASSET-005', Location.Code);
        SalesHeader := TestLibrary.CreateSalesOrderHeader(Customer."No.");
        SalesHeader."Location Code" := Location.Code;
        SalesHeader.Modify();
        TestLibrary.AddDummyItemLine(SalesHeader);
        SalesAssetLine := TestLibrary.AddSalesAssetLine(SalesHeader, Asset."No.", 20000);

        // [WHEN] Posting the shipment
        PostedShptNo := TestLibrary.PostSalesShipment(SalesHeader);

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

        // No cleanup needed - automatic test isolation handles rollback
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
        TestLibrary.Initialize();
        Customer := TestLibrary.CreateTestCustomer('TEST-CUST-004');
        Location := TestLibrary.CreateTestLocation('TEST-LOCC');
        Asset := TestLibrary.CreateAssetAtLocation('TEST-ASSET-006', Location.Code);
        SalesHeader := TestLibrary.CreateSalesOrderHeader(Customer."No.");
        SalesHeader."Location Code" := Location.Code;
        SalesHeader.Modify();
        TestLibrary.AddDummyItemLine(SalesHeader);
        SalesAssetLine := TestLibrary.AddSalesAssetLine(SalesHeader, Asset."No.", 20000);

        // [WHEN] Posting the shipment
        PostedShptNo := TestLibrary.PostSalesShipment(SalesHeader);

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

        // No cleanup needed - automatic test isolation handles rollback
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
        TestLibrary.Initialize();
        Customer := TestLibrary.CreateTestCustomer('TEST-CUST-005');
        Location := TestLibrary.CreateTestLocation('TEST-LOCD');
        Asset1 := TestLibrary.CreateAssetAtLocation('TEST-ASSET-007', Location.Code);
        Asset2 := TestLibrary.CreateAssetAtLocation('TEST-ASSET-008', Location.Code);

        SalesHeader := TestLibrary.CreateSalesOrderHeader(Customer."No.");
        SalesHeader."Location Code" := Location.Code; // Set location code before adding asset lines
        SalesHeader.Modify();
        TestLibrary.AddDummyItemLine(SalesHeader); // Add minimal item line for BC posting requirements
        SalesAssetLine1 := TestLibrary.AddSalesAssetLine(SalesHeader, Asset1."No.", 20000);
        SalesAssetLine2 := TestLibrary.AddSalesAssetLine(SalesHeader, Asset2."No.", 30000);

        // Set only Line 1 to ship
        SalesAssetLine1."Quantity to Ship" := 1;
        SalesAssetLine1.Modify();
        SalesAssetLine2."Quantity to Ship" := 0;
        SalesAssetLine2.Modify();

        // [WHEN] Posting the shipment
        PostedShptNo := TestLibrary.PostSalesShipment(SalesHeader);

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

        // No cleanup needed - automatic test isolation handles rollback
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
        TestLibrary.Initialize();
        Customer := TestLibrary.CreateTestCustomer('TEST-CUST-006');
        Location1 := TestLibrary.CreateTestLocation('TEST-LOCE');
        Location2 := TestLibrary.CreateTestLocation('TEST-LOCF');
        Asset := TestLibrary.CreateAssetAtLocation('TEST-ASSET-009', Location1.Code);

        SalesHeader := TestLibrary.CreateSalesOrderHeader(Customer."No.");
        SalesHeader."Location Code" := Location2.Code;
        SalesHeader.Modify();
        SalesAssetLine := TestLibrary.AddSalesAssetLine(SalesHeader, Asset."No.", 10000);

        // [WHEN] Attempting to post shipment
        ErrorOccurred := false;
        ClearLastError();
        asserterror PostedShptNo := TestLibrary.PostSalesShipment(SalesHeader);

        // [THEN] Error thrown
        if GetLastErrorText() <> '' then
            ErrorOccurred := true;

        LibraryAssert.IsTrue(ErrorOccurred, 'Should throw error when asset not at location');

        // [THEN] Asset holder unchanged
        Asset.Get(Asset."No.");
        LibraryAssert.AreEqual("JML AP Holder Type"::Location, Asset."Current Holder Type", 'Asset should still be at location');
        LibraryAssert.AreEqual(Location1.Code, Asset."Current Holder Code", 'Asset should still be at original location');

        // No cleanup needed - automatic test isolation handles rollback
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
        TestLibrary.Initialize();
        Customer := TestLibrary.CreateTestCustomer('TEST-CUST-007');
        Location := TestLibrary.CreateTestLocation('TEST-LOCG');
        Asset := TestLibrary.CreateAssetAtLocation('TEST-ASSET-010', Location.Code);
        Asset.Blocked := true;
        Asset.Modify();

        // [WHEN] Attempting to add blocked asset to sales order
        ErrorOccurred := false;
        ClearLastError();
        asserterror begin
            SalesHeader := TestLibrary.CreateSalesOrderHeader(Customer."No.");
            SalesHeader."Location Code" := Location.Code;
            SalesHeader.Modify();
            TestLibrary.AddDummyItemLine(SalesHeader);
            SalesAssetLine := TestLibrary.AddSalesAssetLine(SalesHeader, Asset."No.", 20000);
        end;

        // [THEN] Error thrown containing "blocked"
        if GetLastErrorText() <> '' then
            ErrorOccurred := true;

        LibraryAssert.IsTrue(ErrorOccurred, 'Should throw error for blocked asset');
        LibraryAssert.IsTrue(StrPos(LowerCase(GetLastErrorText()), 'blocked') > 0, 'Error should mention blocked');

        // No cleanup needed - automatic test isolation handles rollback
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
        TestLibrary.Initialize();
        Customer := TestLibrary.CreateTestCustomer('TEST-CUST-008');
        Location := TestLibrary.CreateTestLocation('TEST-LOCH');
        ParentAsset := TestLibrary.CreateAssetAtLocation('TEST-ASSET-011', Location.Code);
        ChildAsset := TestLibrary.CreateAssetWithParent('TEST-ASSET-012', ParentAsset."No.");

        // [WHEN] Attempting to add subasset to sales order
        ErrorOccurred := false;
        ClearLastError();
        asserterror begin
            SalesHeader := TestLibrary.CreateSalesOrderHeader(Customer."No.");
            SalesHeader."Location Code" := Location.Code;
            SalesHeader.Modify();
            TestLibrary.AddDummyItemLine(SalesHeader);
            SalesAssetLine := TestLibrary.AddSalesAssetLine(SalesHeader, ChildAsset."No.", 20000);
        end;

        // [THEN] Error thrown about subasset
        if GetLastErrorText() <> '' then
            ErrorOccurred := true;

        LibraryAssert.IsTrue(ErrorOccurred, 'Should throw error for subasset transfer');

        // No cleanup needed - automatic test isolation handles rollback
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
        TestLibrary.Initialize();
        Customer := TestLibrary.CreateTestCustomer('TEST-CUST-009');

        SalesHeader := TestLibrary.CreateSalesOrderHeader(Customer."No.");

        // [WHEN] Attempting to add non-existent asset
        ErrorOccurred := false;
        ClearLastError();
        asserterror SalesAssetLine := TestLibrary.AddSalesAssetLine(SalesHeader, 'NONEXISTENT', 10000);

        // [THEN] Error "Asset does not exist"
        if GetLastErrorText() <> '' then
            ErrorOccurred := true;

        LibraryAssert.IsTrue(ErrorOccurred, 'Should throw error for non-existent asset');
        LibraryAssert.IsTrue(StrPos(LowerCase(GetLastErrorText()), 'cannot be found') > 0, 'Error should mention asset cannot be found');

        // No cleanup needed - automatic test isolation handles rollback
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
        TestLibrary.Initialize();
        Customer := TestLibrary.CreateTestCustomer('TEST-CUST-010');
        SalesHeader := TestLibrary.CreateSalesOrderHeader(Customer."No.");
        TestLibrary.AddDummyItemLine(SalesHeader); // Add item line for normal posting

        // [WHEN] Posting the shipment
        PostedShptNo := TestLibrary.PostSalesShipment(SalesHeader);

        // [THEN] Posted shipment is created
        LibraryAssert.IsTrue(PostedShptHeader.Get(PostedShptNo), 'Posted shipment should be created');

        // [THEN] No posted asset lines should exist
        PostedAssetLine.SetRange("Document No.", PostedShptNo);
        LibraryAssert.RecordCount(PostedAssetLine, 0);

        // No cleanup needed - automatic test isolation handles rollback
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
        TestLibrary.Initialize();
        Customer := TestLibrary.CreateTestCustomer('TEST-CUST-011');
        Location := TestLibrary.CreateTestLocation('TEST-LOCI');
        Asset := TestLibrary.CreateAssetAtCustomer('TEST-ASSET-013', Customer."No.");
        SalesHeader := TestLibrary.CreateSalesReturnOrderHeader(Customer."No.");
        TestLibrary.AddDummyItemLine(SalesHeader);
        SalesAssetLine := TestLibrary.AddSalesAssetLine(SalesHeader, Asset."No.", 20000);
        SalesHeader."Location Code" := Location.Code;
        SalesHeader.Modify();

        // [WHEN] Posting the return receipt
        ReturnRcptNo := TestLibrary.PostSalesReturnReceipt(SalesHeader);

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

        // No cleanup needed - automatic test isolation handles rollback
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
        TestLibrary.Initialize();
        Customer := TestLibrary.CreateTestCustomer('TEST-CUST-012');
        Location := TestLibrary.CreateTestLocation('TEST-LOCJ');
        Asset := TestLibrary.CreateAssetAtLocation('TEST-ASSET-014', Location.Code);

        SalesHeader := TestLibrary.CreateSalesReturnOrderHeader(Customer."No.");
        SalesHeader."Location Code" := Location.Code;
        SalesHeader.Modify();
        TestLibrary.AddDummyItemLine(SalesHeader);

        // [WHEN] Attempting to add asset that's not at customer to return order
        ErrorOccurred := false;
        ClearLastError();
        asserterror SalesAssetLine := TestLibrary.AddSalesAssetLine(SalesHeader, Asset."No.", 20000);

        // [THEN] Error thrown
        if GetLastErrorText() <> '' then
            ErrorOccurred := true;

        LibraryAssert.IsTrue(ErrorOccurred, 'Should throw error when asset not at customer');

        // No cleanup needed - automatic test isolation handles rollback
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
        TestLibrary.Initialize();
        Customer := TestLibrary.CreateTestCustomer('TEST-CUST-013');
        Location := TestLibrary.CreateTestLocation('TEST-LOCK');
        Asset := TestLibrary.CreateAssetAtCustomer('TEST-ASSET-015', Customer."No.");
        SalesHeader := TestLibrary.CreateSalesReturnOrderHeader(Customer."No.");
        TestLibrary.AddDummyItemLine(SalesHeader);
        SalesAssetLine := TestLibrary.AddSalesAssetLine(SalesHeader, Asset."No.", 20000);
        SalesHeader."Location Code" := Location.Code;
        SalesHeader.Modify();

        // [WHEN] Posting the return receipt
        ReturnRcptNo := TestLibrary.PostSalesReturnReceipt(SalesHeader);

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

        // No cleanup needed - automatic test isolation handles rollback
    end;

}
