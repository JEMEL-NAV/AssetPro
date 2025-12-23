pageextension 70182422 "JML AP Pstd Ret Shpt Ext" extends "Posted Return Shipment"
{
    layout
    {
        addafter(ReturnShptLines)
        {
            part(JMLAssetLines; "JML AP Pstd Ret Shpt Ast Sub")
            {
                ApplicationArea = All;
                Caption = 'Asset Lines';
                SubPageLink = "Document No." = field("No.");
            }
        }
    }
}
