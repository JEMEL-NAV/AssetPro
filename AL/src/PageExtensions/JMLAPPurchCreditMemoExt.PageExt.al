pageextension 70182432 "JML AP Purch. Credit Memo Ext" extends "Purchase Credit Memo"
{
    layout
    {
        addafter(PurchLines)
        {
            part(AssetLines; "JML AP Purch. Asset Subpage")
            {
                ApplicationArea = All;
                Caption = 'Asset Lines';
                SubPageLink = "Document Type" = field("Document Type"),
                              "Document No." = field("No.");
            }
        }
    }
}
