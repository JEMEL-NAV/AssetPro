page 70182344 "JML AP Attr Value List"
{
    Caption = 'Asset Attribute Values';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "JML AP Asset Attr Val Sel";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            repeater(Attributes)
            {
                field("Attribute Name"; Rec."Attribute Name")
                {
                    ApplicationArea = All;
                    Caption = 'Attribute';
                    ToolTip = 'Specifies the attribute name.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field(Value; Rec.Value)
                {
                    ApplicationArea = All;
                    Caption = 'Value';
                    ToolTip = 'Specifies the attribute value.';

                    trigger OnValidate()
                    begin
                        SaveAttributeValue();
                    end;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        AttributeDefn: Record "JML AP Attribute Defn";
                        Options: List of [Text];
                        SelectedIndex: Integer;
                        i: Integer;
                        OptionString: Text;
                    begin
                        // Only provide lookup for Option type attributes
                        if Rec."Data Type" <> Rec."Data Type"::Option then
                            exit(false);

                        if Rec."Option String" = '' then
                            exit(false);

                        // Build option string for StrMenu
                        Options := Rec."Option String".Split(',');
                        if Options.Count = 0 then
                            exit(false);

                        // Create comma-separated string from trimmed options
                        Clear(OptionString);
                        for i := 1 to Options.Count do begin
                            if i > 1 then
                                OptionString += ',';
                            OptionString += Options.Get(i).Trim();
                        end;

                        // Show selection dialog
                        SelectedIndex := StrMenu(OptionString, 1);
                        if SelectedIndex > 0 then begin
                            Text := Options.Get(SelectedIndex).Trim();
                            exit(true);
                        end;

                        exit(false);
                    end;
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unit of measure.';
                    Visible = false;
                }
            }
        }
    }

    trigger OnDeleteRecord(): Boolean
    begin
        DeleteAttributeValue();
        exit(true);
    end;

    var
        AssetNo: Code[20];

    /// <summary>
    /// Loads attribute values for the specified asset.
    /// </summary>
    procedure LoadAttributes(NewAssetNo: Code[20]; IndustryCode: Code[20]; LevelNo: Integer)
    begin
        AssetNo := NewAssetNo;
        Rec.SetContext(IndustryCode, LevelNo);
        Rec.PopulateFromAsset(AssetNo);
        CurrPage.Update(false);
    end;

    local procedure SaveAttributeValue()
    var
        AttributeValue: Record "JML AP Attribute Value";
        AttributeDefn: Record "JML AP Attribute Defn";
    begin
        if AssetNo = '' then
            exit;
        if Rec."Attribute Code" = '' then
            exit;

        if not AttributeDefn.Get(Rec."Industry Code", Rec."Level Number", Rec."Attribute Code") then
            exit;

        if not AttributeValue.Get(AssetNo, Rec."Attribute Code") then begin
            AttributeValue.Init();
            AttributeValue."Asset No." := AssetNo;
            AttributeValue."Attribute Code" := Rec."Attribute Code";
            AttributeValue.SetValueFromText(Rec.Value);
            AttributeValue.Insert(true);
        end else begin
            AttributeValue.SetValueFromText(Rec.Value);
            AttributeValue.Modify(true);
        end;
    end;

    local procedure DeleteAttributeValue()
    var
        AttributeValue: Record "JML AP Attribute Value";
    begin
        if AssetNo = '' then
            exit;
        if Rec."Attribute Code" = '' then
            exit;

        if AttributeValue.Get(AssetNo, Rec."Attribute Code") then
            AttributeValue.Delete(true);
    end;
}
