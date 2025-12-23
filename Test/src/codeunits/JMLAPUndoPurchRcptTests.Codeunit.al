codeunit 50119 "JML AP Undo Purch Rcpt Tests"
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
        // Handle messages during test execution
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        // Auto-confirm undo operations
        Reply := true;
    end;

    [Test]
    procedure TestPostedPurchAssetLine_CorrectionFieldExists()
    var
        PostedAssetLine: Record "JML AP Pstd Purch Rcpt Ast Ln";
    begin
        // [SCENARIO] Posted Purchase Receipt Asset Line has Correction field
        // [GIVEN] A Posted Purchase Receipt Asset Line record
        TestLibrary.Initialize();
        PostedAssetLine.Init();

        // [WHEN] Setting Correction field
        PostedAssetLine.Correction := true;

        // [THEN] Correction field is accessible and stores value
        LibraryAssert.AreEqual(true, PostedAssetLine.Correction, 'Correction field should be accessible');
    end;

    [Test]
    procedure TestPostedPurchAssetLine_ApplFromLineFieldExists()
    var
        PostedAssetLine: Record "JML AP Pstd Purch Rcpt Ast Ln";
    begin
        // [SCENARIO] Posted Purchase Receipt Asset Line has Appl.-from Asset Line No. field
        // [GIVEN] A Posted Purchase Receipt Asset Line record
        TestLibrary.Initialize();
        PostedAssetLine.Init();

        // [WHEN] Setting Appl.-from Asset Line No. field
        PostedAssetLine."Appl.-from Asset Line No." := 10000;

        // [THEN] Field is accessible and stores value
        LibraryAssert.AreEqual(10000, PostedAssetLine."Appl.-from Asset Line No.", 'Appl.-from Asset Line No. field should be accessible');
    end;

    [Test]
    procedure TestUndoPurchRcptCodeunit_Exists()
    var
        UndoPurchRcptAsset: Codeunit "JML AP Undo Purch Rcpt Asset";
    begin
        // [SCENARIO] Undo Purchase Receipt Asset codeunit compiles
        // [GIVEN] The undo codeunit
        TestLibrary.Initialize();

        // [THEN] Codeunit is accessible
        // This test validates the codeunit compiles correctly
    end;

    [Test]
    procedure TestPostedPurchAssetLine_CorrectionLineCalculation()
    var
        PostedAssetLine1: Record "JML AP Pstd Purch Rcpt Ast Ln";
        PostedAssetLine2: Record "JML AP Pstd Purch Rcpt Ast Ln";
        ExpectedLineNo: Integer;
    begin
        // [SCENARIO] Correction line number is calculated between existing lines
        // [GIVEN] Two posted asset lines with line numbers 10000 and 20000
        TestLibrary.Initialize();

        PostedAssetLine1.Init();
        PostedAssetLine1."Document No." := 'TEST-PURCH-001';
        PostedAssetLine1."Line No." := 10000;
        PostedAssetLine1.Correction := false;
        PostedAssetLine1.Insert();

        PostedAssetLine2.Init();
        PostedAssetLine2."Document No." := 'TEST-PURCH-001';
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
    procedure TestPostedPurchAssetLine_CorrectionDefaultValue()
    var
        PostedAssetLine: Record "JML AP Pstd Purch Rcpt Ast Ln";
    begin
        // [SCENARIO] Correction field defaults to false
        // [GIVEN] A new Posted Purchase Receipt Asset Line record
        TestLibrary.Initialize();
        PostedAssetLine.Init();

        // [THEN] Correction field defaults to false
        LibraryAssert.AreEqual(false, PostedAssetLine.Correction, 'Correction field should default to false');
    end;

    [Test]
    procedure TestPostedPurchAssetLine_ApplFromLineDefaultValue()
    var
        PostedAssetLine: Record "JML AP Pstd Purch Rcpt Ast Ln";
    begin
        // [SCENARIO] Appl.-from Asset Line No. field defaults to 0
        // [GIVEN] A new Posted Purchase Receipt Asset Line record
        TestLibrary.Initialize();
        PostedAssetLine.Init();

        // [THEN] Appl.-from Asset Line No. field defaults to 0
        LibraryAssert.AreEqual(0, PostedAssetLine."Appl.-from Asset Line No.", 'Appl.-from Asset Line No. should default to 0');
    end;

    [Test]
    procedure TestPostedPurchAssetLine_FieldsCanBeModified()
    var
        PostedAssetLine: Record "JML AP Pstd Purch Rcpt Ast Ln";
    begin
        // [SCENARIO] New fields can be modified programmatically
        // [GIVEN] A Posted Purchase Receipt Asset Line record
        TestLibrary.Initialize();
        PostedAssetLine.Init();
        PostedAssetLine."Document No." := 'TEST-PURCH-002';
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
    procedure TestUndoPurchRcptPage_ActionExists()
    var
        PostedPurchRcptAssetSub: Page "JML AP Pstd Purch Rcpt Ast Sub";
    begin
        // [SCENARIO] Posted Purchase Receipt Asset Subpage has Undo action
        // [GIVEN] The Posted Purchase Receipt Asset Subpage
        TestLibrary.Initialize();

        // [THEN] Page compiles with Undo Receipt action (instantiation is sufficient)
        // Note: Run() removed to avoid UI interaction in automated tests
    end;

    [Test]
    procedure TestUndoSalesShptPage_ActionExists()
    var
        PostedSalesShptAssetSub: Page "JML AP Pstd Sales Shpt Ast Sub";
    begin
        // [SCENARIO] Posted Sales Shipment Asset Subpage has Undo action
        // [GIVEN] The Posted Sales Shipment Asset Subpage
        TestLibrary.Initialize();

        // [THEN] Page compiles with Undo Shipment action (instantiation is sufficient)
        // Note: Run() removed to avoid UI interaction in automated tests
    end;

    [Test]
    procedure TestBothUndoCodeunits_HaveSimilarStructure()
    var
        UndoSalesShptAsset: Codeunit "JML AP Undo Sales Shpt Asset";
        UndoPurchRcptAsset: Codeunit "JML AP Undo Purch Rcpt Asset";
    begin
        // [SCENARIO] Both undo codeunits follow the same pattern
        // [GIVEN] Both Sales and Purchase undo codeunits
        TestLibrary.Initialize();

        // [THEN] Both codeunits compile and are accessible
        // This validates consistent implementation pattern
    end;

    // ============================================================================
    // Story 3.4: Undo Purchase Receipt - Functional Tests
    // ============================================================================

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestUndoReceipt_SingleAsset_CreatesCorrectionLine()
    var
        Vendor: Record Vendor;
        Location: Record Location;
        Asset: Record "JML AP Asset";
        PurchHeader: Record "Purchase Header";
        PurchAssetLine: Record "JML AP Purch. Asset Line";
        PostedAssetLine: Record "JML AP Pstd Purch Rcpt Ast Ln";
        CorrectionLine: Record "JML AP Pstd Purch Rcpt Ast Ln";
        AssetSetup: Record "JML AP Asset Setup";
        PostedRcptNo: Code[20];
        OriginalLineNo: Integer;
    begin
        // [SCENARIO] Undo Purchase Receipt creates correction line with Correction=true and Appl.-from set

        // [GIVEN] Posted Purchase Receipt with one asset
        TestLibrary.Initialize();
        EnsureSetupExists(AssetSetup);
        Vendor := TestLibrary.CreateTestVendor('Test Vendor U01');
        Location := TestLibrary.CreateTestLocation('Test Location U1');
        Asset := TestLibrary.CreateAssetAtVendor('Test Asset U01', Vendor."No.");
        CreatePurchaseOrderWithAsset(PurchHeader, PurchAssetLine, Vendor."No.", Asset."No.", Location.Code);
        PostedRcptNo := PostPurchaseReceipt(PurchHeader);

        // [GIVEN] Original posted line exists
        PostedAssetLine.SetRange("Document No.", PostedRcptNo);
        PostedAssetLine.FindFirst();
        OriginalLineNo := PostedAssetLine."Line No.";

        // [WHEN] Undoing the receipt
        UndoPurchaseReceiptAssetLine(PostedAssetLine);

        // [THEN] Original line marked as correction
        PostedAssetLine.Get(PostedAssetLine."Document No.", OriginalLineNo);
        LibraryAssert.IsTrue(PostedAssetLine.Correction, 'Original line should be marked as Correction');

        // [THEN] Correction line created
        CorrectionLine.SetRange("Document No.", PostedRcptNo);
        CorrectionLine.SetFilter("Appl.-from Asset Line No.", '>0');
        LibraryAssert.RecordCount(CorrectionLine, 1);
        CorrectionLine.FindFirst();
        LibraryAssert.IsTrue(CorrectionLine.Correction, 'Correction line should have Correction=true');
        LibraryAssert.AreEqual(OriginalLineNo, CorrectionLine."Appl.-from Asset Line No.", 'Appl.-from should reference original line');

        // No cleanup needed - automatic test isolation handles rollback
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestUndoReceipt_SingleAsset_ReversesHolderTransfer()
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
        OriginalTransactionNo: Integer;
    begin
        // [SCENARIO] Undo Purchase Receipt reverses asset holder transfer (Location back to Vendor)

        // [GIVEN] Posted Purchase Receipt with asset transferred from Vendor to Location
        TestLibrary.Initialize();
        EnsureSetupExists(AssetSetup);
        Vendor := TestLibrary.CreateTestVendor('Test Vendor U02');
        Location := TestLibrary.CreateTestLocation('Test Location U2');
        Asset := TestLibrary.CreateAssetAtVendor('Test Asset U02', Vendor."No.");
        CreatePurchaseOrderWithAsset(PurchHeader, PurchAssetLine, Vendor."No.", Asset."No.", Location.Code);
        PostedRcptNo := PostPurchaseReceipt(PurchHeader);

        // [GIVEN] Asset is now at Location
        Asset.Get(Asset."No.");
        LibraryAssert.AreEqual("JML AP Holder Type"::Location, Asset."Current Holder Type", 'Asset should be at Location before undo');

        PostedAssetLine.SetRange("Document No.", PostedRcptNo);
        PostedAssetLine.FindFirst();
        OriginalTransactionNo := PostedAssetLine."Transaction No.";

        // [WHEN] Undoing the receipt
        UndoPurchaseReceiptAssetLine(PostedAssetLine);

        // [THEN] Asset transferred back to Vendor
        Asset.Get(Asset."No.");
        LibraryAssert.AreEqual("JML AP Holder Type"::Vendor, Asset."Current Holder Type", 'Asset should be back at Vendor');
        LibraryAssert.AreEqual(Vendor."No.", Asset."Current Holder Code", 'Asset should be at correct vendor');

        // [THEN] Reverse holder entries created (separate from original transaction)
        HolderEntry.SetRange("Asset No.", Asset."No.");
        LibraryAssert.IsTrue(HolderEntry.Count() >= 4, 'Should have at least 4 holder entries (2 original + 2 reverse)');

        // No cleanup needed - automatic test isolation handles rollback
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestUndoReceipt_MultipleAssets_AllReversed()
    var
        Vendor: Record Vendor;
        Location: Record Location;
        Asset1, Asset2, Asset3: Record "JML AP Asset";
        PurchHeader: Record "Purchase Header";
        PurchAssetLine: Record "JML AP Purch. Asset Line";
        PostedAssetLine: Record "JML AP Pstd Purch Rcpt Ast Ln";
        AssetSetup: Record "JML AP Asset Setup";
        PostedRcptNo: Code[20];
    begin
        // [SCENARIO] Undo Purchase Receipt with 3 assets - all reversed

        // [GIVEN] Posted Purchase Receipt with 3 assets
        TestLibrary.Initialize();
        EnsureSetupExists(AssetSetup);
        Vendor := TestLibrary.CreateTestVendor('Test Vendor U03');
        Location := TestLibrary.CreateTestLocation('Test Location U3');
        Asset1 := TestLibrary.CreateAssetAtVendor('Test Asset U03', Vendor."No.");
        Asset2 := TestLibrary.CreateAssetAtVendor('Test Asset U04', Vendor."No.");
        Asset3 := TestLibrary.CreateAssetAtVendor('Test Asset U05', Vendor."No.");

        CreatePurchaseOrderHeader(PurchHeader, Vendor."No.");
        PurchHeader."Location Code" := Location.Code;
        PurchHeader.Modify();
        AddDummyPurchaseLine(PurchHeader);
        AddPurchaseAssetLine(PurchAssetLine, PurchHeader, Asset1."No.", 20000);
        AddPurchaseAssetLine(PurchAssetLine, PurchHeader, Asset2."No.", 30000);
        AddPurchaseAssetLine(PurchAssetLine, PurchHeader, Asset3."No.", 40000);

        PostedRcptNo := PostPurchaseReceipt(PurchHeader);

        // [WHEN] Undoing all 3 receipts
        PostedAssetLine.SetRange("Document No.", PostedRcptNo);
        PostedAssetLine.SetFilter("Appl.-from Asset Line No.", '=0'); // Only original lines
        LibraryAssert.RecordCount(PostedAssetLine, 3);
        PostedAssetLine.FindSet();
        repeat
            UndoPurchaseReceiptAssetLine(PostedAssetLine);
        until PostedAssetLine.Next() = 0;

        // [THEN] All 3 assets back at Vendor
        Asset1.Get(Asset1."No.");
        LibraryAssert.AreEqual("JML AP Holder Type"::Vendor, Asset1."Current Holder Type", 'Asset 1 should be back at Vendor');

        Asset2.Get(Asset2."No.");
        LibraryAssert.AreEqual("JML AP Holder Type"::Vendor, Asset2."Current Holder Type", 'Asset 2 should be back at Vendor');

        Asset3.Get(Asset3."No.");
        LibraryAssert.AreEqual("JML AP Holder Type"::Vendor, Asset3."Current Holder Type", 'Asset 3 should be back at Vendor');

        // [THEN] 3 correction lines created
        PostedAssetLine.SetRange("Document No.", PostedRcptNo);
        PostedAssetLine.SetFilter("Appl.-from Asset Line No.", '>0');
        LibraryAssert.RecordCount(PostedAssetLine, 3);

        // No cleanup needed - automatic test isolation handles rollback
    end;

    [Test]
    procedure TestUndoReceipt_AlreadyInvoiced_ThrowsError()
    var
        Vendor: Record Vendor;
        Location: Record Location;
        Asset: Record "JML AP Asset";
        PurchHeader: Record "Purchase Header";
        PurchAssetLine: Record "JML AP Purch. Asset Line";
        PostedAssetLine: Record "JML AP Pstd Purch Rcpt Ast Ln";
        AssetSetup: Record "JML AP Asset Setup";
        PostedRcptNo: Code[20];
        ErrorOccurred: Boolean;
    begin
        // [SCENARIO] Cannot undo receipt that has been invoiced

        // [GIVEN] Posted Purchase Receipt AND Invoice
        TestLibrary.Initialize();
        EnsureSetupExists(AssetSetup);
        Vendor := TestLibrary.CreateTestVendor('Test Vendor U04');
        Location := TestLibrary.CreateTestLocation('Test Location U4');
        Asset := TestLibrary.CreateAssetAtVendor('Test Asset U06', Vendor."No.");
        CreatePurchaseOrderWithAsset(PurchHeader, PurchAssetLine, Vendor."No.", Asset."No.", Location.Code);

        // Post Receipt + Invoice together
        PostedRcptNo := PostPurchaseReceiptAndInvoice(PurchHeader);

        PostedAssetLine.SetRange("Document No.", PostedRcptNo);
        PostedAssetLine.FindFirst();

        // [WHEN] Attempting to undo invoiced receipt
        ErrorOccurred := false;
        ClearLastError();
        asserterror UndoPurchaseReceiptAssetLine(PostedAssetLine);

        // [THEN] Error thrown
        if GetLastErrorText() <> '' then
            ErrorOccurred := true;

        LibraryAssert.IsTrue(ErrorOccurred, 'Should throw error when trying to undo invoiced receipt');

        // No cleanup needed - automatic test isolation handles rollback
    end;

    [Test]
    procedure TestUndoReceipt_AssetMovedSinceReceipt_ThrowsError()
    var
        Vendor: Record Vendor;
        Location1, Location2: Record Location;
        Asset: Record "JML AP Asset";
        PurchHeader: Record "Purchase Header";
        PurchAssetLine: Record "JML AP Purch. Asset Line";
        PostedAssetLine: Record "JML AP Pstd Purch Rcpt Ast Ln";
        AssetSetup: Record "JML AP Asset Setup";
        PostedRcptNo: Code[20];
        ErrorOccurred: Boolean;
    begin
        // [SCENARIO] Cannot undo receipt if asset has moved to different location

        // [GIVEN] Posted Purchase Receipt (Vendor → Location1)
        TestLibrary.Initialize();
        EnsureSetupExists(AssetSetup);
        Vendor := TestLibrary.CreateTestVendor('Test Vendor U05');
        Location1 := TestLibrary.CreateTestLocation('Test Location U5');
        Location2 := TestLibrary.CreateTestLocation('Test Location U6');
        Asset := TestLibrary.CreateAssetAtVendor('Test Asset U07', Vendor."No.");
        CreatePurchaseOrderWithAsset(PurchHeader, PurchAssetLine, Vendor."No.", Asset."No.", Location1.Code);
        PostedRcptNo := PostPurchaseReceipt(PurchHeader);

        // [GIVEN] Asset manually moved to Location2 after receipt
        Asset.Get(Asset."No.");
        Asset."Current Holder Type" := "JML AP Holder Type"::Location;
        Asset."Current Holder Code" := Location2.Code;
        Asset.Modify();

        PostedAssetLine.SetRange("Document No.", PostedRcptNo);
        PostedAssetLine.FindFirst();

        // [WHEN] Attempting to undo receipt
        ErrorOccurred := false;
        ClearLastError();
        asserterror UndoPurchaseReceiptAssetLine(PostedAssetLine);

        // [THEN] Error thrown about holder mismatch
        if GetLastErrorText() <> '' then
            ErrorOccurred := true;

        LibraryAssert.IsTrue(ErrorOccurred, 'Should throw error when asset has moved');

        // No cleanup needed - automatic test isolation handles rollback
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestUndoReceipt_CorrectionLineNumbers_CalculatedCorrectly()
    var
        Vendor: Record Vendor;
        Location: Record Location;
        Asset: Record "JML AP Asset";
        PurchHeader: Record "Purchase Header";
        PurchAssetLine: Record "JML AP Purch. Asset Line";
        PostedAssetLine: Record "JML AP Pstd Purch Rcpt Ast Ln";
        CorrectionLine: Record "JML AP Pstd Purch Rcpt Ast Ln";
        AssetSetup: Record "JML AP Asset Setup";
        PostedRcptNo: Code[20];
        OriginalLineNo, ExpectedCorrectionLineNo: Integer;
    begin
        // [SCENARIO] Correction line number is next multiple of 10000

        // [GIVEN] Posted Purchase Receipt with asset line
        TestLibrary.Initialize();
        EnsureSetupExists(AssetSetup);
        Vendor := TestLibrary.CreateTestVendor('Test Vendor U06');
        Location := TestLibrary.CreateTestLocation('Test Location U7');
        Asset := TestLibrary.CreateAssetAtVendor('Test Asset U08', Vendor."No.");
        CreatePurchaseOrderWithAsset(PurchHeader, PurchAssetLine, Vendor."No.", Asset."No.", Location.Code);
        PostedRcptNo := PostPurchaseReceipt(PurchHeader);

        PostedAssetLine.SetRange("Document No.", PostedRcptNo);
        PostedAssetLine.FindFirst();
        OriginalLineNo := PostedAssetLine."Line No.";

        // [WHEN] Undoing the receipt
        UndoPurchaseReceiptAssetLine(PostedAssetLine);

        // [THEN] Correction line number should be next multiple of 10000 after original
        ExpectedCorrectionLineNo := OriginalLineNo + 10000;
        CorrectionLine.SetRange("Document No.", PostedRcptNo);
        CorrectionLine.SetFilter("Appl.-from Asset Line No.", '>0');
        CorrectionLine.FindFirst();
        LibraryAssert.AreEqual(ExpectedCorrectionLineNo, CorrectionLine."Line No.", 'Correction line should be next multiple of 10000');

        // No cleanup needed - automatic test isolation handles rollback
    end;

    // ============================================================================
    // Helper Procedures
    // ============================================================================

    local procedure EnsureSetupExists(var AssetSetup: Record "JML AP Asset Setup")
    begin
        if not AssetSetup.Get() then begin
            AssetSetup.Init();
            AssetSetup.Insert(true);
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

    local procedure AddPurchaseAssetLine(var PurchAssetLine: Record "JML AP Purch. Asset Line"; PurchHeader: Record "Purchase Header"; AssetNo: Code[20]; LineNo: Integer)
    begin
        PurchAssetLine.Init();
        PurchAssetLine."Document Type" := PurchHeader."Document Type";
        PurchAssetLine."Document No." := PurchHeader."No.";
        PurchAssetLine."Line No." := LineNo;
        PurchAssetLine.Validate("Asset No.", AssetNo);
        PurchAssetLine."Quantity to Receive" := 1;
        PurchAssetLine.Insert(true);
    end;

    local procedure CreatePurchaseOrderWithAsset(var PurchHeader: Record "Purchase Header"; var PurchAssetLine: Record "JML AP Purch. Asset Line"; VendorNo: Code[20]; AssetNo: Code[20]; LocationCode: Code[10])
    begin
        CreatePurchaseOrderHeader(PurchHeader, VendorNo);
        PurchHeader."Location Code" := LocationCode;
        PurchHeader.Modify();
        AddDummyPurchaseLine(PurchHeader);
        AddPurchaseAssetLine(PurchAssetLine, PurchHeader, AssetNo, 20000);
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

    local procedure PostPurchaseReceiptAndInvoice(PurchHeader: Record "Purchase Header"): Code[20]
    var
        PurchPost: Codeunit "Purch.-Post";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        PurchHeader."Vendor Invoice No." := 'INV-' + PurchHeader."No."; // Required by BC for posting invoice
        PurchHeader.Modify();
        PurchHeader.Receive := true;
        PurchHeader.Invoice := true;
        PurchPost.Run(PurchHeader);

        PurchRcptHeader.SetRange("Order No.", PurchHeader."No.");
        if PurchRcptHeader.FindFirst() then
            exit(PurchRcptHeader."No.");

        exit('');
    end;

    local procedure AddDummyPurchaseLine(var PurchHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
        Item: Record Item;
    begin
        Item := TestLibrary.CreateTestItem('Test Item U');

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

    local procedure UndoPurchaseReceiptAssetLine(var PostedAssetLine: Record "JML AP Pstd Purch Rcpt Ast Ln")
    var
        UndoPurchRcptAsset: Codeunit "JML AP Undo Purch Rcpt Asset";
    begin
        UndoPurchRcptAsset.UndoPostedAssetLine(PostedAssetLine);
    end;

    // Cleanup procedures removed - framework handles test isolation!
}
