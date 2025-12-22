page 70182337 "JML AP Attribute Defns"
{
    Caption = 'Attribute Definitions';
    Description = 'Define custom attribute definitions for tracking additional asset properties and characteristics.';
    PageType = List;
    SourceTable = "JML AP Attribute Defn";
    UsageCategory = Administration;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Attributes)
            {
                field("Industry Code"; Rec."Industry Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the industry code.';
                }
                field("Level Number"; Rec."Level Number")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the level number.';
                }
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
                field("Data Type"; Rec."Data Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the data type.';
                }
                field("Option String"; Rec."Option String")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the option string for option data types.';
                }
                field(Mandatory; Rec.Mandatory)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether mandatory.';
                }
                field("Default Value"; Rec."Default Value")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the default value.';
                }
                field("Display Order"; Rec."Display Order")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the display order.';
                }
            }
        }
    }
}
