tableextension 70182429 "JML AP Sales Inv. Line Ext" extends "Sales Invoice Line"
{
    fields
    {
        field(70182300; "JML AP Asset No."; Code[20])
        {
            Caption = 'Asset No.';
            ToolTip = 'Specifies the asset number that was specified on the sales invoice line.';
            DataClassification = CustomerContent;
            TableRelation = "JML AP Asset";
        }
    }
}
