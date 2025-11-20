table 70182310 "JML AP Asset Attr Val Sel"
{
    Caption = 'Asset Attribute Value Selection';
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; "Attribute Name"; Text[250])
        {
            Caption = 'Attribute Name';
            ToolTip = 'Specifies the attribute name.';
            TableRelation = "JML AP Attribute Defn"."Attribute Name";

            trigger OnValidate()
            begin
                if "Attribute Name" = xRec."Attribute Name" then
                    exit;

                GetAttributeDefn();
            end;

            trigger OnLookup()
            var
                AttributeDefn: Record "JML AP Attribute Defn";
                AttributeDefns: Page "JML AP Attribute Defns";
            begin
                if IndustryCode <> '' then
                    AttributeDefn.SetRange("Industry Code", IndustryCode);
                if LevelNumber > 0 then
                    AttributeDefn.SetRange("Level Number", LevelNumber);
                AttributeDefn.SetRange(Blocked, false);

                AttributeDefns.SetTableView(AttributeDefn);
                AttributeDefns.LookupMode := true;
                if AttributeDefns.RunModal() = Action::LookupOK then begin
                    AttributeDefns.GetRecord(AttributeDefn);
                    "Attribute Name" := AttributeDefn."Attribute Name";
                    Validate("Attribute Name");
                end;
            end;
        }

        field(2; "Attribute Code"; Code[20])
        {
            Caption = 'Attribute Code';
            ToolTip = 'Specifies the attribute code.';
            Editable = false;
        }

        field(3; "Industry Code"; Code[20])
        {
            Caption = 'Industry Code';
            ToolTip = 'Specifies the industry code.';
            Editable = false;
        }

        field(4; "Level Number"; Integer)
        {
            Caption = 'Level Number';
            ToolTip = 'Specifies the level number.';
            Editable = false;
        }

        field(10; Value; Text[250])
        {
            Caption = 'Value';
            ToolTip = 'Specifies the attribute value.';

            trigger OnValidate()
            begin
                ValidateValueByType();
            end;
        }

        field(11; "Data Type"; Enum "JML AP Attribute Type")
        {
            Caption = 'Data Type';
            ToolTip = 'Specifies the data type.';
            Editable = false;
        }

        field(12; "Option String"; Text[250])
        {
            Caption = 'Option String';
            ToolTip = 'Specifies the option string.';
            Editable = false;
        }

        field(20; "Unit of Measure"; Text[30])
        {
            Caption = 'Unit of Measure';
            ToolTip = 'Specifies the unit of measure.';
        }
    }

    keys
    {
        key(PK; "Attribute Code")
        {
            Clustered = true;
        }
    }

    var
        IndustryCode: Code[20];
        LevelNumber: Integer;
        InvalidValueForTypeErr: Label 'The value is not valid for data type %1.', Comment = '%1 = Data type';

    /// <summary>
    /// Sets the filter context for attribute selection.
    /// </summary>
    procedure SetContext(NewIndustryCode: Code[20]; NewLevelNumber: Integer)
    begin
        IndustryCode := NewIndustryCode;
        LevelNumber := NewLevelNumber;
    end;

    /// <summary>
    /// Populates selection from existing attribute values.
    /// </summary>
    procedure PopulateFromAsset(AssetNo: Code[20])
    var
        AttributeValue: Record "JML AP Attribute Value";
        AttributeDefn: Record "JML AP Attribute Defn";
    begin
        Rec.DeleteAll();

        AttributeValue.SetRange("Asset No.", AssetNo);
        if AttributeValue.FindSet() then
            repeat
                // Find the attribute definition by searching all combinations
                AttributeDefn.SetRange("Attribute Code", AttributeValue."Attribute Code");
                if IndustryCode <> '' then
                    AttributeDefn.SetRange("Industry Code", IndustryCode);
                if LevelNumber > 0 then
                    AttributeDefn.SetRange("Level Number", LevelNumber);

                if AttributeDefn.FindFirst() then begin
                    Rec.Init();
                    Rec."Attribute Code" := AttributeValue."Attribute Code";
                    Rec."Attribute Name" := AttributeDefn."Attribute Name";
                    Rec."Industry Code" := AttributeDefn."Industry Code";
                    Rec."Level Number" := AttributeDefn."Level Number";
                    Rec."Data Type" := AttributeDefn."Data Type";
                    Rec."Option String" := AttributeDefn."Option String";
                    Rec.Value := AttributeValue.GetDisplayValue();
                    if Rec.Insert() then;
                end;
                AttributeDefn.Reset();
            until AttributeValue.Next() = 0;
    end;

    local procedure GetAttributeDefn()
    var
        AttributeDefn: Record "JML AP Attribute Defn";
    begin
        AttributeDefn.SetRange("Attribute Name", "Attribute Name");
        if IndustryCode <> '' then
            AttributeDefn.SetRange("Industry Code", IndustryCode);
        if LevelNumber > 0 then
            AttributeDefn.SetRange("Level Number", LevelNumber);

        if AttributeDefn.FindFirst() then begin
            "Attribute Code" := AttributeDefn."Attribute Code";
            "Industry Code" := AttributeDefn."Industry Code";
            "Level Number" := AttributeDefn."Level Number";
            "Data Type" := AttributeDefn."Data Type";
            "Option String" := AttributeDefn."Option String";
        end;
    end;

    local procedure ValidateValueByType()
    var
        IntValue: Integer;
        DecValue: Decimal;
        DateValue: Date;
        BoolValue: Boolean;
        Options: List of [Text];
        OptionFound: Boolean;
        i: Integer;
    begin
        if Value = '' then
            exit;

        case "Data Type" of
            "Data Type"::Text:
                exit;
            "Data Type"::Integer:
                if not Evaluate(IntValue, Value) then
                    Error(InvalidValueForTypeErr, "Data Type");
            "Data Type"::Decimal:
                if not Evaluate(DecValue, Value) then
                    Error(InvalidValueForTypeErr, "Data Type");
            "Data Type"::Date:
                if not Evaluate(DateValue, Value) then
                    Error(InvalidValueForTypeErr, "Data Type");
            "Data Type"::Boolean:
                if not Evaluate(BoolValue, Value) then
                    Error(InvalidValueForTypeErr, "Data Type");
            "Data Type"::Option:
                begin
                    if "Option String" = '' then
                        exit;
                    Options := "Option String".Split(',');
                    OptionFound := false;
                    for i := 1 to Options.Count do
                        if Value = Options.Get(i).Trim() then
                            OptionFound := true;
                    if not OptionFound then
                        Error(InvalidValueForTypeErr, "Data Type");
                end;
        end;
    end;

}
