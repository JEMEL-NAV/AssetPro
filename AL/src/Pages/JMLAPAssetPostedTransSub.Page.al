page 70182358 "JML AP Asset Posted Trans. Sub"
{
    Caption = 'Posted Asset Transfer Lines';
    Description = 'Subpage showing asset lines in posted transfer documents.';
    PageType = ListPart;
    SourceTable = "JML AP Pstd. Asset Trans. Line";
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Asset No."; Rec."Asset No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the asset number that was transferred.';
                }

                field("Asset Description"; Rec."Asset Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the asset.';
                }

                field("From Holder Type"; Rec."From Holder Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the holder type the asset was transferred from.';
                }

                field("From Holder Code"; Rec."From Holder Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the holder code the asset was transferred from.';
                }

                field("From Holder Name"; Rec."From Holder Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the holder name the asset was transferred from.';
                }

                field("From Holder Addr Code"; Rec."From Holder Addr Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the holder address code the asset was transferred from.';
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description for this transfer line.';
                }

                field("Transaction No."; Rec."Transaction No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the transaction number linking this transfer to holder entries.';
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
                ToolTip = 'View the asset card.';
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

            action(TransactionEntries)
            {
                ApplicationArea = All;
                Caption = 'Transaction Entries';
                ToolTip = 'View all holder entries for this transaction.';
                Image = Entries;

                trigger OnAction()
                var
                    HolderEntry: Record "JML AP Holder Entry";
                begin
                    if Rec."Transaction No." = 0 then
                        exit;

                    HolderEntry.SetRange("Transaction No.", Rec."Transaction No.");
                    Page.Run(Page::"JML AP Holder Entries", HolderEntry);
                end;
            }
        }
    }
}
