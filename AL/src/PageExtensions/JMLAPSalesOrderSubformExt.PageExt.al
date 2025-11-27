pageextension 70182435 "JML AP Sales Order Subform Ext" extends "Sales Order Subform"
{
    layout
    {
        addafter("No.")
        {
            field("JML AP Asset No."; Rec."JML AP Asset No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the asset number for component integration. When this sales order is posted, the asset number will flow to the item journal and automatically create component ledger entries for the asset.';
            }
        }
    }
}
