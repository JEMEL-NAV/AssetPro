pageextension 70182411 "JML AP Customer Card Ext" extends "Customer Card"
{
    layout
    {
        addfirst(factboxes)
        {
            part(JMLCustomerAssets; "JML AP Customer Asset FB")
            {
                Caption = 'Assets';
                ApplicationArea = All;
                SubPageLink = "No." = field("No.");
            }
        }
    }
}
