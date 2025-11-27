tableextension 70182431 "JML AP Return Rcpt. Line Ext" extends "Return Receipt Line"
{
    fields
    {
        field(70182300; "JML AP Asset No."; Code[20])
        {
            Caption = 'Asset No.';
            ToolTip = 'Specifies the asset number that was specified on the return order line.';
            DataClassification = CustomerContent;
            TableRelation = "JML AP Asset";
        }
    }
}
