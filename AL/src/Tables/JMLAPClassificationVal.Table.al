table 70182304 "JML AP Classification Val"
{
    Caption = 'Classification Value';
    DataClassification = CustomerContent;
    LookupPageId = "JML AP Classification Vals";
    DrillDownPageId = "JML AP Classification Vals";

    fields
    {
        field(1; "Industry Code"; Code[20])
        {
            Caption = 'Industry Code';
            ToolTip = 'Specifies the industry code this value belongs to.';
            TableRelation = "JML AP Asset Industry";
            NotBlank = true;
        }

        field(2; "Level Number"; Integer)
        {
            Caption = 'Level Number';
            ToolTip = 'Specifies the classification level this value belongs to.';
            TableRelation = "JML AP Classification Lvl"."Level Number" where("Industry Code" = field("Industry Code"));
            NotBlank = true;

            trigger OnValidate()
            begin
                CalcFields("Parent Level Number");
            end;
        }
        field(3; "Code"; Code[20])
        {
            Caption = 'Code';
            ToolTip = 'Specifies the unique code for this classification value.';
            NotBlank = true;
        }

        field(10; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of this classification value.';
        }

        field(20; "Parent Value Code"; Code[20])
        {
            Caption = 'Parent Value Code';
            ToolTip = 'Specifies the parent classification value code (required for Level 2+).';
            TableRelation = "JML AP Classification Val".Code
                where("Industry Code" = field("Industry Code"),
                      "Level Number" = field("Parent Level Number"));

            trigger OnValidate()
            begin
                ValidateParentValue();
            end;
        }

        field(21; "Parent Level Number"; Integer)
        {
            Caption = 'Parent Level Number';
            ToolTip = 'Specifies the parent level number.';
            FieldClass = FlowField;
            CalcFormula = Lookup("JML AP Classification Lvl"."Parent Level Number"
                where("Industry Code" = field("Industry Code"),
                      "Level Number" = field("Level Number")));
            Editable = false;
        }

        field(100; Blocked; Boolean)
        {
            Caption = 'Blocked';
            ToolTip = 'Specifies whether this classification value is blocked from use.';
        }

        field(110; "Asset Count"; Integer)
        {
            Caption = 'Asset Count';
            ToolTip = 'Specifies the number of assets directly classified with this value (leaf nodes only).';
            FieldClass = FlowField;
            CalcFormula = Count("JML AP Asset"
                where("Industry Code" = field("Industry Code"),
                      "Classification Code" = field(Code)));
            // Note: With normalized approach, this counts only assets DIRECTLY classified here (leaf nodes).
            // Does NOT count assets classified under child values.
            // For hierarchical count, use GetTotalAssetCount() procedure instead.
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Industry Code", "Level Number", Code)
        {
            Clustered = true;
        }
        key(Parent; "Industry Code", "Level Number", "Parent Value Code")
        {
        }
        key(Description; Description)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Code, Description)
        {
        }
    }

    trigger OnInsert()
    begin
        ValidateParentValue();
    end;

    trigger OnDelete()
    begin
        ValidateValueCanBeDeleted();
    end;

    local procedure ValidateParentValue()
    var
        ParentValue: Record "JML AP Classification Val";
    begin
        CalcFields("Parent Level Number");

        // Level 1 has no parent
        if "Level Number" = 1 then begin
            if "Parent Value Code" <> '' then
                Error(Level1CannotHaveParentErr);
            exit;
        end;

        // Level 2+ must have parent
        if "Parent Value Code" = '' then
            Error(ParentValueRequiredErr, "Level Number");

        // Parent must exist
        if not ParentValue.Get("Industry Code", "Parent Level Number", "Parent Value Code") then
            Error(ParentValueNotFoundErr, "Parent Value Code", "Parent Level Number");
    end;

    local procedure ValidateValueCanBeDeleted()
    var
        Asset: Record "JML AP Asset";
        ChildValue: Record "JML AP Classification Val";
    begin
        // Cannot delete if assets use this value (directly as their leaf classification)
        Asset.SetRange("Industry Code", "Industry Code");
        Asset.SetRange("Classification Code", Code);
        if not Asset.IsEmpty then
            Error(CannotDeleteValueInUseErr, Code);

        // Cannot delete if child values exist
        ChildValue.SetRange("Industry Code", "Industry Code");
        ChildValue.SetRange("Level Number", "Level Number" + 1);
        ChildValue.SetRange("Parent Value Code", Code);
        if not ChildValue.IsEmpty then
            Error(CannotDeleteValueWithChildrenErr, Code);
    end;

    var
        Level1CannotHaveParentErr: Label 'Level 1 values cannot have a parent value.';
        ParentValueRequiredErr: Label 'Level %1 values must have a parent value.', Comment = '%1 = Level number';
        ParentValueNotFoundErr: Label 'Parent value %1 does not exist at Level %2.', Comment = '%1 = Parent value code, %2 = Level number';
        CannotDeleteValueInUseErr: Label 'Cannot delete classification value %1 because assets are using it.', Comment = '%1 = Classification value code';
        CannotDeleteValueWithChildrenErr: Label 'Cannot delete classification value %1 because child values exist.', Comment = '%1 = Classification value code';
}
