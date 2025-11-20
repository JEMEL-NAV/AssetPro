codeunit 70182393 "JML AP Relationship Mgt"
{
    /// <summary>
    /// Centralized management of asset relationship tracking.
    /// Logs attach and detach events for audit trail and compliance.
    /// </summary>

    var
        AssetNotFoundErr: Label 'Asset %1 does not exist.', Comment = '%1 = Asset No.';
        ParentAssetNotFoundErr: Label 'Parent asset %1 does not exist.', Comment = '%1 = Parent Asset No.';

    /// <summary>
    /// Logs an Attach event when an asset becomes a child of a parent asset.
    /// </summary>
    /// <param name="AssetNo">The asset being attached.</param>
    /// <param name="ParentAssetNo">The parent asset.</param>
    /// <param name="ReasonCode">Optional reason code for the attachment.</param>
    /// <param name="PostingDate">The posting date for this event.</param>
    /// <returns>The Entry No. of the created entry.</returns>
    procedure LogAttachEvent(AssetNo: Code[20]; ParentAssetNo: Code[20]; ReasonCode: Code[10]; PostingDate: Date): Integer
    var
        Asset: Record "JML AP Asset";
        ParentAsset: Record "JML AP Asset";
        RelationshipEntry: Record "JML AP Asset Relation Entry";
        TransactionNo: Integer;
    begin
        // Validate asset exists
        if not Asset.Get(AssetNo) then
            Error(AssetNotFoundErr, AssetNo);

        // Validate parent asset exists
        if not ParentAsset.Get(ParentAssetNo) then
            Error(ParentAssetNotFoundErr, ParentAssetNo);

        // Get next transaction number
        TransactionNo := GetNextTransactionNo();

        // Create relationship entry
        RelationshipEntry.Init();
        RelationshipEntry."Entry Type" := RelationshipEntry."Entry Type"::Attach;
        RelationshipEntry."Asset No." := AssetNo;
        RelationshipEntry."Parent Asset No." := ParentAssetNo;
        RelationshipEntry."Posting Date" := PostingDate;
        RelationshipEntry."Holder Type at Entry" := Asset."Current Holder Type";
        RelationshipEntry."Holder Code at Entry" := Asset."Current Holder Code";
        RelationshipEntry."Reason Code" := ReasonCode;
        RelationshipEntry.Description := StrSubstNo('Attached to parent %1', ParentAssetNo);
        RelationshipEntry."Transaction No." := TransactionNo;
        RelationshipEntry.Insert(true);

        exit(RelationshipEntry."Entry No.");
    end;

    /// <summary>
    /// Logs a Detach event when an asset is freed from a parent asset.
    /// </summary>
    /// <param name="AssetNo">The asset being detached.</param>
    /// <param name="ParentAssetNo">The parent asset.</param>
    /// <param name="ReasonCode">Optional reason code for the detachment.</param>
    /// <param name="PostingDate">The posting date for this event.</param>
    /// <returns>The Entry No. of the created entry.</returns>
    procedure LogDetachEvent(AssetNo: Code[20]; ParentAssetNo: Code[20]; ReasonCode: Code[10]; PostingDate: Date): Integer
    var
        Asset: Record "JML AP Asset";
        ParentAsset: Record "JML AP Asset";
        RelationshipEntry: Record "JML AP Asset Relation Entry";
        TransactionNo: Integer;
    begin
        // Validate asset exists
        if not Asset.Get(AssetNo) then
            Error(AssetNotFoundErr, AssetNo);

        // Validate parent asset exists (may not exist if detaching, but validate anyway)
        if ParentAssetNo <> '' then
            if not ParentAsset.Get(ParentAssetNo) then
                Error(ParentAssetNotFoundErr, ParentAssetNo);

        // Get next transaction number
        TransactionNo := GetNextTransactionNo();

        // Create relationship entry
        RelationshipEntry.Init();
        RelationshipEntry."Entry Type" := RelationshipEntry."Entry Type"::Detach;
        RelationshipEntry."Asset No." := AssetNo;
        RelationshipEntry."Parent Asset No." := ParentAssetNo;
        RelationshipEntry."Posting Date" := PostingDate;
        RelationshipEntry."Holder Type at Entry" := Asset."Current Holder Type";
        RelationshipEntry."Holder Code at Entry" := Asset."Current Holder Code";
        RelationshipEntry."Reason Code" := ReasonCode;
        if ParentAssetNo <> '' then
            RelationshipEntry.Description := StrSubstNo('Detached from parent %1', ParentAssetNo)
        else
            RelationshipEntry.Description := 'Detached from parent';
        RelationshipEntry."Transaction No." := TransactionNo;
        RelationshipEntry.Insert(true);

        exit(RelationshipEntry."Entry No.");
    end;

    /// <summary>
    /// Gets the complete relationship history for an asset.
    /// </summary>
    /// <param name="AssetNo">The asset to get history for.</param>
    /// <param name="var RelationshipEntry">Returns all relationship entries for the asset.</param>
    procedure GetRelationshipHistory(AssetNo: Code[20]; var RelationshipEntry: Record "JML AP Asset Relation Entry")
    begin
        RelationshipEntry.Reset();
        RelationshipEntry.SetRange("Asset No.", AssetNo);
        RelationshipEntry.SetCurrentKey("Asset No.", "Posting Date");
    end;

    /// <summary>
    /// Gets all child assets that were attached to a parent on a specific date.
    /// This is useful for historical queries like "What components were in Vehicle V-001 on 2024-01-15?"
    /// </summary>
    /// <param name="ParentAssetNo">The parent asset.</param>
    /// <param name="AsOfDate">The date to check.</param>
    /// <param name="var TempChildAssets">Returns temporary record with child asset numbers.</param>
    procedure GetComponentsAtDate(ParentAssetNo: Code[20]; AsOfDate: Date; var TempChildAssets: Record "JML AP Asset" temporary)
    var
        RelationshipEntry: Record "JML AP Asset Relation Entry";
        Asset: Record "JML AP Asset";
        LastEntryType: Enum "JML AP Relationship Entry Type";
    begin
        TempChildAssets.Reset();
        TempChildAssets.DeleteAll();

        // Find all assets that had relationship events with this parent up to the date
        RelationshipEntry.SetRange("Parent Asset No.", ParentAssetNo);
        RelationshipEntry.SetFilter("Posting Date", '<=%1', AsOfDate);
        RelationshipEntry.SetCurrentKey("Asset No.", "Posting Date");

        if RelationshipEntry.FindSet() then
            repeat
                // For each asset, find the last entry type before or on the date
                RelationshipEntry.SetRange("Asset No.", RelationshipEntry."Asset No.");
                if RelationshipEntry.FindLast() then
                    LastEntryType := RelationshipEntry."Entry Type";

                // If last entry was Attach, the asset was attached on that date
                if LastEntryType = LastEntryType::Attach then begin
                    if Asset.Get(RelationshipEntry."Asset No.") then begin
                        TempChildAssets.Init();
                        TempChildAssets.TransferFields(Asset);
                        if TempChildAssets.Insert() then;
                    end;
                end;

                // Reset filters for next asset
                RelationshipEntry.SetRange("Asset No.");
                RelationshipEntry.SetRange("Parent Asset No.", ParentAssetNo);
                RelationshipEntry.SetFilter("Posting Date", '<=%1', AsOfDate);
            until RelationshipEntry.Next() = 0;
    end;

    local procedure GetNextTransactionNo(): Integer
    var
        RelationshipEntry: Record "JML AP Asset Relation Entry";
    begin
        if RelationshipEntry.FindLast() then
            exit(RelationshipEntry."Transaction No." + 1)
        else
            exit(1);
    end;
}
