pageextension 70182439 "JML AP Sales Shpt. Lines Ext" extends "Sales Shipment Lines"
{
    layout
    {
        addafter("No.")
        {
            field("JML AP Asset No."; Rec."JML AP Asset No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the asset number that was specified on the sales order line.';
                Editable = false;
            }
        }
    }
}
