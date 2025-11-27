table 70182324 "JML AP Pstd Sales Shpt Ast Ln"
{
    Caption = 'Posted Sales Shipment Asset Line';
    DataClassification = CustomerContent;
    LookupPageId = "JML AP Pstd Sales Shpt Ast Sub";
    DrillDownPageId = "JML AP Pstd Sales Shpt Ast Sub";

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the number of the posted sales shipment.';
            DataClassification = CustomerContent;
            TableRelation = "Sales Shipment Header"."No.";
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
            ToolTip = 'Specifies the asset that was transferred.';
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

        field(20; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            ToolTip = 'Specifies the customer who received the asset.';
            DataClassification = CustomerContent;
            TableRelation = Customer."No.";
            Editable = false;
        }
        field(21; "Sell-to Customer Name"; Text[100])
        {
            Caption = 'Sell-to Customer Name';
            ToolTip = 'Specifies the name of the customer who received the asset.';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(30; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            ToolTip = 'Specifies the reason code for this asset transfer.';
            DataClassification = CustomerContent;
            TableRelation = "Reason Code";
            Editable = false;
        }
        field(31; "Description"; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description for this asset line.';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(40; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the posting date of the shipment.';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(50; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            ToolTip = 'Links to the asset holder entry transaction number created by this shipment.';
            DataClassification = CustomerContent;
            TableRelation = "JML AP Holder Entry"."Transaction No.";
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
