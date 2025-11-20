page 70182336 "JML AP Classification Vals"
{
    Caption = 'Classification Values';
    PageType = List;
    SourceTable = "JML AP Classification Val";
    UsageCategory = Administration;
    ApplicationArea = All;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Values)
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
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the classification code.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description.';
                }
                field("Parent Value Code"; Rec."Parent Value Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the parent value code.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether blocked.';
                }
            }
        }
    }
}
