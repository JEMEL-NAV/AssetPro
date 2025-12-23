pageextension 70182449 "JML AP Sales Invoice Ext" extends "Sales Invoice"
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
