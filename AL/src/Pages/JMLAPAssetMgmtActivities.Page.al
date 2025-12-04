page 70182371 "JML AP Asset Mgmt. Activities"
{
    Caption = 'Activities';
    Description = 'Displays activity cues and statistics for asset management tasks.';
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "JML AP Asset Mgmt. Cue";

    layout
    {
        area(content)
        {
            cuegroup(Assets)
            {
                Caption = 'Assets';

                field("Total Assets"; Rec."Total Assets")
                {
                    ApplicationArea = All;
                    DrillDownPageID = "JML AP Asset List";
                    ToolTip = 'Specifies the total number of assets in the system.';
                }
                field("Assets Without Holder"; Rec."Assets Without Holder")
                {
                    ApplicationArea = All;
                    DrillDownPageID = "JML AP Asset List";
                    ToolTip = 'Specifies the number of assets that do not have a holder assigned.';
                }
                field("Blocked Assets"; Rec."Blocked Assets")
                {
                    ApplicationArea = All;
                    DrillDownPageID = "JML AP Asset List";
                    ToolTip = 'Specifies the number of blocked assets.';
                }

                actions
                {
                    action("New Asset")
                    {
                        ApplicationArea = All;
                        Caption = 'New Asset';
                        RunObject = Page "JML AP Asset Card";
                        RunPageMode = Create;
                        ToolTip = 'Create a new asset record.';
                    }
                }
            }
            cuegroup(Transfers)
            {
                Caption = 'Transfers';

                field("Open Transfer Orders"; Rec."Open Transfer Orders")
                {
                    ApplicationArea = All;
                    DrillDownPageID = "JML AP Asset Transfer Orders";
                    ToolTip = 'Specifies the number of open asset transfer orders.';
                }
                field("Released Transfer Orders"; Rec."Released Transfer Orders")
                {
                    ApplicationArea = All;
                    DrillDownPageID = "JML AP Asset Transfer Orders";
                    ToolTip = 'Specifies the number of released asset transfer orders ready for posting.';
                }

                actions
                {
                    action("New Transfer Order")
                    {
                        ApplicationArea = All;
                        Caption = 'New Transfer Order';
                        RunObject = Page "JML AP Asset Transfer Order";
                        RunPageMode = Create;
                        ToolTip = 'Create a new asset transfer order.';
                    }
                    action("Asset Journal")
                    {
                        ApplicationArea = All;
                        Caption = 'Asset Journal';
                        RunObject = Page "JML AP Asset Journal";
                        ToolTip = 'Open the asset journal for batch asset transfers.';
                    }
                }
            }
            cuegroup(Components)
            {
                Caption = 'Components';

                field("Total Component Entries"; Rec."Total Component Entries")
                {
                    ApplicationArea = All;
                    DrillDownPageID = "JML AP Component Entries";
                    ToolTip = 'Specifies the total number of component entries recorded.';
                }

                actions
                {
                    action("Component Journal")
                    {
                        ApplicationArea = All;
                        Caption = 'Component Journal';
                        RunObject = Page "JML AP Component Journal";
                        ToolTip = 'Open the component journal to record component installations and removals.';
                    }
                }
            }
            cuegroup(TodaysActivity)
            {
                Caption = 'Today''s Activity';

                field("Assets Modified Today"; Rec."Assets Modified Today")
                {
                    ApplicationArea = All;
                    DrillDownPageID = "JML AP Asset List";
                    ToolTip = 'Specifies the number of assets modified today.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;

        Rec.SetFilter("Date Filter", '%1', WorkDate());
    end;
}
