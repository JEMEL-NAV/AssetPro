pageextension 70182443 "JML AP Sales Order Ext" extends "Sales Order"
{
    layout
    {
        addafter(SalesLines)
        {
            part(JMLAssetLines; "JML AP Sales Asset Subpage")
            {
                ApplicationArea = All;
                Caption = 'Asset Lines';
                SubPageLink = "Document Type" = field("Document Type"),
                              "Document No." = field("No.");
            }
        }
    }
}
