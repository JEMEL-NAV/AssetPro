page 70182357 "JML AP Asset Posted Transfer"
{
    Caption = 'Posted Asset Transfer';
    Description = 'View posted asset transfer records showing completed asset movements between holders.';
    PageType = Document;
    SourceTable = "JML AP Posted Asset Transfer";
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the posted transfer number.';
                }

                field("Transfer Order No."; Rec."Transfer Order No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the original transfer order number.';
                }

                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the posting date of the transfer.';
                }

                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the document date.';
                }

                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the user who posted the transfer.';
                }
            }

            group("Transfer From")
            {
                Caption = 'Transfer From';

                field("From Holder Type"; Rec."From Holder Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of the holder that transferred the assets.';
                }

                field("From Holder Code"; Rec."From Holder Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code of the holder that transferred the assets.';
                }

                field("From Holder Name"; Rec."From Holder Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the holder that transferred the assets.';
                }
                field("From Holder Addr Code"; Rec."From Holder Addr Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the sender address code.';
                }
            }

            group("Transfer To")
            {
                Caption = 'Transfer To';

                field("To Holder Type"; Rec."To Holder Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of the holder that received the assets.';
                }

                field("To Holder Code"; Rec."To Holder Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code of the holder that received the assets.';
                }

                field("To Holder Name"; Rec."To Holder Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the holder that received the assets.';
                }
                field("To Holder Addr Code"; Rec."To Holder Addr Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the receiver address code.';
                }
            }

            group("Additional Details")
            {
                Caption = 'Additional Details';

                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the reason code for this transfer.';
                }

                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies an external document number or reference.';
                }

                field("No. Series"; Rec."No. Series")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number series used for this posted transfer.';
                }
            }

            part(Lines; "JML AP Asset Posted Trans. Sub")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
            }
        }

        area(FactBoxes)
        {
            systempart(LinksFactBox; Links)
            {
                ApplicationArea = All;
            }
            systempart(NotesFactBox; Notes)
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(Statistics)
            {
                ApplicationArea = All;
                Caption = 'Statistics';
                ToolTip = 'View statistics for this posted transfer.';
                Image = Statistics;

                trigger OnAction()
                begin
                    Message('Posted Transfer Statistics: %1 lines', CountLines());
                end;
            }

            action(HolderEntries)
            {
                ApplicationArea = All;
                Caption = 'Holder Entries';
                ToolTip = 'View all holder entries created by this transfer.';
                Image = Entries;

                trigger OnAction()
                var
                    HolderEntry: Record "JML AP Holder Entry";
                    PostedLine: Record "JML AP Pstd. Asset Trans. Line";
                    TransactionNoFilter: Text;
                begin
                    PostedLine.SetRange("Document No.", Rec."No.");
                    if PostedLine.FindSet() then begin
                        repeat
                            if PostedLine."Transaction No." <> 0 then begin
                                if TransactionNoFilter <> '' then
                                    TransactionNoFilter += '|';
                                TransactionNoFilter += Format(PostedLine."Transaction No.");
                            end;
                        until PostedLine.Next() = 0;

                        if TransactionNoFilter <> '' then begin
                            HolderEntry.SetFilter("Transaction No.", TransactionNoFilter);
                            Page.Run(Page::"JML AP Holder Entries", HolderEntry);
                        end else
                            Message('No holder entries found for this transfer.');
                    end else
                        Message('No lines found for this transfer.');
                end;
            }
        }

        area(Promoted)
        {
            group(Category_Navigate)
            {
                Caption = 'Navigate';

                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref(HolderEntries_Promoted; HolderEntries)
                {
                }
            }
        }
    }

    local procedure CountLines(): Integer
    var
        PostedLine: Record "JML AP Pstd. Asset Trans. Line";
    begin
        PostedLine.SetRange("Document No.", Rec."No.");
        exit(PostedLine.Count);
    end;
}
