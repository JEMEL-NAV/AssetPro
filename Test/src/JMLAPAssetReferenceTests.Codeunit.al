codeunit 50142 "JML AP Asset Reference Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";

    [Test]
    procedure TestCreateReferenceWithBarcode()
    var
        Asset: Record "JML AP Asset";
        AssetRef: Record "JML AP Asset Reference";
    begin
        // [SCENARIO] Create asset reference with barcode

        // [GIVEN] An asset
        CreateTestAsset(Asset);

        // [WHEN] Creating a barcode reference
        AssetRef.Init();
        AssetRef."Asset No." := Asset."No.";
        AssetRef."Reference Type" := AssetRef."Reference Type"::Barcode;
        AssetRef."Reference No." := '123456789';
        AssetRef.Description := 'Test Barcode';
        AssetRef.Insert(true);

        // [THEN] Reference is created
        AssetRef.Get(Asset."No.", AssetRef."Reference Type"::Barcode, '', '123456789');
        LibraryAssert.AreEqual('123456789', AssetRef."Reference No.", 'Barcode should match');

        // Cleanup
        CleanupTestData(Asset."No.");
    end;

    [Test]
    procedure TestCreateReferenceWithCustomer()
    var
        Asset: Record "JML AP Asset";
        Customer: Record Customer;
        AssetRef: Record "JML AP Asset Reference";
    begin
        // [SCENARIO] Create asset reference with customer number

        // [GIVEN] An asset and a customer
        CreateTestAsset(Asset);
        CreateTestCustomer(Customer);

        // [WHEN] Creating a customer reference
        AssetRef.Init();
        AssetRef."Asset No." := Asset."No.";
        AssetRef."Reference Type" := AssetRef."Reference Type"::Customer;
        AssetRef."Reference Type No." := Customer."No.";
        AssetRef."Reference No." := 'CUST-ASSET-001';
        AssetRef.Description := 'Customer Asset Number';
        AssetRef.Insert(true);

        // [THEN] Reference is created with customer link
        AssetRef.Get(Asset."No.", AssetRef."Reference Type"::Customer, Customer."No.", 'CUST-ASSET-001');
        LibraryAssert.AreEqual(Customer."No.", AssetRef."Reference Type No.", 'Customer No. should match');

        // Cleanup
        CleanupTestData(Asset."No.");
        if Customer.Get(Customer."No.") then
            Customer.Delete(true);
    end;

    [Test]
    procedure TestLookupAssetByReference()
    var
        Asset: Record "JML AP Asset";
        AssetRef: Record "JML AP Asset Reference";
        FoundRef: Record "JML AP Asset Reference";
    begin
        // [SCENARIO] Lookup asset by reference number

        // [GIVEN] An asset with a reference
        CreateTestAsset(Asset);
        AssetRef.Init();
        AssetRef."Asset No." := Asset."No.";
        AssetRef."Reference Type" := AssetRef."Reference Type"::Barcode;
        AssetRef."Reference No." := 'LOOKUP-TEST-123';
        AssetRef.Insert(true);

        // [WHEN] Looking up by reference number
        FoundRef.SetRange("Reference No.", 'LOOKUP-TEST-123');
        FoundRef.FindFirst();

        // [THEN] Correct asset is found
        LibraryAssert.AreEqual(Asset."No.", FoundRef."Asset No.", 'Should find correct asset');

        // Cleanup
        CleanupTestData(Asset."No.");
    end;

    [Test]
    procedure TestDateValidation()
    var
        Asset: Record "JML AP Asset";
        AssetRef: Record "JML AP Asset Reference";
        ErrorOccurred: Boolean;
    begin
        // [SCENARIO] Ending date must be after starting date

        // [GIVEN] An asset
        CreateTestAsset(Asset);

        // [WHEN] Creating reference with ending date before starting date
        AssetRef.Init();
        AssetRef."Asset No." := Asset."No.";
        AssetRef."Reference Type" := AssetRef."Reference Type"::Barcode;
        AssetRef."Reference No." := 'DATE-TEST-123';
        AssetRef."Starting Date" := Today;
        AssetRef."Ending Date" := CalcDate('<-1D>', Today); // Yesterday

        ErrorOccurred := false;
        asserterror AssetRef.Insert(true);
        if GetLastErrorText <> '' then
            ErrorOccurred := true;

        // [THEN] Error occurs
        LibraryAssert.IsTrue(ErrorOccurred, 'Should error when ending date is before starting date');

        // Cleanup (if needed)
        ClearLastError();
        if Asset.Get(Asset."No.") then
            CleanupTestData(Asset."No.");
    end;

    [Test]
    procedure TestDeleteReference()
    var
        Asset: Record "JML AP Asset";
        AssetRef: Record "JML AP Asset Reference";
    begin
        // [SCENARIO] Delete asset reference

        // [GIVEN] An asset with a reference
        CreateTestAsset(Asset);
        AssetRef.Init();
        AssetRef."Asset No." := Asset."No.";
        AssetRef."Reference Type" := AssetRef."Reference Type"::Internal;
        AssetRef."Reference No." := 'DELETE-TEST-123';
        AssetRef.Insert(true);

        // [WHEN] Deleting the reference
        AssetRef.Delete(true);

        // [THEN] Reference no longer exists
        AssetRef.SetRange("Asset No.", Asset."No.");
        AssetRef.SetRange("Reference No.", 'DELETE-TEST-123');
        LibraryAssert.IsTrue(AssetRef.IsEmpty, 'Reference should be deleted');

        // Cleanup
        CleanupTestData(Asset."No.");
    end;

    local procedure CreateTestAsset(var Asset: Record "JML AP Asset")
    var
        AssetSetup: Record "JML AP Asset Setup";
    begin
        // Ensure setup exists
        if not AssetSetup.Get() then begin
            AssetSetup.Init();
            AssetSetup.Insert(true);
        end;

        Asset.Init();
        Asset."No." := 'TEST-REF-' + Format(Random(99999));
        Asset.Description := 'Test Asset for Reference Tests';
        Asset.Insert(true);
    end;

    local procedure CreateTestCustomer(var Customer: Record Customer)
    begin
        Customer.Init();
        Customer."No." := 'TEST-CUST-' + Format(Random(99999));
        Customer.Name := 'Test Customer';
        Customer.Insert(true);
    end;

    local procedure CleanupTestData(AssetNo: Code[20])
    var
        Asset: Record "JML AP Asset";
        AssetRef: Record "JML AP Asset Reference";
    begin
        // Delete references
        AssetRef.SetRange("Asset No.", AssetNo);
        if not AssetRef.IsEmpty then
            AssetRef.DeleteAll(true);

        // Delete asset
        if Asset.Get(AssetNo) then
            Asset.Delete(true);
    end;
}
