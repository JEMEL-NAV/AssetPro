page 70182356 "JML AP Asset Posted Transfers"
{
    Caption = 'Posted Asset Transfers';
    PageType = List;
    SourceTable = "JML AP Posted Asset Transfer";
    ApplicationArea = All;
    UsageCategory = History;
    CardPageId = "JML AP Asset Posted Transfer";
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
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
            action(Lines)
            {
                ApplicationArea = All;
                Caption = 'Lines';
                ToolTip = 'View the posted transfer lines.';
                Image = AllLines;
                RunObject = page "JML AP Asset Posted Transfer";
                RunPageLink = "No." = field("No.");
            }
        }

        area(Promoted)
        {
            group(Category_Navigate)
            {
                Caption = 'Navigate';

                actionref(Lines_Promoted; Lines)
                {
                }
            }
        }
    }
}
