table 70182312 "JML AP Asset Journal Line"
{
    Caption = 'Asset Journal Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "JML AP Asset Journal Batch";
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
            TableRelation = "JML AP Asset" where(Blocked = const(false), "Parent Asset No." = const(''));
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                Asset: Record "JML AP Asset";
            begin
                if "Asset No." = '' then begin
                    Clear("Asset Description");
                    Clear("Current Holder Type");
                    Clear("Current Holder Code");
                    Clear("Current Holder Addr Code");
                    exit;
                end;

                Asset.Get("Asset No.");
                Asset.TestField(Blocked, false);

                "Asset Description" := Asset.Description;
                "Current Holder Type" := Asset."Current Holder Type";
                "Current Holder Code" := Asset."Current Holder Code";
                "Current Holder Addr Code" := Asset."Current Holder Addr Code";

                // Validate not a subasset
                if Asset."Parent Asset No." <> '' then
                    Error(SubassetErr, "Asset No.", Asset."Parent Asset No.");
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

        field(14; "Current Holder Addr Code"; Code[10])
        {
            Caption = 'Current Holder Address Code';
            ToolTip = 'Specifies the current address code of the asset holder.';
            Editable = false;
            DataClassification = CustomerContent;
        }

        field(20; "New Holder Type"; Enum "JML AP Holder Type")
        {
            Caption = 'New Holder Type';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "New Holder Type" <> "New Holder Type"::" " then
                    TestField("Asset No.");

                // Clear code and address code when type changes
                if "New Holder Type" <> xRec."New Holder Type" then begin
                    "New Holder Code" := '';
                    "New Holder Addr Code" := '';
                end;
            end;
        }

        field(21; "New Holder Code"; Code[20])
        {
            Caption = 'New Holder Code';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                Customer: Record Customer;
                Vendor: Record Vendor;
                Location: Record Location;
            begin
                if "New Holder Code" = '' then
                    exit;

                // Clear address code when holder code changes
                if "New Holder Code" <> xRec."New Holder Code" then
                    "New Holder Addr Code" := '';

                TestField("New Holder Type");

                // Validate holder exists
                case "New Holder Type" of
                    "New Holder Type"::Customer:
                        Customer.Get("New Holder Code");
                    "New Holder Type"::Vendor:
                        Vendor.Get("New Holder Code");
                    "New Holder Type"::Location:
                        Location.Get("New Holder Code");
                end;

                // Allow same holder if address changes
                // Only block if holder AND address are identical
                if ("New Holder Type" = "Current Holder Type") and
                   ("New Holder Code" = "Current Holder Code") and
                   ("New Holder Addr Code" = "Current Holder Addr Code")
                then
                    Error(SameHolderAddressErr, "Asset No.");
            end;

            trigger OnLookup()
            var
                Customer: Record Customer;
                Vendor: Record Vendor;
                Location: Record Location;
            begin
                case "New Holder Type" of
                    "New Holder Type"::Customer:
                        if Page.RunModal(Page::"Customer List", Customer) = Action::LookupOK then
                            Validate("New Holder Code", Customer."No.");
                    "New Holder Type"::Vendor:
                        if Page.RunModal(Page::"Vendor List", Vendor) = Action::LookupOK then
                            Validate("New Holder Code", Vendor."No.");
                    "New Holder Type"::Location:
                        if Page.RunModal(Page::"Location List", Location) = Action::LookupOK then
                            Validate("New Holder Code", Location.Code);
                end;
            end;
        }

        field(22; "New Holder Addr Code"; Code[10])
        {
            Caption = 'New Holder Address Code';
            ToolTip = 'Specifies the ship-to address code (for customers) or order address code (for vendors).';
            DataClassification = CustomerContent;
            TableRelation = if ("New Holder Type" = const(Customer)) "Ship-to Address".Code where("Customer No." = field("New Holder Code"))
            else if ("New Holder Type" = const(Vendor)) "Order Address".Code where("Vendor No." = field("New Holder Code"));

            trigger OnValidate()
            begin
                // Clear address code if holder type doesn't support addresses
                if not ("New Holder Type" in ["New Holder Type"::Customer, "New Holder Type"::Vendor]) then
                    "New Holder Addr Code" := '';
            end;
        }

        field(30; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Posting Date" <> 0D then
                    TestField("Asset No.");
            end;
        }

        field(31; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = CustomerContent;
        }

        field(32; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }

        field(33; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
            DataClassification = CustomerContent;
        }

        field(40; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Journal Batch Name", "Line No.")
        {
            Clustered = true;
        }
        key(AssetNo; "Asset No.", "Posting Date")
        {
        }
    }

    trigger OnInsert()
    begin
        TestField("Journal Batch Name");
    end;

    var
        SubassetErr: Label 'Cannot transfer subasset %1. It is attached to parent %2. Detach first.';
        SameHolderAddressErr: Label 'New holder and address must be different from current holder and address for asset %1. Specify a different address for same-holder transfers.';

    procedure SwitchLinesWithErrorsFilter(var ShowAllLinesEnabled: Boolean)
    var
        TempErrorMessage: Record "Error Message" temporary;
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
    begin
        if ShowAllLinesEnabled then begin
            MarkedOnly(false);
            ShowAllLinesEnabled := false;
        end else begin
            JournalErrorsMgt.GetErrorMessages(TempErrorMessage);
            if TempErrorMessage.FindSet() then
                repeat
                    if Rec.Get(TempErrorMessage."Context Record ID") then
                        Rec.Mark(true)
                until TempErrorMessage.Next() = 0;
            MarkedOnly(true);
            ShowAllLinesEnabled := true;
        end;
    end;
}
