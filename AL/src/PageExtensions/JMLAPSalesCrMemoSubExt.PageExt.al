pageextension 70182436 "JML AP Sales Cr. Memo Sub Ext" extends "Sales Cr. Memo Subform"
{
    layout
    {
        addafter("No.")
        {
            field("JML AP Asset No."; Rec."JML AP Asset No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the asset number for component integration. When this credit memo is posted, the asset number will flow to the item journal and automatically create component ledger entries (typically Remove entries) for the asset.';
            }
        }
    }
}
