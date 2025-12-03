codeunit 50140 "JML AP Picture Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";

    [Test]
    procedure TestPictureFieldExists()
    var
        Asset: Record "JML AP Asset";
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        // [SCENARIO] Picture field exists on Asset table

        // [GIVEN] An Asset record
        Asset.Init();

        // [WHEN] Accessing the Picture field via RecordRef
        RecRef.GetTable(Asset);
        FldRef := RecRef.Field(950); // Picture field number

        // [THEN] Field exists and is of type Media
        LibraryAssert.AreEqual('Picture', FldRef.Name, 'Picture field should exist');
        LibraryAssert.AreEqual(FldRef.Type, FieldType::Media, 'Picture field should be Media type');
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

        // [GIVEN] An Asset record
        CreateTestAsset(Asset);

        // [WHEN] Assigning a picture (simulated with blob)
        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText('Test Picture Data');
        TempBlob.CreateInStream(InStr);

        Asset.Picture.ImportStream(InStr, 'TestPicture.png');
        Asset.Modify(true);

        // [THEN] Picture is stored
        LibraryAssert.IsTrue(Asset.Picture.HasValue, 'Picture should have value after assignment');
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
        LibraryAssert.IsFalse(Asset.Picture.HasValue, 'Picture should not have value after removal');

        // Cleanup
        Asset.Delete(true);
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
        Asset."No." := 'TEST-PICTURE-' + Format(Random(99999));
        Asset.Description := 'Test Asset for Picture Tests';
        Asset.Insert(true);
    end;
}
