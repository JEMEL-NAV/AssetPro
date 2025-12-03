table 70182302 "JML AP Asset Industry"
{
    Caption = 'Asset Industry';
    DataClassification = CustomerContent;
    LookupPageId = "JML AP Industries";
    DrillDownPageId = "JML AP Industries";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            ToolTip = 'Specifies the unique code for this industry.';
            NotBlank = true;
        }

        field(10; Name; Text[100])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the name of the industry.';
        }

        field(20; "Number of Levels"; Integer)
        {
            Caption = 'Number of Levels';
            ToolTip = 'Specifies the number of classification levels defined for this industry.';
            FieldClass = FlowField;
            CalcFormula = Count("JML AP Classification Lvl" where("Industry Code" = field("Code")));
            Editable = false;
        }

        field(21; "Number of Values"; Integer)
        {
            Caption = 'Number of Values';
            ToolTip = 'Specifies the number of classification values defined for this industry.';
            FieldClass = FlowField;
            CalcFormula = Count("JML AP Classification Val" where("Industry Code" = field("Code")));
            Editable = false;
        }

        field(22; "Number of Assets"; Integer)
        {
            Caption = 'Number of Assets';
            ToolTip = 'Specifies the number of assets using this industry.';
            FieldClass = FlowField;
            CalcFormula = Count("JML AP Asset" where("Industry Code" = field("Code")));
            Editable = false;
        }

        field(100; Blocked; Boolean)
        {
            Caption = 'Blocked';
            ToolTip = 'Specifies whether this industry is blocked from use.';
        }

        // Note: Industry Template feature (field 110) deferred to Phase 2
        // Will allow pre-populating classification structures from templates
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
        key(Name; Name)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Code, Name)
        {
        }
    }

    trigger OnDelete()
    begin
        ValidateIndustryCanBeDeleted();
    end;

    local procedure ValidateIndustryCanBeDeleted()
    var
        Asset: Record "JML AP Asset";
        ClassificationValue: Record "JML AP Classification Val";
        ClassificationLevel: Record "JML AP Classification Lvl";
    begin
        // Cannot delete if assets exist
        Asset.SetRange("Industry Code", Code);
        if not Asset.IsEmpty then
            Error(CannotDeleteIndustryWithAssetsErr, Code);

        // Cannot delete if classification values exist
        ClassificationValue.SetRange("Industry Code", Code);
        if not ClassificationValue.IsEmpty then
            Error(CannotDeleteIndustryWithClassificationErr, Code);

        // Cannot delete if classification levels exist
        ClassificationLevel.SetRange("Industry Code", Code);
        if not ClassificationLevel.IsEmpty then
            Error(CannotDeleteIndustryWithLevelsErr, Code);
    end;

    var
        CannotDeleteIndustryWithAssetsErr: Label 'Cannot delete industry %1 because assets are using it.', Comment = '%1 = Industry Code';
        CannotDeleteIndustryWithClassificationErr: Label 'Cannot delete industry %1 because classification values exist. Delete classification values first.', Comment = '%1 = Industry Code';
        CannotDeleteIndustryWithLevelsErr: Label 'Cannot delete industry %1 because classification levels exist. Delete classification levels first.', Comment = '%1 = Industry Code';
}
