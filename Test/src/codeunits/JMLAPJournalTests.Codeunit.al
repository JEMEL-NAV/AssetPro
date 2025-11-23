codeunit 50107 "JML AP Journal Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    procedure PostJournal_ValidData_CreatesHolderEntries()
    var
        Asset: Record "JML AP Asset";
        Location1, Location2 : Record Location;
        AssetJnlBatch: Record "JML AP Asset Journal Batch";
        AssetJnlLine: Record "JML AP Asset Journal Line";
        HolderEntry: Record "JML AP Holder Entry";
        AssetJnlPost: Codeunit "JML AP Asset Jnl.-Post";
    begin
        // [GIVEN] An asset at Location 1
        CreateLocation(Location1);
        CreateLocation(Location2);
        CreateAssetAtLocation(Asset, Location1.Code);

        // [GIVEN] A journal batch and line to transfer to Location 2
        CreateJournalBatch(AssetJnlBatch);
        CreateJournalLine(AssetJnlLine, AssetJnlBatch.Name, Asset."No.",
            AssetJnlLine."New Holder Type"::Location, Location2.Code);

        // [WHEN] Posting the journal
        AssetJnlPost.Run(AssetJnlLine);

        // [THEN] Two holder entries created (Transfer Out + Transfer In)
        HolderEntry.SetRange("Asset No.", Asset."No.");
        HolderEntry.SetRange("Document Type", HolderEntry."Document Type"::Journal);
        Assert.RecordCount(HolderEntry, 2);

        // [THEN] Asset holder updated to Location 2
        Asset.Get(Asset."No.");
        Assert.AreEqual(Format(Asset."Current Holder Type"::Location),
            Format(Asset."Current Holder Type"), 'Holder type should be Location');
        Assert.AreEqual(Location2.Code, Asset."Current Holder Code", 'Holder code should be Location 2');

        // Cleanup
        CleanupAsset(Asset);
        CleanupLocation(Location1);
        CleanupLocation(Location2);
    end;

    [Test]
    procedure PostJournal_WithSubasset_ErrorThrown()
    var
        ParentAsset, ChildAsset : Record "JML AP Asset";
        Location1, Location2 : Record Location;
        AssetJnlBatch: Record "JML AP Asset Journal Batch";
        AssetJnlLine: Record "JML AP Asset Journal Line";
        AssetJnlPost: Codeunit "JML AP Asset Jnl.-Post";
    begin
        // [GIVEN] A parent asset and child asset at Location 1
        CreateLocation(Location1);
        CreateLocation(Location2);
        CreateAssetAtLocation(ParentAsset, Location1.Code);
        CreateAssetAtLocation(ChildAsset, Location1.Code);
        ChildAsset."Parent Asset No." := ParentAsset."No.";
        ChildAsset.Modify(true);

        // [GIVEN] A journal line trying to transfer the CHILD asset
        CreateJournalBatch(AssetJnlBatch);
        CreateJournalLine(AssetJnlLine, AssetJnlBatch.Name, ChildAsset."No.",
            AssetJnlLine."New Holder Type"::Location, Location2.Code);

        // [WHEN] Attempting to post the journal
        // [THEN] Error is thrown
        asserterror AssetJnlPost.Run(AssetJnlLine);
        Assert.ExpectedError('Cannot transfer subasset');

        // Cleanup
        CleanupAsset(ChildAsset);
        CleanupAsset(ParentAsset);
        CleanupLocation(Location1);
        CleanupLocation(Location2);
    end;

    [Test]
    procedure PostJournal_WithChildren_TransfersBoth()
    var
        ParentAsset, ChildAsset : Record "JML AP Asset";
        Location1, Location2 : Record Location;
        AssetJnlBatch: Record "JML AP Asset Journal Batch";
        AssetJnlLine: Record "JML AP Asset Journal Line";
        HolderEntry: Record "JML AP Holder Entry";
        AssetJnlPost: Codeunit "JML AP Asset Jnl.-Post";
        TransactionNo: Integer;
    begin
        // [GIVEN] A parent asset with one child at Location 1
        CreateLocation(Location1);
        CreateLocation(Location2);
        CreateAssetAtLocation(ParentAsset, Location1.Code);
        CreateAssetAtLocation(ChildAsset, Location1.Code);
        ChildAsset."Parent Asset No." := ParentAsset."No.";
        ChildAsset.Modify(true);

        // [GIVEN] A journal line to transfer the PARENT asset
        CreateJournalBatch(AssetJnlBatch);
        CreateJournalLine(AssetJnlLine, AssetJnlBatch.Name, ParentAsset."No.",
            AssetJnlLine."New Holder Type"::Location, Location2.Code);

        // [WHEN] Posting the journal
        AssetJnlPost.Run(AssetJnlLine);

        // [THEN] Parent asset transferred to Location 2
        ParentAsset.Get(ParentAsset."No.");
        Assert.AreEqual(Location2.Code, ParentAsset."Current Holder Code", 'Parent should be at Location 2');

        // [THEN] Child asset AUTOMATICALLY transferred to Location 2
        ChildAsset.Get(ChildAsset."No.");
        Assert.AreEqual(Location2.Code, ChildAsset."Current Holder Code", 'Child should be at Location 2');

        // [THEN] Both assets have entries with same Transaction No.
        HolderEntry.SetRange("Asset No.", ParentAsset."No.");
        HolderEntry.SetRange("Document Type", HolderEntry."Document Type"::Journal);
        HolderEntry.FindFirst();
        TransactionNo := HolderEntry."Transaction No.";

        HolderEntry.Reset();
        HolderEntry.SetRange("Asset No.", ChildAsset."No.");
        HolderEntry.SetRange("Transaction No.", TransactionNo);
        Assert.RecordCount(HolderEntry, 2);

        // Cleanup
        CleanupAsset(ChildAsset);
        CleanupAsset(ParentAsset);
        CleanupLocation(Location1);
        CleanupLocation(Location2);
    end;

    [Test]
    procedure ValidatePostingDate_BackdatingBeforeLastEntry_ErrorThrown()
    var
        Asset: Record "JML AP Asset";
        Location1, Location2, Location3 : Record Location;
        AssetJnlPost: Codeunit "JML AP Asset Jnl.-Post";
        OldPostingDate: Date;
        NewPostingDate: Date;
    begin
        // [GIVEN] An asset transferred on 2024-01-15
        CreateLocation(Location1);
        CreateLocation(Location2);
        CreateLocation(Location3);
        CreateAssetAtLocation(Asset, Location1.Code);

        OldPostingDate := CalcDate('<-1M>', WorkDate());
        TransferAssetDirectly(Asset, Location2.Code, OldPostingDate);

        // [WHEN] Attempting to post with date before last entry (2024-01-10)
        NewPostingDate := CalcDate('<-5D>', OldPostingDate);

        // [THEN] Error is thrown
        asserterror AssetJnlPost.ValidatePostingDate(Asset."No.", NewPostingDate);
        Assert.ExpectedError('cannot be before last entry date');

        // Cleanup
        CleanupAsset(Asset);
        CleanupLocation(Location1);
        CleanupLocation(Location2);
        CleanupLocation(Location3);
    end;

    [Test]
    procedure ValidatePostingDate_AfterLastEntry_Success()
    var
        Asset: Record "JML AP Asset";
        Location1, Location2 : Record Location;
        AssetJnlPost: Codeunit "JML AP Asset Jnl.-Post";
        OldPostingDate: Date;
        NewPostingDate: Date;
    begin
        // [GIVEN] An asset transferred on 2024-01-15
        CreateLocation(Location1);
        CreateLocation(Location2);
        CreateAssetAtLocation(Asset, Location1.Code);

        OldPostingDate := CalcDate('<-1M>', WorkDate());
        TransferAssetDirectly(Asset, Location2.Code, OldPostingDate);

        // [WHEN] Validating posting date after last entry (2024-01-20)
        NewPostingDate := CalcDate('<+5D>', OldPostingDate);

        // [THEN] No error thrown
        AssetJnlPost.ValidatePostingDate(Asset."No.", NewPostingDate);

        // Cleanup
        CleanupAsset(Asset);
        CleanupLocation(Location1);
        CleanupLocation(Location2);
    end;

    [Test]
    procedure PostJournal_SameHolderDifferentAddress_Success()
    var
        Asset: Record "JML AP Asset";
        Customer: Record Customer;
        ShipToAddr1, ShipToAddr2 : Record "Ship-to Address";
        AssetJnlBatch: Record "JML AP Asset Journal Batch";
        AssetJnlLine: Record "JML AP Asset Journal Line";
        HolderEntry: Record "JML AP Holder Entry";
        AssetJnlPost: Codeunit "JML AP Asset Jnl.-Post";
    begin
        // [SCENARIO] Asset can be transferred to same holder with different address
        // [GIVEN] Asset at Customer A, Address 1
        CreateCustomer(Customer);
        CreateShipToAddress(ShipToAddr1, Customer."No.", 'ADDR1');
        CreateShipToAddress(ShipToAddr2, Customer."No.", 'ADDR2');
        CreateAssetAtCustomerAddress(Asset, Customer."No.", ShipToAddr1.Code);

        // [GIVEN] Journal line to transfer to Customer A, Address 2
        CreateJournalBatch(AssetJnlBatch);
        CreateJournalLineWithAddress(AssetJnlLine, AssetJnlBatch.Name, Asset."No.",
            AssetJnlLine."New Holder Type"::Customer, Customer."No.", ShipToAddr2.Code);

        // [WHEN] Posting the journal
        AssetJnlPost.SetSuppressConfirmation(true);
        AssetJnlPost.SetSuppressSuccessMessage(true);
        AssetJnlPost.Run(AssetJnlLine);

        // [THEN] Transfer succeeds, asset moved to Address 2
        Asset.Get(Asset."No.");
        Assert.AreEqual(Customer."No.", Asset."Current Holder Code", 'Holder should be same customer');
        Assert.AreEqual(ShipToAddr2.Code, Asset."Current Holder Addr Code", 'Address should be Address 2');

        // [THEN] Holder entries created with correct addresses
        HolderEntry.SetRange("Asset No.", Asset."No.");
        HolderEntry.SetRange("Entry Type", HolderEntry."Entry Type"::"Transfer Out");
        HolderEntry.FindFirst();
        Assert.AreEqual(ShipToAddr1.Code, HolderEntry."Holder Addr Code", 'Transfer Out should have Address 1');

        HolderEntry.SetRange("Entry Type", HolderEntry."Entry Type"::"Transfer In");
        HolderEntry.FindFirst();
        Assert.AreEqual(ShipToAddr2.Code, HolderEntry."Holder Addr Code", 'Transfer In should have Address 2');

        // Cleanup
        CleanupAsset(Asset);
        CleanupShipToAddress(ShipToAddr1);
        CleanupShipToAddress(ShipToAddr2);
        CleanupCustomer(Customer);
    end;

    [Test]
    procedure PostJournal_SameHolderSameAddress_ErrorThrown()
    var
        Asset: Record "JML AP Asset";
        Customer: Record Customer;
        ShipToAddr: Record "Ship-to Address";
        AssetJnlBatch: Record "JML AP Asset Journal Batch";
        AssetJnlLine: Record "JML AP Asset Journal Line";
        AssetJnlPost: Codeunit "JML AP Asset Jnl.-Post";
    begin
        // [SCENARIO] Cannot transfer asset to same holder and same address
        // [GIVEN] Asset at Customer A, Address 1
        CreateCustomer(Customer);
        CreateShipToAddress(ShipToAddr, Customer."No.", 'ADDR1');
        CreateAssetAtCustomerAddress(Asset, Customer."No.", ShipToAddr.Code);

        // [GIVEN] Journal line trying to "transfer" to same holder and same address
        CreateJournalBatch(AssetJnlBatch);
        CreateJournalLineWithAddress(AssetJnlLine, AssetJnlBatch.Name, Asset."No.",
            AssetJnlLine."New Holder Type"::Customer, Customer."No.", ShipToAddr.Code);

        // [WHEN] Attempting to post
        // [THEN] Error thrown
        AssetJnlPost.SetSuppressConfirmation(true);
        AssetJnlPost.SetSuppressSuccessMessage(true);
        asserterror AssetJnlPost.Run(AssetJnlLine);
        Assert.ExpectedError('must be different');

        // Cleanup
        CleanupAsset(Asset);
        CleanupShipToAddress(ShipToAddr);
        CleanupCustomer(Customer);
    end;

    [Test]
    procedure JournalLine_AssetNoValidate_PopulatesCurrentHolderAddress()
    var
        Asset: Record "JML AP Asset";
        Customer: Record Customer;
        ShipToAddr: Record "Ship-to Address";
        AssetJnlBatch: Record "JML AP Asset Journal Batch";
        AssetJnlLine: Record "JML AP Asset Journal Line";
    begin
        // [SCENARIO] Current Holder Address field auto-populated from asset
        // [GIVEN] Asset at Customer with Ship-to Address
        CreateCustomer(Customer);
        CreateShipToAddress(ShipToAddr, Customer."No.", 'MAIN');
        CreateAssetAtCustomerAddress(Asset, Customer."No.", ShipToAddr.Code);

        // [WHEN] Creating journal line and validating Asset No.
        CreateJournalBatch(AssetJnlBatch);
        AssetJnlLine.Init();
        AssetJnlLine."Journal Batch Name" := AssetJnlBatch.Name;
        AssetJnlLine."Line No." := 10000;
        AssetJnlLine.Validate("Asset No.", Asset."No.");

        // [THEN] Current Holder Address Code populated
        Assert.AreEqual(Customer."No.", AssetJnlLine."Current Holder Code", 'Current holder code should be populated');
        Assert.AreEqual(ShipToAddr.Code, AssetJnlLine."Current Holder Addr Code", 'Current holder address should be populated');

        // Cleanup
        CleanupAsset(Asset);
        CleanupShipToAddress(ShipToAddr);
        CleanupCustomer(Customer);
    end;

    [Test]
    procedure ValidatePostingDate_ChildHasLaterEntry_ParentBackdatingBlocked()
    var
        ParentAsset, ChildAsset : Record "JML AP Asset";
        Location1, Location2 : Record Location;
        AssetJnlPost: Codeunit "JML AP Asset Jnl.-Post";
        ParentPostingDate: Date;
        ChildPostingDate: Date;
        NewPostingDate: Date;
    begin
        // [GIVEN] Parent asset transferred on 2024-01-15
        CreateLocation(Location1);
        CreateLocation(Location2);
        CreateAssetAtLocation(ParentAsset, Location1.Code);
        CreateAssetAtLocation(ChildAsset, Location1.Code);
        ChildAsset."Parent Asset No." := ParentAsset."No.";
        ChildAsset.Modify(true);

        ParentPostingDate := CalcDate('<-1M>', WorkDate());
        TransferAssetDirectly(ParentAsset, Location2.Code, ParentPostingDate);

        // [GIVEN] Child asset transferred on 2024-01-20 (later date)
        ChildPostingDate := CalcDate('<+5D>', ParentPostingDate);
        TransferAssetDirectly(ChildAsset, Location2.Code, ChildPostingDate);

        // [WHEN] Attempting to post parent with date before child's last entry (2024-01-18)
        NewPostingDate := CalcDate('<+3D>', ParentPostingDate);

        // [THEN] Error is thrown (must be after child's last entry)
        asserterror AssetJnlPost.ValidatePostingDate(ParentAsset."No.", NewPostingDate);
        Assert.ExpectedError('cannot be before last entry date');

        // Cleanup
        CleanupAsset(ChildAsset);
        CleanupAsset(ParentAsset);
        CleanupLocation(Location1);
        CleanupLocation(Location2);
    end;

    // Helper procedures

    local procedure CreateLocation(var Location: Record Location)
    begin
        Location.Init();
        Location.Code := 'L' + Format(CreateGuid()).Substring(1, 9);
        Location.Name := 'Test Location ' + Location.Code;
        Location.Insert(true);
    end;

    local procedure CreateAssetAtLocation(var Asset: Record "JML AP Asset"; LocationCode: Code[10])
    begin
        Asset.Init();
        Asset."No." := 'TST-' + Format(CreateGuid()).Substring(1, 15);
        Asset.Description := 'Test Asset ' + Asset."No.";
        Asset."Current Holder Type" := Asset."Current Holder Type"::Location;
        Asset."Current Holder Code" := LocationCode;
        Asset."Current Holder Since" := WorkDate();
        Asset.Insert(true);
    end;

    local procedure CreateJournalBatch(var AssetJnlBatch: Record "JML AP Asset Journal Batch")
    begin
        AssetJnlBatch.Init();
        AssetJnlBatch.Name := 'TEST';
        AssetJnlBatch.Description := 'Test Batch';
        if not AssetJnlBatch.Insert(true) then
            AssetJnlBatch.Modify(true);
    end;

    local procedure CreateJournalLine(
        var AssetJnlLine: Record "JML AP Asset Journal Line";
        BatchName: Code[10];
        AssetNo: Code[20];
        NewHolderType: Enum "JML AP Holder Type";
        NewHolderCode: Code[20])
    var
        LastLineNo: Integer;
    begin
        AssetJnlLine.SetRange("Journal Batch Name", BatchName);
        if AssetJnlLine.FindLast() then
            LastLineNo := AssetJnlLine."Line No.";

        AssetJnlLine.Init();
        AssetJnlLine."Journal Batch Name" := BatchName;
        AssetJnlLine."Line No." := LastLineNo + 10000;
        AssetJnlLine.Validate("Asset No.", AssetNo);
        AssetJnlLine.Validate("New Holder Type", NewHolderType);
        AssetJnlLine.Validate("New Holder Code", NewHolderCode);
        AssetJnlLine."Posting Date" := WorkDate();
        AssetJnlLine."Document No." := 'TEST-' + Format(AssetJnlLine."Line No.");
        AssetJnlLine.Insert(true);
    end;

    local procedure TransferAssetDirectly(var Asset: Record "JML AP Asset"; ToLocationCode: Code[10]; PostingDate: Date)
    var
        HolderEntry: Record "JML AP Holder Entry";
        TransactionNo: Integer;
    begin
        // Get next transaction no
        if HolderEntry.FindLast() then
            TransactionNo := HolderEntry."Transaction No." + 1
        else
            TransactionNo := 1;

        // Create Transfer Out entry
        HolderEntry.Init();
        HolderEntry."Asset No." := Asset."No.";
        HolderEntry."Posting Date" := PostingDate;
        HolderEntry."Entry Type" := HolderEntry."Entry Type"::"Transfer Out";
        HolderEntry."Holder Type" := Asset."Current Holder Type";
        HolderEntry."Holder Code" := Asset."Current Holder Code";
        HolderEntry."Transaction No." := TransactionNo;
        HolderEntry."Document Type" := HolderEntry."Document Type"::Manual;
        HolderEntry."Document No." := 'TEST';
        HolderEntry.Insert(true);

        // Create Transfer In entry
        HolderEntry.Init();
        HolderEntry."Asset No." := Asset."No.";
        HolderEntry."Posting Date" := PostingDate;
        HolderEntry."Entry Type" := HolderEntry."Entry Type"::"Transfer In";
        HolderEntry."Holder Type" := HolderEntry."Holder Type"::Location;
        HolderEntry."Holder Code" := ToLocationCode;
        HolderEntry."Transaction No." := TransactionNo;
        HolderEntry."Document Type" := HolderEntry."Document Type"::Manual;
        HolderEntry."Document No." := 'TEST';
        HolderEntry.Insert(true);

        // Update asset
        Asset."Current Holder Type" := Asset."Current Holder Type"::Location;
        Asset."Current Holder Code" := ToLocationCode;
        Asset."Current Holder Since" := PostingDate;
        Asset.Modify(true);
    end;

    local procedure CleanupAsset(var Asset: Record "JML AP Asset")
    var
        HolderEntry: Record "JML AP Holder Entry";
    begin
        if Asset.Get(Asset."No.") then begin
            HolderEntry.SetRange("Asset No.", Asset."No.");
            HolderEntry.DeleteAll(true);
            Asset.Delete(true);
        end;
    end;

    local procedure CleanupLocation(var Location: Record Location)
    begin
        if Location.Get(Location.Code) then
            Location.Delete(true);
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    begin
        Customer.Init();
        Customer."No." := 'CUST-' + Format(CreateGuid()).Substring(1, 8);
        Customer.Name := 'Test Customer ' + Customer."No.";
        Customer.Insert(true);
    end;

    local procedure CreateShipToAddress(var ShipToAddr: Record "Ship-to Address"; CustomerNo: Code[20]; AddrCode: Code[10])
    begin
        ShipToAddr.Init();
        ShipToAddr."Customer No." := CustomerNo;
        ShipToAddr.Code := AddrCode;
        ShipToAddr.Name := 'Address ' + AddrCode;
        ShipToAddr.Address := '123 Test St';
        ShipToAddr.City := 'Test City';
        ShipToAddr.Insert(true);
    end;

    local procedure CreateAssetAtCustomerAddress(var Asset: Record "JML AP Asset"; CustomerNo: Code[20]; AddrCode: Code[10])
    begin
        Asset.Init();
        Asset."No." := 'TST-' + Format(CreateGuid()).Substring(1, 15);
        Asset.Description := 'Test Asset ' + Asset."No.";
        Asset."Current Holder Type" := Asset."Current Holder Type"::Customer;
        Asset."Current Holder Code" := CustomerNo;
        Asset."Current Holder Addr Code" := AddrCode;
        Asset."Current Holder Since" := WorkDate();
        Asset.Insert(true);
    end;

    local procedure CreateJournalLineWithAddress(
        var AssetJnlLine: Record "JML AP Asset Journal Line";
        BatchName: Code[10];
        AssetNo: Code[20];
        NewHolderType: Enum "JML AP Holder Type";
        NewHolderCode: Code[20];
        NewHolderAddrCode: Code[10])
    var
        LastLineNo: Integer;
    begin
        AssetJnlLine.SetRange("Journal Batch Name", BatchName);
        if AssetJnlLine.FindLast() then
            LastLineNo := AssetJnlLine."Line No.";

        AssetJnlLine.Init();
        AssetJnlLine."Journal Batch Name" := BatchName;
        AssetJnlLine."Line No." := LastLineNo + 10000;
        AssetJnlLine.Validate("Asset No.", AssetNo);
        AssetJnlLine.Validate("New Holder Type", NewHolderType);
        AssetJnlLine.Validate("New Holder Code", NewHolderCode);
        AssetJnlLine.Validate("New Holder Addr Code", NewHolderAddrCode);
        AssetJnlLine."Posting Date" := WorkDate();
        AssetJnlLine."Document No." := 'TEST-' + Format(AssetJnlLine."Line No.");
        AssetJnlLine.Insert(true);
    end;

    local procedure CleanupCustomer(var Customer: Record Customer)
    begin
        if Customer.Get(Customer."No.") then
            Customer.Delete(true);
    end;

    local procedure CleanupShipToAddress(var ShipToAddr: Record "Ship-to Address")
    begin
        if ShipToAddr.Get(ShipToAddr."Customer No.", ShipToAddr.Code) then
            ShipToAddr.Delete(true);
    end;
}
