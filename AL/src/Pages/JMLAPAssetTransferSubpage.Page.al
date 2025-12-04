page 70182355 "JML AP Asset Transfer Subpage"
{
    Caption = 'Asset Transfer Lines';
    Description = 'Subpage for entering asset lines in transfer orders.';
    PageType = ListPart;
    SourceTable = "JML AP Asset Transfer Line";
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Asset No."; Rec."Asset No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the asset number to transfer.';
                }

                field("Asset Description"; Rec."Asset Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the asset.';
                }

                field("Current Holder Type"; Rec."Current Holder Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the current holder type of the asset.';
                }

                field("Current Holder Code"; Rec."Current Holder Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the current holder code of the asset.';
                }

                field("Current Holder Name"; Rec."Current Holder Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the current holder name of the asset.';
                }

                field("Current Holder Addr Code"; Rec."Current Holder Addr Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the current holder address code.';
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description for this transfer line.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Asset)
            {
                ApplicationArea = All;
                Caption = 'Asset';
                ToolTip = 'View or edit the asset card.';
                Image = FixedAssets;
                RunObject = page "JML AP Asset Card";
                RunPageLink = "No." = field("Asset No.");
            }

            action(HolderHistory)
            {
                ApplicationArea = All;
                Caption = 'Holder History';
                ToolTip = 'View the holder history for this asset.';
                Image = History;

                trigger OnAction()
                var
                    HolderEntry: Record "JML AP Holder Entry";
                begin
                    if Rec."Asset No." = '' then
                        exit;

                    HolderEntry.SetRange("Asset No.", Rec."Asset No.");
                    Page.Run(Page::"JML AP Holder Entries", HolderEntry);
                end;
            }
        }
    }
}
