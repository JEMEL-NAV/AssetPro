pageextension 70182447 "JML AP Item Journal Ext" extends "Item Journal"
{
    layout
    {
        addafter("Item No.")
        {
            field("JML AP Asset No."; Rec."JML AP Asset No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the asset number for component integration. When specified, item movements will create component entries.';
            }
        }
    }
}
