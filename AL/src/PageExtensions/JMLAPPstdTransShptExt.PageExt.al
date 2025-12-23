pageextension 70182425 "JML AP Pstd Trans Shpt Ext" extends "Posted Transfer Shipment"
{
    layout
    {
        addafter(TransferShipmentLines)
        {
            part(JMLAssetLines; "JML AP Pstd Trans Shpt Ast Sub")
            {
                ApplicationArea = All;
                Caption = 'Asset Lines';
                SubPageLink = "Document No." = field("No.");
            }
        }
    }
}
