page 70182342 "JML AP Asset FactBox"
{
    Caption = 'Asset Details';
    Description = 'Displays key asset information in a factbox including status and holder details.';
    PageType = CardPart;
    SourceTable = "JML AP Asset";
    ApplicationArea = All;

    layout
    {
        area(Content)
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
            field("Current Holder Name"; Rec."Current Holder Name")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the current holder.';
            }
            field(Status; Rec.Status)
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the status.';
            }
        }
    }
}
