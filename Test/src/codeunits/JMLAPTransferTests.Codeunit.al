codeunit 50105 "JML AP Transfer Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        TestLibrary: Codeunit "JML AP Test Library";
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
        TestLibrary.Initialize();
        Location := TestLibrary.CreateTestLocation('WH01-TEST');
        Customer := TestLibrary.CreateTestCustomer('Test Customer');
        Asset := TestLibrary.CreateAssetAtLocation('Test Asset', Location.Code);

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
        TestLibrary.Initialize();
        Location1 := TestLibrary.CreateTestLocation('WH01-TEST');
        Location2 := TestLibrary.CreateTestLocation('WH02-TEST');
        Asset := TestLibrary.CreateAssetAtLocation('Test Asset', Location1.Code);

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

}
