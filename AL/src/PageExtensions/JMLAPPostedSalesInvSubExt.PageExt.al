pageextension 70182440 "JML AP Pstd Sales Inv Sub Ext" extends "Posted Sales Invoice Subform"
{
    layout
    {
        addafter("No.")
        {
            field("JML AP Asset No."; Rec."JML AP Asset No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the asset number that was specified on the sales invoice line.';
                Editable = false;
            }
        }
    }
}
