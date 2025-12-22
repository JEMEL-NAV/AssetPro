page 70182370 "JML AP Asset Mgmt. Role Center"
{
    Caption = 'Asset Manager Role Center';
    Description = 'Main role center for asset managers with navigation, activities, and key performance indicators.';
    PageType = RoleCenter;

    layout
    {
        area(rolecenter)
        {
            part(Headline; "JML AP Asset Mgmt. Headline")
            {
                ApplicationArea = All;
            }
            part(Activities; "JML AP Asset Mgmt. Activities")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Sections)
        {
            group(Assets)
            {
                Caption = 'Assets';

                action("Asset List")
                {
                    ApplicationArea = All;
                    Caption = 'Asset List';
                    RunObject = Page "JML AP Asset List";
                    ToolTip = 'View and manage all assets.';
                }
                action("Asset Tree")
                {
                    ApplicationArea = All;
                    Caption = 'Asset Tree';
                    RunObject = Page "JML AP Asset Tree";
                    ToolTip = 'View assets in a hierarchical tree structure.';
                }
                action("Holder Entries")
                {
                    ApplicationArea = All;
                    Caption = 'Holder Entries';
                    RunObject = Page "JML AP Holder Entries";
                    ToolTip = 'View the complete history of asset holder changes.';
                }
                action("Relationship Entries")
                {
                    ApplicationArea = All;
                    Caption = 'Relationship Entries';
                    RunObject = Page "JML AP Relationship Entries";
                    ToolTip = 'View the history of asset attach and detach events.';
                }
            }
            group(Transfers)
            {
                Caption = 'Transfers';

                action("Transfer Orders")
                {
                    ApplicationArea = All;
                    Caption = 'Transfer Orders';
                    RunObject = Page "JML AP Asset Transfer Orders";
                    ToolTip = 'View and manage asset transfer orders.';
                }

                action("Posted Transfers")
                {
                    ApplicationArea = All;
                    Caption = 'Posted Transfers';
                    RunObject = Page "JML AP Asset Posted Transfers";
                    ToolTip = 'View posted asset transfers.';
                }
                action("Asset Journal")
                {
                    ApplicationArea = All;
                    Caption = 'Asset Journal';
                    RunObject = Page "JML AP Asset Journal";
                    ToolTip = 'Post asset transfers using journal batches.';
                }
            }
            group(Components)
            {
                Caption = 'Components';

                action("Component Entries")
                {
                    ApplicationArea = All;
                    Caption = 'Component Entries';
                    RunObject = Page "JML AP Component Entries";
                    ToolTip = 'View all component installation and removal entries.';
                }
                action("Component Journal")
                {
                    ApplicationArea = All;
                    Caption = 'Component Journal';
                    RunObject = Page "JML AP Component Journal";
                    ToolTip = 'Record component installations and removals.';
                }
            }
            group(Documents)
            {
                Caption = 'Document Integration';

                group(Sales)
                {
                    Caption = 'Sales';

                    action("Posted Sales Shipments")
                    {
                        ApplicationArea = All;
                        Caption = 'Posted Sales Shipments';
                        RunObject = Page "Posted Sales Shipments";
                        ToolTip = 'View posted sales shipments with asset transfers.';
                    }
                    action("Posted Return Receipts")
                    {
                        ApplicationArea = All;
                        Caption = 'Posted Return Receipts';
                        RunObject = Page "Posted Return Receipts";
                        ToolTip = 'View posted return receipts with asset transfers.';
                    }
                }
                group(Purchase)
                {
                    Caption = 'Purchase';

                    action("Posted Purchase Receipts")
                    {
                        ApplicationArea = All;
                        Caption = 'Posted Purchase Receipts';
                        RunObject = Page "Posted Purchase Receipts";
                        ToolTip = 'View posted purchase receipts with asset transfers.';
                    }
                    action("Posted Return Shipments")
                    {
                        ApplicationArea = All;
                        Caption = 'Posted Return Shipments';
                        RunObject = Page "Posted Return Shipments";
                        ToolTip = 'View posted return shipments with asset transfers.';
                    }
                }
            }
            group(Setup)
            {
                Caption = 'Setup & Configuration';

                action("Asset Setup")
                {
                    ApplicationArea = All;
                    Caption = 'Asset Setup';
                    RunObject = Page "JML AP Asset Setup";
                    ToolTip = 'Configure Asset Pro settings and number series.';
                }
                action("Asset Industries")
                {
                    ApplicationArea = All;
                    Caption = 'Asset Industries';
                    RunObject = Page "JML AP Industries";
                    ToolTip = 'Define asset industry categories.';
                }
                action("Asset Journal Batches")
                {
                    ApplicationArea = All;
                    Caption = 'Asset Journal Batches';
                    RunObject = Page "JML AP Asset Journal Batches";
                    ToolTip = 'Manage asset journal batches.';
                }
                action("Component Journal Batches")
                {
                    ApplicationArea = All;
                    Caption = 'Component Journal Batches';
                    RunObject = Page "JML AP Component Jnl. Batches";
                    ToolTip = 'Manage component journal batches.';
                }
                action(Wizard)
                {
                    ApplicationArea = All;
                    Caption = 'Asset Setup Wizard';
                    RunObject = Page "JML AP Setup Wizard";
                    ToolTip = 'Launch the Asset Pro setup wizard.';
                }
                action(ConfigPackages)
                {
                    ApplicationArea = All;
                    Caption = 'Configuration Packages';
                    ToolTip = 'Configuration Packages';
                    RunObject = report "JML AP Config Packages";
                }
            }
        }
        area(Embedding)
        {
            action("Assets Embedded")
            {
                ApplicationArea = All;
                Caption = 'Assets';
                RunObject = Page "JML AP Asset List";
                ToolTip = 'View and manage all assets.';
            }
            action("Transfer Orders Embedded")
            {
                ApplicationArea = All;
                Caption = 'Transfer Orders';
                RunObject = Page "JML AP Asset Transfer Orders";
                ToolTip = 'View and manage asset transfer orders.';
            }
        }
        area(Creation)
        {
            action("New Asset Creation")
            {
                ApplicationArea = All;
                Caption = 'Asset';
                Image = FixedAssets;
                RunObject = Page "JML AP Asset Card";
                RunPageMode = Create;
                ToolTip = 'Create a new asset record.';
            }
            action("New Transfer Order Creation")
            {
                ApplicationArea = All;
                Caption = 'Transfer Order';
                Image = TransferOrder;
                RunObject = Page "JML AP Asset Transfer Order";
                RunPageMode = Create;
                ToolTip = 'Create a new asset transfer order.';
            }
        }
    }
}
