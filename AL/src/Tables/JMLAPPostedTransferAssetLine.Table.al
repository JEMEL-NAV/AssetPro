table 70182323 "JML AP Pstd Trans Shpt Ast Ln"
{
    Caption = 'Posted Transfer Shipment Asset Line';
    DataClassification = CustomerContent;
    LookupPageId = "JML AP Pstd Trans Shpt Ast Sub";
    DrillDownPageId = "JML AP Pstd Trans Shpt Ast Sub";

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the number of the posted transfer shipment document.';
            DataClassification = CustomerContent;
            TableRelation = "Transfer Shipment Header"."No.";
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
        }
        field(11; "Asset Description"; Text[100])
        {
            Caption = 'Asset Description';
            ToolTip = 'Specifies the description of the asset.';
            DataClassification = CustomerContent;
        }

        field(20; "Transfer-from Code"; Code[10])
        {
            Caption = 'Transfer-from Code';
            ToolTip = 'Specifies the source location code.';
            DataClassification = CustomerContent;
            TableRelation = Location.Code;
        }
        field(21; "Transfer-from Name"; Text[100])
        {
            Caption = 'Transfer-from Name';
            ToolTip = 'Specifies the name of the source location.';
            DataClassification = CustomerContent;
        }
        field(22; "Transfer-to Code"; Code[10])
        {
            Caption = 'Transfer-to Code';
            ToolTip = 'Specifies the destination location code.';
            DataClassification = CustomerContent;
            TableRelation = Location.Code;
        }
        field(23; "Transfer-to Name"; Text[100])
        {
            Caption = 'Transfer-to Name';
            ToolTip = 'Specifies the name of the destination location.';
            DataClassification = CustomerContent;
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

        field(40; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the posting date of the transfer shipment.';
            DataClassification = CustomerContent;
        }
        field(41; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            ToolTip = 'Specifies the transaction number linking this asset transfer to holder entries.';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Document No.", "Line No.")
        {
            Clustered = true;
        }
        key(Asset; "Asset No.")
        {
        }
        key(Transaction; "Transaction No.")
        {
        }
    }
}
