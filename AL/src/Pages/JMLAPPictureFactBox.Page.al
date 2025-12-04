page 70182378 "JML AP Picture FactBox"
{
    Caption = 'Asset Picture';
    Description = 'Displays asset images and photos in a factbox.';
    PageType = CardPart;
    SourceTable = "JML AP Asset";

    layout
    {
        area(Content)
        {
            field(Picture; Rec.Picture)
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the picture of the asset.';
                ShowCaption = false;
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(TakePicture)
            {
                ApplicationArea = All;
                Caption = 'Take';
                Image = Camera;
                ToolTip = 'Activate the camera on the device.';
                Visible = CameraAvailable;

                trigger OnAction()
                begin
                    TakeNewPicture();
                end;
            }
            action(ImportPicture)
            {
                ApplicationArea = All;
                Caption = 'Import';
                Image = Import;
                ToolTip = 'Import a picture file.';

                trigger OnAction()
                begin
                    ImportPictureFromFile();
                end;
            }
            action(ExportPicture)
            {
                ApplicationArea = All;
                Caption = 'Export';
                Enabled = DeleteExportEnabled;
                Image = Export;
                ToolTip = 'Export the picture to a file.';

                trigger OnAction()
                begin
                    ExportPictureToFile();
                end;
            }
            action(DeletePicture)
            {
                ApplicationArea = All;
                Caption = 'Delete';
                Enabled = DeleteExportEnabled;
                Image = Delete;
                ToolTip = 'Delete the record.';

                trigger OnAction()
                begin
                    DeleteItemPicture();
                end;
            }
        }
    }
    trigger OnAfterGetRecord()
    begin
        SetEditableOnPictureActions();
    end;

    var
        Camera: Codeunit Camera;
        CameraAvailable: Boolean;
        DeleteExportEnabled: Boolean;
        OverrideImageQst: Label 'The existing picture will be replaced. Do you want to continue?';
        DeleteImageQst: Label 'Are you sure you want to delete the picture?';
        MimeTypeTok: Label 'image/jpeg', Locked = true;


    local procedure TakeNewPicture()
    begin
        Rec.Find();
        Rec.TestField("No.");
        Rec.TestField(Description);
        DoTakeNewPicture();
    end;

    local procedure DoTakeNewPicture(): Boolean
    var
        PictureInstream: InStream;
        PictureDescription: Text;
    begin
        if Rec.Picture.Count() > 0 then if not Confirm(OverrideImageQst) then exit(false);
        if Camera.GetPicture(PictureInstream, PictureDescription) then begin
            Clear(Rec.Picture);
            Rec.Picture.ImportStream(PictureInstream, PictureDescription, MimeTypeTok);
            Rec.Modify(true);
            exit(true);
        end;
        exit(false);
    end;

    local procedure SetEditableOnPictureActions()
    begin
        DeleteExportEnabled := Rec.Picture.Count > 0;
    end;

    local procedure ImportPictureFromFile()
    var
        PicInStream: InStream;
        FromFileName: Text;
    begin
        Rec.TestField("No.");
        if Rec.Picture.Count > 0 then
            if not Confirm(OverrideImageQst) then exit;

        if UploadIntoStream('Import', '', 'All files (*.*)|*.*', FromFileName, PicInStream) then begin
            clear(Rec.Picture);
            Rec.Picture.ImportStream(PicInStream, FromFileName);
            Rec.Modify();
        end;
    end;

    local procedure ExportPictureToFile()
    var
        TenantMedia: Record "Tenant Media";
        PicInStream: InStream;
        ToFileName: Text;
        Index: Integer;
    begin
        Rec.TestField("No.");
        if not (Rec.Picture.Count > 0) then exit;
        for Index := 1 to Rec.Picture.Count do if TenantMedia.get(Rec.Picture.Item(Index)) then begin
                TenantMedia.CalcFields(Content);
                if TenantMedia.Content.HasValue then begin
                    ToFileName := Rec.TableCaption + '_Image' + format(Index) + GetImageFileExt(TenantMedia);
                    TenantMedia.Content.CreateInStream(PicInStream);
                    DownloadFromStream(PicInStream, '', '', '', ToFileName);
                end;
            end;
    end;

    local procedure DeleteItemPicture()
    begin
        Rec.TestField("No.");
        if not Confirm(DeleteImageQst) then exit;
        Clear(Rec.Picture);
        Rec.Modify(true);
    end;

    local procedure GetImageFileExt(var TenantMedia: Record "Tenant Media"): Text
    begin
        case TenantMedia."Mime Type" of
            'image/jpeg':
                exit('.jpg');
            'image/png':
                exit('.png');
            'image/bmp':
                exit('.bmp');
            'image/gif':
                exit('.gif');
            'image/tiff':
                exit('.tiff');
            'image/wmf':
                exit('.wmf');
        end;
    end;
}
