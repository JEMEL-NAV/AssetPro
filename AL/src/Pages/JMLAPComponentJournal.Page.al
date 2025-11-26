page 70182376 "JML AP Component Journal"
{
    Caption = 'Asset Component Journal';
    PageType = Worksheet;
    SourceTable = "JML AP Component Journal Line";
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
                ToolTip = 'Specifies the name of the component journal batch.';
                Lookup = true;

                trigger OnValidate()
                begin
                    SetBatchFilter();
                end;

                trigger OnLookup(var Text: Text): Boolean
                var
                    ComponentJnlBatch: Record "JML AP Component Jnl. Batch";
                begin
                    if Page.RunModal(Page::"JML AP Component Jnl. Batches", ComponentJnlBatch) = Action::LookupOK then begin
                        CurrentBatchName := ComponentJnlBatch.Name;
                        SetBatchFilter();
                    end;
                end;
            }

            repeater(Lines)
            {
                field("Journal Batch"; Rec."Journal Batch")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the journal batch.';
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the line number.';
                    Visible = false;
                }
                field("Asset No."; Rec."Asset No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the asset number.';
                    ShowMandatory = true;
                }
                field("Asset Description"; Rec."Asset Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the asset description.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the item number.';
                    ShowMandatory = true;
                }
                field("Item Description"; Rec."Item Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the item description.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the variant code.';
                }
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the entry type (Install, Remove, Replace, Adjustment).';
                    ShowMandatory = true;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the quantity (positive for Install, negative for Remove).';
                    ShowMandatory = true;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unit of measure code.';
                }
                field(Position; Rec.Position)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the physical location within the asset.';
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the serial number.';
                }
                field("Lot No."; Rec."Lot No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the lot number.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the posting date.';
                    ShowMandatory = true;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the reason code.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the document number.';
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the external document number.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Post)
            {
                ApplicationArea = All;
                Caption = 'Post';
                ToolTip = 'Post the component journal lines.';
                Image = Post;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    ComponentJnlPost: Codeunit "JML AP Component Jnl.-Post";
                begin
                    Commit();
                    ComponentJnlPost.Run(Rec);
                    CurrPage.Update(false);
                end;
            }

            action(PostAndPrint)
            {
                ApplicationArea = All;
                Caption = 'Post and Print';
                ToolTip = 'Post the component journal lines and print the entries.';
                Image = PostPrint;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    ComponentJnlPost: Codeunit "JML AP Component Jnl.-Post";
                    ComponentEntry: Record "JML AP Component Entry";
                begin
                    Commit();
                    ComponentJnlPost.Run(Rec);
                    CurrPage.Update(false);

                    // Print functionality - open Component Entries page
                    ComponentEntry.SetRange("Posting Date", WorkDate());
                    Page.Run(Page::"JML AP Component Entries", ComponentEntry);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        if CurrentBatchName = '' then
            SetDefaultBatch();
        SetBatchFilter();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Journal Batch" := CurrentBatchName;
        Rec."Posting Date" := WorkDate();
    end;

    local procedure SetBatchFilter()
    begin
        Rec.FilterGroup := 2;
        Rec.SetRange("Journal Batch", CurrentBatchName);
        Rec.FilterGroup := 0;
        if Rec.Find('-') then;
        CurrPage.Update(false);
    end;

    local procedure SetDefaultBatch()
    var
        ComponentJnlBatch: Record "JML AP Component Jnl. Batch";
    begin
        if ComponentJnlBatch.FindFirst() then
            CurrentBatchName := ComponentJnlBatch.Name
        else begin
            ComponentJnlBatch.Init();
            ComponentJnlBatch.Name := 'DEFAULT';
            ComponentJnlBatch.Description := 'Default Batch';
            ComponentJnlBatch.Insert();
            CurrentBatchName := ComponentJnlBatch.Name;
        end;
    end;

    var
        CurrentBatchName: Code[10];
}
