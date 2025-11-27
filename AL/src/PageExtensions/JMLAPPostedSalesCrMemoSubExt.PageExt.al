pageextension 70182441 "JML AP Pstd Cr.Memo Sub Ext" extends "Posted Sales Cr. Memo Subform"
{
    layout
    {
        addafter("No.")
        {
            field("JML AP Asset No."; Rec."JML AP Asset No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the asset number that was specified on the sales credit memo line.';
                Editable = false;
            }
        }
    }
}
