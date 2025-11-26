table 70182329 "JML AP Component Entry"
{
    Caption = 'Component Entry';
    DataClassification = CustomerContent;
    DrillDownPageId = "JML AP Component Entries";
    LookupPageId = "JML AP Component Entries";

    fields
    {
        // === PRIMARY KEY ===
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the entry number.';
        }

        // === ASSET REFERENCE ===
        field(10; "Asset No."; Code[20])
        {
            Caption = 'Asset No.';
            ToolTip = 'Specifies the asset number.';
            TableRelation = "JML AP Asset";
            NotBlank = true;
        }

        field(11; "Asset Description"; Text[100])
        {
            Caption = 'Asset Description';
            ToolTip = 'Specifies the asset description.';
            FieldClass = FlowField;
            CalcFormula = Lookup("JML AP Asset".Description where("No." = field("Asset No.")));
            Editable = false;
        }

        // === COMPONENT IDENTIFICATION ===
        field(20; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            ToolTip = 'Specifies the item number.';
            TableRelation = Item;
            NotBlank = true;
        }

        field(21; "Item Description"; Text[100])
        {
            Caption = 'Item Description';
            ToolTip = 'Specifies the item description.';
            FieldClass = FlowField;
            CalcFormula = Lookup(Item.Description where("No." = field("Item No.")));
            Editable = false;
        }

        field(22; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            ToolTip = 'Specifies the variant code.';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }

        // === ENTRY TYPE ===
        field(30; "Entry Type"; Enum "JML AP Component Entry Type")
        {
            Caption = 'Entry Type';
            ToolTip = 'Specifies the entry type (Install, Remove, Replace, Adjustment).';
        }

        // === QUANTITY ===
        field(40; Quantity; Decimal)
        {
            Caption = 'Quantity';
            ToolTip = 'Specifies the quantity (positive for Install/Add, negative for Remove).';
            DecimalPlaces = 0 : 5;
        }

        field(41; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            ToolTip = 'Specifies the unit of measure code.';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }

        // === PHYSICAL DETAILS ===
        field(50; Position; Text[50])
        {
            Caption = 'Position';
            ToolTip = 'Specifies the physical location within the asset (e.g., "Front Panel", "Engine Bay").';
        }

        field(51; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
            ToolTip = 'Specifies the serial number for serialized components.';
        }

        field(52; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
            ToolTip = 'Specifies the lot number.';
        }

        // === DOCUMENT TRACKING ===
        field(60; "Document Type"; Enum "JML AP Document Type")
        {
            Caption = 'Document Type';
            ToolTip = 'Specifies the document type.';
        }

        field(61; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the document number.';
        }

        field(62; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
            ToolTip = 'Specifies the document line number.';
        }

        field(63; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            ToolTip = 'Specifies the external document number.';
        }

        field(64; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            ToolTip = 'Specifies the transaction number grouping related entries.';
        }

        // === POSTING INFO ===
        field(70; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the posting date.';
        }

        field(71; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            ToolTip = 'Specifies the reason code.';
            TableRelation = "Reason Code";
        }

        field(72; "User ID"; Code[50])
        {
            Caption = 'User ID';
            ToolTip = 'Specifies the user who created the entry.';
            Editable = false;
        }

        field(73; "Created DateTime"; DateTime)
        {
            Caption = 'Created Date Time';
            ToolTip = 'Specifies when the entry was created.';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Asset; "Asset No.", "Posting Date")
        {
        }
        key(Item; "Item No.", "Asset No.")
        {
        }
        key(Document; "Document Type", "Document No.")
        {
        }
        key(Transaction; "Transaction No.")
        {
        }
    }

    trigger OnInsert()
    begin
        "User ID" := CopyStr(UserId, 1, MaxStrLen("User ID"));
        "Created DateTime" := CurrentDateTime;
    end;
}
