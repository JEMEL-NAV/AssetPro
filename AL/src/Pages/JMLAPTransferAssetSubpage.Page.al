page 70182363 "JML AP Transfer Asset Subpage"
{
    Caption = 'Asset Lines';
    Description = 'Subpage for managing assets linked to inventory transfer lines.';
    PageType = ListPart;
    SourceTable = "JML AP Transfer Asset Line";
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Asset No."; Rec."Asset No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the asset to transfer with this transfer order.';
                    ShowMandatory = true;
                }
                field("Asset Description"; Rec."Asset Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the asset.';
                }
                field("Current Holder Type"; Rec."Current Holder Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the current holder type of the asset.';
                }
                field("Current Holder Code"; Rec."Current Holder Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the current holder code of the asset.';
                }
                field("Quantity to Ship"; Rec."Quantity to Ship")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether to ship this asset (1 = Yes, 0 = No).';
                    BlankZero = true;
                }
                field("Quantity Shipped"; Rec."Quantity Shipped")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this asset has been shipped (1 = Yes, 0 = No).';
                    BlankZero = true;
                }
                field("Quantity to Receive"; Rec."Quantity to Receive")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether to receive this asset (1 = Yes, 0 = No).';
                    BlankZero = true;
                }
                field("Quantity Received"; Rec."Quantity Received")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this asset has been received (1 = Yes, 0 = No).';
                    BlankZero = true;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the reason code for this asset transfer.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description for this asset line.';
                }
            }
        }
    }
}
