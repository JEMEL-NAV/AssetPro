page 70182380 "JML AP Vendor Asset FB"
{
    Caption = 'Vendor Assets';
    PageType = CardPart;
    SourceTable = Vendor;

    layout
    {
        area(Content)
        {
            field("Asset Count"; AssetCount)
            {
                ApplicationArea = All;
                Caption = 'Assets at Vendor';
                ToolTip = 'Specifies the number of assets currently held by this vendor.';
                Editable = false;
                Style = Strong;
                StyleExpr = true;

                trigger OnDrillDown()
                var
                    Asset: Record "JML AP Asset";
                    AssetList: Page "JML AP Asset List";
                begin
                    Asset.SetRange("Current Holder Type", Asset."Current Holder Type"::Vendor);
                    Asset.SetRange("Current Holder Code", Rec."No.");
                    AssetList.SetTableView(Asset);
                    AssetList.Run();
                end;
            }
            field("Active Assets"; ActiveAssetCount)
            {
                ApplicationArea = All;
                Caption = 'Active Assets';
                ToolTip = 'Specifies the number of active assets at this vendor.';
                Editable = false;

                trigger OnDrillDown()
                var
                    Asset: Record "JML AP Asset";
                    AssetList: Page "JML AP Asset List";
                begin
                    Asset.SetRange("Current Holder Type", Asset."Current Holder Type"::Vendor);
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
                ToolTip = 'Specifies the number of inactive assets at this vendor.';
                Editable = false;

                trigger OnDrillDown()
                var
                    Asset: Record "JML AP Asset";
                    AssetList: Page "JML AP Asset List";
                begin
                    Asset.SetRange("Current Holder Type", Asset."Current Holder Type"::Vendor);
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

        Asset.SetRange("Current Holder Type", Asset."Current Holder Type"::Vendor);
        Asset.SetRange("Current Holder Code", Rec."No.");
        AssetCount := Asset.Count;

        Asset.SetRange(Status, Asset.Status::Active);
        ActiveAssetCount := Asset.Count;

        Asset.SetRange(Status, Asset.Status::Inactive);
        InactiveAssetCount := Asset.Count;
    end;
}
