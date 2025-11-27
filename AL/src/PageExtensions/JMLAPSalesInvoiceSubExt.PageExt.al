pageextension 70182437 "JML AP Sales Invoice Sub Ext" extends "Sales Invoice Subform"
{
    layout
    {
        addafter("No.")
        {
            field("JML AP Asset No."; Rec."JML AP Asset No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the asset number for component integration. When this sales invoice is posted, the asset number will flow to the item journal and automatically create component ledger entries for the asset.';
            }
        }
    }
}
