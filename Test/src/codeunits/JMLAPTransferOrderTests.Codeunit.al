codeunit 50108 "JML AP Transfer Order Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        IsInitialized: Boolean;
    // LibraryRandom: Codeunit "Library - Random";  // Temporarily disabled - missing package

    // ============================================
    // Happy Path Tests
    // ============================================

    [Test]
    procedure PostTransferOrder_ValidOrder_CreatesPostedDocument()
    var
        Asset: Record "JML AP Asset";
        Location1, Location2 : Record Location;
        TransferHeader: Record "JML AP Asset Transfer Header";
        TransferLine: Record "JML AP Asset Transfer Line";
        PostedTransfer: Record "JML AP Posted Asset Transfer";
        AssetTransferPost: Codeunit "JML AP Asset Transfer-Post";
        PostedNo: Code[20];
    begin
        Initialize();

        // [GIVEN] An asset at Location 1
        CreateLocation(Location1);
        CreateLocation(Location2);
        CreateAssetAtLocation(Asset, Location1.Code);

        // [GIVEN] A released transfer order from Location 1 to Location 2
        CreateTransferOrder(TransferHeader, Location1.Code, Location2.Code);
        CreateTransferLine(TransferLine, TransferHeader."No.", Asset."No.");
        ReleaseTransferOrder(TransferHeader);

        // [WHEN] Posting the transfer order
        AssetTransferPost.SetSuppressConfirmation(true);
        AssetTransferPost.SetSuppressMessage(true);
        AssetTransferPost.Run(TransferHeader);
        PostedNo := TransferHeader."Posting No.";

        // [THEN] Posted transfer document created
        Assert.IsTrue(PostedTransfer.Get(PostedNo), 'Posted transfer should exist');
        Assert.AreEqual(TransferHeader."No.", PostedTransfer."Transfer Order No.", 'Transfer Order No. should match');

        // [THEN] Asset transferred to Location 2
        Asset.Get(Asset."No.");
        Assert.AreEqual(Format(Asset."Current Holder Type"::Location), Format(Asset."Current Holder Type"), 'Holder type should be Location');
        Assert.AreEqual(Location2.Code, Asset."Current Holder Code", 'Asset should be at Location 2');

        // [THEN] Source transfer order deleted
        Assert.IsFalse(TransferHeader.Get(TransferHeader."No."), 'Source transfer order should be deleted');

        // Cleanup
        PostedTransfer.Delete(true);
        CleanupAsset(Asset);
        CleanupLocation(Location1);
        CleanupLocation(Location2);
    end;

    [Test]
    procedure PostTransferOrder_MultipleAssets_AllTransferred()
    var
        Asset1, Asset2, Asset3 : Record "JML AP Asset";
        Location1, Location2 : Record Location;
        TransferHeader: Record "JML AP Asset Transfer Header";
        TransferLine: Record "JML AP Asset Transfer Line";
        PostedTransfer: Record "JML AP Posted Asset Transfer";
        PostedLine: Record "JML AP Pstd. Asset Trans. Line";
        AssetTransferPost: Codeunit "JML AP Asset Transfer-Post";
    begin
        Initialize();

        // [GIVEN] Three assets at Location 1
        CreateLocation(Location1);
        CreateLocation(Location2);
        CreateAssetAtLocation(Asset1, Location1.Code);
        CreateAssetAtLocation(Asset2, Location1.Code);
        CreateAssetAtLocation(Asset3, Location1.Code);

        // [GIVEN] A released transfer order with 3 assets
        CreateTransferOrder(TransferHeader, Location1.Code, Location2.Code);
        CreateTransferLine(TransferLine, TransferHeader."No.", Asset1."No.");
        CreateTransferLine(TransferLine, TransferHeader."No.", Asset2."No.");
        CreateTransferLine(TransferLine, TransferHeader."No.", Asset3."No.");
        ReleaseTransferOrder(TransferHeader);

        // [WHEN] Posting the transfer order
        AssetTransferPost.SetSuppressConfirmation(true);
        AssetTransferPost.SetSuppressMessage(true);
        AssetTransferPost.Run(TransferHeader);

        // [THEN] Posted transfer has 3 lines
        PostedTransfer.Get(TransferHeader."Posting No.");
        PostedLine.SetRange("Document No.", PostedTransfer."No.");
        Assert.RecordCount(PostedLine, 3);

        // [THEN] All assets transferred to Location 2
        Asset1.Get(Asset1."No.");
        Asset2.Get(Asset2."No.");
        Asset3.Get(Asset3."No.");
        Assert.AreEqual(Location2.Code, Asset1."Current Holder Code", 'Asset 1 should be at Location 2');
        Assert.AreEqual(Location2.Code, Asset2."Current Holder Code", 'Asset 2 should be at Location 2');
        Assert.AreEqual(Location2.Code, Asset3."Current Holder Code", 'Asset 3 should be at Location 2');

        // Cleanup
        PostedTransfer.Delete(true);
        CleanupAsset(Asset1);
        CleanupAsset(Asset2);
        CleanupAsset(Asset3);
        CleanupLocation(Location1);
        CleanupLocation(Location2);
    end;

    [Test]
    procedure PostTransferOrder_WithChildren_ChildrenTransferred()
    var
        ParentAsset, ChildAsset : Record "JML AP Asset";
        Location1, Location2 : Record Location;
        TransferHeader: Record "JML AP Asset Transfer Header";
        TransferLine: Record "JML AP Asset Transfer Line";
        PostedTransfer: Record "JML AP Posted Asset Transfer";
        AssetTransferPost: Codeunit "JML AP Asset Transfer-Post";
    begin
        Initialize();


        // [GIVEN] A parent asset with one child at Location 1
        CreateLocation(Location1);
        CreateLocation(Location2);
        CreateAssetAtLocation(ParentAsset, Location1.Code);
        CreateAssetAtLocation(ChildAsset, Location1.Code);
        ChildAsset."Parent Asset No." := ParentAsset."No.";
        ChildAsset.Modify(true);

        // [GIVEN] A released transfer order with only parent asset
        CreateTransferOrder(TransferHeader, Location1.Code, Location2.Code);
        CreateTransferLine(TransferLine, TransferHeader."No.", ParentAsset."No.");
        ReleaseTransferOrder(TransferHeader);

        // [WHEN] Posting the transfer order
        AssetTransferPost.SetSuppressConfirmation(true);
        AssetTransferPost.SetSuppressMessage(true);
        AssetTransferPost.Run(TransferHeader);

        // [THEN] Both parent and child transferred to Location 2
        ParentAsset.Get(ParentAsset."No.");
        ChildAsset.Get(ChildAsset."No.");
        Assert.AreEqual(Location2.Code, ParentAsset."Current Holder Code", 'Parent should be at Location 2');
        Assert.AreEqual(Location2.Code, ChildAsset."Current Holder Code", 'Child should be at Location 2');

        // Cleanup
        PostedTransfer.Get(TransferHeader."Posting No.");
        PostedTransfer.Delete(true);
        CleanupAsset(ChildAsset);
        CleanupAsset(ParentAsset);
        CleanupLocation(Location1);
        CleanupLocation(Location2);
    end;

    // ============================================
    // Error Case Tests
    // ============================================

    [Test]
    procedure PostTransferOrder_NotReleased_ThrowsError()
    var
        Asset: Record "JML AP Asset";
        Location1, Location2 : Record Location;
        TransferHeader: Record "JML AP Asset Transfer Header";
        TransferLine: Record "JML AP Asset Transfer Line";
        AssetTransferPost: Codeunit "JML AP Asset Transfer-Post";
    begin
        Initialize();

        // [GIVEN] An open (not released) transfer order
        CreateLocation(Location1);
        CreateLocation(Location2);
        CreateAssetAtLocation(Asset, Location1.Code);
        CreateTransferOrder(TransferHeader, Location1.Code, Location2.Code);
        CreateTransferLine(TransferLine, TransferHeader."No.", Asset."No.");

        // [WHEN] Attempting to post without releasing
        // [THEN] Error is thrown
        AssetTransferPost.SetSuppressConfirmation(true);
        AssetTransferPost.SetSuppressMessage(true);
        asserterror AssetTransferPost.Run(TransferHeader);
        Assert.ExpectedError('must be released');

        // Cleanup - only delete if it still exists (posting should have failed)
        if TransferHeader.Get(TransferHeader."No.") then
            TransferHeader.Delete(true);
        CleanupAsset(Asset);
        CleanupLocation(Location1);
        CleanupLocation(Location2);
    end;

    [Test]
    procedure PostTransferOrder_NoLines_ThrowsError()
    var
        Location1, Location2 : Record Location;
        TransferHeader: Record "JML AP Asset Transfer Header";
        AssetTransferPost: Codeunit "JML AP Asset Transfer-Post";
    begin
        // [GIVEN] A released transfer order with no lines
        CreateLocation(Location1);
        CreateLocation(Location2);
        CreateTransferOrder(TransferHeader, Location1.Code, Location2.Code);
        ReleaseTransferOrder(TransferHeader);

        // [WHEN] Attempting to post
        // [THEN] Error is thrown
        AssetTransferPost.SetSuppressConfirmation(true);
        AssetTransferPost.SetSuppressMessage(true);
        asserterror AssetTransferPost.Run(TransferHeader);
        Assert.ExpectedError('no lines to post');

        // Cleanup - only delete if it still exists (posting should have failed)
        if TransferHeader.Get(TransferHeader."No.") then
            TransferHeader.Delete(true);
        CleanupLocation(Location1);
        CleanupLocation(Location2);
    end;

    [Test]
    procedure PostTransferOrder_AssetNotAtFromHolder_ThrowsError()
    var
        Asset: Record "JML AP Asset";
        Location1, Location2, Location3 : Record Location;
        TransferHeader: Record "JML AP Asset Transfer Header";
        TransferLine: Record "JML AP Asset Transfer Line";
        AssetTransferPost: Codeunit "JML AP Asset Transfer-Post";
    begin
        // [GIVEN] An asset at Location 3
        CreateLocation(Location1);
        CreateLocation(Location2);
        CreateLocation(Location3);
        CreateAssetAtLocation(Asset, Location3.Code);

        // [GIVEN] A released transfer order from Location 1 to Location 2
        CreateTransferOrder(TransferHeader, Location1.Code, Location2.Code);

        // [WHEN] Attempting to add asset to transfer line (asset is at Location 3, not Location 1)
        // [THEN] Error is thrown during line validation
        asserterror CreateTransferLine(TransferLine, TransferHeader."No.", Asset."No.");
        Assert.ExpectedError('is currently at');

        // Cleanup - only delete if it still exists
        if TransferHeader.Get(TransferHeader."No.") then
            TransferHeader.Delete(true);
        CleanupAsset(Asset);
        CleanupLocation(Location1);
        CleanupLocation(Location2);
        CleanupLocation(Location3);
    end;

    [Test]
    procedure PostTransferOrder_AssetBlocked_ThrowsError()
    var
        Asset: Record "JML AP Asset";
        Location1, Location2 : Record Location;
        TransferHeader: Record "JML AP Asset Transfer Header";
        TransferLine: Record "JML AP Asset Transfer Line";
        AssetTransferPost: Codeunit "JML AP Asset Transfer-Post";
    begin
        Initialize();

        // [GIVEN] A blocked asset at Location 1
        CreateLocation(Location1);
        CreateLocation(Location2);
        CreateAssetAtLocation(Asset, Location1.Code);
        Asset.Blocked := true;
        Asset.Modify(true);

        // [GIVEN] A transfer order
        CreateTransferOrder(TransferHeader, Location1.Code, Location2.Code);

        // [WHEN] Attempting to add blocked asset to transfer line
        // [THEN] Error is thrown during line validation
        asserterror CreateTransferLine(TransferLine, TransferHeader."No.", Asset."No.");
        Assert.ExpectedError('Blocked must be equal to');

        // Cleanup - only delete if it still exists
        if TransferHeader.Get(TransferHeader."No.") then
            TransferHeader.Delete(true);
        CleanupAsset(Asset);
        CleanupLocation(Location1);
        CleanupLocation(Location2);
    end;

    [Test]
    procedure PostTransferOrder_Subasset_ThrowsError()
    var
        ParentAsset, ChildAsset : Record "JML AP Asset";
        Location1, Location2 : Record Location;
        TransferHeader: Record "JML AP Asset Transfer Header";
        TransferLine: Record "JML AP Asset Transfer Line";
        AssetTransferPost: Codeunit "JML AP Asset Transfer-Post";
    begin
        Initialize();

        // [GIVEN] A child asset at Location 1
        CreateLocation(Location1);
        CreateLocation(Location2);
        CreateAssetAtLocation(ParentAsset, Location1.Code);
        CreateAssetAtLocation(ChildAsset, Location1.Code);
        ChildAsset."Parent Asset No." := ParentAsset."No.";
        ChildAsset.Modify(true);

        // [GIVEN] A transfer order
        CreateTransferOrder(TransferHeader, Location1.Code, Location2.Code);

        // [WHEN] Attempting to add subasset to transfer line
        // [THEN] Error is thrown during line validation
        asserterror CreateTransferLine(TransferLine, TransferHeader."No.", ChildAsset."No.");
        Assert.ExpectedError('Cannot transfer subasset');

        // Cleanup - only delete if it still exists
        if TransferHeader.Get(TransferHeader."No.") then
            TransferHeader.Delete(true);
        CleanupAsset(ChildAsset);
        CleanupAsset(ParentAsset);
        CleanupLocation(Location1);
        CleanupLocation(Location2);
    end;

    // ============================================
    // Edge Case Tests
    // ============================================

    [Test]
    procedure PostTransferOrder_UsesJournalPattern_ValidatesPostingDate()
    var
        Asset: Record "JML AP Asset";
        Location1, Location2, Location3 : Record Location;
        TransferHeader, InitialTransfer : Record "JML AP Asset Transfer Header";
        TransferLine: Record "JML AP Asset Transfer Line";
        AssetTransferPost: Codeunit "JML AP Asset Transfer-Post";
        PastDate: Date;
    begin
        Initialize();

        // [GIVEN] An asset at Location 1 with an entry dated today
        CreateLocation(Location1);
        CreateLocation(Location2);
        CreateLocation(Location3);
        CreateAssetAtLocation(Asset, Location1.Code);

        // Create initial holder entry by posting a transfer (Location 1 -> Location 2)
        CreateTransferOrder(InitialTransfer, Location1.Code, Location2.Code);
        CreateTransferLine(TransferLine, InitialTransfer."No.", Asset."No.");
        ReleaseTransferOrder(InitialTransfer);
        AssetTransferPost.SetSuppressConfirmation(true);
        AssetTransferPost.SetSuppressMessage(true);
        AssetTransferPost.Run(InitialTransfer);

        // [GIVEN] A released transfer order with past posting date (Location 2 -> Location 3)
        PastDate := CalcDate('<-1Y>', WorkDate());
        CreateTransferOrder(TransferHeader, Location2.Code, Location3.Code);
        TransferHeader."Posting Date" := PastDate;
        TransferHeader.Modify(true);
        CreateTransferLine(TransferLine, TransferHeader."No.", Asset."No.");
        ReleaseTransferOrder(TransferHeader);

        // [WHEN] Attempting to post with backdated posting date
        // [THEN] Error is thrown (journal validates posting date)
        AssetTransferPost.SetSuppressConfirmation(true);
        AssetTransferPost.SetSuppressMessage(true);
        asserterror AssetTransferPost.Run(TransferHeader);
        Assert.ExpectedError('cannot be before last entry date');

        // Cleanup - only delete if it still exists (posting should have failed)
        if TransferHeader.Get(TransferHeader."No.") then
            TransferHeader.Delete(true);
        CleanupAsset(Asset);
        CleanupLocation(Location1);
        CleanupLocation(Location2);
        CleanupLocation(Location3);
    end;

    [Test]
    procedure PostTransferOrder_TransactionNoLinked_AllEntriesHaveSameNo()
    var
        ParentAsset, ChildAsset : Record "JML AP Asset";
        Location1, Location2 : Record Location;
        TransferHeader: Record "JML AP Asset Transfer Header";
        TransferLine: Record "JML AP Asset Transfer Line";
        PostedTransfer: Record "JML AP Posted Asset Transfer";
        PostedLine: Record "JML AP Pstd. Asset Trans. Line";
        HolderEntry: Record "JML AP Holder Entry";
        AssetTransferPost: Codeunit "JML AP Asset Transfer-Post";
        TransactionNo: Integer;
    begin
        Initialize();

        // [GIVEN] A parent asset with one child at Location 1
        CreateLocation(Location1);
        CreateLocation(Location2);
        CreateAssetAtLocation(ParentAsset, Location1.Code);
        CreateAssetAtLocation(ChildAsset, Location1.Code);
        ChildAsset."Parent Asset No." := ParentAsset."No.";
        ChildAsset.Modify(true);

        // [GIVEN] A released transfer order
        CreateTransferOrder(TransferHeader, Location1.Code, Location2.Code);
        CreateTransferLine(TransferLine, TransferHeader."No.", ParentAsset."No.");
        ReleaseTransferOrder(TransferHeader);

        // [WHEN] Posting the transfer order
        AssetTransferPost.SetSuppressConfirmation(true);
        AssetTransferPost.SetSuppressMessage(true);
        AssetTransferPost.Run(TransferHeader);

        // [THEN] Posted lines have Transaction No.
        PostedTransfer.Get(TransferHeader."Posting No.");
        PostedLine.SetRange("Document No.", PostedTransfer."No.");
        PostedLine.FindFirst();
        TransactionNo := PostedLine."Transaction No.";
        Assert.AreNotEqual(0, TransactionNo, 'Transaction No. should be populated');

        // [THEN] All holder entries for this transaction have same Transaction No.
        HolderEntry.SetRange("Transaction No.", TransactionNo);
        Assert.IsTrue(HolderEntry.Count >= 4, 'Should have at least 4 entries (2 parent + 2 child)');

        // Cleanup
        PostedTransfer.Delete(true);
        CleanupAsset(ChildAsset);
        CleanupAsset(ParentAsset);
        CleanupLocation(Location1);
        CleanupLocation(Location2);
    end;

    // TODO: Add test for Transfer Order with address codes
    // [Test]
    // procedure PostTransferOrder_WithShipToAddress_SavesAddressCodeInPostedDoc()
    // Test that From/To address codes are saved in posted transfer header and lines

    // TODO: Add test for address code validation in Transfer Order
    // [Test]
    // procedure CreateTransferOrder_InvalidAddressCode_ValidationError()
    // Test that invalid address codes are caught during transfer order creation

    // ============================================
    // Helper Procedures
    // ============================================

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
        Asset.Validate("Current Holder Type", Asset."Current Holder Type"::Location);
        Asset.Validate("Current Holder Code", LocationCode);
        Asset.Insert(true);
    end;

    local procedure Initialize()
    var
        AssetSetup: Record "JML AP Asset Setup";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        if IsInitialized then
            exit;

        // Create Asset Number Series
        CreateTestNumberSeries(NoSeries, NoSeriesLine, 'ASSET-TEST');

        // Create Transfer Order Number Series
        CreateTestNumberSeries(NoSeries, NoSeriesLine, 'TRANS-TEST');

        // Create Posted Transfer Number Series
        CreateTestNumberSeries(NoSeries, NoSeriesLine, 'PSTRANS-TEST');

        // Create Asset Setup
        if not AssetSetup.Get() then begin
            AssetSetup.Init();
            AssetSetup.Insert();
        end;
        AssetSetup."Asset Nos." := 'ASSET-TEST';
        AssetSetup."Transfer Order Nos." := 'TRANS-TEST';
        AssetSetup."Posted Transfer Nos." := 'PSTRANS-TEST';
        AssetSetup.Modify();

        IsInitialized := true;
        Commit();
    end;

    local procedure CreateTestNumberSeries(var NoSeries: Record "No. Series"; var NoSeriesLine: Record "No. Series Line"; SeriesCode: Code[20])
    begin
        if not NoSeries.Get(SeriesCode) then begin
            NoSeries.Init();
            NoSeries.Code := SeriesCode;
            NoSeries."Default Nos." := true;
            NoSeries."Manual Nos." := true;
            NoSeries.Insert();
        end;

        NoSeriesLine.SetRange("Series Code", SeriesCode);
        if not NoSeriesLine.FindFirst() then begin
            NoSeriesLine.Init();
            NoSeriesLine."Series Code" := SeriesCode;
            NoSeriesLine."Line No." := 10000;
            NoSeriesLine."Starting No." := SeriesCode + '001';
            NoSeriesLine."Ending No." := SeriesCode + '999';
            NoSeriesLine.Insert();
        end;
    end;

    local procedure CreateTransferOrder(var TransferHeader: Record "JML AP Asset Transfer Header"; FromLocationCode: Code[10]; ToLocationCode: Code[10])
    begin
        TransferHeader.Init();
        TransferHeader."No." := '';
        TransferHeader.Insert(true);
        TransferHeader.Validate("From Holder Type", TransferHeader."From Holder Type"::Location);
        TransferHeader.Validate("From Holder Code", FromLocationCode);
        TransferHeader.Validate("To Holder Type", TransferHeader."To Holder Type"::Location);
        TransferHeader.Validate("To Holder Code", ToLocationCode);
        TransferHeader.Modify(true);
    end;

    local procedure CreateTransferLine(var TransferLine: Record "JML AP Asset Transfer Line"; DocumentNo: Code[20]; AssetNo: Code[20])
    var
        LastLineNo: Integer;
    begin
        TransferLine.SetRange("Document No.", DocumentNo);
        if TransferLine.FindLast() then
            LastLineNo := TransferLine."Line No."
        else
            LastLineNo := 0;

        TransferLine.Init();
        TransferLine."Document No." := DocumentNo;
        TransferLine."Line No." := LastLineNo + 10000;
        TransferLine.Validate("Asset No.", AssetNo);
        TransferLine.Insert(true);
    end;

    local procedure ReleaseTransferOrder(var TransferHeader: Record "JML AP Asset Transfer Header")
    begin
        TransferHeader.Status := TransferHeader.Status::Released;
        TransferHeader.Modify(true);
    end;

    local procedure CleanupAsset(var Asset: Record "JML AP Asset")
    var
        HolderEntry: Record "JML AP Holder Entry";
    begin
        HolderEntry.SetRange("Asset No.", Asset."No.");
        HolderEntry.DeleteAll(true);

        if Asset.Get(Asset."No.") then
            Asset.Delete(true);
    end;

    local procedure CleanupLocation(var Location: Record Location)
    begin
        if Location.Get(Location.Code) then
            Location.Delete(true);
    end;
}
