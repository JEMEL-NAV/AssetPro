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
            begin
                if "JML AP Asset No." <> '' then begin
                    if not Asset.Get("JML AP Asset No.") then
                        Error('Asset %1 does not exist.', "JML AP Asset No.");
                    if Type <> Type::Item then
                        Error('Asset No. can only be specified for Item lines.');
                    if "No." = '' then
                        Error('Item No. must be specified when Asset No. is entered.');
                end;
            end;
        }
    }
}
