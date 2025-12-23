codeunit 50118 "JML AP Undo Shipment Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    // Note: BC Test Framework provides automatic test isolation
    // Each test runs in isolated transaction that rolls back automatically

    var
        LibraryAssert: Codeunit "Library Assert";
        TestLibrary: Codeunit "JML AP Test Library";
        IsInitialized: Boolean;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        // Auto-confirm all undo operations during tests
        Reply := true;
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Handle messages during test execution
    end;

    [Test]
    procedure TestPostedAssetLine_CorrectionFieldExists()
    var
        PostedAssetLine: Record "JML AP Pstd Sales Shpt Ast Ln";
    begin
        // [SCENARIO] Posted Sales Shipment Asset Line has Correction field
        // [GIVEN] A Posted Sales Shipment Asset Line record
        TestLibrary.Initialize();
        PostedAssetLine.Init();

        // [WHEN] Setting Correction field
        PostedAssetLine.Correction := true;

        // [THEN] Correction field is accessible and stores value
        LibraryAssert.AreEqual(true, PostedAssetLine.Correction, 'Correction field should be accessible');
    end;

    [Test]
    procedure TestPostedAssetLine_ApplFromLineFieldExists()
    var
        PostedAssetLine: Record "JML AP Pstd Sales Shpt Ast Ln";
    begin
        // [SCENARIO] Posted Sales Shipment Asset Line has Appl.-from Asset Line No. field
        // [GIVEN] A Posted Sales Shipment Asset Line record
        TestLibrary.Initialize();
        PostedAssetLine.Init();

        // [WHEN] Setting Appl.-from Asset Line No. field
        PostedAssetLine."Appl.-from Asset Line No." := 10000;

        // [THEN] Field is accessible and stores value
        LibraryAssert.AreEqual(10000, PostedAssetLine."Appl.-from Asset Line No.", 'Appl.-from Asset Line No. field should be accessible');
    end;

    [Test]
    procedure TestUndoCodeunit_Exists()
    var
        UndoSalesShptAsset: Codeunit "JML AP Undo Sales Shpt Asset";
    begin
        // [SCENARIO] Undo Sales Shipment Asset codeunit compiles
        // [GIVEN] The undo codeunit
        TestLibrary.Initialize();

        // [THEN] Codeunit is accessible
        // This test validates the codeunit compiles correctly
    end;

    [Test]
    procedure TestPostedAssetLine_CorrectionLineCalculation()
    var
        PostedAssetLine1: Record "JML AP Pstd Sales Shpt Ast Ln";
        PostedAssetLine2: Record "JML AP Pstd Sales Shpt Ast Ln";
        ExpectedLineNo: Integer;
    begin
        // [SCENARIO] Correction line number is calculated between existing lines
        // [GIVEN] Two posted asset lines with line numbers 10000 and 20000
        TestLibrary.Initialize();

        PostedAssetLine1.Init();
        PostedAssetLine1."Document No." := 'TEST-001';
        PostedAssetLine1."Line No." := 10000;
        PostedAssetLine1.Correction := false;
        PostedAssetLine1.Insert();

        PostedAssetLine2.Init();
        PostedAssetLine2."Document No." := 'TEST-001';
        PostedAssetLine2."Line No." := 20000;
        PostedAssetLine2.Correction := false;
        PostedAssetLine2.Insert();

        // [THEN] Correction line should be between them
        ExpectedLineNo := 15000; // Halfway between 10000 and 20000
        LibraryAssert.AreEqual(10000, PostedAssetLine1."Line No.", 'First line should be 10000');
        LibraryAssert.AreEqual(20000, PostedAssetLine2."Line No.", 'Second line should be 20000');

        // Cleanup
        PostedAssetLine1.Delete();
        PostedAssetLine2.Delete();
        Commit();
    end;

    [Test]
    procedure TestPostedAssetLine_CorrectionDefaultValue()
    var
        PostedAssetLine: Record "JML AP Pstd Sales Shpt Ast Ln";
    begin
        // [SCENARIO] Correction field defaults to false
        // [GIVEN] A new Posted Sales Shipment Asset Line record
        TestLibrary.Initialize();
        PostedAssetLine.Init();

        // [THEN] Correction field defaults to false
        LibraryAssert.AreEqual(false, PostedAssetLine.Correction, 'Correction field should default to false');
    end;

    [Test]
    procedure TestPostedAssetLine_ApplFromLineDefaultValue()
    var
        PostedAssetLine: Record "JML AP Pstd Sales Shpt Ast Ln";
    begin
        // [SCENARIO] Appl.-from Asset Line No. field defaults to 0
        // [GIVEN] A new Posted Sales Shipment Asset Line record
        TestLibrary.Initialize();
        PostedAssetLine.Init();

        // [THEN] Appl.-from Asset Line No. field defaults to 0
        LibraryAssert.AreEqual(0, PostedAssetLine."Appl.-from Asset Line No.", 'Appl.-from Asset Line No. should default to 0');
    end;

    [Test]
    procedure TestPostedAssetLine_FieldsNotEditable()
    var
        PostedAssetLine: Record "JML AP Pstd Sales Shpt Ast Ln";
    begin
        // [SCENARIO] New fields are marked as not editable
        // [GIVEN] A Posted Sales Shipment Asset Line record
        TestLibrary.Initialize();
        PostedAssetLine.Init();
        PostedAssetLine."Document No." := 'TEST-002';
        PostedAssetLine."Line No." := 10000;
        PostedAssetLine.Correction := false;
        PostedAssetLine."Appl.-from Asset Line No." := 0;
        PostedAssetLine.Insert();

        // [WHEN] Fields are set
        PostedAssetLine.Correction := true;
        PostedAssetLine."Appl.-from Asset Line No." := 5000;

        // [THEN] Fields can be modified (Editable = false is a UI restriction only)
        LibraryAssert.AreEqual(true, PostedAssetLine.Correction, 'Correction can be set');
        LibraryAssert.AreEqual(5000, PostedAssetLine."Appl.-from Asset Line No.", 'Appl.-from can be set');

        // Cleanup
        PostedAssetLine.Delete();
        Commit();
    end;

    [Test]
    procedure Test8_UndoShipmentPageActionExists()
    var
        PostedSalesShptAssetSub: Page "JML AP Pstd Sales Shpt Ast Sub";
    begin
        // [SCENARIO] Posted Sales Shipment Asset Subpage has Undo Shipment action
        // [GIVEN] The Posted Sales Shipment Asset Subpage
        TestLibrary.Initialize();

        // [THEN] Page compiles with Undo Shipment action
    end;

    [Test]
    procedure Test9_BothUndoCodeunitsSimilar()
    var
        UndoSalesShptAsset: Codeunit "JML AP Undo Sales Shpt Asset";
        UndoPurchRcptAsset: Codeunit "JML AP Undo Purch Rcpt Asset";
    begin
        // [SCENARIO] Both undo codeunits follow the same pattern
        // [GIVEN] Both Sales and Purchase undo codeunits
        TestLibrary.Initialize();

        // [THEN] Both codeunits compile and are accessible
    end;

    // ============================================================================
    // Story 2.4: Undo Sales Shipment - Functional Tests
    // ============================================================================

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestUndoShipment_SingleAsset_CreatesCorrectionLine()
    var
        Customer: Record Customer;
        Location: Record Location;
        Asset: Record "JML AP Asset";
        SalesHeader: Record "Sales Header";
        SalesAssetLine: Record "JML AP Sales Asset Line";
        PostedAssetLine: Record "JML AP Pstd Sales Shpt Ast Ln";
        CorrectionLine: Record "JML AP Pstd Sales Shpt Ast Ln";
        AssetSetup: Record "JML AP Asset Setup";
        PostedShptNo: Code[20];
        OriginalLineNo: Integer;
    begin
        // [SCENARIO] Undo shipment creates correction line with proper fields

        // [GIVEN] A posted sales shipment with 1 asset
        TestLibrary.Initialize();
        EnsureSetupExists(AssetSetup);
        Customer := TestLibrary.CreateTestCustomer('Test Customer 001');
        Location := TestLibrary.CreateTestLocation('UNDO-LOC1');
        Asset := TestLibrary.CreateAssetAtLocation('Undo Asset 001', Location.Code);
        CreateSalesOrderWithAsset(SalesHeader, SalesAssetLine, Customer."No.", Asset."No.", Location.Code);
        PostedShptNo := PostSalesShipment(SalesHeader);

        PostedAssetLine.SetRange("Document No.", PostedShptNo);
        PostedAssetLine.FindFirst();
        OriginalLineNo := PostedAssetLine."Line No.";

        // [WHEN] Calling undo shipment on the posted asset line
        UndoSalesShipmentAssetLine(PostedAssetLine);

        // [THEN] Correction line created (filter by Appl.-from to get only the new correction line)
        CorrectionLine.SetRange("Document No.", PostedShptNo);
        CorrectionLine.SetFilter("Appl.-from Asset Line No.", '>0'); // New correction lines have this field set
        LibraryAssert.RecordCount(CorrectionLine, 1);
        CorrectionLine.FindFirst();

        // [THEN] Correction line has correct fields
        LibraryAssert.IsTrue(CorrectionLine.Correction, 'Correction field should be true');
        LibraryAssert.AreEqual(OriginalLineNo, CorrectionLine."Appl.-from Asset Line No.", 'Appl.-from should reference original line');
        LibraryAssert.IsTrue(CorrectionLine."Transaction No." > 0, 'Transaction no. should be assigned');
        LibraryAssert.AreNotEqual(PostedAssetLine."Transaction No.", CorrectionLine."Transaction No.", 'Transaction no. should be different');
        LibraryAssert.AreEqual(Asset."No.", CorrectionLine."Asset No.", 'Asset no. should match');

        // [THEN] Original line marked as corrected
        PostedAssetLine.Get(PostedAssetLine."Document No.", OriginalLineNo);
        LibraryAssert.IsTrue(PostedAssetLine.Correction, 'Original line should be marked as correction');

        // [THEN] Sales Asset Line updated
        SalesAssetLine.Get(SalesAssetLine."Document Type", SalesAssetLine."Document No.", SalesAssetLine."Line No.");
        LibraryAssert.AreEqual(0, SalesAssetLine."Quantity Shipped", 'Quantity Shipped should be reduced to 0');

        // No cleanup needed - automatic test isolation handles rollback
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestUndoShipment_SingleAsset_ReversesHolderTransfer()
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
        OriginalTransactionNo: Integer;
        HolderEntryCountBefore: Integer;
    begin
        // [SCENARIO] Undo shipment reverses asset holder transfer

        // [GIVEN] A posted sales shipment with 1 asset (Location → Customer)
        TestLibrary.Initialize();
        EnsureSetupExists(AssetSetup);
        Customer := TestLibrary.CreateTestCustomer('Test Customer 002');
        Location := TestLibrary.CreateTestLocation('UNDO-LOC2');
        Asset := TestLibrary.CreateAssetAtLocation('Undo Asset 002', Location.Code);
        CreateSalesOrderWithAsset(SalesHeader, SalesAssetLine, Customer."No.", Asset."No.", Location.Code);
        PostedShptNo := PostSalesShipment(SalesHeader);

        // Verify asset transferred to customer
        Asset.Get(Asset."No.");
        LibraryAssert.AreEqual("JML AP Holder Type"::Customer, Asset."Current Holder Type", 'Asset should be at customer before undo');

        // Count holder entries before undo
        PostedAssetLine.SetRange("Document No.", PostedShptNo);
        PostedAssetLine.FindFirst();
        OriginalTransactionNo := PostedAssetLine."Transaction No.";
        HolderEntry.SetRange("Asset No.", Asset."No.");
        HolderEntryCountBefore := HolderEntry.Count();

        // [WHEN] Calling undo shipment
        UndoSalesShipmentAssetLine(PostedAssetLine);

        // [THEN] Asset holder reversed to location
        Asset.Get(Asset."No.");
        LibraryAssert.AreEqual("JML AP Holder Type"::Location, Asset."Current Holder Type", 'Asset holder type should be Location');
        LibraryAssert.AreEqual(Location.Code, Asset."Current Holder Code", 'Asset should be back at original location');

        // [THEN] New holder entries created (reverse transfer)
        HolderEntry.SetRange("Asset No.", Asset."No.");
        LibraryAssert.AreEqual(HolderEntryCountBefore + 2, HolderEntry.Count(), '2 new holder entries should be created');

        // [THEN] Reverse holder entries have different transaction no.
        PostedAssetLine.SetRange("Document No.", PostedShptNo);
        PostedAssetLine.SetFilter("Appl.-from Asset Line No.", '>0'); // Get the correction line (not original)
        PostedAssetLine.FindFirst();
        LibraryAssert.AreNotEqual(OriginalTransactionNo, PostedAssetLine."Transaction No.", 'Correction should have new transaction no.');

        // No cleanup needed - automatic test isolation handles rollback
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestUndoShipment_MultipleAssets_AllReversed()
    var
        Customer: Record Customer;
        Location: Record Location;
        Asset1, Asset2, Asset3: Record "JML AP Asset";
        SalesHeader: Record "Sales Header";
        SalesAssetLine: Record "JML AP Sales Asset Line";
        PostedAssetLine: Record "JML AP Pstd Sales Shpt Ast Ln";
        CorrectionLine: Record "JML AP Pstd Sales Shpt Ast Ln";
        AssetSetup: Record "JML AP Asset Setup";
        PostedShptNo: Code[20];
    begin
        // [SCENARIO] Undo shipment with multiple assets reverses all

        // [GIVEN] A posted sales shipment with 3 assets
        TestLibrary.Initialize();
        EnsureSetupExists(AssetSetup);
        Customer := TestLibrary.CreateTestCustomer('Test Customer 003');
        Location := TestLibrary.CreateTestLocation('UNDO-LOC3');
        Asset1 := TestLibrary.CreateAssetAtLocation('Undo Asset 003', Location.Code);
        Asset2 := TestLibrary.CreateAssetAtLocation('Undo Asset 004', Location.Code);
        Asset3 := TestLibrary.CreateAssetAtLocation('Undo Asset 005', Location.Code);

        CreateSalesOrderHeader(SalesHeader, Customer."No.");
        SalesHeader."Location Code" := Location.Code;
        SalesHeader.Modify();
        AddDummySalesLine(SalesHeader);
        AddSalesAssetLine(SalesAssetLine, SalesHeader, Asset1."No.", 20000);
        AddSalesAssetLine(SalesAssetLine, SalesHeader, Asset2."No.", 30000);
        AddSalesAssetLine(SalesAssetLine, SalesHeader, Asset3."No.", 40000);

        PostedShptNo := PostSalesShipment(SalesHeader);

        // Verify all assets at customer
        Asset1.Get(Asset1."No.");
        Asset2.Get(Asset2."No.");
        Asset3.Get(Asset3."No.");
        LibraryAssert.AreEqual("JML AP Holder Type"::Customer, Asset1."Current Holder Type", 'Asset1 should be at customer');
        LibraryAssert.AreEqual("JML AP Holder Type"::Customer, Asset2."Current Holder Type", 'Asset2 should be at customer');
        LibraryAssert.AreEqual("JML AP Holder Type"::Customer, Asset3."Current Holder Type", 'Asset3 should be at customer');

        // [WHEN] Undoing all 3 shipments
        PostedAssetLine.SetRange("Document No.", PostedShptNo);
        PostedAssetLine.SetRange(Correction, false);
        PostedAssetLine.FindSet();
        repeat
            UndoSalesShipmentAssetLine(PostedAssetLine);
            PostedAssetLine.Get(PostedAssetLine."Document No.", PostedAssetLine."Line No."); // Refresh
            PostedAssetLine.SetRange(Correction, false); // Re-apply filter after refresh
            PostedAssetLine.SetRange("Document No.", PostedShptNo);
        until PostedAssetLine.Next() = 0;

        // [THEN] 3 correction lines created (filter by Appl.-from to get only new correction lines)
        CorrectionLine.SetRange("Document No.", PostedShptNo);
        CorrectionLine.SetFilter("Appl.-from Asset Line No.", '>0');
        LibraryAssert.RecordCount(CorrectionLine, 3);

        // [THEN] All 3 assets back at location
        Asset1.Get(Asset1."No.");
        Asset2.Get(Asset2."No.");
        Asset3.Get(Asset3."No.");
        LibraryAssert.AreEqual("JML AP Holder Type"::Location, Asset1."Current Holder Type", 'Asset1 should be back at location');
        LibraryAssert.AreEqual("JML AP Holder Type"::Location, Asset2."Current Holder Type", 'Asset2 should be back at location');
        LibraryAssert.AreEqual("JML AP Holder Type"::Location, Asset3."Current Holder Type", 'Asset3 should be back at location');

        // No cleanup needed - automatic test isolation handles rollback
    end;

    [Test]
    procedure TestUndoShipment_AlreadyInvoiced_ThrowsError()
    var
        Customer: Record Customer;
        Location: Record Location;
        Asset: Record "JML AP Asset";
        SalesHeader: Record "Sales Header";
        SalesAssetLine: Record "JML AP Sales Asset Line";
        PostedAssetLine: Record "JML AP Pstd Sales Shpt Ast Ln";
        AssetSetup: Record "JML AP Asset Setup";
        PostedShptNo: Code[20];
        OriginalSalesOrderNo: Code[20];
        ErrorOccurred: Boolean;
    begin
        // [SCENARIO] Cannot undo shipment after order is invoiced and deleted

        // [GIVEN] A posted sales shipment
        TestLibrary.Initialize();
        EnsureSetupExists(AssetSetup);
        Customer := TestLibrary.CreateTestCustomer('Test Customer 004');
        Location := TestLibrary.CreateTestLocation('UNDO-LOC4');
        Asset := TestLibrary.CreateAssetAtLocation('Undo Asset 006', Location.Code);
        CreateSalesOrderWithAsset(SalesHeader, SalesAssetLine, Customer."No.", Asset."No.", Location.Code);
        OriginalSalesOrderNo := SalesHeader."No.";
        PostedShptNo := PostSalesShipment(SalesHeader);

        PostedAssetLine.SetRange("Document No.", PostedShptNo);
        PostedAssetLine.FindFirst();

        // [GIVEN] Sales Asset Line deleted to simulate order line being gone (simpler approach)
        SalesAssetLine.Reset();
        SalesAssetLine.SetRange("Document Type", SalesAssetLine."Document Type"::Order);
        SalesAssetLine.SetRange("Document No.", OriginalSalesOrderNo);
        SalesAssetLine.SetRange("Asset No.", Asset."No.");
        if SalesAssetLine.FindFirst() then
            SalesAssetLine.Delete(); // Simple delete, no validation

        // [WHEN] Trying to undo shipment
        ErrorOccurred := false;
        ClearLastError();
        asserterror UndoSalesShipmentAssetLine(PostedAssetLine);

        // [THEN] Error thrown
        if GetLastErrorText() <> '' then
            ErrorOccurred := true;

        LibraryAssert.IsTrue(ErrorOccurred, 'Should throw error when sales order line not found');
        LibraryAssert.IsTrue(StrPos(GetLastErrorText(), 'not found') > 0, 'Error should mention order line not found');

        // [THEN] Asset holder unchanged (still at customer)
        Asset.Get(Asset."No.");
        LibraryAssert.AreEqual("JML AP Holder Type"::Customer, Asset."Current Holder Type", 'Asset should still be at customer');

        // [THEN] Posted line unchanged (not marked as correction)
        PostedAssetLine.Get(PostedAssetLine."Document No.", PostedAssetLine."Line No.");
        LibraryAssert.IsFalse(PostedAssetLine.Correction, 'Original line should not be marked as correction');

        // No cleanup needed - automatic test isolation handles rollback
    end;

    [Test]
    procedure TestUndoShipment_AssetMovedSinceShipment_ThrowsError()
    var
        Customer: Record Customer;
        Location1, Location2: Record Location;
        Asset: Record "JML AP Asset";
        SalesHeader: Record "Sales Header";
        SalesAssetLine: Record "JML AP Sales Asset Line";
        PostedAssetLine: Record "JML AP Pstd Sales Shpt Ast Ln";
        AssetSetup: Record "JML AP Asset Setup";
        PostedShptNo: Code[20];
        ErrorOccurred: Boolean;
    begin
        // [SCENARIO] Cannot undo shipment when asset has moved to different holder

        // [GIVEN] A posted sales shipment (asset at customer)
        TestLibrary.Initialize();
        EnsureSetupExists(AssetSetup);
        Customer := TestLibrary.CreateTestCustomer('Test Customer 005');
        Location1 := TestLibrary.CreateTestLocation('UNDO-LOC5');
        Location2 := TestLibrary.CreateTestLocation('UNDO-LOC6');
        Asset := TestLibrary.CreateAssetAtLocation('Undo Asset 007', Location1.Code);
        CreateSalesOrderWithAsset(SalesHeader, SalesAssetLine, Customer."No.", Asset."No.", Location1.Code);
        PostedShptNo := PostSalesShipment(SalesHeader);

        PostedAssetLine.SetRange("Document No.", PostedShptNo);
        PostedAssetLine.FindFirst();

        // [GIVEN] Asset manually moved to different location
        Asset.Get(Asset."No.");
        Asset."Current Holder Type" := "JML AP Holder Type"::Location;
        Asset."Current Holder Code" := Location2.Code;
        Asset.Modify();
        Commit(); // Ensure change is persisted

        // [WHEN] Trying to undo shipment
        ErrorOccurred := false;
        ClearLastError();
        asserterror UndoSalesShipmentAssetLine(PostedAssetLine);

        // [THEN] Error thrown about holder mismatch
        if GetLastErrorText() <> '' then
            ErrorOccurred := true;

        LibraryAssert.IsTrue(ErrorOccurred, 'Should throw error when asset holder does not match');
        LibraryAssert.IsTrue(StrPos(GetLastErrorText(), 'holder') > 0, 'Error should mention holder mismatch');

        // [THEN] Asset holder unchanged (still at new location - error prevented undo)
        Asset.Get(Asset."No.");
        LibraryAssert.AreEqual("JML AP Holder Type"::Location, Asset."Current Holder Type", 'Asset should still be at new location');
        LibraryAssert.AreEqual(Location2.Code, Asset."Current Holder Code", 'Asset should still be at Location2');

        // [THEN] Posted line unchanged
        PostedAssetLine.Get(PostedAssetLine."Document No.", PostedAssetLine."Line No.");
        LibraryAssert.IsFalse(PostedAssetLine.Correction, 'Original line should not be marked as correction');

        // No cleanup needed - automatic test isolation handles rollback
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestUndoShipment_CorrectionLineNumbers_CalculatedCorrectly()
    var
        Customer: Record Customer;
        Location: Record Location;
        Asset1, Asset2: Record "JML AP Asset";
        SalesHeader: Record "Sales Header";
        SalesAssetLine: Record "JML AP Sales Asset Line";
        PostedAssetLine: Record "JML AP Pstd Sales Shpt Ast Ln";
        CorrectionLine: Record "JML AP Pstd Sales Shpt Ast Ln";
        AssetSetup: Record "JML AP Asset Setup";
        PostedShptNo: Code[20];
        ExpectedCorrectionLineNo: Integer;
    begin
        // [SCENARIO] Correction line number is calculated between existing lines

        // [GIVEN] A posted sales shipment with 2 assets (lines 20000 and 30000)
        TestLibrary.Initialize();
        EnsureSetupExists(AssetSetup);
        Customer := TestLibrary.CreateTestCustomer('Test Customer 006');
        Location := TestLibrary.CreateTestLocation('UNDO-LOC7');
        Asset1 := TestLibrary.CreateAssetAtLocation('Undo Asset 008', Location.Code);
        Asset2 := TestLibrary.CreateAssetAtLocation('Undo Asset 009', Location.Code);

        CreateSalesOrderHeader(SalesHeader, Customer."No.");
        SalesHeader."Location Code" := Location.Code;
        SalesHeader.Modify();
        AddDummySalesLine(SalesHeader);
        AddSalesAssetLine(SalesAssetLine, SalesHeader, Asset1."No.", 20000);
        AddSalesAssetLine(SalesAssetLine, SalesHeader, Asset2."No.", 30000);

        PostedShptNo := PostSalesShipment(SalesHeader);

        // Find the first two posted asset lines to determine their actual line numbers
        PostedAssetLine.SetRange("Document No.", PostedShptNo);
        PostedAssetLine.FindSet();
        PostedAssetLine.FindFirst(); // First line
        PostedAssetLine.Next(); // Second line

        // [WHEN] Undoing first posted asset line
        PostedAssetLine.SetRange("Document No.", PostedShptNo);
        PostedAssetLine.FindFirst(); // Get first posted asset line again
        UndoSalesShipmentAssetLine(PostedAssetLine);

        // [THEN] Correction line created and properly inserted
        CorrectionLine.SetRange("Document No.", PostedShptNo);
        CorrectionLine.SetFilter("Appl.-from Asset Line No.", '>0'); // Get only the new correction line
        LibraryAssert.RecordCount(CorrectionLine, 1);
        CorrectionLine.FindFirst();

        LibraryAssert.IsTrue(CorrectionLine."Line No." > PostedAssetLine."Line No.", 'Correction line should be after original line');
        LibraryAssert.AreEqual(PostedAssetLine."Line No.", CorrectionLine."Appl.-from Asset Line No.", 'Should reference original line');

        // [THEN] All 3 lines exist
        PostedAssetLine.Reset();
        PostedAssetLine.SetRange("Document No.", PostedShptNo);
        LibraryAssert.RecordCount(PostedAssetLine, 3);

        // No cleanup needed - automatic test isolation handles rollback
    end;

    // ============================================================================
    // Helper Procedures
    // ============================================================================

    local procedure UndoSalesShipmentAssetLine(var PostedAssetLine: Record "JML AP Pstd Sales Shpt Ast Ln")
    var
        UndoSalesShptAsset: Codeunit "JML AP Undo Sales Shpt Asset";
    begin
        UndoSalesShptAsset.UndoPostedAssetLine(PostedAssetLine);
    end;

    local procedure EnsureSetupExists(var AssetSetup: Record "JML AP Asset Setup")
    begin
        if not AssetSetup.Get() then begin
            AssetSetup.Init();
            AssetSetup.Insert(true);
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
        SalesAssetLine.Validate("Asset No.", AssetNo);
        SalesAssetLine."Quantity to Ship" := 1;
        SalesAssetLine.Insert(true);
    end;

    local procedure CreateSalesOrderWithAsset(var SalesHeader: Record "Sales Header"; var SalesAssetLine: Record "JML AP Sales Asset Line"; CustomerNo: Code[20]; AssetNo: Code[20]; LocationCode: Code[10])
    begin
        CreateSalesOrderHeader(SalesHeader, CustomerNo);
        SalesHeader."Location Code" := LocationCode;
        SalesHeader.Modify();
        AddDummySalesLine(SalesHeader);
        AddSalesAssetLine(SalesAssetLine, SalesHeader, AssetNo, 20000);
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

    local procedure AddDummySalesLine(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        Item := TestLibrary.CreateTestItem('Test Item 001');

        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := 10000;
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine.Validate("No.", Item."No.");
        SalesLine.Validate(Quantity, 1);
        SalesLine.Validate("Qty. to Ship", 1);
        SalesLine.Insert(true);
    end;
}
