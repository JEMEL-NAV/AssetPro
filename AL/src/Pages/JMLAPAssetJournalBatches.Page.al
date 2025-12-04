page 70182351 "JML AP Asset Journal Batches"
{
    Caption = 'Asset Journal Batches';
    Description = 'Manage asset journal batches for organizing and grouping asset transactions.';
    PageType = List;
    SourceTable = "JML AP Asset Journal Batch";
    ApplicationArea = All;
    UsageCategory = Lists;
    CardPageId = "JML AP Asset Journal";

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the journal batch.';
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the journal batch.';
                }

                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the reason code for transfers in this batch.';
                }

                field("No. Series"; Rec."No. Series")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number series for document numbers.';
                }

                field("Posting No. Series"; Rec."Posting No. Series")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number series for posted document numbers.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(EditJournal)
            {
                ApplicationArea = All;
                Caption = 'Edit Journal';
                ToolTip = 'Open the journal lines for this batch.';
                Image = OpenJournal;
                ShortcutKey = 'Return';

                trigger OnAction()
                var
                    AssetJnlLine: Record "JML AP Asset Journal Line";
                begin
                    AssetJnlLine.FilterGroup := 2;
                    AssetJnlLine.SetRange("Journal Batch Name", Rec.Name);
                    AssetJnlLine.FilterGroup := 0;
                    Page.Run(Page::"JML AP Asset Journal", AssetJnlLine);
                end;
            }
        }

        area(Navigation)
        {
            action(Lines)
            {
                ApplicationArea = All;
                Caption = 'Lines';
                ToolTip = 'View or edit journal lines for this batch.';
                Image = AllLines;
                RunObject = page "JML AP Asset Journal";
                RunPageLink = "Journal Batch Name" = field(Name);
            }
        }

        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(EditJournal_Promoted; EditJournal)
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
}
