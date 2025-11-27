pageextension 70182431 "JML AP Purch. Invoice Ext" extends "Purchase Invoice"
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
