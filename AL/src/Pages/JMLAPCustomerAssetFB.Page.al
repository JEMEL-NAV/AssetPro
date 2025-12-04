page 70182379 "JML AP Customer Asset FB"
{
    Caption = 'Customer Assets';
    Description = 'Displays assets currently held by the selected customer.';
    PageType = CardPart;
    SourceTable = Customer;

    layout
    {
        area(Content)
        {
            field("Asset Count"; AssetCount)
            {
                ApplicationArea = All;
                Caption = 'Assets at Customer';
                ToolTip = 'Specifies the number of assets currently held by this customer.';
                Editable = false;
                Style = Strong;
                StyleExpr = true;

                trigger OnDrillDown()
                var
                    Asset: Record "JML AP Asset";
                    AssetList: Page "JML AP Asset List";
                begin
                    Asset.SetRange("Current Holder Type", Asset."Current Holder Type"::Customer);
                    Asset.SetRange("Current Holder Code", Rec."No.");
                    AssetList.SetTableView(Asset);
                    AssetList.Run();
                end;
            }
            field("Active Assets"; ActiveAssetCount)
            {
                ApplicationArea = All;
                Caption = 'Active Assets';
                ToolTip = 'Specifies the number of active assets at this customer.';
                Editable = false;

                trigger OnDrillDown()
                var
                    Asset: Record "JML AP Asset";
                    AssetList: Page "JML AP Asset List";
                begin
                    Asset.SetRange("Current Holder Type", Asset."Current Holder Type"::Customer);
                    Asset.SetRange("Current Holder Code", Rec."No.");
                    Asset.SetRange(Status, Asset.Status::Active);
                    AssetList.SetTableView(Asset);
                    AssetList.Run();
                end;
            }
            field("Inactive Assets"; InactiveAssetCount)
            {
                ApplicationArea = All;
                Caption = 'Inactive Assets';
                ToolTip = 'Specifies the number of inactive assets at this customer.';
                Editable = false;

                trigger OnDrillDown()
                var
                    Asset: Record "JML AP Asset";
                    AssetList: Page "JML AP Asset List";
                begin
                    Asset.SetRange("Current Holder Type", Asset."Current Holder Type"::Customer);
                    Asset.SetRange("Current Holder Code", Rec."No.");
                    Asset.SetRange(Status, Asset.Status::Inactive);
                    AssetList.SetTableView(Asset);
                    AssetList.Run();
                end;
            }
        }
    }

    var
        AssetCount: Integer;
        ActiveAssetCount: Integer;
        InactiveAssetCount: Integer;

    trigger OnAfterGetCurrRecord()
    begin
        CalculateAssetCounts();
    end;

    local procedure CalculateAssetCounts()
    var
        Asset: Record "JML AP Asset";
    begin
        AssetCount := 0;
        ActiveAssetCount := 0;
        InactiveAssetCount := 0;

        if Rec."No." = '' then
            exit;

        Asset.SetRange("Current Holder Type", Asset."Current Holder Type"::Customer);
        Asset.SetRange("Current Holder Code", Rec."No.");
        AssetCount := Asset.Count;

        Asset.SetRange(Status, Asset.Status::Active);
        ActiveAssetCount := Asset.Count;

        Asset.SetRange(Status, Asset.Status::Inactive);
        InactiveAssetCount := Asset.Count;
    end;
}
