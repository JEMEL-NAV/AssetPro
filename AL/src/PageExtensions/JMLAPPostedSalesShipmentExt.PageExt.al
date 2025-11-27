pageextension 70182444 "JML AP Pstd Sales Shpt Ext" extends "Posted Sales Shipment"
{
    layout
    {
        addafter(SalesShipmLines)
        {
            part(AssetLines; "JML AP Pstd Sales Shpt Ast Sub")
            {
                ApplicationArea = All;
                Caption = 'Asset Lines';
                SubPageLink = "Document No." = field("No.");
            }
        }
    }
}
