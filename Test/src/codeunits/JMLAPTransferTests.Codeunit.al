codeunit 50105 "JML AP Transfer Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        IsInitialized: Boolean;

    [Test]
    procedure Test_TransferAssetLocationToCustomer()
    var
        Asset: Record "JML AP Asset";
        Customer: Record Customer;
        HolderEntry: Record "JML AP Holder Entry";
        Location: Record Location;
        TransferMgt: Codeunit "JML AP Transfer Mgt";
        EntryCount: Integer;
    begin
        // [GIVEN] Asset at location
        Initialize();
        CreateTestLocation(Location, 'WH01-TEST', 'Test Warehouse');
        CreateTestCustomer(Customer, 'C001-TEST', 'Test Customer');
        CreateTestAsset(Asset, 'Test Asset');

        Asset."Current Holder Type" := Asset."Current Holder Type"::Location;
        Asset."Current Holder Code" := Location.Code;
        Asset.Modify();

        // [WHEN] Transfer to customer
        TransferMgt.TransferAsset(
            Asset,
            Asset."Current Holder Type"::Customer,
            Customer."No.",
            "JML AP Document Type"::Manual,
            '',
            ''
        );

        // [THEN] Two entries created (Out + In)
        HolderEntry.SetRange("Asset No.", Asset."No.");
        EntryCount := HolderEntry.Count();
        Assert.AreEqual(2, EntryCount, 'Should have 2 holder entries (Out + In)');

        // Verify asset current holder updated
        Asset.Get(Asset."No.");
        Assert.AreEqual(Asset."Current Holder Type"::Customer, Asset."Current Holder Type", 'Holder type should be Customer');
        Assert.AreEqual(Customer."No.", Asset."Current Holder Code", 'Holder code should be Customer No.');
    end;

    [Test]
    procedure Test_TransactionNoIncrement()
    var
        Asset: Record "JML AP Asset";
        HolderEntry: Record "JML AP Holder Entry";
        Location1, Location2: Record Location;
        TransferMgt: Codeunit "JML AP Transfer Mgt";
        TransNo1, TransNo2: Integer;
    begin
        // [GIVEN] Asset and 2 locations
        Initialize();
        CreateTestLocation(Location1, 'WH01-TEST', 'Warehouse 1');
        CreateTestLocation(Location2, 'WH02-TEST', 'Warehouse 2');
        CreateTestAsset(Asset, 'Test Asset');

        Asset."Current Holder Type" := Asset."Current Holder Type"::Location;
        Asset."Current Holder Code" := Location1.Code;
        Asset.Modify();

        // [WHEN] Perform 2 transfers
        TransferMgt.TransferAsset(Asset, Asset."Current Holder Type"::Location, Location2.Code, "JML AP Document Type"::Manual, '', '');
        TransferMgt.TransferAsset(Asset, Asset."Current Holder Type"::Location, Location1.Code, "JML AP Document Type"::Manual, '', '');

        // [THEN] Transaction numbers increment
        HolderEntry.SetRange("Asset No.", Asset."No.");
        HolderEntry.SetFilter("Transaction No.", '>0');
        if HolderEntry.FindSet() then begin
            TransNo1 := HolderEntry."Transaction No.";
            HolderEntry.Next();
            HolderEntry.Next();
            TransNo2 := HolderEntry."Transaction No.";

            Assert.IsTrue(TransNo2 > TransNo1, 'Transaction 2 should be greater than Transaction 1');
        end;
    end;

    local procedure Initialize()
    var
        Asset: Record "JML AP Asset";
        HolderEntry: Record "JML AP Holder Entry";
        Customer: Record Customer;
        Location: Record Location;
        AssetSetup: Record "JML AP Asset Setup";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        if IsInitialized then
            exit;

        // Clean test data
        HolderEntry.DeleteAll();
        Asset.DeleteAll();
        Customer.DeleteAll();
        Location.DeleteAll();
        NoSeriesLine.DeleteAll();
        NoSeries.DeleteAll();
        AssetSetup.DeleteAll();

        // Create basic setup
        CreateTestNumberSeries(NoSeries, NoSeriesLine);

        AssetSetup.Init();
        AssetSetup."Asset Nos." := NoSeries.Code;
        AssetSetup."Enable Attributes" := true;
        AssetSetup.Insert();

        IsInitialized := true;
        Commit();
    end;

    local procedure CreateTestAsset(var Asset: Record "JML AP Asset"; Description: Text[100])
    begin
        Asset.Init();
        Asset.Validate(Description, Description);
        Asset.Insert(true);
    end;

    local procedure CreateTestLocation(var Location: Record Location; LocationCode: Code[10]; LocationName: Text[100])
    begin
        if not Location.Get(LocationCode) then begin
            Location.Init();
            Location.Code := LocationCode;
            Location.Name := LocationName;
            Location.Insert();
        end;
    end;

    local procedure CreateTestCustomer(var Customer: Record Customer; CustomerNo: Code[20]; CustomerName: Text[100])
    begin
        if not Customer.Get(CustomerNo) then begin
            Customer.Init();
            Customer."No." := CustomerNo;
            Customer.Name := CustomerName;
            Customer.Insert();
        end;
    end;

    local procedure CreateTestNumberSeries(var NoSeries: Record "No. Series"; var NoSeriesLine: Record "No. Series Line")
    begin
        NoSeries.Init();
        NoSeries.Code := 'ASSET-TEST';
        NoSeries.Description := 'Test Asset Numbers';
        NoSeries."Default Nos." := true;
        NoSeries."Manual Nos." := true;
        if NoSeries.Insert() then;

        NoSeriesLine.Init();
        NoSeriesLine."Series Code" := NoSeries.Code;
        NoSeriesLine."Line No." := 10000;
        NoSeriesLine."Starting No." := 'AT-0001';
        NoSeriesLine."Ending No." := 'AT-9999';
        NoSeriesLine."Increment-by No." := 1;
        if NoSeriesLine.Insert() then;
    end;
}
