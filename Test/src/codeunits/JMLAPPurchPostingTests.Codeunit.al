codeunit 50116 "JML AP Purch Posting Tests"
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
    // Story 3.1: Purchase Order Posting with Assets - Happy Path Tests
    // ============================================================================

    [Test]
    procedure TestPostPurchaseOrder_SingleAsset_TransfersToLocation()
    var
        Vendor: Record Vendor;
        Location: Record Location;
        Asset: Record "JML AP Asset";
        PurchHeader: Record "Purchase Header";
        PurchAssetLine: Record "JML AP Purch. Asset Line";
        PostedRcptHeader: Record "Purch. Rcpt. Header";
        PostedAssetLine: Record "JML AP Pstd Purch Rcpt Ast Ln";
        HolderEntry: Record "JML AP Holder Entry";
        AssetSetup: Record "JML AP Asset Setup";
        PostedRcptNo: Code[20];
    begin
        // [SCENARIO] Post Purchase Order with single asset, verify holder transfer from Vendor to Location

        // [GIVEN] A vendor, location, and asset at that vendor
        Initialize();
        EnsureSetupExists(AssetSetup);
        CreateTestVendor(Vendor, 'TEST-VEND-001');
        CreateTestLocation(Location, 'TEST-LOCP');
        CreateTestAsset(Asset, 'TEST-ASSET-P001', "JML AP Holder Type"::Vendor, Vendor."No.");
        CreatePurchaseOrderWithAsset(PurchHeader, PurchAssetLine, Vendor."No.", Asset."No.", Location.Code);

        // [WHEN] Posting the purchase receipt
        PostedRcptNo := PostPurchaseReceipt(PurchHeader);

        // [THEN] Asset holder changed to location
        Asset.Get(Asset."No.");
        LibraryAssert.AreEqual("JML AP Holder Type"::Location, Asset."Current Holder Type", 'Asset holder type should be Location');
        LibraryAssert.AreEqual(Location.Code, Asset."Current Holder Code", 'Asset holder code should be location code');

        // [THEN] Posted receipt header created
        LibraryAssert.IsTrue(PostedRcptHeader.Get(PostedRcptNo), 'Posted receipt header should exist');

        // [THEN] Posted asset line created
        PostedAssetLine.SetRange("Document No.", PostedRcptNo);
        LibraryAssert.RecordCount(PostedAssetLine, 1);
        PostedAssetLine.FindFirst();
        LibraryAssert.AreEqual(Asset."No.", PostedAssetLine."Asset No.", 'Posted line asset no. should match');
        LibraryAssert.IsTrue(PostedAssetLine."Transaction No." > 0, 'Transaction no. should be assigned');

        // [THEN] Holder entries created (Transfer Out from Vendor + Transfer In to Location)
        HolderEntry.SetRange("Asset No.", Asset."No.");
        HolderEntry.SetRange("Transaction No.", PostedAssetLine."Transaction No.");
        LibraryAssert.RecordCount(HolderEntry, 2);

        // Cleanup
        CleanupTestData(PurchHeader."No.", Asset."No.", Vendor."No.", Location.Code);
    end;

    [Test]
    procedure TestPostPurchaseOrder_MultipleAssets_AllTransferred()
    var
        Vendor: Record Vendor;
        Location: Record Location;
        Asset1, Asset2, Asset3: Record "JML AP Asset";
        PurchHeader: Record "Purchase Header";
        PurchAssetLine: Record "JML AP Purch. Asset Line";
        PostedAssetLine: Record "JML AP Pstd Purch Rcpt Ast Ln";
        HolderEntry: Record "JML AP Holder Entry";
        AssetSetup: Record "JML AP Asset Setup";
        PostedRcptNo: Code[20];
    begin
        // [SCENARIO] Post Purchase Order with 3 assets, verify all transferred from Vendor to Location

        // [GIVEN] A vendor, location, and 3 assets at that vendor
        Initialize();
        EnsureSetupExists(AssetSetup);
        CreateTestVendor(Vendor, 'TEST-VEND-002');
        CreateTestLocation(Location, 'TEST-LOCD');
        CreateTestAsset(Asset1, 'TEST-ASSET-P002', "JML AP Holder Type"::Vendor, Vendor."No.");
        CreateTestAsset(Asset2, 'TEST-ASSET-P003', "JML AP Holder Type"::Vendor, Vendor."No.");
        CreateTestAsset(Asset3, 'TEST-ASSET-P004', "JML AP Holder Type"::Vendor, Vendor."No.");

        // [GIVEN] A purchase order with 3 asset lines
        CreatePurchaseOrderHeader(PurchHeader, Vendor."No.");
        PurchHeader."Location Code" := Location.Code; // Set location code before adding asset lines
        PurchHeader.Modify();
        AddDummyPurchaseLine(PurchHeader); // Add minimal item line for BC posting requirements
        AddPurchaseAssetLine(PurchAssetLine, PurchHeader, Asset1."No.", 20000);
        AddPurchaseAssetLine(PurchAssetLine, PurchHeader, Asset2."No.", 30000);
        AddPurchaseAssetLine(PurchAssetLine, PurchHeader, Asset3."No.", 40000);

        // [WHEN] Posting the purchase receipt
        PostedRcptNo := PostPurchaseReceipt(PurchHeader);

        // [THEN] All 3 assets transferred to location
        Asset1.Get(Asset1."No.");
        LibraryAssert.AreEqual("JML AP Holder Type"::Location, Asset1."Current Holder Type", 'Asset 1 should be at Location');
        LibraryAssert.AreEqual(Location.Code, Asset1."Current Holder Code", 'Asset 1 should be at correct location');

        Asset2.Get(Asset2."No.");
        LibraryAssert.AreEqual("JML AP Holder Type"::Location, Asset2."Current Holder Type", 'Asset 2 should be at Location');
        LibraryAssert.AreEqual(Location.Code, Asset2."Current Holder Code", 'Asset 2 should be at correct location');

        Asset3.Get(Asset3."No.");
        LibraryAssert.AreEqual("JML AP Holder Type"::Location, Asset3."Current Holder Type", 'Asset 3 should be at Location');
        LibraryAssert.AreEqual(Location.Code, Asset3."Current Holder Code", 'Asset 3 should be at correct location');

        // [THEN] 3 posted asset lines created
        PostedAssetLine.SetRange("Document No.", PostedRcptNo);
        LibraryAssert.RecordCount(PostedAssetLine, 3);

        // [THEN] Each line has unique transaction number
        PostedAssetLine.FindSet();
        repeat
            LibraryAssert.IsTrue(PostedAssetLine."Transaction No." > 0, 'Transaction no. should be assigned');
        until PostedAssetLine.Next() = 0;

        // [THEN] Total 6 holder entries (3 Transfer Out + 3 Transfer In)
        HolderEntry.SetFilter("Asset No.", '%1|%2|%3', Asset1."No.", Asset2."No.", Asset3."No.");
        LibraryAssert.RecordCount(HolderEntry, 6);

        // Cleanup
        CleanupTestData(PurchHeader."No.", Asset1."No.", Vendor."No.", Location.Code);
        CleanupAsset(Asset2."No.");
        CleanupAsset(Asset3."No.");
    end;

    [Test]
    procedure TestPostPurchaseOrder_CreatesPostedReceiptAssetLines()
    var
        Vendor: Record Vendor;
        Location: Record Location;
        Asset: Record "JML AP Asset";
        PurchHeader: Record "Purchase Header";
        PurchAssetLine: Record "JML AP Purch. Asset Line";
        PostedAssetLine: Record "JML AP Pstd Purch Rcpt Ast Ln";
        AssetSetup: Record "JML AP Asset Setup";
        PostedRcptNo: Code[20];
    begin
        // [SCENARIO] Post Purchase Receipt and verify Posted Receipt Asset Lines created with correct data

        // [GIVEN] A purchase order with asset
        Initialize();
        EnsureSetupExists(AssetSetup);
        CreateTestVendor(Vendor, 'TEST-VEND-003');
        CreateTestLocation(Location, 'TEST-LOCE');
        CreateTestAsset(Asset, 'TEST-ASSET-P005', "JML AP Holder Type"::Vendor, Vendor."No.");
        CreatePurchaseOrderWithAsset(PurchHeader, PurchAssetLine, Vendor."No.", Asset."No.", Location.Code);

        // [WHEN] Posting the purchase receipt
        PostedRcptNo := PostPurchaseReceipt(PurchHeader);

        // [THEN] Posted Receipt Asset Line created with correct fields
        PostedAssetLine.SetRange("Document No.", PostedRcptNo);
        LibraryAssert.RecordCount(PostedAssetLine, 1);
        PostedAssetLine.FindFirst();
        LibraryAssert.AreEqual(Asset."No.", PostedAssetLine."Asset No.", 'Asset No. should match');
        LibraryAssert.AreEqual(Vendor."No.", PostedAssetLine."Buy-from Vendor No.", 'Vendor No. should match');
        LibraryAssert.AreEqual(Location.Code, PostedAssetLine."Location Code", 'Location Code should match');
        LibraryAssert.IsTrue(PostedAssetLine."Transaction No." > 0, 'Transaction No. should be assigned');
        LibraryAssert.IsFalse(PostedAssetLine.Correction, 'Should not be a correction line');

        // Cleanup
        CleanupTestData(PurchHeader."No.", Asset."No.", Vendor."No.", Location.Code);
    end;

    [Test]
    procedure TestPostPurchaseOrder_CreatesHolderEntries()
    var
        Vendor: Record Vendor;
        Location: Record Location;
        Asset: Record "JML AP Asset";
        PurchHeader: Record "Purchase Header";
        PurchAssetLine: Record "JML AP Purch. Asset Line";
        PostedAssetLine: Record "JML AP Pstd Purch Rcpt Ast Ln";
        HolderEntry: Record "JML AP Holder Entry";
        AssetSetup: Record "JML AP Asset Setup";
        PostedRcptNo: Code[20];
        TransferOutFound, TransferInFound: Boolean;
    begin
        // [SCENARIO] Verify holder entries (Transfer Out + Transfer In) created and linked via Transaction No.

        // [GIVEN] A purchase order with asset
        Initialize();
        EnsureSetupExists(AssetSetup);
        CreateTestVendor(Vendor, 'TEST-VEND-004');
        CreateTestLocation(Location, 'TEST-LOCF');
        CreateTestAsset(Asset, 'TEST-ASSET-P006', "JML AP Holder Type"::Vendor, Vendor."No.");
        CreatePurchaseOrderWithAsset(PurchHeader, PurchAssetLine, Vendor."No.", Asset."No.", Location.Code);

        // [WHEN] Posting the purchase receipt
        PostedRcptNo := PostPurchaseReceipt(PurchHeader);

        // [THEN] Posted asset line has transaction number
        PostedAssetLine.SetRange("Document No.", PostedRcptNo);
        PostedAssetLine.FindFirst();
        LibraryAssert.IsTrue(PostedAssetLine."Transaction No." > 0, 'Transaction no. should be assigned');

        // [THEN] Holder entries created with matching transaction number
        HolderEntry.SetRange("Asset No.", Asset."No.");
        HolderEntry.SetRange("Transaction No.", PostedAssetLine."Transaction No.");
        LibraryAssert.RecordCount(HolderEntry, 2);

        // [THEN] Verify Transfer Out entry (from Vendor)
        TransferOutFound := false;
        TransferInFound := false;
        HolderEntry.FindSet();
        repeat
            if HolderEntry."Entry Type" = HolderEntry."Entry Type"::"Transfer Out" then begin
                TransferOutFound := true;
                LibraryAssert.AreEqual("JML AP Holder Type"::Vendor, HolderEntry."Holder Type", 'Transfer Out holder type should be Vendor');
                LibraryAssert.AreEqual(Vendor."No.", HolderEntry."Holder Code", 'Transfer Out holder code should be vendor');
            end;
            if HolderEntry."Entry Type" = HolderEntry."Entry Type"::"Transfer In" then begin
                TransferInFound := true;
                LibraryAssert.AreEqual("JML AP Holder Type"::Location, HolderEntry."Holder Type", 'Transfer In holder type should be Location');
                LibraryAssert.AreEqual(Location.Code, HolderEntry."Holder Code", 'Transfer In holder code should be location');
            end;
        until HolderEntry.Next() = 0;

        LibraryAssert.IsTrue(TransferOutFound, 'Transfer Out entry should exist');
        LibraryAssert.IsTrue(TransferInFound, 'Transfer In entry should exist');

        // Cleanup
        CleanupTestData(PurchHeader."No.", Asset."No.", Vendor."No.", Location.Code);
    end;

    [Test]
    procedure TestPostPurchaseOrder_PartialReceive_HandlesCorrectly()
    var
        Vendor: Record Vendor;
        Location: Record Location;
        Asset1, Asset2: Record "JML AP Asset";
        PurchHeader: Record "Purchase Header";
        PurchAssetLine1, PurchAssetLine2: Record "JML AP Purch. Asset Line";
        PostedAssetLine: Record "JML AP Pstd Purch Rcpt Ast Ln";
        AssetSetup: Record "JML AP Asset Setup";
        PostedRcptNo: Code[20];
    begin
        // [SCENARIO] Post Purchase Order with partial receipt (only first asset received)

        // [GIVEN] Purchase order with 2 assets, first set to receive, second not
        Initialize();
        EnsureSetupExists(AssetSetup);
        CreateTestVendor(Vendor, 'TEST-VEND-005');
        CreateTestLocation(Location, 'TEST-LOCG');
        CreateTestAsset(Asset1, 'TEST-ASSET-P007', "JML AP Holder Type"::Vendor, Vendor."No.");
        CreateTestAsset(Asset2, 'TEST-ASSET-P008', "JML AP Holder Type"::Vendor, Vendor."No.");

        CreatePurchaseOrderHeader(PurchHeader, Vendor."No.");
        PurchHeader."Location Code" := Location.Code;
        PurchHeader.Modify();
        AddDummyPurchaseLine(PurchHeader);
        AddPurchaseAssetLine(PurchAssetLine1, PurchHeader, Asset1."No.", 20000);
        PurchAssetLine1."Quantity to Receive" := 1; // Will be received
        PurchAssetLine1.Modify();
        AddPurchaseAssetLine(PurchAssetLine2, PurchHeader, Asset2."No.", 30000);
        PurchAssetLine2."Quantity to Receive" := 0; // Will NOT be received
        PurchAssetLine2.Modify();

        // [WHEN] Posting the purchase receipt
        PostedRcptNo := PostPurchaseReceipt(PurchHeader);

        // [THEN] Only first asset transferred to location
        Asset1.Get(Asset1."No.");
        LibraryAssert.AreEqual("JML AP Holder Type"::Location, Asset1."Current Holder Type", 'Asset 1 should be at Location');
        LibraryAssert.AreEqual(Location.Code, Asset1."Current Holder Code", 'Asset 1 should be at location');

        // [THEN] Second asset remains at vendor
        Asset2.Get(Asset2."No.");
        LibraryAssert.AreEqual("JML AP Holder Type"::Vendor, Asset2."Current Holder Type", 'Asset 2 should still be at Vendor');
        LibraryAssert.AreEqual(Vendor."No.", Asset2."Current Holder Code", 'Asset 2 should still be at vendor');

        // [THEN] Only 1 posted asset line created
        PostedAssetLine.SetRange("Document No.", PostedRcptNo);
        LibraryAssert.RecordCount(PostedAssetLine, 1);
        PostedAssetLine.FindFirst();
        LibraryAssert.AreEqual(Asset1."No.", PostedAssetLine."Asset No.", 'Posted line should be for first asset');

        // Cleanup
        CleanupTestData(PurchHeader."No.", Asset1."No.", Vendor."No.", Location.Code);
        CleanupAsset(Asset2."No.");
    end;

    // ============================================================================
    // Story 3.2: Purchase Order Posting - Error Scenarios
    // ============================================================================

    [Test]
    procedure TestPostPurchaseOrder_AssetNotAtVendor_ThrowsError()
    var
        Vendor: Record Vendor;
        Location: Record Location;
        Asset: Record "JML AP Asset";
        PurchHeader: Record "Purchase Header";
        PurchAssetLine: Record "JML AP Purch. Asset Line";
        AssetSetup: Record "JML AP Asset Setup";
        ErrorOccurred: Boolean;
    begin
        // [SCENARIO] Asset is at Location instead of Vendor, adding to purchase line should fail

        // [GIVEN] Asset at Location (not at Vendor), Purchase Order for that asset
        Initialize();
        EnsureSetupExists(AssetSetup);
        CreateTestVendor(Vendor, 'TEST-VEND-006');
        CreateTestLocation(Location, 'TEST-LOCH');
        CreateTestAsset(Asset, 'TEST-ASSET-P009', "JML AP Holder Type"::Location, Location.Code); // Asset at Location, not Vendor

        CreatePurchaseOrderHeader(PurchHeader, Vendor."No.");
        PurchHeader."Location Code" := Location.Code;
        PurchHeader.Modify();
        AddDummyPurchaseLine(PurchHeader);
        Commit(); // Commit test data before asserterror to prevent rollback

        // [WHEN] Attempting to add asset line (validation happens here)
        ErrorOccurred := false;
        ClearLastError();
        asserterror begin
            AddPurchaseAssetLine(PurchAssetLine, PurchHeader, Asset."No.", 20000);
        end;

        // [THEN] Error thrown
        if GetLastErrorText() <> '' then
            ErrorOccurred := true;

        LibraryAssert.IsTrue(ErrorOccurred, 'Should throw error when adding asset not at vendor');

        // [THEN] Asset holder unchanged
        Asset.Get(Asset."No.");
        LibraryAssert.AreEqual("JML AP Holder Type"::Location, Asset."Current Holder Type", 'Asset should still be at Location');
        LibraryAssert.AreEqual(Location.Code, Asset."Current Holder Code", 'Asset should still be at original location');

        // Cleanup
        ClearLastError();
        CleanupTestData(PurchHeader."No.", Asset."No.", Vendor."No.", Location.Code);
    end;

    [Test]
    procedure TestPostPurchaseOrder_AssetBlocked_ThrowsError()
    var
        Vendor: Record Vendor;
        Location: Record Location;
        Asset: Record "JML AP Asset";
        PurchHeader: Record "Purchase Header";
        PurchAssetLine: Record "JML AP Purch. Asset Line";
        AssetSetup: Record "JML AP Asset Setup";
        PostedRcptNo: Code[20];
        ErrorOccurred: Boolean;
    begin
        // [SCENARIO] Asset is blocked, posting should fail

        // [GIVEN] Blocked asset at Vendor
        Initialize();
        EnsureSetupExists(AssetSetup);
        CreateTestVendor(Vendor, 'TEST-VEND-007');
        CreateTestLocation(Location, 'TEST-LOCI');
        CreateTestAsset(Asset, 'TEST-ASSET-P010', "JML AP Holder Type"::Vendor, Vendor."No.");
        Asset.Blocked := true;
        Asset.Modify();

        CreatePurchaseOrderHeader(PurchHeader, Vendor."No.");
        PurchHeader."Location Code" := Location.Code;
        PurchHeader.Modify();
        AddDummyPurchaseLine(PurchHeader);

        // [WHEN] Attempting to add blocked asset to purchase line
        ErrorOccurred := false;
        ClearLastError();
        asserterror begin
            AddPurchaseAssetLine(PurchAssetLine, PurchHeader, Asset."No.", 20000);
        end;

        // [THEN] Error thrown
        if GetLastErrorText() <> '' then
            ErrorOccurred := true;

        LibraryAssert.IsTrue(ErrorOccurred, 'Should throw error when asset is blocked');
        LibraryAssert.IsTrue(StrPos(LowerCase(GetLastErrorText()), 'blocked') > 0, 'Error should mention blocked');

        // Cleanup
        ClearLastError();
        CleanupTestData(PurchHeader."No.", Asset."No.", Vendor."No.", Location.Code);
    end;

    [Test]
    procedure TestPostPurchaseOrder_Subasset_ThrowsError()
    var
        Vendor: Record Vendor;
        Location: Record Location;
        ParentAsset, Subasset: Record "JML AP Asset";
        PurchHeader: Record "Purchase Header";
        PurchAssetLine: Record "JML AP Purch. Asset Line";
        AssetSetup: Record "JML AP Asset Setup";
        PostedRcptNo: Code[20];
        ErrorOccurred: Boolean;
    begin
        // [SCENARIO] Subasset cannot be posted, should fail with appropriate error

        // [GIVEN] Parent asset and subasset at Vendor
        Initialize();
        EnsureSetupExists(AssetSetup);
        CreateTestVendor(Vendor, 'TEST-VEND-008');
        CreateTestLocation(Location, 'TEST-LOCJ');
        CreateTestAsset(ParentAsset, 'TEST-PARENT-P01', "JML AP Holder Type"::Vendor, Vendor."No.");
        CreateTestAsset(Subasset, 'TEST-SUB-P01', "JML AP Holder Type"::Vendor, Vendor."No.");
        Subasset."Parent Asset No." := ParentAsset."No.";
        Subasset.Modify();

        CreatePurchaseOrderHeader(PurchHeader, Vendor."No.");
        PurchHeader."Location Code" := Location.Code;
        PurchHeader.Modify();
        AddDummyPurchaseLine(PurchHeader);

        // [WHEN] Attempting to add subasset to purchase line
        ErrorOccurred := false;
        ClearLastError();
        asserterror begin
            AddPurchaseAssetLine(PurchAssetLine, PurchHeader, Subasset."No.", 20000);
        end;

        // [THEN] Error thrown mentioning subasset/parent
        if GetLastErrorText() <> '' then
            ErrorOccurred := true;

        LibraryAssert.IsTrue(ErrorOccurred, 'Should throw error when adding subasset');

        // Cleanup
        ClearLastError();
        CleanupTestData(PurchHeader."No.", Subasset."No.", Vendor."No.", Location.Code);
        CleanupAsset(ParentAsset."No.");
    end;

    [Test]
    procedure TestPostPurchaseOrder_AssetDoesNotExist_ThrowsError()
    var
        Vendor: Record Vendor;
        Location: Record Location;
        PurchHeader: Record "Purchase Header";
        PurchAssetLine: Record "JML AP Purch. Asset Line";
        AssetSetup: Record "JML AP Asset Setup";
        ErrorOccurred: Boolean;
    begin
        // [SCENARIO] Non-existent asset on purchase line, posting should fail

        // [GIVEN] Purchase order with non-existent asset reference
        Initialize();
        EnsureSetupExists(AssetSetup);
        CreateTestVendor(Vendor, 'TEST-VEND-009');
        CreateTestLocation(Location, 'TEST-LOCK');

        CreatePurchaseOrderHeader(PurchHeader, Vendor."No.");
        PurchHeader."Location Code" := Location.Code;
        PurchHeader.Modify();
        AddDummyPurchaseLine(PurchHeader);

        // [WHEN] Attempting to add non-existent asset
        ErrorOccurred := false;
        ClearLastError();
        asserterror begin
            AddPurchaseAssetLine(PurchAssetLine, PurchHeader, 'NONEXISTENT', 20000);
        end;

        // [THEN] Error thrown
        if GetLastErrorText() <> '' then
            ErrorOccurred := true;

        LibraryAssert.IsTrue(ErrorOccurred, 'Should throw error when asset does not exist');

        // Cleanup
        ClearLastError();
        CleanupTestData(PurchHeader."No.", '', Vendor."No.", Location.Code);
    end;

    [Test]
    procedure TestPostPurchaseOrder_NoAssetLines_PostsSuccessfully()
    var
        Vendor: Record Vendor;
        Location: Record Location;
        PurchHeader: Record "Purchase Header";
        PostedRcptHeader: Record "Purch. Rcpt. Header";
        AssetSetup: Record "JML AP Asset Setup";
        PostedRcptNo: Code[20];
    begin
        // [SCENARIO] Purchase Order without asset lines should post successfully (normal BC behavior)

        // [GIVEN] Purchase order with only item lines, no asset lines
        Initialize();
        EnsureSetupExists(AssetSetup);
        CreateTestVendor(Vendor, 'TEST-VEND-010');
        CreateTestLocation(Location, 'TEST-LOCL');

        CreatePurchaseOrderHeader(PurchHeader, Vendor."No.");
        PurchHeader."Location Code" := Location.Code;
        PurchHeader.Modify();
        AddDummyPurchaseLine(PurchHeader); // Only item line, no asset lines

        // [WHEN] Posting the purchase receipt
        PostedRcptNo := PostPurchaseReceipt(PurchHeader);

        // [THEN] Receipt posts successfully
        LibraryAssert.IsTrue(PostedRcptNo <> '', 'Posted receipt number should be assigned');
        LibraryAssert.IsTrue(PostedRcptHeader.Get(PostedRcptNo), 'Posted receipt header should exist');

        // Cleanup
        CleanupTestData(PurchHeader."No.", '', Vendor."No.", Location.Code);
    end;

    // ============================================================================
    // Story 3.3: Purchase Return Order - Asset Returns
    // ============================================================================

    [Test]
    procedure TestPostPurchaseReturnOrder_WithAsset_TransfersToVendor()
    var
        Vendor: Record Vendor;
        Location: Record Location;
        Asset: Record "JML AP Asset";
        PurchHeader: Record "Purchase Header";
        PurchAssetLine: Record "JML AP Purch. Asset Line";
        PostedRetShptHeader: Record "Return Shipment Header";
        PostedAssetLine: Record "JML AP Pstd Ret Shpt Ast Ln";
        HolderEntry: Record "JML AP Holder Entry";
        AssetSetup: Record "JML AP Asset Setup";
        PostedShptNo: Code[20];
    begin
        // [SCENARIO] Post Purchase Return Order, verify asset returns from Location to Vendor

        // [GIVEN] Vendor, location, and asset at that location
        Initialize();
        EnsureSetupExists(AssetSetup);
        CreateTestVendor(Vendor, 'TEST-VEND-011');
        CreateTestLocation(Location, 'TEST-LOCM');
        CreateTestAsset(Asset, 'TEST-ASSET-P011', "JML AP Holder Type"::Location, Location.Code);
        CreateReturnOrderWithAsset(PurchHeader, PurchAssetLine, Vendor."No.", Asset."No.", Location.Code);

        // [WHEN] Posting the return shipment
        PostedShptNo := PostReturnShipment(PurchHeader);

        // [THEN] Asset holder changed to vendor
        Asset.Get(Asset."No.");
        LibraryAssert.AreEqual("JML AP Holder Type"::Vendor, Asset."Current Holder Type", 'Asset holder type should be Vendor');
        LibraryAssert.AreEqual(Vendor."No.", Asset."Current Holder Code", 'Asset holder code should be vendor number');

        // [THEN] Posted return shipment header created
        LibraryAssert.IsTrue(PostedRetShptHeader.Get(PostedShptNo), 'Posted return shipment header should exist');

        // [THEN] Posted return shipment asset line created
        PostedAssetLine.SetRange("Document No.", PostedShptNo);
        LibraryAssert.RecordCount(PostedAssetLine, 1);
        PostedAssetLine.FindFirst();
        LibraryAssert.AreEqual(Asset."No.", PostedAssetLine."Asset No.", 'Posted line asset no. should match');
        LibraryAssert.IsTrue(PostedAssetLine."Transaction No." > 0, 'Transaction no. should be assigned');

        // [THEN] Holder entries created (Transfer Out from Location + Transfer In to Vendor)
        HolderEntry.SetRange("Asset No.", Asset."No.");
        HolderEntry.SetRange("Transaction No.", PostedAssetLine."Transaction No.");
        LibraryAssert.RecordCount(HolderEntry, 2);

        // Cleanup
        CleanupTestData(PurchHeader."No.", Asset."No.", Vendor."No.", Location.Code);
    end;

    [Test]
    procedure TestPostPurchaseReturnOrder_AssetNotAtLocation_ThrowsError()
    var
        Vendor: Record Vendor;
        Location: Record Location;
        Customer: Record Customer;
        Asset: Record "JML AP Asset";
        PurchHeader: Record "Purchase Header";
        PurchAssetLine: Record "JML AP Purch. Asset Line";
        AssetSetup: Record "JML AP Asset Setup";
        ErrorOccurred: Boolean;
    begin
        // [SCENARIO] Asset at Customer instead of Location, adding to return line should fail

        // [GIVEN] Asset at Customer (not at Location), Return Order for that asset
        Initialize();
        EnsureSetupExists(AssetSetup);
        CreateTestVendor(Vendor, 'TEST-VEND-012');
        CreateTestLocation(Location, 'TEST-LOCN');
        CreateTestCustomer(Customer, 'TEST-CUST-P01');
        CreateTestAsset(Asset, 'TEST-ASSET-P012', "JML AP Holder Type"::Customer, Customer."No."); // Asset at Customer, not Location

        CreateReturnOrderHeader(PurchHeader, Vendor."No.");
        PurchHeader."Location Code" := Location.Code;
        PurchHeader.Modify();
        AddDummyPurchaseLineForReturn(PurchHeader);
        Commit(); // Commit test data before asserterror to prevent rollback

        // [WHEN] Attempting to add return asset line (validation happens here)
        ErrorOccurred := false;
        ClearLastError();
        asserterror begin
            AddReturnAssetLine(PurchAssetLine, PurchHeader, Asset."No.", 20000);
        end;

        // [THEN] Error thrown
        if GetLastErrorText() <> '' then
            ErrorOccurred := true;

        LibraryAssert.IsTrue(ErrorOccurred, 'Should throw error when adding asset not at location');

        // [THEN] Asset holder unchanged
        Asset.Get(Asset."No.");
        LibraryAssert.AreEqual("JML AP Holder Type"::Customer, Asset."Current Holder Type", 'Asset should still be at Customer');
        LibraryAssert.AreEqual(Customer."No.", Asset."Current Holder Code", 'Asset should still be at customer');

        // Cleanup
        ClearLastError();
        CleanupTestData(PurchHeader."No.", Asset."No.", Vendor."No.", Location.Code);
    end;

    [Test]
    procedure TestPostPurchaseReturnOrder_CreatesReturnShipmentAssetLines()
    var
        Vendor: Record Vendor;
        Location: Record Location;
        Asset1, Asset2: Record "JML AP Asset";
        PurchHeader: Record "Purchase Header";
        PurchAssetLine: Record "JML AP Purch. Asset Line";
        PostedAssetLine: Record "JML AP Pstd Ret Shpt Ast Ln";
        AssetSetup: Record "JML AP Asset Setup";
        PostedShptNo: Code[20];
    begin
        // [SCENARIO] Post Return Order with 2 assets, verify Posted Return Shipment Asset Lines created

        // [GIVEN] Return order with 2 assets at location
        Initialize();
        EnsureSetupExists(AssetSetup);
        CreateTestVendor(Vendor, 'TEST-VEND-013');
        CreateTestLocation(Location, 'TEST-LOCO');
        CreateTestAsset(Asset1, 'TEST-ASSET-P013', "JML AP Holder Type"::Location, Location.Code);
        CreateTestAsset(Asset2, 'TEST-ASSET-P014', "JML AP Holder Type"::Location, Location.Code);

        CreateReturnOrderHeader(PurchHeader, Vendor."No.");
        PurchHeader."Location Code" := Location.Code;
        PurchHeader.Modify();
        AddDummyPurchaseLineForReturn(PurchHeader);
        AddReturnAssetLine(PurchAssetLine, PurchHeader, Asset1."No.", 20000);
        AddReturnAssetLine(PurchAssetLine, PurchHeader, Asset2."No.", 30000);

        // [WHEN] Posting the return shipment
        PostedShptNo := PostReturnShipment(PurchHeader);

        // [THEN] 2 Posted Return Shipment Asset Lines created
        PostedAssetLine.SetRange("Document No.", PostedShptNo);
        LibraryAssert.RecordCount(PostedAssetLine, 2);

        // [THEN] Each line has transaction number assigned
        PostedAssetLine.FindSet();
        repeat
            LibraryAssert.IsTrue(PostedAssetLine."Transaction No." > 0, 'Transaction no. should be assigned');
            LibraryAssert.AreEqual(Vendor."No.", PostedAssetLine."Buy-from Vendor No.", 'Vendor no. should match');
            LibraryAssert.AreEqual(Location.Code, PostedAssetLine."Location Code", 'Location code should match');
        until PostedAssetLine.Next() = 0;

        // Cleanup
        CleanupTestData(PurchHeader."No.", Asset1."No.", Vendor."No.", Location.Code);
        CleanupAsset(Asset2."No.");
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

    local procedure CreateTestVendor(var Vendor: Record Vendor; VendorNo: Code[20])
    begin
        if not Vendor.Get(VendorNo) then begin
            Vendor.Init();
            Vendor."No." := VendorNo;
            Vendor.Name := 'Test Vendor ' + VendorNo;
            Vendor."Gen. Bus. Posting Group" := 'DOMESTIC'; // Set required posting groups
            Vendor."Vendor Posting Group" := 'DOMESTIC';
            Vendor.Insert(true);
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

    local procedure CreateTestCustomer(var Customer: Record Customer; CustomerNo: Code[20])
    begin
        if not Customer.Get(CustomerNo) then begin
            Customer.Init();
            Customer."No." := CustomerNo;
            Customer.Name := 'Test Customer ' + CustomerNo;
            Customer."Gen. Bus. Posting Group" := 'DOMESTIC';
            Customer."Customer Posting Group" := 'DOMESTIC';
            Customer.Insert(true);
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

    local procedure CreatePurchaseOrderHeader(var PurchHeader: Record "Purchase Header"; VendorNo: Code[20])
    begin
        PurchHeader.Init();
        PurchHeader."Document Type" := PurchHeader."Document Type"::Order;
        PurchHeader."No." := '';
        PurchHeader.Insert(true);
        PurchHeader.Validate("Buy-from Vendor No.", VendorNo);
        PurchHeader.Modify(true);
    end;

    local procedure CreateReturnOrderHeader(var PurchHeader: Record "Purchase Header"; VendorNo: Code[20])
    begin
        PurchHeader.Init();
        PurchHeader."Document Type" := PurchHeader."Document Type"::"Return Order";
        PurchHeader."No." := '';
        PurchHeader.Insert(true);
        PurchHeader.Validate("Buy-from Vendor No.", VendorNo);
        PurchHeader.Modify(true);
    end;

    local procedure AddPurchaseAssetLine(var PurchAssetLine: Record "JML AP Purch. Asset Line"; PurchHeader: Record "Purchase Header"; AssetNo: Code[20]; LineNo: Integer)
    begin
        PurchAssetLine.Init();
        PurchAssetLine."Document Type" := PurchHeader."Document Type";
        PurchAssetLine."Document No." := PurchHeader."No.";
        PurchAssetLine."Line No." := LineNo;
        PurchAssetLine.Validate("Asset No.", AssetNo);  // Use Validate to trigger OnValidate and populate description
        PurchAssetLine."Quantity to Receive" := 1;
        PurchAssetLine.Insert(true);
    end;

    local procedure AddReturnAssetLine(var PurchAssetLine: Record "JML AP Purch. Asset Line"; PurchHeader: Record "Purchase Header"; AssetNo: Code[20]; LineNo: Integer)
    begin
        PurchAssetLine.Init();
        PurchAssetLine."Document Type" := PurchHeader."Document Type";
        PurchAssetLine."Document No." := PurchHeader."No.";
        PurchAssetLine."Line No." := LineNo;
        PurchAssetLine.Validate("Asset No.", AssetNo);  // Use Validate to trigger OnValidate and populate description
        PurchAssetLine."Quantity to Ship" := 1; // For return orders
        PurchAssetLine.Insert(true);
    end;

    local procedure CreatePurchaseOrderWithAsset(var PurchHeader: Record "Purchase Header"; var PurchAssetLine: Record "JML AP Purch. Asset Line"; VendorNo: Code[20]; AssetNo: Code[20]; LocationCode: Code[10])
    begin
        CreatePurchaseOrderHeader(PurchHeader, VendorNo);
        PurchHeader."Location Code" := LocationCode; // Set location code before adding asset lines
        PurchHeader.Modify();
        AddDummyPurchaseLine(PurchHeader); // Add minimal item line for BC posting requirements
        AddPurchaseAssetLine(PurchAssetLine, PurchHeader, AssetNo, 20000); // Use line 20000 after dummy line
    end;

    local procedure CreateReturnOrderWithAsset(var PurchHeader: Record "Purchase Header"; var PurchAssetLine: Record "JML AP Purch. Asset Line"; VendorNo: Code[20]; AssetNo: Code[20]; LocationCode: Code[10])
    begin
        CreateReturnOrderHeader(PurchHeader, VendorNo);
        PurchHeader."Location Code" := LocationCode;
        PurchHeader.Modify();
        AddDummyPurchaseLineForReturn(PurchHeader);
        AddReturnAssetLine(PurchAssetLine, PurchHeader, AssetNo, 20000);
    end;

    local procedure PostPurchaseReceipt(PurchHeader: Record "Purchase Header"): Code[20]
    var
        PurchPost: Codeunit "Purch.-Post";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        PurchHeader.Receive := true;
        PurchHeader.Invoice := false;
        PurchPost.Run(PurchHeader);

        PurchRcptHeader.SetRange("Order No.", PurchHeader."No.");
        if PurchRcptHeader.FindFirst() then
            exit(PurchRcptHeader."No.");

        exit('');
    end;

    local procedure PostReturnShipment(PurchHeader: Record "Purchase Header"): Code[20]
    var
        PurchPost: Codeunit "Purch.-Post";
        ReturnShptHeader: Record "Return Shipment Header";
    begin
        PurchHeader.Ship := true;
        PurchHeader.Invoice := false;
        PurchPost.Run(PurchHeader);

        ReturnShptHeader.SetRange("Return Order No.", PurchHeader."No.");
        if ReturnShptHeader.FindFirst() then
            exit(ReturnShptHeader."No.");

        exit('');
    end;

    local procedure AddDummyPurchaseLine(var PurchHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
        Item: Record Item;
    begin
        // BC requires at least one item line to post a purchase order
        CreateTestItem(Item, 'TEST-ITEM-P');

        PurchLine.Init();
        PurchLine."Document Type" := PurchHeader."Document Type";
        PurchLine."Document No." := PurchHeader."No.";
        PurchLine."Line No." := 10000;
        PurchLine.Type := PurchLine.Type::Item;
        PurchLine.Validate("No.", Item."No.");
        PurchLine.Validate(Quantity, 1);
        PurchLine.Validate("Qty. to Receive", 1);
        PurchLine.Insert(true);
    end;

    local procedure AddDummyPurchaseLineForReturn(var PurchHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
        Item: Record Item;
    begin
        // BC requires at least one item line to post a return order
        CreateTestItem(Item, 'TEST-ITEM-P');

        PurchLine.Init();
        PurchLine."Document Type" := PurchHeader."Document Type";
        PurchLine."Document No." := PurchHeader."No.";
        PurchLine."Line No." := 10000;
        PurchLine.Type := PurchLine.Type::Item;
        PurchLine.Validate("No.", Item."No.");
        PurchLine.Validate(Quantity, 1);
        PurchLine.Validate("Return Qty. to Ship", 1);
        PurchLine.Insert(true);
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
            if not ItemUnitOfMeasure.Get(Item."No.", 'PCS') then begin
                ItemUnitOfMeasure.Init();
                ItemUnitOfMeasure."Item No." := Item."No.";
                ItemUnitOfMeasure.Code := 'PCS';
                ItemUnitOfMeasure."Qty. per Unit of Measure" := 1;
                ItemUnitOfMeasure.Insert(true);
            end;
        end;
    end;

    local procedure CleanupTestData(PurchHeaderNo: Code[20]; AssetNo: Code[20]; VendorNo: Code[20]; LocationCode: Code[10])
    var
        Asset: Record "JML AP Asset";
        HolderEntry: Record "JML AP Holder Entry";
    begin
        // Note: We don't delete posted Purchase Headers/Lines as BC prevents this by design
        // Posted documents remain in the database
        // Only clean up master data (assets, vendors, locations, etc.)

        // Delete asset and holder entries
        if AssetNo <> '' then begin
            HolderEntry.SetRange("Asset No.", AssetNo);
            HolderEntry.DeleteAll(true);

            if Asset.Get(AssetNo) then
                Asset.Delete(true);
        end;

        // Don't delete vendors/locations as they may be in use

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
}
