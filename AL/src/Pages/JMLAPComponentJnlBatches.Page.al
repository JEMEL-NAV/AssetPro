page 70182377 "JML AP Component Jnl. Batches"
{
    Caption = 'Component Journal Batches';
    PageType = List;
    SourceTable = "JML AP Component Jnl. Batch";
    ApplicationArea = All;
    UsageCategory = Lists;
    CardPageId = "JML AP Component Journal";

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the component journal batch.';
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the component journal batch.';
                }

                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the reason code for component entries in this batch.';
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
                ToolTip = 'Open the component journal lines for this batch.';
                Image = OpenJournal;
                ShortcutKey = 'Return';

                trigger OnAction()
                var
                    ComponentJnlLine: Record "JML AP Component Journal Line";
                begin
                    ComponentJnlLine.FilterGroup := 2;
                    ComponentJnlLine.SetRange("Journal Batch", Rec.Name);
                    ComponentJnlLine.FilterGroup := 0;
                    Page.Run(Page::"JML AP Component Journal", ComponentJnlLine);
                end;
            }
        }

        area(Navigation)
        {
            action(Lines)
            {
                ApplicationArea = All;
                Caption = 'Lines';
                ToolTip = 'View or edit component journal lines for this batch.';
                Image = AllLines;
                RunObject = page "JML AP Component Journal";
                RunPageLink = "Journal Batch" = field(Name);
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
