codeunit 50141 "JML AP Asset Count FB Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";

    [Test]
    procedure TestCustomerAssetCount()
    var
        Customer: Record Customer;
        Asset: Record "JML AP Asset";
        AssetCount: Integer;
    begin
        // [SCENARIO] Customer with assets shows correct count

        // [GIVEN] A customer with 2 assets
        CreateTestCustomer(Customer);
        CreateAssetAtCustomer(Asset, Customer."No.");
        CreateAssetAtCustomer(Asset, Customer."No.");

        // [WHEN] Counting assets at customer
        Asset.Reset();
        Asset.SetRange("Current Holder Type", Asset."Current Holder Type"::Customer);
        Asset.SetRange("Current Holder Code", Customer."No.");
        AssetCount := Asset.Count;

        // [THEN] Count is 2
        LibraryAssert.AreEqual(2, AssetCount, 'Should have 2 assets at customer');

        // Cleanup
        CleanupTestData(Customer."No.");
    end;

    [Test]
    procedure TestVendorAssetCount()
    var
        Vendor: Record Vendor;
        Asset: Record "JML AP Asset";
        AssetCount: Integer;
    begin
        // [SCENARIO] Vendor with assets shows correct count

        // [GIVEN] A vendor with 1 asset
        CreateTestVendor(Vendor);
        CreateAssetAtVendor(Asset, Vendor."No.");

        // [WHEN] Counting assets at vendor
        Asset.Reset();
        Asset.SetRange("Current Holder Type", Asset."Current Holder Type"::Vendor);
        Asset.SetRange("Current Holder Code", Vendor."No.");
        AssetCount := Asset.Count;

        // [THEN] Count is 1
        LibraryAssert.AreEqual(1, AssetCount, 'Should have 1 asset at vendor');

        // Cleanup
        CleanupTestDataVendor(Vendor."No.");
    end;

    [Test]
    procedure TestAssetStatusBreakdown()
    var
        Customer: Record Customer;
        Asset1: Record "JML AP Asset";
        Asset2: Record "JML AP Asset";
        ActiveCount: Integer;
        InactiveCount: Integer;
    begin
        // [SCENARIO] Status breakdown shows correct counts

        // [GIVEN] A customer with 1 active and 1 inactive asset
        CreateTestCustomer(Customer);
        CreateAssetAtCustomer(Asset1, Customer."No.");
        Asset1.Status := Asset1.Status::Active;
        Asset1.Modify(true);

        CreateAssetAtCustomer(Asset2, Customer."No.");
        Asset2.Status := Asset2.Status::Inactive;
        Asset2.Modify(true);

        // [WHEN] Counting by status
        Asset1.Reset();
        Asset1.SetRange("Current Holder Type", Asset1."Current Holder Type"::Customer);
        Asset1.SetRange("Current Holder Code", Customer."No.");
        Asset1.SetRange(Status, Asset1.Status::Active);
        ActiveCount := Asset1.Count;

        Asset2.Reset();
        Asset2.SetRange("Current Holder Type", Asset2."Current Holder Type"::Customer);
        Asset2.SetRange("Current Holder Code", Customer."No.");
        Asset2.SetRange(Status, Asset2.Status::Inactive);
        InactiveCount := Asset2.Count;

        // [THEN] Active count is 1, Inactive count is 1
        LibraryAssert.AreEqual(1, ActiveCount, 'Should have 1 active asset');
        LibraryAssert.AreEqual(1, InactiveCount, 'Should have 1 inactive asset');

        // Cleanup
        CleanupTestData(Customer."No.");
    end;

    [Test]
    procedure TestShipToAddressAssetCount()
    var
        Customer: Record Customer;
        ShipToAddr: Record "Ship-to Address";
        Asset: Record "JML AP Asset";
        AssetSetup: Record "JML AP Asset Setup";
        AssetCount: Integer;
    begin
        // [SCENARIO] Ship-to Address with assets shows correct count

        // [GIVEN] A ship-to address with 1 asset
        CreateTestCustomer(Customer);
        CreateTestShipToAddress(ShipToAddr, Customer."No.");

        // Ensure setup exists
        if not AssetSetup.Get() then begin
            AssetSetup.Init();
            AssetSetup.Insert(true);
        end;

        Asset.Init();
        Asset."No." := 'TEST-SHIPTO-' + Format(Random(99999));
        Asset.Description := 'Test Asset at Ship-to';
        Asset."Current Holder Type" := Asset."Current Holder Type"::Customer;
        Asset."Current Holder Code" := Customer."No.";
        Asset."Current Holder Addr Code" := ShipToAddr.Code;
        Asset.Insert(true);

        // [WHEN] Counting assets at ship-to address
        Asset.Reset();
        Asset.SetRange("Current Holder Type", Asset."Current Holder Type"::Customer);
        Asset.SetRange("Current Holder Code", Customer."No.");
        Asset.SetRange("Current Holder Addr Code", ShipToAddr.Code);
        AssetCount := Asset.Count;

        // [THEN] Count is 1
        LibraryAssert.AreEqual(1, AssetCount, 'Should have 1 asset at ship-to address');

        // Cleanup
        CleanupTestData(Customer."No.");
    end;

    local procedure CreateTestCustomer(var Customer: Record Customer)
    begin
        Customer.Init();
        Customer."No." := 'TEST-CUST-' + Format(Random(99999));
        Customer.Name := 'Test Customer';
        Customer.Insert(true);
    end;

    local procedure CreateTestVendor(var Vendor: Record Vendor)
    begin
        Vendor.Init();
        Vendor."No." := 'TEST-VEND-' + Format(Random(99999));
        Vendor.Name := 'Test Vendor';
        Vendor.Insert(true);
    end;

    local procedure CreateTestShipToAddress(var ShipToAddr: Record "Ship-to Address"; CustomerNo: Code[20])
    begin
        ShipToAddr.Init();
        ShipToAddr."Customer No." := CustomerNo;
        ShipToAddr.Code := 'TEST-' + Format(Random(9999));
        ShipToAddr.Name := 'Test Ship-to Address';
        ShipToAddr.Insert(true);
    end;

    local procedure CreateAssetAtCustomer(var Asset: Record "JML AP Asset"; CustomerNo: Code[20])
    var
        AssetSetup: Record "JML AP Asset Setup";
    begin
        // Ensure setup exists
        if not AssetSetup.Get() then begin
            AssetSetup.Init();
            AssetSetup.Insert(true);
        end;

        Asset.Init();
        Asset."No." := 'TEST-ASSET-' + Format(Random(99999));
        Asset.Description := 'Test Asset';
        Asset."Current Holder Type" := Asset."Current Holder Type"::Customer;
        Asset."Current Holder Code" := CustomerNo;
        Asset.Insert(true);
    end;

    local procedure CreateAssetAtVendor(var Asset: Record "JML AP Asset"; VendorNo: Code[20])
    var
        AssetSetup: Record "JML AP Asset Setup";
    begin
        // Ensure setup exists
        if not AssetSetup.Get() then begin
            AssetSetup.Init();
            AssetSetup.Insert(true);
        end;

        Asset.Init();
        Asset."No." := 'TEST-ASSET-' + Format(Random(99999));
        Asset.Description := 'Test Asset';
        Asset."Current Holder Type" := Asset."Current Holder Type"::Vendor;
        Asset."Current Holder Code" := VendorNo;
        Asset.Insert(true);
    end;

    local procedure CleanupTestData(CustomerNo: Code[20])
    var
        Customer: Record Customer;
        Asset: Record "JML AP Asset";
        ShipToAddr: Record "Ship-to Address";
    begin
        // Delete assets
        Asset.SetRange("Current Holder Code", CustomerNo);
        if not Asset.IsEmpty then
            Asset.DeleteAll(true);

        // Delete ship-to addresses
        ShipToAddr.SetRange("Customer No.", CustomerNo);
        if not ShipToAddr.IsEmpty then
            ShipToAddr.DeleteAll(true);

        // Delete customer
        if Customer.Get(CustomerNo) then
            Customer.Delete(true);
    end;

    local procedure CleanupTestDataVendor(VendorNo: Code[20])
    var
        Vendor: Record Vendor;
        Asset: Record "JML AP Asset";
    begin
        // Delete assets
        Asset.SetRange("Current Holder Code", VendorNo);
        if not Asset.IsEmpty then
            Asset.DeleteAll(true);

        // Delete vendor
        if Vendor.Get(VendorNo) then
            Vendor.Delete(true);
    end;
}
