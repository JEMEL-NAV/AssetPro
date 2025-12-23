pageextension 70182412 "JML AP Vendor Card Ext" extends "Vendor Card"
{
    layout
    {
        addfirst(factboxes)
        {
            part(JMLVendorAssets; "JML AP Vendor Asset FB")
            {
                ApplicationArea = All;
                Caption = 'Assets';
                SubPageLink = "No." = field("No.");
            }
        }
    }
}
