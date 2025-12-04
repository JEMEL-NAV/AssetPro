page 70182365 "JML AP Relationship Entries"
{
    Caption = 'Asset Relationship Entries';
    Description = 'View historical records of asset parent-child relationships including attach and detach events.';
    PageType = List;
    SourceTable = "JML AP Asset Relation Entry";
    ApplicationArea = All;
    UsageCategory = History;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Entries)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique entry number for this relationship entry.';
                }
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this is an Attach or Detach event.';
                }
                field("Asset No."; Rec."Asset No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the asset that was attached to or detached from a parent.';
                }
                field("Parent Asset No."; Rec."Parent Asset No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the parent asset in the relationship.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the posting date when the relationship change occurred.';
                }
                field("Holder Type at Entry"; Rec."Holder Type at Entry")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the holder type of the asset at the time of the relationship change.';
                }
                field("Holder Code at Entry"; Rec."Holder Code at Entry")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the holder code of the asset at the time of the relationship change.';
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the reason code for the relationship change.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the relationship change.';
                }
                field("Entry Date"; Rec."Entry Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date when this entry was created.';
                    Visible = false;
                }
                field("Entry Time"; Rec."Entry Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the time when this entry was created.';
                    Visible = false;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the user who created this entry.';
                }
                field("Transaction No."; Rec."Transaction No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the transaction number that links related relationship entries.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(ShowAsset)
            {
                ApplicationArea = All;
                Caption = 'Show Asset';
                ToolTip = 'Open the asset card for the selected entry.';
                Image = Item;
                RunObject = page "JML AP Asset Card";
                RunPageLink = "No." = field("Asset No.");
            }
            action(ShowParentAsset)
            {
                ApplicationArea = All;
                Caption = 'Show Parent Asset';
                ToolTip = 'Open the parent asset card for the selected entry.';
                Image = ItemTracking;
                RunObject = page "JML AP Asset Card";
                RunPageLink = "No." = field("Parent Asset No.");
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Navigate';
                actionref(ShowAsset_Promoted; ShowAsset)
                {
                }
                actionref(ShowParentAsset_Promoted; ShowParentAsset)
                {
                }
            }
        }
    }
}
