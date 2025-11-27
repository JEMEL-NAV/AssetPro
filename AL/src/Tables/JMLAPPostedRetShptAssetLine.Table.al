table 70182327 "JML AP Pstd Ret Shpt Ast Ln"
{
    Caption = 'Posted Return Shipment Asset Line';
    DataClassification = CustomerContent;
    LookupPageId = "JML AP Pstd Ret Shpt Ast Sub";
    DrillDownPageId = "JML AP Pstd Ret Shpt Ast Sub";

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the number of the posted return shipment.';
            DataClassification = CustomerContent;
            TableRelation = "Return Shipment Header"."No.";
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
            ToolTip = 'Specifies the asset that was returned.';
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
            ToolTip = 'Specifies the vendor to whom the asset was returned.';
            DataClassification = CustomerContent;
            TableRelation = Vendor."No.";
            Editable = false;
        }
        field(21; "Buy-from Vendor Name"; Text[100])
        {
            Caption = 'Buy-from Vendor Name';
            ToolTip = 'Specifies the name of the vendor to whom the asset was returned.';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(30; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            ToolTip = 'Specifies the location from which the asset was returned.';
            DataClassification = CustomerContent;
            TableRelation = Location.Code;
            Editable = false;
        }

        field(40; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            ToolTip = 'Specifies the reason code for this asset return.';
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
            ToolTip = 'Specifies the posting date of the return shipment.';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(60; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            ToolTip = 'Links to the asset holder entry transaction number created by this return shipment.';
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
