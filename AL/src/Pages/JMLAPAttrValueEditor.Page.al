page 70182345 "JML AP Attr Value Editor"
{
    Caption = 'Asset Attribute Values';
    PageType = StandardDialog;
    SourceTable = "JML AP Asset";

    layout
    {
        area(Content)
        {
            part(AttributeValueList; "JML AP Attr Value List")
            {
                ApplicationArea = All;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.CalcFields("Classification Level No.");
        CurrPage.AttributeValueList.PAGE.LoadAttributes(
            Rec."No.",
            Rec."Industry Code",
            Rec."Classification Level No.");
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = Action::OK then
            CurrPage.AttributeValueList.PAGE.SaveRecord();
    end;
}
