tableextension 70182426 "JML AP Item Journal Line Ext" extends "Item Journal Line"
{
    fields
    {
        field(70182300; "JML AP Asset No."; Code[20])
        {
            Caption = 'Asset No.';
            ToolTip = 'Specifies the asset number for component integration.';
            DataClassification = CustomerContent;
            TableRelation = "JML AP Asset";

            trigger OnValidate()
            var
                Asset: Record "JML AP Asset";
                AssetNotExistErr: Label 'Asset %1 does not exist.', Comment = '%1 = Asset No.';
                ItemNoMustBeSpecifiedErr: Label 'Item No. must be specified when Asset No. is entered.';
            begin
                if "JML AP Asset No." <> '' then begin
                    if not Asset.Get("JML AP Asset No.") then
                        Error(AssetNotExistErr, "JML AP Asset No.");

                    // Validate that item journal has an item number
                    if "Item No." = '' then
                        Error(ItemNoMustBeSpecifiedErr);
                end;
            end;
        }
    }
}
