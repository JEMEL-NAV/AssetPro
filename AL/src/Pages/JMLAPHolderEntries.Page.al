page 70182339 "JML AP Holder Entries"
{
    Caption = 'Asset Holder Entries';
    PageType = List;
    SourceTable = "JML AP Holder Entry";
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Entries)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the entry number.';
                }
                field("Asset No."; Rec."Asset No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the asset number.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the posting date.';
                }
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the entry type.';
                }
                field("Holder Type"; Rec."Holder Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the holder type.';
                }
                field("Holder Code"; Rec."Holder Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the holder code.';
                }
                field("Holder Name"; Rec."Holder Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the holder name.';
                }
                field("Holder Addr Code"; Rec."Holder Addr Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the holder address code.';
                }
                field("Transaction No."; Rec."Transaction No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the transaction number.';
                }
            }
        }
    }
}
