page 70182301 "JML AP Classification Vals Fb"
{
    ApplicationArea = All;
    Caption = 'JML AP Classification Vals Fb';
    Description = 'Displays classification value details in a factbox.';
    PageType = ListPart;
    SourceTable = "JML AP Classification Val";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Industry Code"; Rec."Industry Code")
                {
                    ToolTip = 'Specifies the industry code.';
                    Visible = false;
                }
                field("Level Number"; Rec."Level Number")
                {
                    ToolTip = 'Specifies the level number.';
                    Visible = false;
                }
                field("Code"; Rec."Code")
                {
                    ToolTip = 'Specifies the classification code.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the description.';
                }
                field("Parent Value Code"; Rec."Parent Value Code")
                {
                    ToolTip = 'Specifies the parent value code.';
                }
            }
        }
    }
}
