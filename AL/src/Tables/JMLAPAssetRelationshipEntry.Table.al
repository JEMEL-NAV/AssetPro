table 70182317 "JML AP Asset Relation Entry"
{
    Caption = 'Asset Relationship Entry';
    DataClassification = CustomerContent;
    LookupPageId = "JML AP Relationship Entries";
    DrillDownPageId = "JML AP Relationship Entries";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the unique entry number for this relationship entry.';
            DataClassification = CustomerContent;
            AutoIncrement = true;
        }
        field(2; "Entry Type"; Enum "JML AP Relationship Entry Type")
        {
            Caption = 'Entry Type';
            ToolTip = 'Specifies whether this is an Attach or Detach event.';
            DataClassification = CustomerContent;
        }
        field(10; "Asset No."; Code[20])
        {
            Caption = 'Asset No.';
            ToolTip = 'Specifies the asset that was attached to or detached from a parent.';
            DataClassification = CustomerContent;
            TableRelation = "JML AP Asset";
        }
        field(11; "Parent Asset No."; Code[20])
        {
            Caption = 'Parent Asset No.';
            ToolTip = 'Specifies the parent asset in the relationship.';
            DataClassification = CustomerContent;
            TableRelation = "JML AP Asset";
        }
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the posting date when the relationship change occurred.';
            DataClassification = CustomerContent;
        }
        field(21; "Entry Date"; Date)
        {
            Caption = 'Entry Date';
            ToolTip = 'Specifies the date when this entry was created.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(22; "Entry Time"; Time)
        {
            Caption = 'Entry Time';
            ToolTip = 'Specifies the time when this entry was created.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(30; "Holder Type at Entry"; Enum "JML AP Holder Type")
        {
            Caption = 'Holder Type at Entry';
            ToolTip = 'Specifies the holder type of the asset at the time of the relationship change.';
            DataClassification = CustomerContent;
        }
        field(31; "Holder Code at Entry"; Code[20])
        {
            Caption = 'Holder Code at Entry';
            ToolTip = 'Specifies the holder code of the asset at the time of the relationship change.';
            DataClassification = CustomerContent;
        }
        field(40; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            ToolTip = 'Specifies the reason code for the relationship change.';
            DataClassification = CustomerContent;
            TableRelation = "Reason Code";
        }
        field(41; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the relationship change.';
            DataClassification = CustomerContent;
        }
        field(50; "User ID"; Code[50])
        {
            Caption = 'User ID';
            ToolTip = 'Specifies the user who created this entry.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(51; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            ToolTip = 'Specifies the transaction number that links related relationship entries.';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(AssetLookup; "Asset No.", "Posting Date")
        {
        }
        key(ParentLookup; "Parent Asset No.", "Posting Date")
        {
        }
        key(TransactionLookup; "Transaction No.")
        {
        }
    }

    trigger OnInsert()
    begin
        "Entry Date" := Today;
        "Entry Time" := Time;
        if "User ID" = '' then
            "User ID" := CopyStr(UserId, 1, MaxStrLen("User ID"));
    end;
}
