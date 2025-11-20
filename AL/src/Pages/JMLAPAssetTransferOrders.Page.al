page 70182353 "JML AP Asset Transfer Orders"
{
    Caption = 'Asset Transfer Orders';
    PageType = List;
    SourceTable = "JML AP Asset Transfer Header";
    ApplicationArea = All;
    UsageCategory = Lists;
    CardPageId = "JML AP Asset Transfer Order";
    Editable = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the transfer order number.';
                }

                field("From Holder Type"; Rec."From Holder Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of the holder transferring the assets.';
                }

                field("From Holder Code"; Rec."From Holder Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code of the holder transferring the assets.';
                }

                field("From Holder Name"; Rec."From Holder Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the holder transferring the assets.';
                }

                field("To Holder Type"; Rec."To Holder Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of the holder receiving the assets.';
                }

                field("To Holder Code"; Rec."To Holder Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code of the holder receiving the assets.';
                }

                field("To Holder Name"; Rec."To Holder Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the holder receiving the assets.';
                }

                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the posting date for the transfer.';
                }

                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the document date.';
                }

                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the status of the transfer order (Open or Released).';
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
        area(Processing)
        {
            action(Release)
            {
                ApplicationArea = All;
                Caption = 'Release';
                ToolTip = 'Release the transfer order to make it ready for posting.';
                Image = ReleaseDoc;

                trigger OnAction()
                begin
                    if Rec.Status = Rec.Status::Released then
                        Error(AlreadyReleasedErr);

                    Rec.TestField("From Holder Type");
                    Rec.TestField("From Holder Code");
                    Rec.TestField("To Holder Type");
                    Rec.TestField("To Holder Code");

                    if not HasLines() then
                        Error(NoLinesErr);

                    Rec.Status := Rec.Status::Released;
                    Rec.Modify(true);
                    CurrPage.Update(false);
                end;
            }

            action(Reopen)
            {
                ApplicationArea = All;
                Caption = 'Reopen';
                ToolTip = 'Reopen the released transfer order for editing.';
                Image = ReOpen;

                trigger OnAction()
                begin
                    if Rec.Status = Rec.Status::Open then
                        Error(AlreadyOpenErr);

                    Rec.Status := Rec.Status::Open;
                    Rec.Modify(true);
                    CurrPage.Update(false);
                end;
            }

            action(Post)
            {
                ApplicationArea = All;
                Caption = 'Post';
                ToolTip = 'Post the transfer order to transfer assets and create holder entries.';
                Image = Post;
                ShortcutKey = 'F9';

                trigger OnAction()
                var
                    AssetTransferPost: Codeunit "JML AP Asset Transfer-Post";
                begin
                    if Rec.Status <> Rec.Status::Released then
                        Error(NotReleasedErr);

                    AssetTransferPost.Run(Rec);
                    CurrPage.Update(false);
                end;
            }
        }

        area(Navigation)
        {
            action(Lines)
            {
                ApplicationArea = All;
                Caption = 'Lines';
                ToolTip = 'View or edit the transfer order lines.';
                Image = AllLines;
                RunObject = page "JML AP Asset Transfer Order";
                RunPageLink = "No." = field("No.");
            }
        }

        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Release_Promoted; Release)
                {
                }
                actionref(Reopen_Promoted; Reopen)
                {
                }
                actionref(Post_Promoted; Post)
                {
                }
            }

            group(Category_Navigate)
            {
                Caption = 'Navigate';

                actionref(Lines_Promoted; Lines)
                {
                }
            }
        }
    }

    local procedure HasLines(): Boolean
    var
        TransferLine: Record "JML AP Asset Transfer Line";
    begin
        TransferLine.SetRange("Document No.", Rec."No.");
        exit(not TransferLine.IsEmpty);
    end;

    var
        AlreadyReleasedErr: Label 'The transfer order is already released.';
        AlreadyOpenErr: Label 'The transfer order is already open.';
        NotReleasedErr: Label 'The transfer order must be released before posting.';
        NoLinesErr: Label 'There are no lines to release.';
}
