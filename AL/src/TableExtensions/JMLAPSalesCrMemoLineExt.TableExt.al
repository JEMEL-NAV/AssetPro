tableextension 70182430 "JML AP Sales Cr.Memo Line Ext" extends "Sales Cr.Memo Line"
{
    fields
    {
        field(70182300; "JML AP Asset No."; Code[20])
        {
            Caption = 'Asset No.';
            ToolTip = 'Specifies the asset number that was specified on the sales credit memo line.';
            DataClassification = CustomerContent;
            TableRelation = "JML AP Asset";
        }
    }
}
