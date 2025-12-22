page 70182352 "JML AP Asset Journal"
{
    Caption = 'Asset Journal';
    Description = 'Record asset transactions and movements including holder changes and status updates.';
    PageType = Worksheet;
    SourceTable = "JML AP Asset Journal Line";
    ApplicationArea = All;
    UsageCategory = Tasks;
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            field(CurrentBatchName; CurrentBatchName)
            {
                ApplicationArea = All;
                Caption = 'Batch Name';
                ToolTip = 'Specifies the name of the journal batch.';
                Lookup = true;

                trigger OnValidate()
                begin
                    SetBatchFilter();
                end;

                trigger OnLookup(var Text: Text): Boolean
                var
                    AssetJnlBatch: Record "JML AP Asset Journal Batch";
                begin
                    if Page.RunModal(Page::"JML AP Asset Journal Batches", AssetJnlBatch) = Action::LookupOK then begin
                        CurrentBatchName := AssetJnlBatch.Name;
                        SetBatchFilter();
                    end;
                end;
            }

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
                    ToolTip = 'Specifies the asset description.';
                }

                field("Current Holder Type"; Rec."Current Holder Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the current holder type of the asset.';
                }

                field("Current Holder Code"; Rec."Current Holder Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the current holder of the asset.';
                }

                field("Current Holder Addr Code"; Rec."Current Holder Addr Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the current address code of the asset holder.';
                }

                field("New Holder Type"; Rec."New Holder Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the new holder type for the asset.';
                }

                field("New Holder Code"; Rec."New Holder Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the new holder for the asset.';
                }

                field("New Holder Addr Code"; Rec."New Holder Addr Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the ship-to address code (for customers) or order address code (for vendors).';
                }

                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the posting date for this transfer.';
                }

                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the document number for this transfer.';
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the transfer.';
                }

                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the reason code for this transfer.';
                }

                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies an external document reference.';
                }
            }
        }

        area(FactBoxes)
        {
            part(AssetFactBox; "JML AP Asset FactBox")
            {
                ApplicationArea = All;
                Caption = 'Asset';
                SubPageLink = "No." = field("Asset No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group(Posting)
            {
                Caption = 'Posting';

                action(Post)
                {
                    ApplicationArea = All;
                    Caption = 'Post';
                    ToolTip = 'Post the asset transfers in this journal.';
                    Image = Post;
                    ShortcutKey = 'F9';

                    trigger OnAction()
                    var
                        AssetJnlPost: Codeunit "JML AP Asset Jnl.-Post";
                    begin
                        AssetJnlPost.Run(Rec);
                        CurrPage.Update(false);
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
                        Message(TestReportNotImplementedMsg);
                    end;
                }
            }

            group(Functions)
            {
                Caption = 'Functions';

                action(SuggestLines)
                {
                    ApplicationArea = All;
                    Caption = 'Suggest Lines';
                    ToolTip = 'Suggest journal lines based on criteria.';
                    Image = SuggestLines;

                    trigger OnAction()
                    begin
                        Message(SuggestLinesNotImplementedMsg);
                    end;
                }
            }
            group("Page")
            {
                Caption = 'Page';
                action(EditInExcel)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Edit in Excel';
                    Image = Excel;
                    ToolTip = 'Send the data in the journal to an Excel file for analysis or editing.';
                    Visible = IsSaaSExcelAddinEnabled;
                    AccessByPermission = System "Allow Action Export To Excel" = X;

                    trigger OnAction()
                    var
                        ODataUtility: Codeunit ODataUtility;
                    begin
                        ODataUtility.EditJournalWorksheetInExcel(CurrPage.Caption, CurrPage.ObjectId(false), Rec."Journal Batch Name", '');
                    end;
                }
            }
        }
        area(Navigation)
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

            action(HolderEntries)
            {
                ApplicationArea = All;
                Caption = 'Holder Entries';
                ToolTip = 'View holder entries for this asset.';
                Image = Entries;

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

        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Post_Promoted; Post)
                {
                }
            }

            group(Category_Navigate)
            {
                Caption = 'Navigate';

                actionref(Asset_Promoted; Asset)
                {
                }

                actionref(HolderEntries_Promoted; HolderEntries)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        ServerSetting: Codeunit "Server Setting";
    begin
        IsSaaSExcelAddinEnabled := ServerSetting.GetIsSaasExcelAddinEnabled();
        if CurrentBatchName = '' then
            SetDefaultBatch();
        SetBatchFilter();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Journal Batch Name" := CurrentBatchName;
        Rec."Posting Date" := WorkDate();
    end;

    local procedure SetBatchFilter()
    begin
        Rec.FilterGroup := 2;
        Rec.SetRange("Journal Batch Name", CurrentBatchName);
        Rec.FilterGroup := 0;
        if Rec.Find('-') then;
        CurrPage.Update(false);
    end;

    local procedure SetDefaultBatch()
    var
        AssetJnlBatch: Record "JML AP Asset Journal Batch";
    begin
        if AssetJnlBatch.FindFirst() then
            CurrentBatchName := AssetJnlBatch.Name
        else begin
            AssetJnlBatch.Init();
            AssetJnlBatch.Name := 'DEFAULT';
            AssetJnlBatch.Description := 'Default Batch';
            AssetJnlBatch.Insert();
            CurrentBatchName := AssetJnlBatch.Name;
        end;
    end;

    var
        CurrentBatchName: Code[10];
        IsSaaSExcelAddinEnabled: Boolean;
        TestReportNotImplementedMsg: Label 'Test report not yet implemented. Will be added in future phase.';
        SuggestLinesNotImplementedMsg: Label 'Suggest lines not yet implemented. Will be added in future phase.';
}
