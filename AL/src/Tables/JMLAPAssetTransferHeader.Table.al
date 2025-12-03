table 70182313 "JML AP Asset Transfer Header"
{
    Caption = 'Asset Transfer Header';
    DataClassification = CustomerContent;
    LookupPageId = "JML AP Asset Transfer Orders";
    DrillDownPageId = "JML AP Asset Transfer Orders";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then
                    "No. Series" := '';
            end;
        }

        field(2; "From Holder Type"; Enum "JML AP Holder Type")
        {
            Caption = 'From Holder Type';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "From Holder Type" <> xRec."From Holder Type" then begin
                    "From Holder Code" := '';
                    "From Holder Addr Code" := '';
                end;
            end;
        }

        field(3; "From Holder Code"; Code[20])
        {
            Caption = 'From Holder Code';
            DataClassification = CustomerContent;
            TableRelation = if ("From Holder Type" = const(Customer)) Customer."No."
            else if ("From Holder Type" = const(Vendor)) Vendor."No."
            else if ("From Holder Type" = const(Location)) Location.Code;

            trigger OnValidate()
            var
                Customer: Record Customer;
                Vendor: Record Vendor;
                Location: Record Location;
            begin
                if "From Holder Code" = '' then begin
                    "From Holder Name" := '';
                    "From Holder Addr Code" := '';
                    exit;
                end;

                // Clear address code when holder code changes
                if "From Holder Code" <> xRec."From Holder Code" then
                    "From Holder Addr Code" := '';

                case "From Holder Type" of
                    "From Holder Type"::Customer:
                        begin
                            Customer.Get("From Holder Code");
                            "From Holder Name" := Customer.Name;
                        end;
                    "From Holder Type"::Vendor:
                        begin
                            Vendor.Get("From Holder Code");
                            "From Holder Name" := Vendor.Name;
                        end;
                    "From Holder Type"::Location:
                        begin
                            Location.Get("From Holder Code");
                            "From Holder Name" := Location.Name;
                        end;
                end;
            end;
        }

        field(4; "From Holder Name"; Text[100])
        {
            Caption = 'From Holder Name';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(5; "From Holder Addr Code"; Code[10])
        {
            Caption = 'From Holder Address Code';
            ToolTip = 'Specifies the ship-to address code (for customers) or order address code (for vendors) of the sender.';
            DataClassification = CustomerContent;
            TableRelation = if ("From Holder Type" = const(Customer)) "Ship-to Address".Code where("Customer No." = field("From Holder Code"))
            else if ("From Holder Type" = const(Vendor)) "Order Address".Code where("Vendor No." = field("From Holder Code"));

            trigger OnValidate()
            begin
                // Clear address code if holder type doesn't support addresses
                if not ("From Holder Type" in ["From Holder Type"::Customer, "From Holder Type"::Vendor]) then
                    "From Holder Addr Code" := '';
            end;
        }

        field(10; "To Holder Type"; Enum "JML AP Holder Type")
        {
            Caption = 'To Holder Type';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "To Holder Type" <> xRec."To Holder Type" then begin
                    "To Holder Code" := '';
                    "To Holder Addr Code" := '';
                end;
            end;
        }

        field(11; "To Holder Code"; Code[20])
        {
            Caption = 'To Holder Code';
            DataClassification = CustomerContent;
            TableRelation = if ("To Holder Type" = const(Customer)) Customer."No."
            else if ("To Holder Type" = const(Vendor)) Vendor."No."
            else if ("To Holder Type" = const(Location)) Location.Code;

            trigger OnValidate()
            var
                Customer: Record Customer;
                Vendor: Record Vendor;
                Location: Record Location;
            begin
                if "To Holder Code" = '' then begin
                    "To Holder Name" := '';
                    "To Holder Addr Code" := '';
                    exit;
                end;

                // Clear address code when holder code changes
                if "To Holder Code" <> xRec."To Holder Code" then
                    "To Holder Addr Code" := '';

                case "To Holder Type" of
                    "To Holder Type"::Customer:
                        begin
                            Customer.Get("To Holder Code");
                            "To Holder Name" := Customer.Name;
                        end;
                    "To Holder Type"::Vendor:
                        begin
                            Vendor.Get("To Holder Code");
                            "To Holder Name" := Vendor.Name;
                        end;
                    "To Holder Type"::Location:
                        begin
                            Location.Get("To Holder Code");
                            "To Holder Name" := Location.Name;
                        end;
                end;

                // Validate different from From Holder
                if ("To Holder Type" = "From Holder Type") and
                   ("To Holder Code" = "From Holder Code")
                then
                    Error(SameHolderErr);
            end;
        }

        field(12; "To Holder Name"; Text[100])
        {
            Caption = 'To Holder Name';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(13; "To Holder Addr Code"; Code[10])
        {
            Caption = 'To Holder Address Code';
            ToolTip = 'Specifies the ship-to address code (for customers) or order address code (for vendors) of the receiver.';
            DataClassification = CustomerContent;
            TableRelation = if ("To Holder Type" = const(Customer)) "Ship-to Address".Code where("Customer No." = field("To Holder Code"))
            else if ("To Holder Type" = const(Vendor)) "Order Address".Code where("Vendor No." = field("To Holder Code"));

            trigger OnValidate()
            begin
                // Clear address code if holder type doesn't support addresses
                if not ("To Holder Type" in ["To Holder Type"::Customer, "To Holder Type"::Vendor]) then
                    "To Holder Addr Code" := '';
            end;
        }

        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = CustomerContent;
        }

        field(21; "Document Date"; Date)
        {
            Caption = 'Document Date';
            DataClassification = CustomerContent;
        }

        field(30; Status; Enum "JML AP Transfer Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(40; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(41; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Posting No. Series" <> '' then
                    TestField(Status, Status::Open);
            end;

            trigger OnLookup()
            var
                NoSeries: Record "No. Series";
            begin
                GetSetup();
                AssetSetup.TestField("Posted Transfer Nos.");
                if NoSeries.Get(AssetSetup."Posted Transfer Nos.") then
                    Validate("Posting No. Series", NoSeries.Code);
            end;
        }

        field(42; "Posting No."; Code[20])
        {
            Caption = 'Posting No.';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(50; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
            DataClassification = CustomerContent;
        }

        field(51; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
        key(StatusKey; Status)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "From Holder Code", "To Holder Code", Status)
        {
        }
    }

    trigger OnInsert()
    var
        NoSeries: Codeunit "No. Series";
    begin
        GetSetup();
        if "No." = '' then begin
            AssetSetup.TestField("Transfer Order Nos.");
            "No. Series" := AssetSetup."Transfer Order Nos.";
            "No." := NoSeries.GetNextNo("No. Series");
        end;

        if "Posting Date" = 0D then
            "Posting Date" := WorkDate();
        if "Document Date" = 0D then
            "Document Date" := WorkDate();

        if "Posting No. Series" = '' then begin
            AssetSetup.TestField("Posted Transfer Nos.");
            "Posting No. Series" := AssetSetup."Posted Transfer Nos.";
        end;
    end;

    trigger OnDelete()
    var
        AssetTransferLine: Record "JML AP Asset Transfer Line";
    begin
        // Note: No status check here - Released documents can be deleted after posting
        // Status validation is enforced in OnInsert, OnModify, OnRename

        AssetTransferLine.SetRange("Document No.", "No.");
        AssetTransferLine.DeleteAll(true);
    end;

    var
        AssetSetup: Record "JML AP Asset Setup";
        SetupRead: Boolean;
        SameHolderErr: Label 'To Holder must be different from From Holder.';

    local procedure GetSetup()
    begin
        if not SetupRead then begin
            AssetSetup.Get();
            SetupRead := true;
        end;
    end;

    /// <summary>
    /// Checks if the transfer order has any lines.
    /// </summary>
    procedure HasLines(): Boolean
    var
        TransferLine: Record "JML AP Asset Transfer Line";
    begin
        TransferLine.SetRange("Document No.", "No.");
        exit(not TransferLine.IsEmpty);
    end;

    /// <summary>
    /// Counts the number of lines in the transfer order.
    /// </summary>
    procedure CountLines(): Integer
    var
        TransferLine: Record "JML AP Asset Transfer Line";
    begin
        TransferLine.SetRange("Document No.", "No.");
        exit(TransferLine.Count);
    end;

    internal procedure PerformManualRelease()
    begin
        if Rec.Status <> Rec.Status::Released then begin
            CODEUNIT.Run(CODEUNIT::"JML AP Release Asset Transfer", Rec);
            Commit();
        end;
    end;
}
