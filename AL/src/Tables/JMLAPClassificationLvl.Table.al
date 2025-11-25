table 70182303 "JML AP Classification Lvl"
{
    Caption = 'Classification Level';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Industry Code"; Code[20])
        {
            Caption = 'Industry Code';
            ToolTip = 'Specifies the industry code this level belongs to.';
            TableRelation = "JML AP Asset Industry";
            NotBlank = true;
        }

        field(2; "Level Number"; Integer)
        {
            Caption = 'Level Number';
            ToolTip = 'Specifies the level number (1 = root level).';
            NotBlank = true;
            MinValue = 1;
            MaxValue = 50;
        }

        field(10; "Level Name"; Text[50])
        {
            Caption = 'Level Name';
            ToolTip = 'Specifies the name of this level (e.g., "Fleet", "Vessel Type").';
            NotBlank = true;
        }

        field(20; "Parent Level Number"; Integer)
        {
            Caption = 'Parent Level Number';
            ToolTip = 'Specifies the parent level number (0 for Level 1).';
            Editable = false;
        }

        field(30; "Use in Lists"; Boolean)
        {
            Caption = 'Use in Lists';
            ToolTip = 'Specifies whether this level should be shown in list filters.';
            InitValue = true;
        }

        field(40; "Value Count"; Integer)
        {
            Caption = 'Value Count';
            ToolTip = 'Specifies the number of values defined for this level.';
            FieldClass = FlowField;
            CalcFormula = Count("JML AP Classification Val"
                where("Industry Code" = field("Industry Code"),
                      "Level Number" = field("Level Number")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Industry Code", "Level Number")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Level Number", "Level Name")
        {
        }
    }

    trigger OnInsert()
    begin
        ValidateLevelNumberSequence();
        UpdateParentLevel();
    end;

    trigger OnModify()
    begin
        ValidateLevelNumberSequence();
    end;

    trigger OnDelete()
    begin
        ValidateLevelCanBeDeleted();
    end;

    local procedure ValidateLevelNumberSequence()
    var
        PreviousLevel: Record "JML AP Classification Lvl";
    begin
        // Level 1 is always valid
        if "Level Number" = 1 then
            exit;

        // Check previous level exists
        if not PreviousLevel.Get("Industry Code", "Level Number" - 1) then
            Error(PreviousLevelMustExistErr, "Level Number" - 1, "Level Number");
    end;

    local procedure UpdateParentLevel()
    begin
        if "Level Number" > 1 then
            "Parent Level Number" := "Level Number" - 1
        else
            "Parent Level Number" := 0;
    end;

    local procedure ValidateLevelCanBeDeleted()
    var
        ClassificationValue: Record "JML AP Classification Val";
        NextLevel: Record "JML AP Classification Lvl";
    begin
        // Cannot delete if values exist
        ClassificationValue.SetRange("Industry Code", "Industry Code");
        ClassificationValue.SetRange("Level Number", "Level Number");
        if not ClassificationValue.IsEmpty then
            Error(CannotDeleteLevelWithValuesErr, "Level Number");

        // Cannot delete if child levels exist
        if NextLevel.Get("Industry Code", "Level Number" + 1) then
            Error(CannotDeleteLevelWithChildLevelsErr, "Level Number", "Level Number" + 1);
    end;

    var
        PreviousLevelMustExistErr: Label 'Level %1 must exist before creating Level %2.', Comment = '%1 = Previous level number, %2 = Current level number';
        CannotDeleteLevelWithValuesErr: Label 'Cannot delete Level %1 because classification values exist.', Comment = '%1 = Level number';
        CannotDeleteLevelWithChildLevelsErr: Label 'Cannot delete Level %1 because Level %2 exists. Delete child levels first.', Comment = '%1 = Level number, %2 = Child level number';
}
