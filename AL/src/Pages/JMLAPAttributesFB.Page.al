page 70182338 "JML AP Attributes FB"
{
    Caption = 'Attributes';
    PageType = ListPart;
    SourceTable = "JML AP Attribute Value";
    ApplicationArea = All;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Attributes)
            {
                field("Attribute Code"; Rec."Attribute Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the attribute code.';
                }
                field("Attribute Name"; Rec."Attribute Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the attribute name.';
                }
                field("Display Value"; DisplayValue)
                {
                    ApplicationArea = All;
                    Caption = 'Value';
                    ToolTip = 'Specifies the attribute value.';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(EditAttributes)
            {
                ApplicationArea = All;
                Caption = 'Edit';
                ToolTip = 'Edit the asset''s attribute values.';
                Image = Edit;

                trigger OnAction()
                var
                    Asset: Record "JML AP Asset";
                    AttrValueEditor: Page "JML AP Attr Value Editor";
                begin
                    if AssetNo = '' then
                        exit;

                    if not Asset.Get(AssetNo) then
                        exit;

                    AttrValueEditor.SetRecord(Asset);
                    if AttrValueEditor.RunModal() = Action::OK then begin
                        CurrPage.Update(false);
                        LoadAttributesForAsset(AssetNo);
                    end;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        DisplayValue := Rec.GetDisplayValue();
        Rec.CalcFields("Attribute Name");
        if Rec."Asset No." <> '' then
            AssetNo := Rec."Asset No.";
    end;

    trigger OnAfterGetCurrRecord()
    begin
        if Rec."Asset No." <> '' then
            AssetNo := Rec."Asset No.";
    end;

    var
        AssetNo: Code[20];
        DisplayValue: Text[250];

    /// <summary>
    /// Loads attributes for the specified asset.
    /// </summary>
    procedure LoadAttributesForAsset(NewAssetNo: Code[20])
    begin
        AssetNo := NewAssetNo;
        Rec.SetRange("Asset No.", AssetNo);
        CurrPage.Update(false);
    end;
}
