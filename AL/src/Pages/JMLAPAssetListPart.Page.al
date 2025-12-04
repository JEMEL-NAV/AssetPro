page 70182341 "JML AP Asset ListPart"
{
    Caption = 'Assets';
    Description = 'List part showing assets for embedding in other pages and factboxes.';
    PageType = ListPart;
    SourceTable = "JML AP Asset";
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Assets)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the asset number.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the status.';
                }
            }
        }
    }
}
