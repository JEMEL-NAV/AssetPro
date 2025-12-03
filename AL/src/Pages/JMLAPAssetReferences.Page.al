page 70182382 "JML AP Asset References"
{
    Caption = 'Asset References';
    PageType = List;
    SourceTable = "JML AP Asset Reference";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Reference Type"; Rec."Reference Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of reference.';
                }
                field("Reference Type No."; Rec."Reference Type No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the reference type number.';
                }
                field("Reference No."; Rec."Reference No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the reference number.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies an additional description.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the starting date.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the ending date.';
                }
            }
        }
    }
}
