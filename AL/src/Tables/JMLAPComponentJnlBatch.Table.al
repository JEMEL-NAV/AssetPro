table 70182330 "JML AP Component Jnl. Batch"
{
    Caption = 'Component Journal Batch';
    DataClassification = CustomerContent;
    LookupPageId = "JML AP Component Jnl. Batches";
    DrillDownPageId = "JML AP Component Jnl. Batches";

    fields
    {
        field(1; "Name"; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the name of the component journal batch.';
        }

        field(2; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies a description of the component journal batch.';
        }

        field(3; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the reason code for component entries in this batch.';
        }

        field(10; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the number series for document numbers.';

            trigger OnValidate()
            begin
                if "No. Series" <> '' then begin
                    if "No. Series" = "Posting No. Series" then
                        Error(NoSeriesSameErr, FieldCaption("No. Series"), FieldCaption("Posting No. Series"));
                end;
            end;
        }

        field(11; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the number series for posted document numbers.';

            trigger OnValidate()
            begin
                if "Posting No. Series" <> '' then begin
                    if "Posting No. Series" = "No. Series" then
                        Error(NoSeriesSameErr, FieldCaption("Posting No. Series"), FieldCaption("No. Series"));
                end;
            end;
        }
    }

    keys
    {
        key(PK; "Name")
        {
            Clustered = true;
        }
    }

    trigger OnDelete()
    var
        ComponentJnlLine: Record "JML AP Component Journal Line";
    begin
        ComponentJnlLine.SetRange("Journal Batch", Name);
        ComponentJnlLine.DeleteAll(true);
    end;

    var
        NoSeriesSameErr: Label '%1 and %2 must be different.';
}
