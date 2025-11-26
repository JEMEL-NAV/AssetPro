page 70182376 "JML AP Component Journal"
{
    Caption = 'Component Journal';
    PageType = Worksheet;
    SourceTable = "JML AP Component Journal Line";
    ApplicationArea = All;
    UsageCategory = Tasks;

    layout
    {
        area(Content)
        {
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
                begin
                    // Placeholder - will be implemented in Stage 4.3
                    Message('Post action will be implemented in Stage 4.3 with Component Jnl.-Post codeunit.');
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
                begin
                    // Placeholder - will be implemented in Stage 4.3
                    Message('Post and Print action will be implemented in Stage 4.3.');
                end;
            }
        }
    }
}
