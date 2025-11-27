page 70182364 "JML AP Pstd Trans Shpt Ast Sub"
{
    Caption = 'Posted Asset Lines';
    PageType = ListPart;
    SourceTable = "JML AP Pstd Trans Shpt Ast Ln";
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Asset No."; Rec."Asset No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the asset that was transferred.';
                }
                field("Asset Description"; Rec."Asset Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the asset.';
                }
                field("Transfer-from Code"; Rec."Transfer-from Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the source location code.';
                }
                field("Transfer-from Name"; Rec."Transfer-from Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the source location.';
                }
                field("Transfer-to Code"; Rec."Transfer-to Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the destination location code.';
                }
                field("Transfer-to Name"; Rec."Transfer-to Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the destination location.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the posting date of the transfer shipment.';
                }
                field("Transaction No."; Rec."Transaction No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the transaction number linking this asset transfer to holder entries.';
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
