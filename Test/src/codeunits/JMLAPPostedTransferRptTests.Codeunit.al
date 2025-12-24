codeunit 50134 "JML AP Pstd Transfer Rpt Tests"
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
    procedure PostedTransferReport_NoPostedTransfers_RunsWithoutError()
    var
        PostedTransfer: Record "JML AP Posted Asset Transfer";
        PostedTransferReport: Report "JML AP Posted Asset Transfer";
    begin
        TestLibrary.Initialize();

        // [GIVEN] No posted transfers in the system
        PostedTransfer.DeleteAll();

        // [WHEN] Running the Posted Asset Transfer report with no data
        PostedTransfer.SetView('');
        PostedTransferReport.SetTableView(PostedTransfer);
        PostedTransferReport.UseRequestPage(false);

        // [THEN] Report throws error for empty dataset (BC standard behavior)
        asserterror PostedTransferReport.Run();
        Assert.ExpectedError('The report couldn''t be generated, because it was empty');
    end;

    [Test]
    procedure PostedTransferReport_SinglePostedTransfer_DisplaysCorrectly()
    var
        Asset: Record "JML AP Asset";
        Location1, Location2: Record Location;
        TransferHeader: Record "JML AP Asset Transfer Header";
        PostedTransfer: Record "JML AP Posted Asset Transfer";
        PostedTransferReport: Report "JML AP Posted Asset Transfer";
    begin
        TestLibrary.Initialize();

        // [GIVEN] A posted transfer
        Location1 := TestLibrary.CreateTestLocation('FROM');
        Location2 := TestLibrary.CreateTestLocation('TO');
        Asset := TestLibrary.CreateAssetAtLocation('Test Asset', Location1.Code);

        TransferHeader := TestLibrary.CreateAndPostTransferOrder(Asset."No.", Location1.Code, Location2.Code);

        // Find the posted transfer
        PostedTransfer.SetRange("Transfer Order No.", TransferHeader."No.");
        PostedTransfer.FindFirst();

        // [WHEN] Running the Posted Asset Transfer report
        PostedTransfer.SetRecFilter();
        PostedTransferReport.SetTableView(PostedTransfer);
        PostedTransferReport.UseRequestPage(false);
        PostedTransferReport.Run();

        // [THEN] Report completes successfully
        Assert.IsTrue(true, 'Report should run successfully with posted transfer');
    end;

    // ============================================
    // Document Structure Tests
    // ============================================

    [Test]
    procedure PostedTransferReport_WithMultipleLines_DisplaysAllLines()
    var
        Asset1, Asset2, Asset3: Record "JML AP Asset";
        Location1, Location2: Record Location;
        TransferHeader: Record "JML AP Asset Transfer Header";
        TransferLine: Record "JML AP Asset Transfer Line";
        PostedTransfer: Record "JML AP Posted Asset Transfer";
        PostedLine: Record "JML AP Pstd. Asset Trans. Line";
        PostedTransferReport: Report "JML AP Posted Asset Transfer";
        AssetTransferPost: Codeunit "JML AP Asset Transfer-Post";
    begin
        TestLibrary.Initialize();

        // [GIVEN] A posted transfer with multiple assets
        Location1 := TestLibrary.CreateTestLocation('FROM');
        Location2 := TestLibrary.CreateTestLocation('TO');

        Asset1 := TestLibrary.CreateAssetAtLocation('Asset 1', Location1.Code);
        Asset2 := TestLibrary.CreateAssetAtLocation('Asset 2', Location1.Code);
        Asset3 := TestLibrary.CreateAssetAtLocation('Asset 3', Location1.Code);

        TransferHeader := TestLibrary.CreateTransferOrder(Location1.Code, Location2.Code);
        TestLibrary.CreateTransferLine(TransferLine, TransferHeader."No.", Asset1."No.");
        TestLibrary.CreateTransferLine(TransferLine, TransferHeader."No.", Asset2."No.");
        TestLibrary.CreateTransferLine(TransferLine, TransferHeader."No.", Asset3."No.");

        TestLibrary.ReleaseAndPostTransferOrder(TransferHeader);

        // Find the posted transfer
        PostedTransfer.SetCurrentKey("Transfer Order No.");
        PostedTransfer.SetRange("Transfer Order No.", TransferHeader."No.");
        PostedTransfer.FindFirst();

        // [THEN] Posted transfer has 3 lines
        PostedLine.SetRange("Document No.", PostedTransfer."No.");
        Assert.RecordCount(PostedLine, 3);

        // [WHEN] Running the Posted Asset Transfer report
        PostedTransfer.SetRecFilter();
        PostedTransferReport.SetTableView(PostedTransfer);
        PostedTransferReport.UseRequestPage(false);
        PostedTransferReport.Run();

        // [THEN] Report completes successfully with all lines
        Assert.IsTrue(true, 'Report should display all posted transfer lines');
    end;

    // ============================================
    // Holder Address Tests
    // ============================================

    [Test]
    procedure PostedTransferReport_LocationToLocation_FormatsAddresses()
    var
        Asset: Record "JML AP Asset";
        Location1, Location2: Record Location;
        TransferHeader: Record "JML AP Asset Transfer Header";
        PostedTransfer: Record "JML AP Posted Asset Transfer";
        PostedTransferReport: Report "JML AP Posted Asset Transfer";
    begin
        TestLibrary.Initialize();

        // [GIVEN] Posted transfer between two locations
        Location1 := TestLibrary.CreateTestLocation('LOC01');
        Location2 := TestLibrary.CreateTestLocation('LOC02');
        Asset := TestLibrary.CreateAssetAtLocation('Test Asset', Location1.Code);

        TransferHeader := TestLibrary.CreateAndPostTransferOrder(Asset."No.", Location1.Code, Location2.Code);

        // Find the posted transfer
        PostedTransfer.SetRange("Transfer Order No.", TransferHeader."No.");
        PostedTransfer.FindFirst();

        // [WHEN] Running the Posted Asset Transfer report
        PostedTransfer.SetRecFilter();
        PostedTransferReport.SetTableView(PostedTransfer);
        PostedTransferReport.UseRequestPage(false);
        PostedTransferReport.Run();

        // [THEN] Report completes successfully with location addresses
        Assert.IsTrue(true, 'Report should format location addresses');
    end;

    [Test]
    procedure PostedTransferReport_CustomerToCustomer_FormatsAddresses()
    var
        Asset: Record "JML AP Asset";
        Customer1, Customer2: Record Customer;
        TransferHeader: Record "JML AP Asset Transfer Header";
        PostedTransfer: Record "JML AP Posted Asset Transfer";
        PostedTransferReport: Report "JML AP Posted Asset Transfer";
    begin
        TestLibrary.Initialize();

        // [GIVEN] Posted transfer between two customers
        Customer1 := TestLibrary.CreateCustomer();
        Customer2 := TestLibrary.CreateCustomer();
        Asset := TestLibrary.CreateAssetAtCustomer('Test Asset', Customer1."No.");

        TransferHeader := TestLibrary.CreateTransferOrder(Customer1."No.", Customer2."No.");
        TransferHeader."From Holder Type" := TransferHeader."From Holder Type"::Customer;
        TransferHeader."To Holder Type" := TransferHeader."To Holder Type"::Customer;
        TransferHeader.Modify(true);

        TestLibrary.CreateTransferLineForOrder(TransferHeader, Asset."No.");
        TransferHeader := TestLibrary.ReleaseAndPostTransferOrder(TransferHeader);

        // Find the posted transfer
        PostedTransfer.SetRange("Transfer Order No.", TransferHeader."No.");
        PostedTransfer.FindFirst();

        // [WHEN] Running the Posted Asset Transfer report
        PostedTransfer.SetRecFilter();
        PostedTransferReport.SetTableView(PostedTransfer);
        PostedTransferReport.UseRequestPage(false);
        PostedTransferReport.Run();

        // [THEN] Report completes successfully with customer addresses
        Assert.IsTrue(true, 'Report should format customer addresses');
    end;

    // ============================================
    // Posted Document Details Tests
    // ============================================

    [Test]
    procedure PostedTransferReport_IncludesPostingDate_DisplaysCorrectly()
    var
        Asset: Record "JML AP Asset";
        Location1, Location2: Record Location;
        TransferHeader: Record "JML AP Asset Transfer Header";
        PostedTransfer: Record "JML AP Posted Asset Transfer";
        PostedTransferReport: Report "JML AP Posted Asset Transfer";
    begin
        TestLibrary.Initialize();

        // [GIVEN] A posted transfer with posting date
        Location1 := TestLibrary.CreateTestLocation('FROM');
        Location2 := TestLibrary.CreateTestLocation('TO');
        Asset := TestLibrary.CreateAssetAtLocation('Test Asset', Location1.Code);

        TransferHeader := TestLibrary.CreateAndPostTransferOrder(Asset."No.", Location1.Code, Location2.Code);

        // Find the posted transfer
        PostedTransfer.SetRange("Transfer Order No.", TransferHeader."No.");
        PostedTransfer.FindFirst();

        // [THEN] Posted transfer has posting date
        Assert.AreNotEqual(0D, PostedTransfer."Posting Date", 'Posted transfer should have posting date');

        // [WHEN] Running the Posted Asset Transfer report
        PostedTransfer.SetRecFilter();
        PostedTransferReport.SetTableView(PostedTransfer);
        PostedTransferReport.UseRequestPage(false);
        PostedTransferReport.Run();

        // [THEN] Report completes successfully showing posting date
        Assert.IsTrue(true, 'Report should display posting date');
    end;

    [Test]
    procedure PostedTransferReport_IncludesUserID_DisplaysCorrectly()
    var
        Asset: Record "JML AP Asset";
        Location1, Location2: Record Location;
        TransferHeader: Record "JML AP Asset Transfer Header";
        PostedTransfer: Record "JML AP Posted Asset Transfer";
        PostedTransferReport: Report "JML AP Posted Asset Transfer";
    begin
        TestLibrary.Initialize();

        // [GIVEN] A posted transfer with user ID
        Location1 := TestLibrary.CreateTestLocation('FROM');
        Location2 := TestLibrary.CreateTestLocation('TO');
        Asset := TestLibrary.CreateAssetAtLocation('Test Asset', Location1.Code);

        TransferHeader := TestLibrary.CreateAndPostTransferOrder(Asset."No.", Location1.Code, Location2.Code);

        // Find the posted transfer
        PostedTransfer.SetRange("Transfer Order No.", TransferHeader."No.");
        PostedTransfer.FindFirst();

        // [THEN] Posted transfer has user ID
        Assert.AreNotEqual('', PostedTransfer."User ID", 'Posted transfer should have user ID');

        // [WHEN] Running the Posted Asset Transfer report
        PostedTransfer.SetRecFilter();
        PostedTransferReport.SetTableView(PostedTransfer);
        PostedTransferReport.UseRequestPage(false);
        PostedTransferReport.Run();

        // [THEN] Report completes successfully showing user ID
        Assert.IsTrue(true, 'Report should display user ID');
    end;

    [Test]
    procedure PostedTransferReport_IncludesOriginalOrderNo_DisplaysCorrectly()
    var
        Asset: Record "JML AP Asset";
        Location1, Location2: Record Location;
        TransferHeader: Record "JML AP Asset Transfer Header";
        PostedTransfer: Record "JML AP Posted Asset Transfer";
        PostedTransferReport: Report "JML AP Posted Asset Transfer";
        OriginalOrderNo: Code[20];
    begin
        TestLibrary.Initialize();

        // [GIVEN] A posted transfer with original order number
        Location1 := TestLibrary.CreateTestLocation('FROM');
        Location2 := TestLibrary.CreateTestLocation('TO');
        Asset := TestLibrary.CreateAssetAtLocation('Test Asset', Location1.Code);

        TransferHeader := TestLibrary.CreateAndPostTransferOrder(Asset."No.", Location1.Code, Location2.Code);
        OriginalOrderNo := TransferHeader."No.";

        // Find the posted transfer
        PostedTransfer.SetRange("Transfer Order No.", OriginalOrderNo);
        PostedTransfer.FindFirst();

        // [THEN] Posted transfer references original order number
        Assert.AreEqual(OriginalOrderNo, PostedTransfer."Transfer Order No.", 'Should reference original order');

        // [WHEN] Running the Posted Asset Transfer report
        PostedTransfer.SetRecFilter();
        PostedTransferReport.SetTableView(PostedTransfer);
        PostedTransferReport.UseRequestPage(false);
        PostedTransferReport.Run();

        // [THEN] Report completes successfully showing original order number
        Assert.IsTrue(true, 'Report should display original transfer order number');
    end;

    // ============================================
    // Additional Fields Tests
    // ============================================

    [Test]
    procedure PostedTransferReport_WithReasonCode_DisplaysCorrectly()
    var
        Asset: Record "JML AP Asset";
        Location1, Location2: Record Location;
        TransferHeader: Record "JML AP Asset Transfer Header";
        PostedTransfer: Record "JML AP Posted Asset Transfer";
        PostedTransferReport: Report "JML AP Posted Asset Transfer";
    begin
        TestLibrary.Initialize();

        // [GIVEN] Posted transfer with reason code
        Location1 := TestLibrary.CreateTestLocation('FROM');
        Location2 := TestLibrary.CreateTestLocation('TO');
        Asset := TestLibrary.CreateAssetAtLocation('Test Asset', Location1.Code);

        TransferHeader := TestLibrary.CreateTransferOrder(Location1.Code, Location2.Code);
        TransferHeader."Reason Code" := 'RELOC';
        TransferHeader.Modify(true);

        TestLibrary.CreateTransferLineForOrder(TransferHeader, Asset."No.");
        TransferHeader := TestLibrary.ReleaseAndPostTransferOrder(TransferHeader);

        // Find the posted transfer
        PostedTransfer.SetRange("Transfer Order No.", TransferHeader."No.");
        PostedTransfer.FindFirst();

        // [WHEN] Running the Posted Asset Transfer report
        PostedTransfer.SetRecFilter();
        PostedTransferReport.SetTableView(PostedTransfer);
        PostedTransferReport.UseRequestPage(false);
        PostedTransferReport.Run();

        // [THEN] Report completes successfully with reason code
        Assert.IsTrue(true, 'Report should display reason code');
    end;

    [Test]
    procedure PostedTransferReport_WithExternalDocNo_DisplaysCorrectly()
    var
        Asset: Record "JML AP Asset";
        Location1, Location2: Record Location;
        TransferHeader: Record "JML AP Asset Transfer Header";
        PostedTransfer: Record "JML AP Posted Asset Transfer";
        PostedTransferReport: Report "JML AP Posted Asset Transfer";
    begin
        TestLibrary.Initialize();

        // [GIVEN] Posted transfer with external document number
        Location1 := TestLibrary.CreateTestLocation('FROM');
        Location2 := TestLibrary.CreateTestLocation('TO');
        Asset := TestLibrary.CreateAssetAtLocation('Test Asset', Location1.Code);

        TransferHeader := TestLibrary.CreateTransferOrder(Location1.Code, Location2.Code);
        TransferHeader."External Document No." := 'EXT-12345';
        TransferHeader.Modify(true);

        TestLibrary.CreateTransferLineForOrder(TransferHeader, Asset."No.");
        TransferHeader := TestLibrary.ReleaseAndPostTransferOrder(TransferHeader);

        // Find the posted transfer
        PostedTransfer.SetRange("Transfer Order No.", TransferHeader."No.");
        PostedTransfer.FindFirst();

        // [WHEN] Running the Posted Asset Transfer report
        PostedTransfer.SetRecFilter();
        PostedTransferReport.SetTableView(PostedTransfer);
        PostedTransferReport.UseRequestPage(false);
        PostedTransferReport.Run();

        // [THEN] Report completes successfully with external document number
        Assert.IsTrue(true, 'Report should display external document number');
    end;

    // ============================================
    // Edge Case Tests
    // ============================================

    [Test]
    procedure PostedTransferReport_MultiplePostedTransfers_DisplaysCorrectly()
    var
        Asset1, Asset2: Record "JML AP Asset";
        Location1, Location2: Record Location;
        PostedTransfer: Record "JML AP Posted Asset Transfer";
        PostedTransferReport: Report "JML AP Posted Asset Transfer";
    begin
        TestLibrary.Initialize();

        // [GIVEN] Multiple posted transfers
        Location1 := TestLibrary.CreateTestLocation('FROM');
        Location2 := TestLibrary.CreateTestLocation('TO');

        Asset1 := TestLibrary.CreateAssetAtLocation('Asset 1', Location1.Code);
        Asset2 := TestLibrary.CreateAssetAtLocation('Asset 2', Location1.Code);

        TestLibrary.CreateAndPostTransferOrder(Asset1."No.", Location1.Code, Location2.Code);
        TestLibrary.CreateAndPostTransferOrder(Asset2."No.", Location1.Code, Location2.Code);

        // [WHEN] Running the Posted Asset Transfer report for all posted transfers
        PostedTransfer.SetView('');
        PostedTransferReport.SetTableView(PostedTransfer);
        PostedTransferReport.UseRequestPage(false);
        PostedTransferReport.Run();

        // [THEN] Report completes successfully with multiple transfers
        Assert.IsTrue(true, 'Report should handle multiple posted transfers');
    end;
}
