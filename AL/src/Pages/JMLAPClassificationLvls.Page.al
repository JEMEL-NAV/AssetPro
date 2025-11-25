page 70182335 "JML AP Classification Lvls"
{
    Caption = 'Classification Levels';
    PageType = List;
    SourceTable = "JML AP Classification Lvl";
    UsageCategory = Administration;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Levels)
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
                field("Level Name"; Rec."Level Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the level name.';
                }
                field("Use in Lists"; Rec."Use in Lists")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether to use in lists.';
                }
            }
        }
    }
    actions
    {
        area(Navigation)
        {
            action(LevelAttributes)
            {
                ApplicationArea = All;
                Caption = 'Attributes';
                ToolTip = 'View classification levels for this industry.';
                Image = Hierarchy;
                RunObject = page "JML AP Attribute Defns";
                RunPageLink = "Industry Code" = field("Industry Code"), "Level Number" = field("Level Number");
            }
        }
        area(Promoted)
        {
            actionref(LevelAttributes_Promoted; LevelAttributes) { }
        }
    }
}
