table 70182318 "JML AP Sales Asset Line"
{
    Caption = 'Sales Asset Line';
    DataClassification = CustomerContent;
    LookupPageId = "JML AP Sales Asset Subpage";
    DrillDownPageId = "JML AP Sales Asset Subpage";

    fields
    {
        field(1; "Document Type"; Enum "Sales Document Type")
        {
            Caption = 'Document Type';
            ToolTip = 'Specifies the type of the sales document (Order, Invoice, Credit Memo, Return Order).';
            DataClassification = CustomerContent;
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the number of the sales document.';
            DataClassification = CustomerContent;
            TableRelation = "Sales Header"."No." where("Document Type" = field("Document Type"));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
            ToolTip = 'Specifies the line number.';
            DataClassification = CustomerContent;
        }

        field(10; "Asset No."; Code[20])
        {
            Caption = 'Asset No.';
            ToolTip = 'Specifies the asset to transfer with this sales document.';
            DataClassification = CustomerContent;
            TableRelation = "JML AP Asset";

            trigger OnValidate()
            var
                Asset: Record "JML AP Asset";
                SalesHeader: Record "Sales Header";
            begin
                if "Asset No." = '' then begin
                    ClearAssetInfo();
                    exit;
                end;

                // Validate asset exists
                if not Asset.Get("Asset No.") then
                    Error('Asset %1 does not exist.', "Asset No.");

                // Validate asset not blocked
                if Asset.Blocked then
                    Error('Asset %1 is blocked and cannot be transferred.', "Asset No.");

                // Validate not a subasset
                if Asset."Parent Asset No." <> '' then
                    Error('Cannot transfer subasset %1. It is attached to parent %2. Detach first.',
                        Asset."No.", Asset."Parent Asset No.");

                // Get asset information
                "Asset Description" := Asset.Description;
                "Current Holder Type" := Asset."Current Holder Type";
                "Current Holder Code" := Asset."Current Holder Code";

                // Validate holder based on document type
                if SalesHeader.Get("Document Type", "Document No.") then
                    ValidateAssetHolder(Asset, SalesHeader);
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
            ToolTip = 'Specifies whether to ship/deliver this asset (1 = Yes, 0 = No). For delivery documents (Order, Invoice).';
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
            ToolTip = 'Specifies whether to receive this asset (1 = Yes, 0 = No). For return documents (Credit Memo, Return Order).';
            DataClassification = CustomerContent;
            InitValue = 1;
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
        field(31; "Description"; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description for this asset line.';
            DataClassification = CustomerContent;
        }

        field(40; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            ToolTip = 'Specifies the customer number from the sales header.';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Document Type", "Document No.", "Line No.")
        {
            Clustered = true;
        }
        key(Asset; "Asset No.")
        {
        }
    }

    trigger OnInsert()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Get customer from header
        if SalesHeader.Get("Document Type", "Document No.") then
            "Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
    end;

    trigger OnDelete()
    begin
        // No special delete logic needed
    end;

    local procedure ClearAssetInfo()
    begin
        "Asset Description" := '';
        "Current Holder Type" := "Current Holder Type"::" ";
        "Current Holder Code" := '';
    end;

    local procedure ValidateAssetHolder(Asset: Record "JML AP Asset"; SalesHeader: Record "Sales Header")
    var
        IsDelivery: Boolean;
        IsReturn: Boolean;
    begin
        // Determine if this is a delivery or return document
        IsDelivery := SalesHeader."Document Type" in [SalesHeader."Document Type"::Order, SalesHeader."Document Type"::Invoice];
        IsReturn := SalesHeader."Document Type" in [SalesHeader."Document Type"::"Credit Memo", SalesHeader."Document Type"::"Return Order"];

        if IsDelivery then begin
            // Delivery: Asset must be held by location (from Location Code on header)
            if SalesHeader."Location Code" = '' then
                Error('Location Code must be specified on the sales header before adding assets.');

            if Asset."Current Holder Type" <> Asset."Current Holder Type"::Location then
                Error('Asset %1 is not held by a location. Current holder: %2 %3.',
                    Asset."No.", Asset."Current Holder Type", Asset."Current Holder Code");

            if Asset."Current Holder Code" <> SalesHeader."Location Code" then
                Error('Asset %1 is not held by location %2. Current location: %3.',
                    Asset."No.", SalesHeader."Location Code", Asset."Current Holder Code");
        end;

        if IsReturn then begin
            // Return: Asset must be held by customer (Sell-to Customer No.)
            if Asset."Current Holder Type" <> Asset."Current Holder Type"::Customer then
                Error('Asset %1 is not held by a customer. Current holder: %2 %3.',
                    Asset."No.", Asset."Current Holder Type", Asset."Current Holder Code");

            if Asset."Current Holder Code" <> SalesHeader."Sell-to Customer No." then
                Error('Asset %1 is not held by customer %2. Current customer: %3.',
                    Asset."No.", SalesHeader."Sell-to Customer No.", Asset."Current Holder Code");
        end;
    end;
}
