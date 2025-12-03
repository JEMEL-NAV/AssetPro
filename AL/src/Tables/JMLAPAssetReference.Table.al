table 70182332 "JML AP Asset Reference"
{
    Caption = 'Asset Reference';
    DataClassification = CustomerContent;
    LookupPageId = "JML AP Asset Reference List";

    fields
    {
        field(1; "Asset No."; Code[20])
        {
            Caption = 'Asset No.';
            ToolTip = 'Specifies the asset number.';
            TableRelation = "JML AP Asset";
            NotBlank = true;
        }
        field(2; "Reference Type"; Enum "JML AP Asset Ref Type")
        {
            Caption = 'Reference Type';
            ToolTip = 'Specifies the type of reference.';

            trigger OnValidate()
            begin
                if ("Reference Type" <> xRec."Reference Type") and (xRec."Reference Type" <> xRec."Reference Type"::" ") then
                    "Reference Type No." := '';
            end;
        }
        field(3; "Reference Type No."; Code[20])
        {
            Caption = 'Reference Type No.';
            ToolTip = 'Specifies the reference type number (e.g., Customer No., Vendor No.).';
            TableRelation = if ("Reference Type" = const(Customer)) Customer."No."
            else
            if ("Reference Type" = const(Vendor)) Vendor."No.";
        }
        field(4; "Reference No."; Code[50])
        {
            Caption = 'Reference No.';
            ToolTip = 'Specifies the reference number (e.g., barcode, customer asset number).';
            ExtendedDatatype = Barcode;
            NotBlank = true;
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description for the reference.';
        }
        field(6; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            ToolTip = 'Specifies an additional description.';
        }
        field(7; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            ToolTip = 'Specifies the date when this reference becomes valid.';

            trigger OnValidate()
            begin
                CheckDates();
            end;
        }
        field(8; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
            ToolTip = 'Specifies the date when this reference expires.';

            trigger OnValidate()
            begin
                CheckDates();
            end;
        }
    }

    keys
    {
        key(PK; "Asset No.", "Reference Type", "Reference Type No.", "Reference No.")
        {
            Clustered = true;
        }
        key(Key2; "Reference No.")
        {
        }
        key(Key3; "Reference No.", "Reference Type", "Reference Type No.")
        {
        }
        key(Key4; "Reference Type", "Reference No.")
        {
        }
        key(Key5; "Reference Type", "Reference Type No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Asset No.", "Reference Type", "Reference Type No.", "Reference No.")
        {
        }
        fieldgroup(Brick; "Asset No.", "Reference Type", "Reference No.", Description)
        {
        }
    }

    trigger OnInsert()
    begin
        if ("Reference Type No." <> '') and ("Reference Type" = "Reference Type"::" ") then
            Error(BlankReferenceTypeErr);
    end;

    trigger OnRename()
    begin
        if ("Reference Type No." <> '') and ("Reference Type" = "Reference Type"::" ") then
            Error(BlankReferenceTypeErr);
    end;

    local procedure CheckDates()
    var
        StartingEndingDateErr: Label '%1 %2 is before %3 %4.', Comment = '%1 and %3 = Date Captions, %2 and %4 = Date Values';
    begin
        if "Ending Date" = 0D then
            exit;
        if "Ending Date" < "Starting Date" then
            Error(StartingEndingDateErr, FieldCaption("Ending Date"), "Ending Date", FieldCaption("Starting Date"), "Starting Date");
    end;

    var
        BlankReferenceTypeErr: Label 'You cannot enter a Reference Type No. for a blank Reference Type.';
}
