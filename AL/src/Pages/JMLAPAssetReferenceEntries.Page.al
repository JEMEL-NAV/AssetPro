page 70182383 "JML AP Asset Reference Entries"
{
    Caption = 'Asset Reference Entries';
    PageType = List;
    SourceTable = "JML AP Asset Reference";
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Asset No."; Rec."Asset No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the asset number.';
                }
                field("Reference Type"; Rec."Reference Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of reference.';
                }
                field("Reference Type No."; Rec."Reference Type No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the reference type number.';
                }
                field("Reference No."; Rec."Reference No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the reference number.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the starting date.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the ending date.';
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
                ToolTip = 'View the asset card for this reference.';
                Image = ShowList;
                RunObject = page "JML AP Asset Card";
                RunPageLink = "No." = field("Asset No.");
            }
        }
    }
}
