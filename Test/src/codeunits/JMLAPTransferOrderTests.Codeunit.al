codeunit 50108 "JML AP Transfer Order Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library - Assert";
        LibraryRandom: Codeunit "Library - Random";

    // ============================================
    // Happy Path Tests
    // ============================================

    [Test]
    procedure PostTransferOrder_ValidOrder_CreatesPostedDocument()
    var
        Asset: Record "JML AP Asset";
        Location1, Location2: Record Location;
        TransferHeader: Record "JML AP Asset Transfer Header";
        TransferLine: Record "JML AP Asset Transfer Line";
        PostedTransfer: Record "JML AP Posted Asset Transfer";
        AssetTransferPost: Codeunit "JML AP Asset Transfer-Post";
        PostedNo: Code[20];
    begin
        // [GIVEN] An asset at Location 1
        CreateLocation(Location1);
        CreateLocation(Location2);
        CreateAssetAtLocation(Asset, Location1.Code);

        // [GIVEN] A released transfer order from Location 1 to Location 2
        CreateTransferOrder(TransferHeader, Location1.Code, Location2.Code);
        CreateTransferLine(TransferLine, TransferHeader."No.", Asset."No.");
        ReleaseTransferOrder(TransferHeader);

        // [WHEN] Posting the transfer order
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
        Asset1, Asset2, Asset3: Record "JML AP Asset";
        Location1, Location2: Record Location;
        TransferHeader: Record "JML AP Asset Transfer Header";
        TransferLine: Record "JML AP Asset Transfer Line";
        PostedTransfer: Record "JML AP Posted Asset Transfer";
        PostedLine: Record "JML AP Pstd. Asset Trans. Line";
        AssetTransferPost: Codeunit "JML AP Asset Transfer-Post";
    begin
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
        ParentAsset, ChildAsset: Record "JML AP Asset";
        Location1, Location2: Record Location;
        TransferHeader: Record "JML AP Asset Transfer Header";
        TransferLine: Record "JML AP Asset Transfer Line";
        PostedTransfer: Record "JML AP Posted Asset Transfer";
        AssetTransferPost: Codeunit "JML AP Asset Transfer-Post";
    begin
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
        Location1, Location2: Record Location;
        TransferHeader: Record "JML AP Asset Transfer Header";
        TransferLine: Record "JML AP Asset Transfer Line";
        AssetTransferPost: Codeunit "JML AP Asset Transfer-Post";
    begin
        // [GIVEN] An open (not released) transfer order
        CreateLocation(Location1);
        CreateLocation(Location2);
        CreateAssetAtLocation(Asset, Location1.Code);
        CreateTransferOrder(TransferHeader, Location1.Code, Location2.Code);
        CreateTransferLine(TransferLine, TransferHeader."No.", Asset."No.");

        // [WHEN] Attempting to post without releasing
        // [THEN] Error is thrown
        asserterror AssetTransferPost.Run(TransferHeader);
        Assert.ExpectedError('must be released');

        // Cleanup
        TransferHeader.Delete(true);
        CleanupAsset(Asset);
        CleanupLocation(Location1);
        CleanupLocation(Location2);
    end;

    [Test]
    procedure PostTransferOrder_NoLines_ThrowsError()
    var
        Location1, Location2: Record Location;
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
        asserterror AssetTransferPost.Run(TransferHeader);
        Assert.ExpectedError('no lines to post');

        // Cleanup
        TransferHeader.Delete(true);
        CleanupLocation(Location1);
        CleanupLocation(Location2);
    end;

    [Test]
    procedure PostTransferOrder_AssetNotAtFromHolder_ThrowsError()
    var
        Asset: Record "JML AP Asset";
        Location1, Location2, Location3: Record Location;
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
        CreateTransferLine(TransferLine, TransferHeader."No.", Asset."No.");
        ReleaseTransferOrder(TransferHeader);

        // [WHEN] Attempting to post (asset is at Location 3, not Location 1)
        // [THEN] Error is thrown
        asserterror AssetTransferPost.Run(TransferHeader);
        Assert.ExpectedErrorCode('Dialog');

        // Cleanup
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
        Location1, Location2: Record Location;
        TransferHeader: Record "JML AP Asset Transfer Header";
        TransferLine: Record "JML AP Asset Transfer Line";
        AssetTransferPost: Codeunit "JML AP Asset Transfer-Post";
    begin
        // [GIVEN] A blocked asset at Location 1
        CreateLocation(Location1);
        CreateLocation(Location2);
        CreateAssetAtLocation(Asset, Location1.Code);
        Asset.Blocked := true;
        Asset.Modify(true);

        // [GIVEN] A released transfer order
        CreateTransferOrder(TransferHeader, Location1.Code, Location2.Code);
        CreateTransferLine(TransferLine, TransferHeader."No.", Asset."No.");
        ReleaseTransferOrder(TransferHeader);

        // [WHEN] Attempting to post
        // [THEN] Error is thrown
        asserterror AssetTransferPost.Run(TransferHeader);
        Assert.ExpectedErrorCode('TestField');

        // Cleanup
        TransferHeader.Delete(true);
        CleanupAsset(Asset);
        CleanupLocation(Location1);
        CleanupLocation(Location2);
    end;

    [Test]
    procedure PostTransferOrder_Subasset_ThrowsError()
    var
        ParentAsset, ChildAsset: Record "JML AP Asset";
        Location1, Location2: Record Location;
        TransferHeader: Record "JML AP Asset Transfer Header";
        TransferLine: Record "JML AP Asset Transfer Line";
        AssetTransferPost: Codeunit "JML AP Asset Transfer-Post";
    begin
        // [GIVEN] A child asset at Location 1
        CreateLocation(Location1);
        CreateLocation(Location2);
        CreateAssetAtLocation(ParentAsset, Location1.Code);
        CreateAssetAtLocation(ChildAsset, Location1.Code);
        ChildAsset."Parent Asset No." := ParentAsset."No.";
        ChildAsset.Modify(true);

        // [GIVEN] A released transfer order trying to transfer the child directly
        CreateTransferOrder(TransferHeader, Location1.Code, Location2.Code);
        CreateTransferLine(TransferLine, TransferHeader."No.", ChildAsset."No.");
        ReleaseTransferOrder(TransferHeader);

        // [WHEN] Attempting to post
        // [THEN] Error is thrown
        asserterror AssetTransferPost.Run(TransferHeader);
        Assert.ExpectedError('Cannot transfer subasset');

        // Cleanup
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
        Location1, Location2: Record Location;
        TransferHeader: Record "JML AP Asset Transfer Header";
        TransferLine: Record "JML AP Asset Transfer Line";
        AssetTransferPost: Codeunit "JML AP Asset Transfer-Post";
        PastDate: Date;
    begin
        // [GIVEN] An asset at Location 1 with an entry dated today
        CreateLocation(Location1);
        CreateLocation(Location2);
        CreateAssetAtLocation(Asset, Location1.Code);

        // [GIVEN] A released transfer order with past posting date
        PastDate := CalcDate('<-1Y>', WorkDate());
        CreateTransferOrder(TransferHeader, Location1.Code, Location2.Code);
        TransferHeader."Posting Date" := PastDate;
        TransferHeader.Modify(true);
        CreateTransferLine(TransferLine, TransferHeader."No.", Asset."No.");
        ReleaseTransferOrder(TransferHeader);

        // [WHEN] Attempting to post with backdated posting date
        // [THEN] Error is thrown (journal validates posting date)
        asserterror AssetTransferPost.Run(TransferHeader);
        Assert.ExpectedError('cannot be before last entry date');

        // Cleanup
        TransferHeader.Delete(true);
        CleanupAsset(Asset);
        CleanupLocation(Location1);
        CleanupLocation(Location2);
    end;

    [Test]
    procedure PostTransferOrder_TransactionNoLinked_AllEntriesHaveSameNo()
    var
        ParentAsset, ChildAsset: Record "JML AP Asset";
        Location1, Location2: Record Location;
        TransferHeader: Record "JML AP Asset Transfer Header";
        TransferLine: Record "JML AP Asset Transfer Line";
        PostedTransfer: Record "JML AP Posted Asset Transfer";
        PostedLine: Record "JML AP Pstd. Asset Trans. Line";
        HolderEntry: Record "JML AP Holder Entry";
        AssetTransferPost: Codeunit "JML AP Asset Transfer-Post";
        TransactionNo: Integer;
    begin
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

    // ============================================
    // Helper Procedures
    // ============================================

    local procedure CreateLocation(var Location: Record Location)
    begin
        Location.Init();
        Location.Code := 'LOC-' + Format(LibraryRandom.RandIntInRange(10000, 99999));
        Location.Name := 'Test Location ' + Location.Code;
        Location.Insert(true);
    end;

    local procedure CreateAssetAtLocation(var Asset: Record "JML AP Asset"; LocationCode: Code[10])
    begin
        Asset.Init();
        Asset."No." := 'ASSET-' + Format(LibraryRandom.RandIntInRange(10000, 99999));
        Asset.Description := 'Test Asset ' + Asset."No.";
        Asset.Validate("Current Holder Type", Asset."Current Holder Type"::Location);
        Asset.Validate("Current Holder Code", LocationCode);
        Asset.Insert(true);
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
