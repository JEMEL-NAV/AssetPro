pageextension 70182438 "JML AP Sales Ret Order Sub Ext" extends "Sales Return Order Subform"
{
    layout
    {
        addafter("No.")
        {
            field("JML AP Asset No."; Rec."JML AP Asset No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the asset number for component integration. When this return order is posted, the asset number will flow to the item journal and automatically create component ledger entries for the asset.';
            }
        }
    }
}
