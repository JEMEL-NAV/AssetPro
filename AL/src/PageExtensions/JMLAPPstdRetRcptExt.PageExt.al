pageextension 70182445 "JML AP Pstd Ret Rcpt Ext" extends "Posted Return Receipt"
{
    layout
    {
        addafter(ReturnRcptLines)
        {
            part(AssetLines; "JML AP Pstd Ret Rcpt Ast Sub")
            {
                ApplicationArea = All;
                Caption = 'Asset Lines';
                SubPageLink = "Document No." = field("No.");
            }
        }
    }
}
