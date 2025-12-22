tableextension 70182427 "JML AP Sales Line Ext" extends "Sales Line"
{
    fields
    {
        field(70182300; "JML AP Asset No."; Code[20])
        {
            Caption = 'Asset No.';
            ToolTip = 'Specifies the asset number for component integration. When the sales document is posted, this asset number flows to the item journal and automatically creates component ledger entries.';
            DataClassification = CustomerContent;
            TableRelation = "JML AP Asset";

            trigger OnValidate()
            var
                Asset: Record "JML AP Asset";
                AssetNotExistErr: Label 'Asset %1 does not exist.', Comment = '%1 = Asset No.';
                AssetOnlyForItemLinesErr: Label 'Asset No. can only be specified for Item lines.';
                ItemNoMustBeSpecifiedErr: Label 'Item No. must be specified when Asset No. is entered.';
            begin
                if "JML AP Asset No." <> '' then begin
                    if not Asset.Get("JML AP Asset No.") then
                        Error(AssetNotExistErr, "JML AP Asset No.");
                    if Type <> Type::Item then
                        Error(AssetOnlyForItemLinesErr);
                    if "No." = '' then
                        Error(ItemNoMustBeSpecifiedErr);
                end;
            end;
        }
    }
}
