table 70182315 "JML AP Posted Asset Transfer"
{
    Caption = 'Posted Asset Transfer';
    DataClassification = CustomerContent;
    LookupPageId = "JML AP Asset Posted Transfers";
    DrillDownPageId = "JML AP Asset Posted Transfers";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = CustomerContent;
        }

        field(2; "Transfer Order No."; Code[20])
        {
            Caption = 'Transfer Order No.';
            DataClassification = CustomerContent;
        }

        field(3; "From Holder Type"; Enum "JML AP Holder Type")
        {
            Caption = 'From Holder Type';
            DataClassification = CustomerContent;
        }

        field(4; "From Holder Code"; Code[20])
        {
            Caption = 'From Holder Code';
            DataClassification = CustomerContent;
        }

        field(5; "From Holder Name"; Text[100])
        {
            Caption = 'From Holder Name';
            DataClassification = CustomerContent;
        }

        field(10; "To Holder Type"; Enum "JML AP Holder Type")
        {
            Caption = 'To Holder Type';
            DataClassification = CustomerContent;
        }

        field(11; "To Holder Code"; Code[20])
        {
            Caption = 'To Holder Code';
            DataClassification = CustomerContent;
        }

        field(12; "To Holder Name"; Text[100])
        {
            Caption = 'To Holder Name';
            DataClassification = CustomerContent;
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

        field(40; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
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

        field(60; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
        key(OrderKey; "Transfer Order No.")
        {
        }
        key(DateKey; "Posting Date")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "From Holder Code", "To Holder Code", "Posting Date")
        {
        }
    }
}
