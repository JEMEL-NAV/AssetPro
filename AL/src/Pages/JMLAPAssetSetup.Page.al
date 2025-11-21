page 70182330 "JML AP Asset Setup"
{
    Caption = 'Asset Setup';
    PageType = Card;
    SourceTable = "JML AP Asset Setup";
    ApplicationArea = All;
    UsageCategory = Administration;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Numbering)
            {
                Caption = 'Numbering';

                field("Asset Nos."; Rec."Asset Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number series for assets.';
                }
                field("Transfer Order Nos."; Rec."Transfer Order Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number series for asset transfer orders.';
                }
                field("Posted Transfer Nos."; Rec."Posted Transfer Nos.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number series for posted asset transfers.';
                }
            }

            group(General)
            {
                Caption = 'General';

                field("Default Industry Code"; Rec."Default Industry Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the default industry code for new assets.';
                }
            }

            group(Features)
            {
                Caption = 'Features';

                field("Enable Attributes"; Rec."Enable Attributes")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether custom attributes are enabled.';
                }
                field("Enable Holder History"; Rec."Enable Holder History")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether holder history tracking is enabled.';
                }
                field("Block Manual Holder Change"; Rec."Block Manual Holder Change")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether manual changes to Current Holder on Asset Card are blocked. When enabled, holders can only be changed via Asset Journal or Transfer Orders.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.GetRecordOnce();
    end;
}
