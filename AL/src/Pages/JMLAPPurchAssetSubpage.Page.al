page 70182360 "JML AP Purch. Asset Subpage"
{
    Caption = 'Asset Lines';
    PageType = ListPart;
    SourceTable = "JML AP Purch. Asset Line";
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            repeater(Lines)
            {
                field("Asset No."; Rec."Asset No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the asset to transfer with this purchase document.';
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
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
                field("Quantity to Receive"; Rec."Quantity to Receive")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether to receive this asset (1 = Yes, 0 = No). For receipt documents.';
                    Visible = IsReceiptDoc;
                }
                field("Quantity Received"; Rec."Quantity Received")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this asset has been received (1 = Yes, 0 = No).';
                    Visible = IsReceiptDoc;
                }
                field("Quantity to Ship"; Rec."Quantity to Ship")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether to ship/return this asset (1 = Yes, 0 = No). For return documents.';
                    Visible = IsReturnDoc;
                }
                field("Quantity Shipped"; Rec."Quantity Shipped")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this asset has been shipped (1 = Yes, 0 = No).';
                    Visible = IsReturnDoc;
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

    actions
    {
        area(processing)
        {
            action(AssetCard)
            {
                ApplicationArea = All;
                Caption = 'Asset Card';
                ToolTip = 'Open the asset card for this asset.';
                Image = Card;
                RunObject = page "JML AP Asset Card";
                RunPageLink = "No." = field("Asset No.");
                Enabled = Rec."Asset No." <> '';
            }
        }
    }

    trigger OnOpenPage()
    begin
        UpdateVisibility();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateVisibility();
    end;

    var
        IsReceiptDoc: Boolean;
        IsReturnDoc: Boolean;

    local procedure UpdateVisibility()
    var
        PurchHeader: Record "Purchase Header";
    begin
        if PurchHeader.Get(Rec."Document Type", Rec."Document No.") then begin
            IsReceiptDoc := PurchHeader."Document Type" in [PurchHeader."Document Type"::Order, PurchHeader."Document Type"::Invoice];
            IsReturnDoc := PurchHeader."Document Type" in [PurchHeader."Document Type"::"Credit Memo", PurchHeader."Document Type"::"Return Order"];
        end;
    end;
}
