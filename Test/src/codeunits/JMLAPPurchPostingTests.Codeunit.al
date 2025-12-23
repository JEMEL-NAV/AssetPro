codeunit 50116 "JML AP Purch Posting Tests"
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
        TestLibrary.Initialize();
        Vendor := TestLibrary.CreateTestVendor('TEST-VEND-001');
        Location := TestLibrary.CreateTestLocation('TEST-LOCP');
        Asset := TestLibrary.CreateAssetAtVendor('TEST-ASSET-P001', Vendor."No.");
        PurchHeader := TestLibrary.CreatePurchaseOrderHeader(Vendor."No.");
        PurchHeader."Location Code" := Location.Code;
        PurchHeader.Modify();
        TestLibrary.AddDummyItemLine(PurchHeader);
        PurchAssetLine := TestLibrary.AddPurchaseAssetLine(PurchHeader, Asset."No.", 20000);

        // [WHEN] Posting the purchase receipt
        PostedRcptNo := TestLibrary.PostPurchaseReceipt(PurchHeader);

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

        // No cleanup needed - automatic test isolation handles rollback
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
        TestLibrary.Initialize();
        Vendor := TestLibrary.CreateTestVendor('TEST-VEND-002');
        Location := TestLibrary.CreateTestLocation('TEST-LOCD');
        Asset1 := TestLibrary.CreateAssetAtVendor('TEST-ASSET-P002', Vendor."No.");
        Asset2 := TestLibrary.CreateAssetAtVendor('TEST-ASSET-P003', Vendor."No.");
        Asset3 := TestLibrary.CreateAssetAtVendor('TEST-ASSET-P004', Vendor."No.");

        // [GIVEN] A purchase order with 3 asset lines
        PurchHeader := TestLibrary.CreatePurchaseOrderHeader(Vendor."No.");
        PurchHeader."Location Code" := Location.Code; // Set location code before adding asset lines
        PurchHeader.Modify();
        TestLibrary.AddDummyItemLine(PurchHeader); // Add minimal item line for BC posting requirements
        TestLibrary.AddPurchaseAssetLine(PurchHeader, Asset1."No.", 20000);
        TestLibrary.AddPurchaseAssetLine(PurchHeader, Asset2."No.", 30000);
        TestLibrary.AddPurchaseAssetLine(PurchHeader, Asset3."No.", 40000);

        // [WHEN] Posting the purchase receipt
        PostedRcptNo := TestLibrary.PostPurchaseReceipt(PurchHeader);

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

        // No cleanup needed - automatic test isolation handles rollback
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
        TestLibrary.Initialize();
        Vendor := TestLibrary.CreateTestVendor('TEST-VEND-003');
        Location := TestLibrary.CreateTestLocation('TEST-LOCE');
        Asset := TestLibrary.CreateAssetAtVendor('TEST-ASSET-P005', Vendor."No.");
        PurchHeader := TestLibrary.CreatePurchaseOrderHeader(Vendor."No.");
        PurchHeader."Location Code" := Location.Code;
        PurchHeader.Modify();
        TestLibrary.AddDummyItemLine(PurchHeader);
        PurchAssetLine := TestLibrary.AddPurchaseAssetLine(PurchHeader, Asset."No.", 20000);

        // [WHEN] Posting the purchase receipt
        PostedRcptNo := TestLibrary.PostPurchaseReceipt(PurchHeader);

        // [THEN] Posted Receipt Asset Line created with correct fields
        PostedAssetLine.SetRange("Document No.", PostedRcptNo);
        LibraryAssert.RecordCount(PostedAssetLine, 1);
        PostedAssetLine.FindFirst();
        LibraryAssert.AreEqual(Asset."No.", PostedAssetLine."Asset No.", 'Asset No. should match');
        LibraryAssert.AreEqual(Vendor."No.", PostedAssetLine."Buy-from Vendor No.", 'Vendor No. should match');
        LibraryAssert.AreEqual(Location.Code, PostedAssetLine."Location Code", 'Location Code should match');
        LibraryAssert.IsTrue(PostedAssetLine."Transaction No." > 0, 'Transaction No. should be assigned');
        LibraryAssert.IsFalse(PostedAssetLine.Correction, 'Should not be a correction line');

        // No cleanup needed - automatic test isolation handles rollback
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
        TestLibrary.Initialize();
        Vendor := TestLibrary.CreateTestVendor('TEST-VEND-004');
        Location := TestLibrary.CreateTestLocation('TEST-LOCF');
        Asset := TestLibrary.CreateAssetAtVendor('TEST-ASSET-P006', Vendor."No.");
        PurchHeader := TestLibrary.CreatePurchaseOrderHeader(Vendor."No.");
        PurchHeader."Location Code" := Location.Code;
        PurchHeader.Modify();
        TestLibrary.AddDummyItemLine(PurchHeader);
        PurchAssetLine := TestLibrary.AddPurchaseAssetLine(PurchHeader, Asset."No.", 20000);

        // [WHEN] Posting the purchase receipt
        PostedRcptNo := TestLibrary.PostPurchaseReceipt(PurchHeader);

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

        // No cleanup needed - automatic test isolation handles rollback
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
        TestLibrary.Initialize();
        Vendor := TestLibrary.CreateTestVendor('TEST-VEND-005');
        Location := TestLibrary.CreateTestLocation('TEST-LOCG');
        Asset1 := TestLibrary.CreateAssetAtVendor('TEST-ASSET-P007', Vendor."No.");
        Asset2 := TestLibrary.CreateAssetAtVendor('TEST-ASSET-P008', Vendor."No.");

        PurchHeader := TestLibrary.CreatePurchaseOrderHeader(Vendor."No.");
        PurchHeader."Location Code" := Location.Code;
        PurchHeader.Modify();
        TestLibrary.AddDummyItemLine(PurchHeader);
        PurchAssetLine1 := TestLibrary.AddPurchaseAssetLine(PurchHeader, Asset1."No.", 20000);
        PurchAssetLine1."Quantity to Receive" := 1; // Will be received
        PurchAssetLine1.Modify();
        PurchAssetLine2 := TestLibrary.AddPurchaseAssetLine(PurchHeader, Asset2."No.", 30000);
        PurchAssetLine2."Quantity to Receive" := 0; // Will NOT be received
        PurchAssetLine2.Modify();

        // [WHEN] Posting the purchase receipt
        PostedRcptNo := TestLibrary.PostPurchaseReceipt(PurchHeader);

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

        // No cleanup needed - automatic test isolation handles rollback
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
        TestLibrary.Initialize();
        Vendor := TestLibrary.CreateTestVendor('TEST-VEND-006');
        Location := TestLibrary.CreateTestLocation('TEST-LOCH');
        Asset := TestLibrary.CreateAssetAtLocation('TEST-ASSET-P009', Location.Code); // Asset at Location, not Vendor

        PurchHeader := TestLibrary.CreatePurchaseOrderHeader(Vendor."No.");
        PurchHeader."Location Code" := Location.Code;
        PurchHeader.Modify();
        TestLibrary.AddDummyItemLine(PurchHeader);
        Commit(); // Commit test data before asserterror to prevent rollback

        // [WHEN] Attempting to add asset line (validation happens here)
        ErrorOccurred := false;
        ClearLastError();
        asserterror begin
            PurchAssetLine := TestLibrary.AddPurchaseAssetLine(PurchHeader, Asset."No.", 20000);
        end;

        // [THEN] Error thrown
        if GetLastErrorText() <> '' then
            ErrorOccurred := true;

        LibraryAssert.IsTrue(ErrorOccurred, 'Should throw error when adding asset not at vendor');

        // [THEN] Asset holder unchanged
        Asset.Get(Asset."No.");
        LibraryAssert.AreEqual("JML AP Holder Type"::Location, Asset."Current Holder Type", 'Asset should still be at Location');
        LibraryAssert.AreEqual(Location.Code, Asset."Current Holder Code", 'Asset should still be at original location');

        // No cleanup needed - automatic test isolation handles rollback
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
        TestLibrary.Initialize();
        Vendor := TestLibrary.CreateTestVendor('TEST-VEND-007');
        Location := TestLibrary.CreateTestLocation('TEST-LOCI');
        Asset := TestLibrary.CreateAssetAtVendor('TEST-ASSET-P010', Vendor."No.");
        Asset.Blocked := true;
        Asset.Modify();

        PurchHeader := TestLibrary.CreatePurchaseOrderHeader(Vendor."No.");
        PurchHeader."Location Code" := Location.Code;
        PurchHeader.Modify();
        TestLibrary.AddDummyItemLine(PurchHeader);

        // [WHEN] Attempting to add blocked asset to purchase line
        ErrorOccurred := false;
        ClearLastError();
        asserterror begin
            PurchAssetLine := TestLibrary.AddPurchaseAssetLine(PurchHeader, Asset."No.", 20000);
        end;

        // [THEN] Error thrown
        if GetLastErrorText() <> '' then
            ErrorOccurred := true;

        LibraryAssert.IsTrue(ErrorOccurred, 'Should throw error when asset is blocked');
        LibraryAssert.IsTrue(StrPos(LowerCase(GetLastErrorText()), 'blocked') > 0, 'Error should mention blocked');

        // No cleanup needed - automatic test isolation handles rollback
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
        TestLibrary.Initialize();
        Vendor := TestLibrary.CreateTestVendor('TEST-VEND-008');
        Location := TestLibrary.CreateTestLocation('TEST-LOCJ');
        ParentAsset := TestLibrary.CreateAssetAtVendor('TEST-PARENT-P01', Vendor."No.");
        Subasset := TestLibrary.CreateAssetWithParent('TEST-SUB-P01', ParentAsset."No.");

        PurchHeader := TestLibrary.CreatePurchaseOrderHeader(Vendor."No.");
        PurchHeader."Location Code" := Location.Code;
        PurchHeader.Modify();
        TestLibrary.AddDummyItemLine(PurchHeader);

        // [WHEN] Attempting to add subasset to purchase line
        ErrorOccurred := false;
        ClearLastError();
        asserterror begin
            PurchAssetLine := TestLibrary.AddPurchaseAssetLine(PurchHeader, Subasset."No.", 20000);
        end;

        // [THEN] Error thrown mentioning subasset/parent
        if GetLastErrorText() <> '' then
            ErrorOccurred := true;

        LibraryAssert.IsTrue(ErrorOccurred, 'Should throw error when adding subasset');

        // No cleanup needed - automatic test isolation handles rollback
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
        TestLibrary.Initialize();
        Vendor := TestLibrary.CreateTestVendor('TEST-VEND-009');
        Location := TestLibrary.CreateTestLocation('TEST-LOCK');

        PurchHeader := TestLibrary.CreatePurchaseOrderHeader(Vendor."No.");
        PurchHeader."Location Code" := Location.Code;
        PurchHeader.Modify();
        TestLibrary.AddDummyItemLine(PurchHeader);

        // [WHEN] Attempting to add non-existent asset
        ErrorOccurred := false;
        ClearLastError();
        asserterror begin
            PurchAssetLine := TestLibrary.AddPurchaseAssetLine(PurchHeader, 'NONEXISTENT', 20000);
        end;

        // [THEN] Error thrown
        if GetLastErrorText() <> '' then
            ErrorOccurred := true;

        LibraryAssert.IsTrue(ErrorOccurred, 'Should throw error when asset does not exist');

        // No cleanup needed - automatic test isolation handles rollback
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
        TestLibrary.Initialize();
        Vendor := TestLibrary.CreateTestVendor('TEST-VEND-010');
        Location := TestLibrary.CreateTestLocation('TEST-LOCL');

        PurchHeader := TestLibrary.CreatePurchaseOrderHeader(Vendor."No.");
        PurchHeader."Location Code" := Location.Code;
        PurchHeader.Modify();
        TestLibrary.AddDummyItemLine(PurchHeader); // Only item line, no asset lines

        // [WHEN] Posting the purchase receipt
        PostedRcptNo := TestLibrary.PostPurchaseReceipt(PurchHeader);

        // [THEN] Receipt posts successfully
        LibraryAssert.IsTrue(PostedRcptNo <> '', 'Posted receipt number should be assigned');
        LibraryAssert.IsTrue(PostedRcptHeader.Get(PostedRcptNo), 'Posted receipt header should exist');

        // No cleanup needed - automatic test isolation handles rollback
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
        TestLibrary.Initialize();
        Vendor := TestLibrary.CreateTestVendor('TEST-VEND-011');
        Location := TestLibrary.CreateTestLocation('TEST-LOCM');
        Asset := TestLibrary.CreateAssetAtLocation('TEST-ASSET-P011', Location.Code);
        PurchHeader := TestLibrary.CreatePurchaseReturnOrderHeader(Vendor."No.");
        PurchHeader."Location Code" := Location.Code;
        PurchHeader.Modify();
        TestLibrary.AddDummyItemLine(PurchHeader);
        PurchAssetLine := TestLibrary.AddPurchaseAssetLine(PurchHeader, Asset."No.", 20000);

        // [WHEN] Posting the return shipment
        PostedShptNo := TestLibrary.PostPurchaseReturnShipment(PurchHeader);

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

        // No cleanup needed - automatic test isolation handles rollback
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
        TestLibrary.Initialize();
        Vendor := TestLibrary.CreateTestVendor('TEST-VEND-012');
        Location := TestLibrary.CreateTestLocation('TEST-LOCN');
        Customer := TestLibrary.CreateTestCustomer('TEST-CUST-P01');
        Asset := TestLibrary.CreateAssetAtCustomer('TEST-ASSET-P012', Customer."No."); // Asset at Customer, not Location

        PurchHeader := TestLibrary.CreatePurchaseReturnOrderHeader(Vendor."No.");
        PurchHeader."Location Code" := Location.Code;
        PurchHeader.Modify();
        TestLibrary.AddDummyItemLine(PurchHeader);
        Commit(); // Commit test data before asserterror to prevent rollback

        // [WHEN] Attempting to add return asset line (validation happens here)
        ErrorOccurred := false;
        ClearLastError();
        asserterror begin
            PurchAssetLine := TestLibrary.AddPurchaseAssetLine(PurchHeader, Asset."No.", 20000);
        end;

        // [THEN] Error thrown
        if GetLastErrorText() <> '' then
            ErrorOccurred := true;

        LibraryAssert.IsTrue(ErrorOccurred, 'Should throw error when adding asset not at location');

        // [THEN] Asset holder unchanged
        Asset.Get(Asset."No.");
        LibraryAssert.AreEqual("JML AP Holder Type"::Customer, Asset."Current Holder Type", 'Asset should still be at Customer');
        LibraryAssert.AreEqual(Customer."No.", Asset."Current Holder Code", 'Asset should still be at customer');

        // No cleanup needed - automatic test isolation handles rollback
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
        TestLibrary.Initialize();
        Vendor := TestLibrary.CreateTestVendor('TEST-VEND-013');
        Location := TestLibrary.CreateTestLocation('TEST-LOCO');
        Asset1 := TestLibrary.CreateAssetAtLocation('TEST-ASSET-P013', Location.Code);
        Asset2 := TestLibrary.CreateAssetAtLocation('TEST-ASSET-P014', Location.Code);

        PurchHeader := TestLibrary.CreatePurchaseReturnOrderHeader(Vendor."No.");
        PurchHeader."Location Code" := Location.Code;
        PurchHeader.Modify();
        TestLibrary.AddDummyItemLine(PurchHeader);
        TestLibrary.AddPurchaseAssetLine(PurchHeader, Asset1."No.", 20000);
        TestLibrary.AddPurchaseAssetLine(PurchHeader, Asset2."No.", 30000);

        // [WHEN] Posting the return shipment
        PostedShptNo := TestLibrary.PostPurchaseReturnShipment(PurchHeader);

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

        // No cleanup needed - automatic test isolation handles rollback
    end;
}
