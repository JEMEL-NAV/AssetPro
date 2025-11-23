table 70182316 "JML AP Pstd. Asset Trans. Line"
{
    Caption = 'Posted Asset Transfer Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "JML AP Posted Asset Transfer"."No.";
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
        }

        field(11; "Asset Description"; Text[100])
        {
            Caption = 'Asset Description';
            DataClassification = CustomerContent;
        }

        field(12; "From Holder Type"; Enum "JML AP Holder Type")
        {
            Caption = 'From Holder Type';
            DataClassification = CustomerContent;
        }

        field(13; "From Holder Code"; Code[20])
        {
            Caption = 'From Holder Code';
            DataClassification = CustomerContent;
        }

        field(14; "From Holder Name"; Text[100])
        {
            Caption = 'From Holder Name';
            DataClassification = CustomerContent;
        }

        field(15; "From Holder Addr Code"; Code[10])
        {
            Caption = 'From Holder Address Code';
            ToolTip = 'Specifies the holder address code of the asset at time of transfer.';
            DataClassification = CustomerContent;
        }

        field(20; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }

        field(30; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
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
        key(AssetKey; "Asset No.")
        {
        }
    }
}
