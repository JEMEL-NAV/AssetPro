pageextension 70182442 "JML AP Pstd Ret Rcpt Sub Ext" extends "Posted Return Receipt Subform"
{
    layout
    {
        addafter("No.")
        {
            field("JML AP Asset No."; Rec."JML AP Asset No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the asset number that was specified on the return order line.';
                Editable = false;
            }
        }
    }
}
