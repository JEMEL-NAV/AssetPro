page 70182332 "JML AP Asset List"
{
    Caption = 'Assets';
    Description = 'List of all fixed assets with their current status, holder information, and classification details.';
    PageType = List;
    SourceTable = "JML AP Asset";
    CardPageId = "JML AP Asset Card";
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Assets)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the asset number.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the asset.';
                }
                field("Industry Code"; Rec."Industry Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the industry code.';
                }
                field("Classification Code"; Rec."Classification Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the classification code.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the status of the asset.';
                }
                field("Current Holder Type"; Rec."Current Holder Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the current holder type.';
                }
                field("Current Holder Code"; Rec."Current Holder Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the current holder code.';
                }
                field("Current Holder Name"; Rec."Current Holder Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the current holder name.';
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the serial number.';
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(HolderHistory)
            {
                ApplicationArea = All;
                Caption = 'Holder History';
                ToolTip = 'View the holder history for this asset.';
                Image = History;
                RunObject = page "JML AP Holder Entries";
                RunPageLink = "Asset No." = field("No.");
            }
            action(RelationshipHistory)
            {
                ApplicationArea = All;
                Caption = 'Relationship History';
                ToolTip = 'View the attach/detach history for the selected asset.';
                Image = History;
                RunObject = page "JML AP Relationship Entries";
                RunPageLink = "Asset No." = field("No.");
            }
        }
        area(Processing)
        {
            action(DetachFromParent)
            {
                ApplicationArea = All;
                Caption = 'Detach from Parent';
                ToolTip = 'Detach selected assets from their parent assets.';
                Image = UnLinkAccount;

                trigger OnAction()
                var
                    Asset: Record "JML AP Asset";
                    DetachedCount: Integer;
                begin
                    CurrPage.SetSelectionFilter(Asset);
                    if Asset.FindSet() then begin
                        repeat
                            if Asset."Parent Asset No." <> '' then begin
                                Asset.DetachFromParent();
                                DetachedCount += 1;
                            end;
                        until Asset.Next() = 0;
                    end;

                    if DetachedCount > 0 then
                        Message(AssetsDetachedMsg, DetachedCount)
                    else
                        Message(NoAssetsWithParentMsg);

                    CurrPage.Update(false);
                end;
            }
            action(TransferAsset)
            {
                ApplicationArea = All;
                Caption = 'Transfer Asset';
                ToolTip = 'Transfer this asset to a new holder.';
                Image = TransferOrder;

                trigger OnAction()
                begin
                    Message(TransferFunctionalityMsg);
                end;
            }
        }
        area(Reporting)
        {
            action(AssetListReport)
            {
                ApplicationArea = All;
                Caption = 'Asset List Report';
                ToolTip = 'Print a detailed list of assets with optional grouping.';
                Image = Report;
                RunObject = report "JML AP Asset List";
            }
            action(AssetsByHolderReport)
            {
                ApplicationArea = All;
                Caption = 'Assets by Holder Report';
                ToolTip = 'Show which assets are currently held by each holder.';
                Image = Report;
                RunObject = report "JML AP Assets by Holder";
            }
        }
    }

    var
        AssetsDetachedMsg: Label '%1 asset(s) detached from parent.', Comment = '%1 = Number of assets detached';
        NoAssetsWithParentMsg: Label 'No assets with parent relationships were selected.';
        TransferFunctionalityMsg: Label 'Transfer functionality will be implemented via page extension.';
}
