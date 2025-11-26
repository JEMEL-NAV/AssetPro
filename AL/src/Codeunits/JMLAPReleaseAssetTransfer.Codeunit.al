codeunit 70182395 "JML AP Release Asset Transfer"
{
    TableNo = "JML AP Asset Transfer Header";
    Permissions = TableData "JML AP Asset Transfer Header" = rm,
                  TableData "JML AP Asset Transfer Line" = r;

    trigger OnRun()
    begin
        AssetTransferHeader.Copy(Rec);
        Code();
        Rec := AssetTransferHeader;
    end;

    var
        AssetTransferHeader: Record "JML AP Asset Transfer Header";
        NothingToReleaseErr: Label 'There is nothing to release for transfer order %1.', Comment = '%1 = Document No.';
        SameHolderErr: Label 'The transfer order %1 cannot be released because From Holder and To Holder are the same.', Comment = '%1 = Document No.';

    local procedure Code()
    var
        TransferLine: Record "JML AP Asset Transfer Line";
        IsHandled: Boolean;
    begin
        if AssetTransferHeader.Status = AssetTransferHeader.Status::Released then
            exit;

        OnBeforeReleaseAssetTransferDoc(AssetTransferHeader);

        // Validate header fields
        AssetTransferHeader.TestField("From Holder Type");
        AssetTransferHeader.TestField("From Holder Code");
        AssetTransferHeader.TestField("To Holder Type");
        AssetTransferHeader.TestField("To Holder Code");
        AssetTransferHeader.TestField("Posting Date");

        // Check holders are different
        IsHandled := false;
        OnBeforeCheckSameHolder(AssetTransferHeader, IsHandled);
        if not IsHandled then
            if (AssetTransferHeader."From Holder Type" = AssetTransferHeader."To Holder Type") and
               (AssetTransferHeader."From Holder Code" = AssetTransferHeader."To Holder Code") and
               (AssetTransferHeader."From Holder Addr Code" = AssetTransferHeader."To Holder Addr Code")
            then
                Error(SameHolderErr, AssetTransferHeader."No.");

        AssetTransferHeader.TestField(Status, AssetTransferHeader.Status::Open);

        // Check and validate lines
        CheckTransferLines(TransferLine, AssetTransferHeader);

        IsHandled := false;
        OnRunOnBeforeSetStatusReleased(AssetTransferHeader, IsHandled);
        if IsHandled then
            exit;

        // Release the document
        AssetTransferHeader.Validate(Status, AssetTransferHeader.Status::Released);
        AssetTransferHeader.Modify();

        OnAfterReleaseAssetTransferDoc(AssetTransferHeader);
    end;

    procedure Release(var TransHeader: Record "JML AP Asset Transfer Header")
    begin
        if TransHeader.Status = TransHeader.Status::Released then
            exit;

        AssetTransferHeader.Copy(TransHeader);
        Code();
        TransHeader := AssetTransferHeader;
    end;

    procedure Reopen(var TransHeader: Record "JML AP Asset Transfer Header")
    begin
        if TransHeader.Status = TransHeader.Status::Open then
            exit;

        OnBeforeReopenAssetTransferDoc(TransHeader);

        TransHeader.Validate(Status, TransHeader.Status::Open);
        TransHeader.Modify();

        OnAfterReopenAssetTransferDoc(TransHeader);
    end;

    local procedure CheckTransferLines(var TransferLine: Record "JML AP Asset Transfer Line"; TransHeader: Record "JML AP Asset Transfer Header")
    var
        Asset: Record "JML AP Asset";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckTransferLines(TransferLine, IsHandled, TransHeader);
        if IsHandled then
            exit;

        // Check lines exist
        TransferLine.SetRange("Document No.", TransHeader."No.");
        if TransferLine.IsEmpty() then
            Error(NothingToReleaseErr, TransHeader."No.");

        // Validate each line
        if TransferLine.FindSet() then
            repeat
                TransferLine.TestField("Asset No.");

                // Validate asset exists and is not blocked
                if not Asset.Get(TransferLine."Asset No.") then
                    Error('Asset %1 does not exist.', TransferLine."Asset No.");

                if Asset.Blocked then
                    Error('Asset %1 is blocked and cannot be transferred.', Asset."No.");

                // Validate asset is at From Holder
                if (Asset."Current Holder Type" <> TransHeader."From Holder Type") or
                   (Asset."Current Holder Code" <> TransHeader."From Holder Code")
                then
                    Error('Asset %1 is not at the From Holder location. Current holder: %2 %3',
                        Asset."No.",
                        Asset."Current Holder Type",
                        Asset."Current Holder Code");

                // Validate not a subasset
                if Asset."Parent Asset No." <> '' then
                    Error('Cannot transfer subasset %1 directly. Transfer the parent asset instead.', Asset."No.");

            until TransferLine.Next() = 0;

        OnAfterCheckTransferLines(TransferLine, TransHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckTransferLines(var TransferLine: Record "JML AP Asset Transfer Line"; var IsHandled: Boolean; TransHeader: Record "JML AP Asset Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckTransferLines(var TransferLine: Record "JML AP Asset Transfer Line"; TransHeader: Record "JML AP Asset Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReleaseAssetTransferDoc(var AssetTransferHeader: Record "JML AP Asset Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReleaseAssetTransferDoc(var AssetTransferHeader: Record "JML AP Asset Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReopenAssetTransferDoc(var AssetTransferHeader: Record "JML AP Asset Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReopenAssetTransferDoc(var AssetTransferHeader: Record "JML AP Asset Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSameHolder(var AssetTransferHeader: Record "JML AP Asset Transfer Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeSetStatusReleased(var AssetTransferHeader: Record "JML AP Asset Transfer Header"; var IsHandled: Boolean)
    begin
    end;
}
