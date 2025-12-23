pageextension 70182430 "JML AP Purch. Order Ext" extends "Purchase Order"
{
    layout
    {
        addafter(PurchLines)
        {
            part(JMLAssetLines; "JML AP Purch. Asset Subpage")
            {
                ApplicationArea = All;
                Caption = 'Asset Lines';
                SubPageLink = "Document Type" = field("Document Type"),
                              "Document No." = field("No.");
            }
        }
    }
}
