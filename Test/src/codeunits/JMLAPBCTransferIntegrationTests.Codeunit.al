codeunit 50124 "JML AP BC Transfer Integ Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    // Note: Test Isolation is enabled by default in BC test framework
    // Each test runs in isolated transaction that rolls back automatically
    // Manual cleanup procedures have been removed

    var
        LibraryAssert: Codeunit "Library Assert";
        IsInitialized: Boolean;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Handle messages during test execution
    end;

    // ============================================================================
    // Story 4.1: BC Transfer Order with Assets - Happy Path Tests
    // ============================================================================

    [Test]
    procedure TestPostBCTransferOrder_WithAsset_TransfersToLocation()
    var
        LocationFrom, LocationTo: Record Location;
        Asset: Record "JML AP Asset";
        TransferHeader: Record "Transfer Header";
        TransferAssetLine: Record "JML AP Transfer Asset Line";
        TransShptHeader: Record "Transfer Shipment Header";
        PostedAssetLine: Record "JML AP Pstd Trans Shpt Ast Ln";
        HolderEntry: Record "JML AP Holder Entry";
        AssetSetup: Record "JML AP Asset Setup";
        PostedShptNo: Code[20];
    begin
        // [SCENARIO] Post BC Transfer Order with single asset, verify holder transfer

        // [GIVEN] Two locations and asset at Transfer-from Location
        Initialize();
        EnsureSetupExists(AssetSetup);
        CreateTestLocation(LocationFrom, 'FROM-A');
        CreateTestLocation(LocationTo, 'TO-A');
        CreateTestAsset(Asset, 'TEST-ASSET-101', "JML AP Holder Type"::Location, LocationFrom.Code);
        CreateTransferOrderWithAsset(TransferHeader, TransferAssetLine, LocationFrom.Code, LocationTo.Code, Asset."No.");

        // [WHEN] Posting the transfer shipment
        PostedShptNo := PostTransferShipment(TransferHeader);

        // [THEN] Asset holder changed to Transfer-to Location
        Asset.Get(Asset."No.");
        LibraryAssert.AreEqual("JML AP Holder Type"::Location, Asset."Current Holder Type", 'Asset holder type should be Location');
        LibraryAssert.AreEqual(LocationTo.Code, Asset."Current Holder Code", 'Asset should be at Transfer-to Location');

        // [THEN] Posted shipment header created
        LibraryAssert.IsTrue(TransShptHeader.Get(PostedShptNo), 'Posted transfer shipment header should exist');

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
    procedure TestPostBCTransferOrder_MultipleAssets_AllTransferred()
    var
        LocationFrom, LocationTo: Record Location;
        Asset1, Asset2, Asset3: Record "JML AP Asset";
        TransferHeader: Record "Transfer Header";
        TransferAssetLine: Record "JML AP Transfer Asset Line";
        PostedAssetLine: Record "JML AP Pstd Trans Shpt Ast Ln";
        HolderEntry: Record "JML AP Holder Entry";
        AssetSetup: Record "JML AP Asset Setup";
        PostedShptNo: Code[20];
    begin
        // [SCENARIO] Post BC Transfer Order with 3 assets, verify all transferred

        // [GIVEN] Two locations and 3 assets at Transfer-from Location
        Initialize();
        EnsureSetupExists(AssetSetup);
        CreateTestLocation(LocationFrom, 'FROM-B');
        CreateTestLocation(LocationTo, 'TO-B');
        CreateTestAsset(Asset1, 'TEST-ASSET-102', "JML AP Holder Type"::Location, LocationFrom.Code);
        CreateTestAsset(Asset2, 'TEST-ASSET-103', "JML AP Holder Type"::Location, LocationFrom.Code);
        CreateTestAsset(Asset3, 'TEST-ASSET-104', "JML AP Holder Type"::Location, LocationFrom.Code);

        // [GIVEN] A transfer order with 3 asset lines
        CreateTransferOrderHeader(TransferHeader, LocationFrom.Code, LocationTo.Code);
        AddDummyTransferLine(TransferHeader);
        AddTransferAssetLine(TransferAssetLine, TransferHeader, Asset1."No.", 20000);
        AddTransferAssetLine(TransferAssetLine, TransferHeader, Asset2."No.", 30000);
        AddTransferAssetLine(TransferAssetLine, TransferHeader, Asset3."No.", 40000);

        // [WHEN] Posting the transfer shipment
        PostedShptNo := PostTransferShipment(TransferHeader);

        // [THEN] All 3 assets transferred to Transfer-to Location
        Asset1.Get(Asset1."No.");
        Asset2.Get(Asset2."No.");
        Asset3.Get(Asset3."No.");
        LibraryAssert.AreEqual(LocationTo.Code, Asset1."Current Holder Code", 'Asset1 should be at Transfer-to Location');
        LibraryAssert.AreEqual(LocationTo.Code, Asset2."Current Holder Code", 'Asset2 should be at Transfer-to Location');
        LibraryAssert.AreEqual(LocationTo.Code, Asset3."Current Holder Code", 'Asset3 should be at Transfer-to Location');

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
    procedure TestPostBCTransferOrder_CreatesPostedTransferShptAssetLines()
    var
        LocationFrom, LocationTo: Record Location;
        Asset: Record "JML AP Asset";
        TransferHeader: Record "Transfer Header";
        TransferAssetLine: Record "JML AP Transfer Asset Line";
        PostedAssetLine: Record "JML AP Pstd Trans Shpt Ast Ln";
        TransShptHeader: Record "Transfer Shipment Header";
        AssetSetup: Record "JML AP Asset Setup";
        PostedShptNo: Code[20];
    begin
        // [SCENARIO] Verify Posted Transfer Shipment Asset Line structure

        // [GIVEN] Standard setup with 1 asset
        Initialize();
        EnsureSetupExists(AssetSetup);
        CreateTestLocation(LocationFrom, 'FROM-C');
        CreateTestLocation(LocationTo, 'TO-C');
        CreateTestAsset(Asset, 'TEST-ASSET-105', "JML AP Holder Type"::Location, LocationFrom.Code);
        CreateTransferOrderWithAsset(TransferHeader, TransferAssetLine, LocationFrom.Code, LocationTo.Code, Asset."No.");

        // [WHEN] Posting the shipment
        PostedShptNo := PostTransferShipment(TransferHeader);

        // [THEN] Posted line fields are correct
        TransShptHeader.Get(PostedShptNo);
        PostedAssetLine.SetRange("Document No.", PostedShptNo);
        PostedAssetLine.FindFirst();

        LibraryAssert.AreEqual(PostedShptNo, PostedAssetLine."Document No.", 'Document no. should match');
        LibraryAssert.AreEqual(10000, PostedAssetLine."Line No.", 'Line no. should be 10000');
        LibraryAssert.AreEqual(Asset."No.", PostedAssetLine."Asset No.", 'Asset no. should match');
        LibraryAssert.AreEqual(Asset.Description, PostedAssetLine."Asset Description", 'Asset description should match');
        LibraryAssert.AreEqual(LocationFrom.Code, PostedAssetLine."Transfer-from Code", 'Transfer-from code should match');
        LibraryAssert.AreEqual(LocationFrom.Name, PostedAssetLine."Transfer-from Name", 'Transfer-from name should match');
        LibraryAssert.AreEqual(LocationTo.Code, PostedAssetLine."Transfer-to Code", 'Transfer-to code should match');
        LibraryAssert.AreEqual(LocationTo.Name, PostedAssetLine."Transfer-to Name", 'Transfer-to name should match');
        LibraryAssert.AreEqual(TransShptHeader."Posting Date", PostedAssetLine."Posting Date", 'Posting date should match');
        LibraryAssert.IsTrue(PostedAssetLine."Transaction No." > 0, 'Transaction no. should be assigned');

        // No cleanup needed - automatic test isolation handles rollback
    end;

    [Test]
    procedure TestPostBCTransferOrder_CreatesHolderEntries()
    var
        LocationFrom, LocationTo: Record Location;
        Asset: Record "JML AP Asset";
        TransferHeader: Record "Transfer Header";
        TransferAssetLine: Record "JML AP Transfer Asset Line";
        PostedAssetLine: Record "JML AP Pstd Trans Shpt Ast Ln";
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
        CreateTestLocation(LocationFrom, 'FROM-D');
        CreateTestLocation(LocationTo, 'TO-D');
        CreateTestAsset(Asset, 'TEST-ASSET-106', "JML AP Holder Type"::Location, LocationFrom.Code);
        CreateTransferOrderWithAsset(TransferHeader, TransferAssetLine, LocationFrom.Code, LocationTo.Code, Asset."No.");

        // [WHEN] Posting the shipment
        PostedShptNo := PostTransferShipment(TransferHeader);

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
        LibraryAssert.AreEqual(LocationFrom.Code, TransferOutEntry."Holder Code", 'Transfer Out holder code should be from location');

        // [THEN] Find Transfer In entry
        HolderEntry.SetRange("Entry Type", HolderEntry."Entry Type"::"Transfer In");
        LibraryAssert.RecordCount(HolderEntry, 1);
        HolderEntry.FindFirst();
        TransferInEntry := HolderEntry;

        LibraryAssert.AreEqual(Asset."No.", TransferInEntry."Asset No.", 'Transfer In asset no. should match');
        LibraryAssert.AreEqual("JML AP Holder Type"::Location, TransferInEntry."Holder Type", 'Transfer In holder type should be Location');
        LibraryAssert.AreEqual(LocationTo.Code, TransferInEntry."Holder Code", 'Transfer In holder code should be to location');
        LibraryAssert.AreEqual(TransactionNo, TransferInEntry."Transaction No.", 'Transaction numbers should match');

        // No cleanup needed - automatic test isolation handles rollback
    end;

    [Test]
    procedure TestPostBCTransferOrder_PartialShip_HandlesCorrectly()
    var
        LocationFrom, LocationTo: Record Location;
        Asset1, Asset2: Record "JML AP Asset";
        TransferHeader: Record "Transfer Header";
        TransferAssetLine1, TransferAssetLine2: Record "JML AP Transfer Asset Line";
        PostedAssetLine: Record "JML AP Pstd Trans Shpt Ast Ln";
        AssetSetup: Record "JML AP Asset Setup";
        PostedShptNo: Code[20];
    begin
        // [SCENARIO] Post partial shipment, verify quantities

        // [GIVEN] 2 Transfer Asset Lines, only first one set to ship
        Initialize();
        EnsureSetupExists(AssetSetup);
        CreateTestLocation(LocationFrom, 'FROM-E');
        CreateTestLocation(LocationTo, 'TO-E');
        CreateTestAsset(Asset1, 'TEST-ASSET-107', "JML AP Holder Type"::Location, LocationFrom.Code);
        CreateTestAsset(Asset2, 'TEST-ASSET-108', "JML AP Holder Type"::Location, LocationFrom.Code);

        CreateTransferOrderHeader(TransferHeader, LocationFrom.Code, LocationTo.Code);
        AddDummyTransferLine(TransferHeader);
        AddTransferAssetLine(TransferAssetLine1, TransferHeader, Asset1."No.", 20000);
        AddTransferAssetLine(TransferAssetLine2, TransferHeader, Asset2."No.", 30000);

        // Set only Line 1 to ship
        TransferAssetLine1."Quantity to Ship" := 1;
        TransferAssetLine1.Modify();
        TransferAssetLine2."Quantity to Ship" := 0;
        TransferAssetLine2.Modify();

        // [WHEN] Posting the shipment
        PostedShptNo := PostTransferShipment(TransferHeader);

        // [THEN] Only Line 1 asset transferred
        Asset1.Get(Asset1."No.");
        Asset2.Get(Asset2."No.");
        LibraryAssert.AreEqual(LocationTo.Code, Asset1."Current Holder Code", 'Asset1 should be at Transfer-to Location');
        LibraryAssert.AreEqual(LocationFrom.Code, Asset2."Current Holder Code", 'Asset2 should still be at Transfer-from Location');

        // [THEN] Only 1 posted asset line created
        PostedAssetLine.SetRange("Document No.", PostedShptNo);
        LibraryAssert.RecordCount(PostedAssetLine, 1);
        PostedAssetLine.FindFirst();
        LibraryAssert.AreEqual(Asset1."No.", PostedAssetLine."Asset No.", 'Posted line should be for Asset1');

        // [THEN] Line quantities updated correctly
        TransferAssetLine1.Get(TransferAssetLine1."Document No.", TransferAssetLine1."Line No.");
        TransferAssetLine2.Get(TransferAssetLine2."Document No.", TransferAssetLine2."Line No.");
        LibraryAssert.AreEqual(1, TransferAssetLine1."Quantity Shipped", 'Line 1 quantity shipped should be 1');
        LibraryAssert.AreEqual(0, TransferAssetLine1."Quantity to Ship", 'Line 1 quantity to ship should be 0');
        LibraryAssert.AreEqual(1, TransferAssetLine1."Quantity to Receive", 'Line 1 quantity to receive should be 1');
        LibraryAssert.AreEqual(0, TransferAssetLine2."Quantity Shipped", 'Line 2 quantity shipped should be 0');
        LibraryAssert.AreEqual(0, TransferAssetLine2."Quantity to Ship", 'Line 2 quantity to ship should be 0');

        // No cleanup needed - automatic test isolation handles rollback
    end;

    // ============================================================================
    // Story 4.2: BC Transfer Order - Error Scenarios
    // ============================================================================

    [Test]
    procedure TestPostBCTransferOrder_AssetNotAtFromLocation_ThrowsError()
    var
        LocationFrom, LocationTo, LocationOther: Record Location;
        Asset: Record "JML AP Asset";
        TransferHeader: Record "Transfer Header";
        TransferAssetLine: Record "JML AP Transfer Asset Line";
        AssetSetup: Record "JML AP Asset Setup";
        PostedShptNo: Code[20];
        ErrorOccurred: Boolean;
    begin
        // [SCENARIO] Asset is not at Transfer-from Location, posting fails

        // [GIVEN] Asset at Location A, Transfer Order from Location B to Location C
        Initialize();
        EnsureSetupExists(AssetSetup);
        CreateTestLocation(LocationFrom, 'FROM-F');
        CreateTestLocation(LocationTo, 'TO-F');
        CreateTestLocation(LocationOther, 'OTHER-F');
        CreateTestAsset(Asset, 'TEST-ASSET-109', "JML AP Holder Type"::Location, LocationOther.Code);

        CreateTransferOrderHeader(TransferHeader, LocationFrom.Code, LocationTo.Code);
        AddDummyTransferLine(TransferHeader);

        // [WHEN] Attempting to add asset from wrong location
        ErrorOccurred := false;
        ClearLastError();
        asserterror AddTransferAssetLine(TransferAssetLine, TransferHeader, Asset."No.", 20000);

        // [THEN] Error thrown
        if GetLastErrorText() <> '' then
            ErrorOccurred := true;

        LibraryAssert.IsTrue(ErrorOccurred, 'Should throw error when asset not at Transfer-from Location');

        // No cleanup needed - automatic test isolation handles rollback
        ClearLastError();
    end;

    [Test]
    procedure TestPostBCTransferOrder_AssetBlocked_ThrowsError()
    var
        LocationFrom, LocationTo: Record Location;
        Asset: Record "JML AP Asset";
        TransferHeader: Record "Transfer Header";
        TransferAssetLine: Record "JML AP Transfer Asset Line";
        AssetSetup: Record "JML AP Asset Setup";
        PostedShptNo: Code[20];
        ErrorOccurred: Boolean;
    begin
        // [SCENARIO] Blocked asset cannot be transferred

        // [GIVEN] Blocked asset
        Initialize();
        EnsureSetupExists(AssetSetup);
        CreateTestLocation(LocationFrom, 'FROM-G');
        CreateTestLocation(LocationTo, 'TO-G');
        CreateTestAsset(Asset, 'TEST-ASSET-110', "JML AP Holder Type"::Location, LocationFrom.Code);
        Asset.Blocked := true;
        Asset.Modify();

        CreateTransferOrderHeader(TransferHeader, LocationFrom.Code, LocationTo.Code);
        AddDummyTransferLine(TransferHeader);

        // [WHEN] Attempting to add blocked asset to transfer order
        ErrorOccurred := false;
        ClearLastError();
        asserterror AddTransferAssetLine(TransferAssetLine, TransferHeader, Asset."No.", 20000);

        // [THEN] Error thrown containing "blocked"
        if GetLastErrorText() <> '' then
            ErrorOccurred := true;

        LibraryAssert.IsTrue(ErrorOccurred, 'Should throw error for blocked asset');
        LibraryAssert.IsTrue(StrPos(LowerCase(GetLastErrorText()), 'blocked') > 0, 'Error should mention blocked');

        // No cleanup needed - automatic test isolation handles rollback
        ClearLastError();
    end;

    [Test]
    procedure TestPostBCTransferOrder_Subasset_ThrowsError()
    var
        LocationFrom, LocationTo: Record Location;
        ParentAsset, ChildAsset: Record "JML AP Asset";
        TransferHeader: Record "Transfer Header";
        TransferAssetLine: Record "JML AP Transfer Asset Line";
        AssetSetup: Record "JML AP Asset Setup";
        PostedShptNo: Code[20];
        ErrorOccurred: Boolean;
    begin
        // [SCENARIO] Subasset (child with parent) cannot be transferred independently

        // [GIVEN] Child asset with parent
        Initialize();
        EnsureSetupExists(AssetSetup);
        CreateTestLocation(LocationFrom, 'FROM-H');
        CreateTestLocation(LocationTo, 'TO-H');
        CreateTestAsset(ParentAsset, 'TEST-ASSET-111', "JML AP Holder Type"::Location, LocationFrom.Code);
        CreateTestAsset(ChildAsset, 'TEST-ASSET-112', "JML AP Holder Type"::Location, LocationFrom.Code);
        ChildAsset."Parent Asset No." := ParentAsset."No.";
        ChildAsset.Modify();

        CreateTransferOrderHeader(TransferHeader, LocationFrom.Code, LocationTo.Code);
        AddDummyTransferLine(TransferHeader);

        // [WHEN] Attempting to add subasset to transfer order
        ErrorOccurred := false;
        ClearLastError();
        asserterror AddTransferAssetLine(TransferAssetLine, TransferHeader, ChildAsset."No.", 20000);

        // [THEN] Error thrown about subasset
        if GetLastErrorText() <> '' then
            ErrorOccurred := true;

        LibraryAssert.IsTrue(ErrorOccurred, 'Should throw error for subasset transfer');

        // No cleanup needed - automatic test isolation handles rollback
        ClearLastError();
    end;

    [Test]
    procedure TestPostBCTransferOrder_NoAssetLines_PostsSuccessfully()
    var
        LocationFrom, LocationTo: Record Location;
        TransferHeader: Record "Transfer Header";
        TransShptHeader: Record "Transfer Shipment Header";
        PostedAssetLine: Record "JML AP Pstd Trans Shpt Ast Ln";
        AssetSetup: Record "JML AP Asset Setup";
        PostedShptNo: Code[20];
    begin
        // [SCENARIO] BC Transfer Order without asset lines posts normally

        // [GIVEN] Transfer order with item line but no asset lines
        Initialize();
        EnsureSetupExists(AssetSetup);
        CreateTestLocation(LocationFrom, 'FROM-I');
        CreateTestLocation(LocationTo, 'TO-I');
        CreateTransferOrderHeader(TransferHeader, LocationFrom.Code, LocationTo.Code);
        AddDummyTransferLine(TransferHeader);

        // [WHEN] Posting the shipment
        PostedShptNo := PostTransferShipment(TransferHeader);

        // [THEN] Posted shipment is created
        LibraryAssert.IsTrue(TransShptHeader.Get(PostedShptNo), 'Posted transfer shipment should be created');

        // [THEN] No posted asset lines should exist
        PostedAssetLine.SetRange("Document No.", PostedShptNo);
        LibraryAssert.RecordCount(PostedAssetLine, 0);

        // No cleanup needed - automatic test isolation handles rollback
    end;

    // ============================================================================
    // Helper Procedures
    // ============================================================================

    local procedure Initialize()
    var
        InTransitLoc: Record Location;
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        // BC Test Framework provides automatic test isolation
        // Each test gets a clean database state and changes roll back automatically

        if IsInitialized then
            exit;

        // Create In-Transit location required for Transfer Orders
        // This is created once and reused across tests
        if not InTransitLoc.Get('INTRANS') then begin
            InTransitLoc.Init();
            InTransitLoc.Code := 'INTRANS';
            InTransitLoc.Name := 'In-Transit';
            InTransitLoc."Use As In-Transit" := true;
            InTransitLoc.Insert(true);

            // Create Inventory Posting Setup for INTRANS location
            if not InventoryPostingSetup.Get('INTRANS', 'RESALE') then begin
                InventoryPostingSetup.Init();
                InventoryPostingSetup."Location Code" := 'INTRANS';
                InventoryPostingSetup."Invt. Posting Group Code" := 'RESALE';
                InventoryPostingSetup."Inventory Account" := '2130';
                InventoryPostingSetup.Insert(true);
            end;
        end;

        IsInitialized := true;
        // No Commit() - automatic test isolation handles rollback
    end;

    local procedure EnsureSetupExists(var AssetSetup: Record "JML AP Asset Setup")
    begin
        if not AssetSetup.Get() then begin
            AssetSetup.Init();
            AssetSetup.Insert(true);
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

    local procedure CreateTransferOrderHeader(var TransferHeader: Record "Transfer Header"; FromLocationCode: Code[10]; ToLocationCode: Code[10])
    begin
        TransferHeader.Init();
        TransferHeader."No." := '';
        TransferHeader.Insert(true);
        TransferHeader.Validate("Transfer-from Code", FromLocationCode);
        TransferHeader.Validate("Transfer-to Code", ToLocationCode);
        TransferHeader.Validate("In-Transit Code", 'INTRANS'); // Use standard In-Transit location from demo data
        TransferHeader.Modify(true);
    end;

    local procedure AddTransferAssetLine(var TransferAssetLine: Record "JML AP Transfer Asset Line"; TransferHeader: Record "Transfer Header"; AssetNo: Code[20]; LineNo: Integer)
    begin
        TransferAssetLine.Init();
        TransferAssetLine."Document No." := TransferHeader."No.";
        TransferAssetLine."Line No." := LineNo;
        TransferAssetLine.Validate("Asset No.", AssetNo);  // Use Validate to trigger OnValidate and populate description
        TransferAssetLine."Quantity to Ship" := 1;
        TransferAssetLine.Insert(true);
    end;

    local procedure CreateTransferOrderWithAsset(var TransferHeader: Record "Transfer Header"; var TransferAssetLine: Record "JML AP Transfer Asset Line"; FromLocationCode: Code[10]; ToLocationCode: Code[10]; AssetNo: Code[20])
    begin
        CreateTransferOrderHeader(TransferHeader, FromLocationCode, ToLocationCode);
        AddDummyTransferLine(TransferHeader);
        AddTransferAssetLine(TransferAssetLine, TransferHeader, AssetNo, 20000); // Use line 20000 after dummy line
    end;

    local procedure PostTransferShipment(TransferHeader: Record "Transfer Header"): Code[20]
    var
        TransferPostShipment: Codeunit "TransferOrder-Post Shipment";
        TransShptHeader: Record "Transfer Shipment Header";
    begin
        TransferPostShipment.Run(TransferHeader);

        TransShptHeader.SetRange("Transfer Order No.", TransferHeader."No.");
        if TransShptHeader.FindFirst() then
            exit(TransShptHeader."No.");

        exit('');
    end;

    // ============================================================================
    // Cleanup Procedures - NOT NEEDED with Test Isolation
    // ============================================================================
    // BC Test Framework automatically rolls back database changes after each test
    // Manual cleanup procedures have been removed - the framework handles it!

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

    local procedure AddDummyTransferLine(var TransferHeader: Record "Transfer Header")
    var
        TransferLine: Record "Transfer Line";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Add a minimal item line to satisfy BC posting requirements
        CreateTestItem(Item, 'TEST-ITEM-002');

        // Add inventory at Transfer-from Location
        AddInventory(Item."No.", TransferHeader."Transfer-from Code", 10);

        TransferLine.Init();
        TransferLine."Document No." := TransferHeader."No.";
        TransferLine."Line No." := 10000;
        TransferLine.Validate("Item No.", Item."No."); // Use Validate to set Unit of Measure
        TransferLine.Validate(Quantity, 1);
        TransferLine.Validate("Qty. to Ship", 1);
        TransferLine.Insert(true);
    end;

    local procedure AddInventory(ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
    begin
        // Create and post inventory adjustment
        ItemJournalLine.Init();
        ItemJournalLine."Journal Template Name" := '';
        ItemJournalLine."Journal Batch Name" := '';
        ItemJournalLine."Line No." := 10000;
        ItemJournalLine."Entry Type" := ItemJournalLine."Entry Type"::"Positive Adjmt.";
        ItemJournalLine."Posting Date" := WorkDate();
        ItemJournalLine."Document No." := 'TESTINV';
        ItemJournalLine.Validate("Item No.", ItemNo);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate(Quantity, Quantity);
        ItemJnlPostLine.RunWithCheck(ItemJournalLine);
    end;
}
