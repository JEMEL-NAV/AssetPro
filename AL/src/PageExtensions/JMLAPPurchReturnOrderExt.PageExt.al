pageextension 70182433 "JML AP Purch. Return Order Ext" extends "Purchase Return Order"
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
