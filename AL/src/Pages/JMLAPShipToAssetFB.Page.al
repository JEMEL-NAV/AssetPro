page 70182384 "JML AP Ship-to Asset FB"
{
    Caption = 'Ship-to Address Assets';
    PageType = CardPart;
    SourceTable = "Ship-to Address";

    layout
    {
        area(Content)
        {
            field("Asset Count"; AssetCount)
            {
                ApplicationArea = All;
                Caption = 'Assets at Ship-to Address';
                ToolTip = 'Specifies the number of assets currently at this ship-to address.';
                Editable = false;
                Style = Strong;
                StyleExpr = true;

                trigger OnDrillDown()
                var
                    Asset: Record "JML AP Asset";
                    AssetList: Page "JML AP Asset List";
                begin
                    Asset.SetRange("Current Holder Type", Asset."Current Holder Type"::Customer);
                    Asset.SetRange("Current Holder Code", Rec."Customer No.");
                    Asset.SetRange("Current Holder Addr Code", Rec.Code);
                    AssetList.SetTableView(Asset);
                    AssetList.Run();
                end;
            }
            field("Active Assets"; ActiveAssetCount)
            {
                ApplicationArea = All;
                Caption = 'Active Assets';
                ToolTip = 'Specifies the number of active assets at this ship-to address.';
                Editable = false;

                trigger OnDrillDown()
                var
                    Asset: Record "JML AP Asset";
                    AssetList: Page "JML AP Asset List";
                begin
                    Asset.SetRange("Current Holder Type", Asset."Current Holder Type"::Customer);
                    Asset.SetRange("Current Holder Code", Rec."Customer No.");
                    Asset.SetRange("Current Holder Addr Code", Rec.Code);
                    Asset.SetRange(Status, Asset.Status::Active);
                    AssetList.SetTableView(Asset);
                    AssetList.Run();
                end;
            }
            field("Inactive Assets"; InactiveAssetCount)
            {
                ApplicationArea = All;
                Caption = 'Inactive Assets';
                ToolTip = 'Specifies the number of inactive assets at this ship-to address.';
                Editable = false;

                trigger OnDrillDown()
                var
                    Asset: Record "JML AP Asset";
                    AssetList: Page "JML AP Asset List";
                begin
                    Asset.SetRange("Current Holder Type", Asset."Current Holder Type"::Customer);
                    Asset.SetRange("Current Holder Code", Rec."Customer No.");
                    Asset.SetRange("Current Holder Addr Code", Rec.Code);
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

        if (Rec."Customer No." = '') or (Rec.Code = '') then
            exit;

        Asset.SetRange("Current Holder Type", Asset."Current Holder Type"::Customer);
        Asset.SetRange("Current Holder Code", Rec."Customer No.");
        Asset.SetRange("Current Holder Addr Code", Rec.Code);
        AssetCount := Asset.Count;

        Asset.SetRange(Status, Asset.Status::Active);
        ActiveAssetCount := Asset.Count;

        Asset.SetRange(Status, Asset.Status::Inactive);
        InactiveAssetCount := Asset.Count;
    end;
}
