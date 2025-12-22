table 70182325 "JML AP Pstd Purch Rcpt Ast Ln"
{
    Caption = 'Posted Purchase Receipt Asset Line';
    DataClassification = CustomerContent;
    LookupPageId = "JML AP Pstd Purch Rcpt Ast Sub";
    DrillDownPageId = "JML AP Pstd Purch Rcpt Ast Sub";

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the number of the posted purchase receipt.';
            DataClassification = CustomerContent;
            TableRelation = "Purch. Rcpt. Header"."No.";
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
            ToolTip = 'Specifies the asset that was received.';
            DataClassification = CustomerContent;
            TableRelation = "JML AP Asset";
            Editable = false;
        }
        field(11; "Asset Description"; Text[100])
        {
            Caption = 'Asset Description';
            ToolTip = 'Specifies the description of the asset.';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(20; "Buy-from Vendor No."; Code[20])
        {
            Caption = 'Buy-from Vendor No.';
            ToolTip = 'Specifies the vendor from whom the asset was received.';
            DataClassification = CustomerContent;
            TableRelation = Vendor."No.";
            Editable = false;
        }
        field(21; "Buy-from Vendor Name"; Text[100])
        {
            Caption = 'Buy-from Vendor Name';
            ToolTip = 'Specifies the name of the vendor from whom the asset was received.';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(30; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            ToolTip = 'Specifies the location where the asset was received.';
            DataClassification = CustomerContent;
            TableRelation = Location.Code;
            Editable = false;
        }

        field(40; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            ToolTip = 'Specifies the reason code for this asset receipt.';
            DataClassification = CustomerContent;
            TableRelation = "Reason Code";
            Editable = false;
        }
        field(41; "Description"; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description for this asset line.';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(50; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the posting date of the receipt.';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(60; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            ToolTip = 'Links to the asset holder entry transaction number created by this receipt.';
            DataClassification = CustomerContent;
            TableRelation = "JML AP Holder Entry"."Transaction No.";
            Editable = false;
        }

        field(70; "Correction"; Boolean)
        {
            Caption = 'Correction';
            ToolTip = 'Specifies if this line was undone or is a correction line.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(71; "Appl.-from Asset Line No."; Integer)
        {
            Caption = 'Appl.-from Asset Line No.';
            ToolTip = 'Specifies the line number of the original asset line that this correction line undoes.';
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
        key(Asset; "Asset No.", "Posting Date")
        {
        }
        key(Transaction; "Transaction No.")
        {
        }
    }
}
