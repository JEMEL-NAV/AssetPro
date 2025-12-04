page 70182368 "JML AP Pstd Ret Rcpt Ast Sub"
{
    Caption = 'Posted Return Receipt Asset Lines';
    Description = 'Subpage showing assets on posted return receipt lines.';
    PageType = ListPart;
    SourceTable = "JML AP Pstd Ret Rcpt Ast Ln";
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Lines)
            {
                field("Asset No."; Rec."Asset No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the asset that was returned.';
                }
                field("Asset Description"; Rec."Asset Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the asset.';
                }
                field("Sell-to Customer No."; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the customer who returned the asset.';
                }
                field("Sell-to Customer Name"; Rec."Sell-to Customer Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the customer who returned the asset.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the location where the asset was received.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the posting date of the return receipt.';
                }
                field("Transaction No."; Rec."Transaction No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Links to the asset holder entry transaction number created by this return receipt.';
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the reason code for this asset return.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description for this asset line.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(AssetCard)
            {
                ApplicationArea = All;
                Caption = 'Asset Card';
                ToolTip = 'Open the asset card for this asset.';
                Image = Card;
                RunObject = page "JML AP Asset Card";
                RunPageLink = "No." = field("Asset No.");
                Enabled = Rec."Asset No." <> '';
            }
            action(HolderEntries)
            {
                ApplicationArea = All;
                Caption = 'Holder Entries';
                ToolTip = 'View the holder entries for this transaction.';
                Image = Entries;
                Enabled = Rec."Transaction No." > 0;

                trigger OnAction()
                var
                    HolderEntry: Record "JML AP Holder Entry";
                begin
                    HolderEntry.SetRange("Transaction No.", Rec."Transaction No.");
                    Page.Run(Page::"JML AP Holder Entries", HolderEntry);
                end;
            }
        }
    }
}
