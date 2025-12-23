pageextension 70182434 "JML AP Pstd Purch. Rcpt Ext" extends "Posted Purchase Receipt"
{
    layout
    {
        addafter(PurchReceiptLines)
        {
            part(JMLAssetLines; "JML AP Pstd Purch Rcpt Ast Sub")
            {
                ApplicationArea = All;
                Caption = 'Asset Lines';
                SubPageLink = "Document No." = field("No.");
            }
        }
    }
}
