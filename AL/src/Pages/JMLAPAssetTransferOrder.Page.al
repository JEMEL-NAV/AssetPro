page 70182354 "JML AP Asset Transfer Order"
{
    Caption = 'Asset Transfer Order';
    PageType = Document;
    SourceTable = "JML AP Asset Transfer Header";
    ApplicationArea = All;

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
                    ToolTip = 'Specifies the transfer order number.';
                }

                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the status of the transfer order (Open or Released).';
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
            }

            group("Transfer From")
            {
                Caption = 'Transfer From';

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
                field("From Holder Addr Code"; Rec."From Holder Addr Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the sender address code.';
                    Importance = Additional;
                }
            }

            group("Transfer To")
            {
                Caption = 'Transfer To';

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
                field("To Holder Addr Code"; Rec."To Holder Addr Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the receiver address code.';
                    Importance = Additional;
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

                field("Posting No. Series"; Rec."Posting No. Series")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number series for the posted transfer document.';
                }
            }

            part(Lines; "JML AP Asset Transfer Subpage")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
                UpdatePropagation = Both;
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
            group(Release)
            {
                Caption = 'Release';

                action(ReleaseAction)
                {
                    ApplicationArea = All;
                    Caption = 'Release';
                    ToolTip = 'Release the transfer order to make it ready for posting.';
                    Image = ReleaseDoc;
                    ShortcutKey = 'Ctrl+F9';

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

                action(ReopenAction)
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
            }

            group(Posting)
            {
                Caption = 'Posting';

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
                        CurrPage.Close();
                    end;
                }

                action(TestReport)
                {
                    ApplicationArea = All;
                    Caption = 'Test Report';
                    ToolTip = 'View a test report to check for errors before posting.';
                    Image = TestReport;

                    trigger OnAction()
                    begin
                        Message('Test report will be implemented in a future phase.');
                    end;
                }
            }
        }

        area(Navigation)
        {
            action(Statistics)
            {
                ApplicationArea = All;
                Caption = 'Statistics';
                ToolTip = 'View statistics for this transfer order.';
                Image = Statistics;

                trigger OnAction()
                begin
                    Message('Statistics: %1 lines', CountLines());
                end;
            }
        }

        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ReleaseAction_Promoted; ReleaseAction)
                {
                }
                actionref(ReopenAction_Promoted; ReopenAction)
                {
                }
                actionref(Post_Promoted; Post)
                {
                }
            }

            group(Category_Report)
            {
                Caption = 'Report';

                actionref(TestReport_Promoted; TestReport)
                {
                }
            }

            group(Category_Navigate)
            {
                Caption = 'Navigate';

                actionref(Statistics_Promoted; Statistics)
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

    local procedure CountLines(): Integer
    var
        TransferLine: Record "JML AP Asset Transfer Line";
    begin
        TransferLine.SetRange("Document No.", Rec."No.");
        exit(TransferLine.Count);
    end;

    var
        AlreadyReleasedErr: Label 'The transfer order is already released.';
        AlreadyOpenErr: Label 'The transfer order is already open.';
        NotReleasedErr: Label 'The transfer order must be released before posting.';
        NoLinesErr: Label 'There are no lines to release.';
}
