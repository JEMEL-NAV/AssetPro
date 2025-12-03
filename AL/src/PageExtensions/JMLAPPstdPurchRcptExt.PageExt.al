pageextension 70182434 "JML AP Pstd Purch. Rcpt Ext" extends "Posted Purchase Receipt"
{
    layout
    {
        addafter(PurchReceiptLines)
        {
            part(AssetLines; "JML AP Pstd Purch Rcpt Ast Sub")
            {
                ApplicationArea = All;
                Caption = 'Asset Lines';
                SubPageLink = "Document No." = field("No.");
            }
        }
    }
}
