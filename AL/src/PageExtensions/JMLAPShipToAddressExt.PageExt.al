pageextension 70182413 "JML AP Ship-to Address Ext" extends "Ship-to Address"
{
    layout
    {
        addfirst(factboxes)
        {
            part(ShipToAssets; "JML AP Ship-to Asset FB")
            {
                ApplicationArea = All;
                Caption = 'Assets';
                SubPageLink = "Customer No." = field("Customer No."),
                              Code = field(Code);
            }
        }
    }
}
