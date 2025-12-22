table 70182322 "JML AP Transfer Asset Line"
{
    Caption = 'Transfer Asset Line';
    DataClassification = CustomerContent;
    LookupPageId = "JML AP Transfer Asset Subpage";
    DrillDownPageId = "JML AP Transfer Asset Subpage";

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the number of the transfer order document.';
            DataClassification = CustomerContent;
            TableRelation = "Transfer Header"."No.";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            ToolTip = 'Specifies the line number.';
            DataClassification = CustomerContent;
        }

        field(10; "Asset No."; Code[20])
        {
            Caption = 'Asset No.';
            ToolTip = 'Specifies the asset to transfer with this transfer order.';
            DataClassification = CustomerContent;
            TableRelation = "JML AP Asset";

            trigger OnValidate()
            var
                Asset: Record "JML AP Asset";
            begin
                if "Asset No." = '' then begin
                    ClearAssetInfo();
                    exit;
                end;

                // Validate asset exists
                if not Asset.Get("Asset No.") then
                    Error(AssetNotExistErr, "Asset No.");

                // Validate asset not blocked
                if Asset.Blocked then
                    Error(AssetBlockedErr, "Asset No.");

                // Validate not a subasset
                if Asset."Parent Asset No." <> '' then
                    Error(SubassetTransferErr, Asset."No.", Asset."Parent Asset No.");

                // Get asset information
                "Asset Description" := Asset.Description;
                "Current Holder Type" := Asset."Current Holder Type";
                "Current Holder Code" := Asset."Current Holder Code";

                // Validate holder - must be at Transfer-from Location                
                ValidateAssetHolder(Asset);
            end;
        }
        field(11; "Asset Description"; Text[100])
        {
            Caption = 'Asset Description';
            ToolTip = 'Specifies the description of the asset.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(12; "Current Holder Type"; Enum "JML AP Holder Type")
        {
            Caption = 'Current Holder Type';
            ToolTip = 'Specifies the current holder type of the asset.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(13; "Current Holder Code"; Code[20])
        {
            Caption = 'Current Holder Code';
            ToolTip = 'Specifies the current holder code of the asset.';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(50; "Quantity to Ship"; Decimal)
        {
            Caption = 'Quantity to Ship';
            ToolTip = 'Specifies whether to ship this asset (1 = Yes, 0 = No).';
            DataClassification = CustomerContent;
            InitValue = 1;
            MinValue = 0;
            MaxValue = 1;
            DecimalPlaces = 0 : 0;

            trigger OnValidate()
            begin
                if "Quantity to Ship" < 0 then
                    "Quantity to Ship" := 0;
                if "Quantity to Ship" > 1 then
                    "Quantity to Ship" := 1;
            end;
        }
        field(51; "Quantity Shipped"; Decimal)
        {
            Caption = 'Quantity Shipped';
            ToolTip = 'Specifies whether this asset has been shipped (1 = Yes, 0 = No).';
            DataClassification = CustomerContent;
            Editable = false;
            DecimalPlaces = 0 : 0;
        }
        field(52; "Quantity to Receive"; Decimal)
        {
            Caption = 'Quantity to Receive';
            ToolTip = 'Specifies whether to receive this asset (1 = Yes, 0 = No). Set automatically when shipped.';
            DataClassification = CustomerContent;
            MinValue = 0;
            MaxValue = 1;
            DecimalPlaces = 0 : 0;

            trigger OnValidate()
            begin
                if "Quantity to Receive" < 0 then
                    "Quantity to Receive" := 0;
                if "Quantity to Receive" > 1 then
                    "Quantity to Receive" := 1;
            end;
        }
        field(53; "Quantity Received"; Decimal)
        {
            Caption = 'Quantity Received';
            ToolTip = 'Specifies whether this asset has been received (1 = Yes, 0 = No).';
            DataClassification = CustomerContent;
            Editable = false;
            DecimalPlaces = 0 : 0;
        }

        field(30; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            ToolTip = 'Specifies the reason code for this asset transfer.';
            DataClassification = CustomerContent;
            TableRelation = "Reason Code";
        }
        field(31; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description for this asset line.';
            DataClassification = CustomerContent;
        }

        field(40; "Transfer-from Code"; Code[10])
        {
            Caption = 'Transfer-from Code';
            ToolTip = 'Specifies the location code from the transfer header.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(41; "Transfer-to Code"; Code[10])
        {
            Caption = 'Transfer-to Code';
            ToolTip = 'Specifies the location code from the transfer header.';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Document No.", "Line No.")
        {
            Clustered = true;
        }
        key(Asset; "Asset No.")
        {
        }
    }

    trigger OnInsert()
    begin
        GetTransferHeader();

        if TransferHeader.Get("Document No.") then begin
            "Transfer-from Code" := TransferHeader."Transfer-from Code";
            "Transfer-to Code" := TransferHeader."Transfer-to Code";
        end;
    end;

    trigger OnDelete()
    begin
        TestStatusOpen();
        TestField("Quantity Shipped", 0);
        TestField("Quantity Received", 0);
    end;

    var
        TransferHeader: Record "Transfer Header";
        StatusCheckSuspended: Boolean;
        AssetNotExistErr: label 'Asset %1 does not exist.', Comment = '%1: Asset No.';
        AssetBlockedErr: label 'Asset %1 is blocked and cannot be transferred.', Comment = '%1: Asset No.';
        SubassetTransferErr: label 'Cannot transfer subasset %1. It is attached to parent %2. Detach first.', Comment = '%1: Asset No., %2: Parent Asset No.';
        TransferFromCodeNotSpecifiedErr: label 'Transfer-from Code must be specified on the transfer header before adding assets.', Comment = '';
        AssetNotAtLocationErr: label 'Asset %1 is not at location %2. Current location: %3 %4.', Comment = '%1: Asset No., %2: Transfer-from Code, %3: Current Holder Type, %4: Current Holder Code';
        AssetNotHeldByLocationErr: Label 'Asset %1 is not held by a location. Current holder: %2 %3.', Comment = '%1 = Asset No., %2 = Holder Type, %3 = Holder Code';

    local procedure ClearAssetInfo()
    begin
        "Asset Description" := '';
        "Current Holder Type" := "Current Holder Type"::" ";
        "Current Holder Code" := '';
    end;

    local procedure ValidateAssetHolder(Asset: Record "JML AP Asset")
    begin
        GetTransferHeader();

        // Asset must be held by Transfer-from Location
        if TransferHeader."Transfer-from Code" = '' then
            Error(TransferFromCodeNotSpecifiedErr);

        if Asset."Current Holder Type" <> Asset."Current Holder Type"::Location then
            Error(AssetNotHeldByLocationErr,
                Asset."No.", Asset."Current Holder Type", Asset."Current Holder Code");

        if Asset."Current Holder Code" <> TransferHeader."Transfer-from Code" then
            Error(AssetNotAtLocationErr, Asset."No.", TransferHeader."Transfer-from Code", Asset."Current Holder Type", Asset."Current Holder Code");
    end;

    /// <summary>
    /// Test whether the status of a transfer document is set to 'Open'.
    /// </summary>
    procedure TestStatusOpen()
    begin
        if StatusCheckSuspended then
            exit;

        GetTransferHeader();

        TransferHeader.TestField(Status, TransferHeader.Status::Open);
    end;

    /// <summary>
    /// Gets the transfer header associated with the transfer line.
    /// Ensures the global TransferHeader variable is correctly set.
    /// </summary>
    /// <returns>The transfer header of the current line.</returns>
    procedure GetTransferHeader(): Record "Transfer Header"
    begin
        if ("Document No." <> TransferHeader."No.") then
            TransferHeader.Get("Document No.");
        exit(TransferHeader);
    end;

    /// <summary>
    /// Sets the status check suspension flag.
    /// </summary>
    /// <param name="Suspend">A boolean value indicating whether to suspend the status check.</param>
    procedure SuspendStatusCheck(Suspend: Boolean)
    begin
        StatusCheckSuspended := Suspend;
    end;
}
