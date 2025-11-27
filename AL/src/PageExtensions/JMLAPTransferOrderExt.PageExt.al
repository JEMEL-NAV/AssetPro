pageextension 70182424 "JML AP Transfer Order Ext" extends "Transfer Order"
{
    layout
    {
        addafter(TransferLines)
        {
            part("Asset Lines"; "JML AP Transfer Asset Subpage")
            {
                ApplicationArea = All;
                Caption = 'Asset Lines';
                SubPageLink = "Document No." = field("No.");
            }
        }
    }
}
