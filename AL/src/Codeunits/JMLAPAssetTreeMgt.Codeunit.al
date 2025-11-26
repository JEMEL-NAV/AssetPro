codeunit 70182394 "JML AP Asset Tree Mgt"
{
    /// <summary>
    /// Updates the presentation order for all assets in a given root asset tree.
    /// This ensures proper hierarchical display in tree views.
    /// </summary>
    procedure UpdatePresentationOrder(RootAssetNo: Code[20])
    var
        Asset: Record "JML AP Asset";
        TempAsset: Record "JML AP Asset" temporary;
    begin
        // Load all assets in the tree into temporary table
        Asset.SetRange("Root Asset No.", RootAssetNo);
        if Asset.FindSet() then
            repeat
                TempAsset.TransferFields(Asset);
                TempAsset.Insert();
            until Asset.Next() = 0;

        // Also include the root asset itself if viewing from a parent
        if RootAssetNo <> '' then
            if Asset.Get(RootAssetNo) then begin
                TempAsset.TransferFields(Asset);
                if TempAsset.Insert() then;
            end;

        // Calculate presentation order using depth-first traversal
        UpdatePresentationOrderIterative(TempAsset, RootAssetNo);
    end;

    local procedure UpdatePresentationOrderIterative(var TempAsset: Record "JML AP Asset" temporary; RootAssetNo: Code[20])
    var
        Asset: Record "JML AP Asset";
        TempStack: Record "Name/Value Buffer" temporary;
        CurrentAssetNo: Code[20];
        PresentationOrder: Integer;
    begin
        PresentationOrder := 0;

        // Start with the root asset
        TempAsset.Reset();
        TempAsset.SetRange("No.", RootAssetNo);
        if TempAsset.FindFirst() then
            PushAssetToStack(TempStack, TempAsset."No.");

        // If no specific root, start with all root-level assets in the filtered set
        if not TempStack.FindFirst() then begin
            TempAsset.Reset();
            TempAsset.SetRange("Parent Asset No.", '');
            if TempAsset.FindSet() then
                repeat
                    PushAssetToStack(TempStack, TempAsset."No.");
                until TempAsset.Next() = 0;
        end;

        // Depth-first traversal using stack
        while PopAssetFromStack(TempStack, CurrentAssetNo) do
            if TempAsset.Get(CurrentAssetNo) then begin
                PresentationOrder += 10000;

                // Update the real asset record
                if Asset.Get(CurrentAssetNo) then
                    if Asset."Presentation Order" <> PresentationOrder then begin
                        Asset."Presentation Order" := PresentationOrder;
                        Asset.Modify();
                    end;

                // Push children onto stack (in reverse order for correct tree display)
                TempAsset.Reset();
                TempAsset.SetCurrentKey("No.");
                TempAsset.Ascending(false);
                TempAsset.SetRange("Parent Asset No.", CurrentAssetNo);
                if TempAsset.FindSet() then
                    repeat
                        PushAssetToStack(TempStack, TempAsset."No.");
                    until TempAsset.Next() = 0;
            end;
    end;

    local procedure PushAssetToStack(var TempStack: Record "Name/Value Buffer" temporary; AssetNo: Code[20])
    var
        NextEntryNo: Integer;
    begin
        TempStack.Reset();
        if TempStack.FindLast() then
            NextEntryNo := TempStack.ID + 1
        else
            NextEntryNo := 1;

        TempStack.Init();
        TempStack.ID := NextEntryNo;
        TempStack.Name := CopyStr(AssetNo, 1, MaxStrLen(TempStack.Name));
        TempStack.Insert();
    end;

    local procedure PopAssetFromStack(var TempStack: Record "Name/Value Buffer" temporary; var AssetNo: Code[20]): Boolean
    begin
        TempStack.Reset();
        if not TempStack.FindLast() then
            exit(false);

        AssetNo := CopyStr(TempStack.Name, 1, 20);
        TempStack.Delete();
        exit(true);
    end;
}
