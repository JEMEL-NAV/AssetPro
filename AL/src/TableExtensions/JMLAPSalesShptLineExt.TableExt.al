tableextension 70182428 "JML AP Sales Shpt. Line Ext" extends "Sales Shipment Line"
{
    fields
    {
        field(70182300; "JML AP Asset No."; Code[20])
        {
            Caption = 'Asset No.';
            ToolTip = 'Specifies the asset number that was specified on the sales order line.';
            DataClassification = CustomerContent;
            TableRelation = "JML AP Asset";
        }
    }
}
