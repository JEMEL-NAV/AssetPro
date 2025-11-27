pageextension 70182446 "JML AP Sales Credit Memo Ext" extends "Sales Credit Memo"
{
    layout
    {
        addafter(SalesLines)
        {
            part(AssetLines; "JML AP Sales Asset Subpage")
            {
                ApplicationArea = All;
                Caption = 'Asset Lines';
                SubPageLink = "Document Type" = field("Document Type"),
                              "Document No." = field("No.");
            }
        }
    }
}
