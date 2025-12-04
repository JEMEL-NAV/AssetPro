page 70182369 "JML AP Pstd Ret Shpt Ast Sub"
{
    Caption = 'Posted Return Shipment Asset Lines';
    Description = 'Subpage showing assets on posted return shipment lines.';
    PageType = ListPart;
    SourceTable = "JML AP Pstd Ret Shpt Ast Ln";
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
                field("Buy-from Vendor No."; Rec."Buy-from Vendor No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the vendor to whom the asset was returned.';
                }
                field("Buy-from Vendor Name"; Rec."Buy-from Vendor Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the vendor to whom the asset was returned.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the location from which the asset was returned.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the posting date of the return shipment.';
                }
                field("Transaction No."; Rec."Transaction No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Links to the asset holder entry transaction number created by this return shipment.';
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
