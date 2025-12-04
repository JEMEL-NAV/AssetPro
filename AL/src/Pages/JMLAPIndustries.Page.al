page 70182334 "JML AP Industries"
{
    Caption = 'Asset Industries';
    Description = 'Define industry codes for categorizing assets by business sector or industry type.';
    PageType = List;
    SourceTable = "JML AP Asset Industry";
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Industries)
            {
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the industry code.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the industry name.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the industry is blocked.';
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(ClassificationLevels)
            {
                ApplicationArea = All;
                Caption = 'Classification Levels';
                ToolTip = 'View classification levels for this industry.';
                Image = Hierarchy;
                RunObject = page "JML AP Classification Lvls";
                RunPageLink = "Industry Code" = field(Code);
            }
            action(ClassificationValues)
            {
                ApplicationArea = All;
                Caption = 'Classification Values';
                ToolTip = 'View classification values for this industry.';
                Image = List;
                RunObject = page "JML AP Classification Vals";
                RunPageLink = "Industry Code" = field(Code);
            }
        }
        area(Promoted)
        {
            actionref(ClassificationLevels_Promoted; ClassificationLevels) { }
            actionref(ClassificationValues_Promoted; ClassificationValues) { }
        }
    }
}
