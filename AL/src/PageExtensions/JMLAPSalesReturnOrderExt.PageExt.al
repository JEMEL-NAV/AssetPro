pageextension 70182448 "JML AP Sales Return Order Ext" extends "Sales Return Order"
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
