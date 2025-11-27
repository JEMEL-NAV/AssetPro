codeunit 50113 "JML AP Sales Integration Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";
        IsInitialized: Boolean;

    [Test]
    procedure TestSalesLine_AssetNoFieldExists()
    var
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO] Sales Line table has been extended with Asset No. field

        // [GIVEN] A Sales Line record
        Initialize();
        SalesLine.Init();

        // [THEN] Asset No. field is accessible
        SalesLine."JML AP Asset No." := 'TEST';
        LibraryAssert.AreEqual('TEST', SalesLine."JML AP Asset No.", 'Asset No. field should be accessible');
    end;

    [Test]
    procedure TestPostedSalesShipmentLine_AssetNoFieldExists()
    var
        SalesShptLine: Record "Sales Shipment Line";
    begin
        // [SCENARIO] Posted Sales Shipment Line table has been extended with Asset No. field

        // [GIVEN] A Sales Shipment Line record
        Initialize();
        SalesShptLine.Init();

        // [THEN] Asset No. field is accessible
        SalesShptLine."JML AP Asset No." := 'TEST';
        LibraryAssert.AreEqual('TEST', SalesShptLine."JML AP Asset No.", 'Asset No. field should be accessible');
    end;

    [Test]
    procedure TestPostedSalesInvoiceLine_AssetNoFieldExists()
    var
        SalesInvLine: Record "Sales Invoice Line";
    begin
        // [SCENARIO] Posted Sales Invoice Line table has been extended with Asset No. field

        // [GIVEN] A Sales Invoice Line record
        Initialize();
        SalesInvLine.Init();

        // [THEN] Asset No. field is accessible
        SalesInvLine."JML AP Asset No." := 'TEST';
        LibraryAssert.AreEqual('TEST', SalesInvLine."JML AP Asset No.", 'Asset No. field should be accessible');
    end;

    [Test]
    procedure TestPostedSalesCrMemoLine_AssetNoFieldExists()
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        // [SCENARIO] Posted Sales Credit Memo Line table has been extended with Asset No. field

        // [GIVEN] A Sales Cr.Memo Line record
        Initialize();
        SalesCrMemoLine.Init();

        // [THEN] Asset No. field is accessible
        SalesCrMemoLine."JML AP Asset No." := 'TEST';
        LibraryAssert.AreEqual('TEST', SalesCrMemoLine."JML AP Asset No.", 'Asset No. field should be accessible');
    end;

    [Test]
    procedure TestReturnReceiptLine_AssetNoFieldExists()
    var
        ReturnRcptLine: Record "Return Receipt Line";
    begin
        // [SCENARIO] Return Receipt Line table has been extended with Asset No. field

        // [GIVEN] A Return Receipt Line record
        Initialize();
        ReturnRcptLine.Init();

        // [THEN] Asset No. field is accessible
        ReturnRcptLine."JML AP Asset No." := 'TEST';
        LibraryAssert.AreEqual('TEST', ReturnRcptLine."JML AP Asset No.", 'Asset No. field should be accessible');
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
        Commit();
    end;
}
