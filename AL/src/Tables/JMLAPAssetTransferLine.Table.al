table 70182314 "JML AP Asset Transfer Line"
{
    Caption = 'Asset Transfer Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "JML AP Asset Transfer Header"."No.";
            DataClassification = CustomerContent;
        }

        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = CustomerContent;
        }

        field(10; "Asset No."; Code[20])
        {
            Caption = 'Asset No.';
            TableRelation = "JML AP Asset";
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                Asset: Record "JML AP Asset";
                TransferHeader: Record "JML AP Asset Transfer Header";
            begin
                if "Asset No." = '' then begin
                    Clear("Asset Description");
                    Clear("Current Holder Type");
                    Clear("Current Holder Code");
                    exit;
                end;

                Asset.Get("Asset No.");
                Asset.TestField(Blocked, false);

                "Asset Description" := Asset.Description;
                "Current Holder Type" := Asset."Current Holder Type";
                "Current Holder Code" := Asset."Current Holder Code";
                "Current Holder Name" := Asset."Current Holder Name";
                "Current Holder Addr Code" := Asset."Current Holder Addr Code";

                // Validate not a subasset
                if Asset."Parent Asset No." <> '' then
                    Error(SubassetErr, "Asset No.", Asset."Parent Asset No.");

                // Validate current holder matches From Holder
                if TransferHeader.Get("Document No.") then begin
                    if (Asset."Current Holder Type" <> TransferHeader."From Holder Type") or
                       (Asset."Current Holder Code" <> TransferHeader."From Holder Code")
                    then
                        Error(WrongHolderErr, Asset."No.",
                            Format(Asset."Current Holder Type"), Asset."Current Holder Code",
                            Format(TransferHeader."From Holder Type"), TransferHeader."From Holder Code");
                end;
            end;

            trigger OnLookup()
            var
                Asset: Record "JML AP Asset";
                AssetList: Page "JML AP Asset List";
                TransferHeader: Record "JML AP Asset Transfer Header";
            begin
                // Filter assets by From Holder if header exists
                if TransferHeader.Get("Document No.") then begin
                    Asset.SetRange("Current Holder Type", TransferHeader."From Holder Type");
                    Asset.SetRange("Current Holder Code", TransferHeader."From Holder Code");
                end;

                // Exclude subassets (they cannot be transferred independently)
                Asset.SetRange("Parent Asset No.", '');

                // Exclude blocked assets
                Asset.SetRange(Blocked, false);

                AssetList.SetTableView(Asset);
                AssetList.LookupMode := true;
                if AssetList.RunModal() = Action::LookupOK then begin
                    AssetList.GetRecord(Asset);
                    Validate("Asset No.", Asset."No.");
                end;
            end;
        }

        field(11; "Asset Description"; Text[100])
        {
            Caption = 'Asset Description';
            Editable = false;
            DataClassification = CustomerContent;
        }

        field(12; "Current Holder Type"; Enum "JML AP Holder Type")
        {
            Caption = 'Current Holder Type';
            Editable = false;
            DataClassification = CustomerContent;
        }

        field(13; "Current Holder Code"; Code[20])
        {
            Caption = 'Current Holder Code';
            Editable = false;
            DataClassification = CustomerContent;
        }

        field(14; "Current Holder Name"; Text[100])
        {
            Caption = 'Current Holder Name';
            Editable = false;
            DataClassification = CustomerContent;
        }

        field(15; "Current Holder Addr Code"; Code[10])
        {
            Caption = 'Current Holder Address Code';
            ToolTip = 'Specifies the current holder address code of the asset.';
            Editable = false;
            DataClassification = CustomerContent;
        }

        field(20; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Document No.", "Line No.")
        {
            Clustered = true;
        }
        key(AssetKey; "Asset No.")
        {
        }
    }

    trigger OnInsert()
    var
        TransferHeader: Record "JML AP Asset Transfer Header";
    begin
        TestField("Document No.");

        if TransferHeader.Get("Document No.") then
            TransferHeader.TestField(Status, TransferHeader.Status::Open);
    end;

    trigger OnModify()
    var
        TransferHeader: Record "JML AP Asset Transfer Header";
    begin
        if TransferHeader.Get("Document No.") then
            TransferHeader.TestField(Status, TransferHeader.Status::Open);
    end;

    trigger OnDelete()
    begin
        // Note: No status check here - Released documents can be deleted after posting
        // Status validation is enforced in OnInsert, OnModify
    end;

    var
        SubassetErr: Label 'Cannot transfer subasset %1. It is attached to parent %2. Detach first.', Comment = '%1 = Asset No., %2 = Parent Asset No.';
        WrongHolderErr: Label 'Asset %1 is currently at %2 %3, but the transfer document expects it at %4 %5.', Comment = '%1 = Asset No., %2 = Current Holder Type, %3 = Current Holder Code, %4 = From Holder Type, %5 = From Holder Code';
}
