codeunit 70182380 "JML AP Asset Management"
{
    /// <summary>
    /// Copies an asset with optional children.
    /// </summary>
    procedure CopyAsset(
        SourceAsset: Record "JML AP Asset";
        NewAssetNo: Code[20];
        CopyChildren: Boolean): Code[20]
    var
        NewAsset: Record "JML AP Asset";
        JMLAPGeneral: Codeunit "JML AP General";
    begin
        // License check
        if GuiAllowed then begin
            if not JMLAPGeneral.IsAllowedToUse(false) then
                error('');
        end else
            if not JMLAPGeneral.IsAllowedToUse(true) then
                error('');

        // Create new asset
        NewAsset.Init();
        NewAsset.TransferFields(SourceAsset, false);
        NewAsset."No." := NewAssetNo;
        NewAsset."Parent Asset No." := ''; // Reset parent
        NewAsset.Insert(true);

        // Copy attributes
        CopyAssetAttributes(SourceAsset."No.", NewAsset."No.");

        // Copy children if requested
        if CopyChildren then
            CopyChildAssets(SourceAsset."No.", NewAsset."No.");

        exit(NewAsset."No.");
    end;

    local procedure CopyAssetAttributes(SourceAssetNo: Code[20]; NewAssetNo: Code[20])
    var
        SourceAttr: Record "JML AP Attribute Value";
        NewAttr: Record "JML AP Attribute Value";
    begin
        SourceAttr.SetRange("Asset No.", SourceAssetNo);
        if SourceAttr.FindSet() then
            repeat
                NewAttr.Init();
                NewAttr.TransferFields(SourceAttr, false);
                NewAttr."Asset No." := NewAssetNo;
                NewAttr.Insert(true);
            until SourceAttr.Next() = 0;
    end;

    local procedure CopyChildAssets(SourceParentNo: Code[20]; NewParentNo: Code[20])
    var
        ChildAsset: Record "JML AP Asset";
        NewChildAsset: Record "JML AP Asset";
        NewChildNo: Code[20];
    begin
        ChildAsset.SetRange("Parent Asset No.", SourceParentNo);
        if ChildAsset.FindSet() then
            repeat
                NewChildNo := GetNextChildAssetNo();
                CopyAsset(ChildAsset, NewChildNo, true); // Recursive copy

                // Link copied child to new parent
                NewChildAsset.Get(NewChildNo);
                NewChildAsset.Validate("Parent Asset No.", NewParentNo);
                NewChildAsset.Modify(true);
            until ChildAsset.Next() = 0;
    end;

    local procedure GetNextChildAssetNo(): Code[20]
    var
        AssetSetup: Record "JML AP Asset Setup";
        NoSeries: Codeunit "No. Series";
        NewNo: Code[20];
    begin
        AssetSetup.GetRecordOnce();
        NewNo := NoSeries.GetNextNo(AssetSetup."Asset Nos.", Today);
        exit(NewNo);
    end;
}
