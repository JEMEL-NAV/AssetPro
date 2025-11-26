table 70182328 "JML AP Component Journal Line"
{
    Caption = 'Component Journal Line';
    DataClassification = CustomerContent;

    fields
    {
        // === PRIMARY KEY ===
        field(1; "Journal Batch"; Code[20])
        {
            Caption = 'Journal Batch';
            ToolTip = 'Specifies the journal batch.';
            TableRelation = "JML AP Asset Journal Batch";
        }

        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            ToolTip = 'Specifies the line number.';
        }

        // === ASSET ===
        field(10; "Asset No."; Code[20])
        {
            Caption = 'Asset No.';
            ToolTip = 'Specifies the asset number.';
            TableRelation = "JML AP Asset";

            trigger OnValidate()
            var
                Asset: Record "JML AP Asset";
            begin
                if Asset.Get("Asset No.") then
                    "Asset Description" := Asset.Description
                else
                    "Asset Description" := '';
            end;
        }

        field(11; "Asset Description"; Text[100])
        {
            Caption = 'Asset Description';
            ToolTip = 'Specifies the asset description.';
        }

        // === COMPONENT ===
        field(20; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            ToolTip = 'Specifies the item number.';
            TableRelation = Item;

            trigger OnValidate()
            var
                Item: Record Item;
            begin
                if Item.Get("Item No.") then begin
                    "Item Description" := Item.Description;
                    if "Unit of Measure Code" = '' then
                        "Unit of Measure Code" := Item."Base Unit of Measure";
                end else begin
                    "Item Description" := '';
                end;
            end;
        }

        field(21; "Item Description"; Text[100])
        {
            Caption = 'Item Description';
            ToolTip = 'Specifies the item description.';
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
            ToolTip = 'Specifies the quantity (positive for Install, negative for Remove).';
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
            ToolTip = 'Specifies the physical location within the asset.';
        }

        field(51; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
            ToolTip = 'Specifies the serial number.';
        }

        field(52; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
            ToolTip = 'Specifies the lot number.';
        }

        // === POSTING INFO ===
        field(60; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the posting date.';
        }

        field(61; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            ToolTip = 'Specifies the reason code.';
            TableRelation = "Reason Code";
        }

        field(62; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the document number.';
        }

        field(63; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            ToolTip = 'Specifies the external document number.';
        }
    }

    keys
    {
        key(PK; "Journal Batch", "Line No.")
        {
            Clustered = true;
        }
    }
}
