codeunit 50140 "JML AP Picture Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";
        IsInitialized: Boolean;

    [Test]
    procedure TestPictureFieldExists()
    var
        Asset: Record "JML AP Asset";
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        // [SCENARIO] Picture field exists on Asset table
        Initialize();

        // [GIVEN] An Asset record
        Asset.Init();

        // [WHEN] Accessing the Picture field via RecordRef
        RecRef.GetTable(Asset);
        FldRef := RecRef.Field(950); // Picture field number

        // [THEN] Field exists and is of type MediaSet
        LibraryAssert.AreEqual('Picture', FldRef.Name, 'Picture field should exist');
        LibraryAssert.AreEqual(Format(FldRef.Type), Format(FieldType::MediaSet), 'Picture field should be MediaSet type');
    end;

    [Test]
    procedure TestPictureCanBeAssigned()
    var
        Asset: Record "JML AP Asset";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
    begin
        // [SCENARIO] Picture can be assigned to Asset
        Initialize();

        // [GIVEN] An Asset record
        CreateTestAsset(Asset);

        // [WHEN] Assigning a picture (simulated with blob)
        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText('Test Picture Data');
        TempBlob.CreateInStream(InStr);

        Asset.Picture.ImportStream(InStr, 'TestPicture.png');
        Asset.Modify(true);

        // [THEN] Picture is stored
        LibraryAssert.IsTrue(Asset.Picture.Count() > 0, 'Picture should have value after assignment');
    end;

    [Test]
    procedure TestPictureCanBeRemoved()
    var
        Asset: Record "JML AP Asset";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
    begin
        // [SCENARIO] Picture can be removed from Asset
        Initialize();

        // [GIVEN] An Asset with a picture
        CreateTestAsset(Asset);
        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText('Test Picture Data');
        TempBlob.CreateInStream(InStr);
        Asset.Picture.ImportStream(InStr, 'TestPicture.png');
        Asset.Modify(true);

        // [WHEN] Removing the picture
        Clear(Asset.Picture);
        Asset.Modify(true);

        // [THEN] Picture is removed
        LibraryAssert.IsFalse(Asset.Picture.Count() > 0, 'Picture should not have value after removal');

        // Cleanup
        Asset.Delete(true);
    end;

    local procedure Initialize()
    var
        AssetSetup: Record "JML AP Asset Setup";
        Asset: Record "JML AP Asset";
    begin
        // Clean up test data before each test (must run every time)
        Asset.DeleteAll(true);

        // One-time setup
        if IsInitialized then
            exit;

        // Create Asset Setup record if it doesn't exist
        if not AssetSetup.Get() then begin
            AssetSetup.Init();
            AssetSetup.Insert(true);
        end;

        IsInitialized := true;
    end;

    local procedure CreateTestAsset(var Asset: Record "JML AP Asset")
    var
        GuidStr: Text;
    begin
        Asset.Init();
        GuidStr := DelChr(Format(CreateGuid()), '=', '{}');
        Asset."No." := CopyStr('PIC-' + CopyStr(GuidStr, 1, 8), 1, 20);
        Asset.Description := 'Test Asset for Picture Tests';
        Asset.Insert(true);
    end;
}
