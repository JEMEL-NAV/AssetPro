codeunit 70182394 "JML AP Asset Tree Mgt"
{

    var
        TempAsset: Record "JML AP Asset" temporary;

    /// <summary>
    /// Updates the presentation order for all assets in a given root asset tree.
    /// This ensures proper hierarchical display in tree views.
    /// </summary>
    procedure UpdatePresentationOrder(RootAssetNo: code[20])
    begin
        TempAsset.Reset();
        TempAsset.DeleteAll();

        // Create temporary table with all assets in the tree
        CreateTempAssetRec(RootAssetNo);

        // Calculate presentation order using depth-first traversal
        UpdatePresentationOrderIterative();
    end;

    local procedure CreateTempAssetRec(RootAssetNo: code[20])
    var
        Asset: Record "JML AP Asset";
    begin
        // Also include the root asset itself if viewing from a parent
        if RootAssetNo <> '' then
            if Asset.Get(RootAssetNo) then
                if not TempAsset.Get(RootAssetNo) then begin
                    TempAsset.TransferFields(Asset);
                    if TempAsset.Insert() then;
                end;

        // Load all assets in the tree into temporary table
        if RootAssetNo = '' then
            Asset.SetRange("Parent Asset No.", '')
        else
            Asset.SetRange("Parent Asset No.", RootAssetNo);
        if Asset.FindSet() then
            repeat
                TempAsset.TransferFields(Asset);
                TempAsset.Insert();
                CreateTempAssetRec(TempAsset."No.");
            until Asset.Next() = 0;
    end;

    local procedure UpdatePresentationOrderIterative()
    var
        Asset: Record "JML AP Asset";
        TempCurAsset: Record "JML AP Asset" temporary;
        TempStack: Record TempStack temporary;
        CurAssetID: RecordId;
        PresentationOrder: Integer;
        HasChildren: Boolean;
        Indentation: Integer;
    begin
        PresentationOrder := 0;
        TempCurAsset.Copy(TempAsset, true);

        TempCurAsset.SetCurrentKey("Parent Asset No.");
        TempCurAsset.Ascending(false);
        TempCurAsset.SetRange("Parent Asset No.", '');
        if TempCurAsset.FindSet(false) then
            repeat
                TempStack.Push(TempCurAsset.RecordId());
            until TempCurAsset.Next() = 0;

        while TempStack.Pop(CurAssetID) do begin
            TempCurAsset.Get(CurAssetID);
            HasChildren := false;

            TempAsset.SetRange("Parent Asset No.", TempCurAsset."No.");
            if TempAsset.FindSet(false) then
                repeat
                    TempStack.Push(TempAsset.RecordId());
                    HasChildren := true;
                until TempAsset.Next() = 0;

            if TempCurAsset."Parent Asset No." <> '' then begin
                TempAsset.Get(TempCurAsset."Parent Asset No.");
                Indentation := TempAsset.Indentation + 1;
            end else
                Indentation := 0;
            PresentationOrder := PresentationOrder + 10000;

            if (TempCurAsset."Presentation Order" <> PresentationOrder) or
               (TempCurAsset.Indentation <> Indentation) or (TempCurAsset."Has Children" <> HasChildren)
            then begin
                Asset.Get(TempCurAsset."No.");
                Asset.Validate("Presentation Order", PresentationOrder);
                Asset.Validate(Indentation, Indentation);
                Asset.Modify();
                TempAsset.Get(TempCurAsset."No.");
                TempAsset.Validate("Presentation Order", PresentationOrder);
                TempAsset.Validate(Indentation, Indentation);
                TempAsset.Modify();
            end;
        end;

        // // Start with the root asset
        // TempAsset.Reset();
        // if RootAssetNo <> '' then
        //     TempAsset.SetRange("No.", RootAssetNo)
        // else
        //     TempAsset.SetRange("Parent Asset No.", '');
        // if TempAsset.FindSet() then
        //     repeat
        //         TempStack.Push(TempAsset.RecordId());
        //     until TempAsset.Next() = 0;



        // // If no specific root, start with all root-level assets in the filtered set
        // if not TempStack.FindFirst() then begin
        //     TempAsset.Reset();
        //     TempAsset.SetRange("Parent Asset No.", '');
        //     if TempAsset.FindSet() then
        //         repeat
        //             PushAssetToStack(TempStack, TempAsset."No.");
        //         until TempAsset.Next() = 0;
        // end;

        // // Depth-first traversal using stack
        // while PopAssetFromStack(TempStack, CurrentAssetNo) do
        //     if TempAsset.Get(CurrentAssetNo) then begin
        //         PresentationOrder += 10000;

        //         // Update the real asset record
        //         if Asset.Get(CurrentAssetNo) then
        //             if Asset."Presentation Order" <> PresentationOrder then begin
        //                 Asset."Presentation Order" := PresentationOrder;
        //                 Asset.Modify();
        //             end;

        //         // Push children onto stack (in reverse order for correct tree display)
        //         TempAsset.Reset();
        //         TempAsset.SetCurrentKey("No.");
        //         TempAsset.Ascending(false);
        //         TempAsset.SetRange("Parent Asset No.", CurrentAssetNo);
        //         if TempAsset.FindSet() then
        //             repeat
        //                 PushAssetToStack(TempStack, TempAsset."No.");
        //             until TempAsset.Next() = 0;
        //     end;
    end;

    // local procedure PushAssetToStack(var TempStack: Record "Name/Value Buffer" temporary; AssetNo: Code[20])
    // var
    //     NextEntryNo: Integer;
    // begin
    //     TempStack.Reset();
    //     if TempStack.FindLast() then
    //         NextEntryNo := TempStack.ID + 1
    //     else
    //         NextEntryNo := 1;

    //     TempStack.Init();
    //     TempStack.ID := NextEntryNo;
    //     TempStack.Name := CopyStr(AssetNo, 1, MaxStrLen(TempStack.Name));
    //     TempStack.Insert();
    // end;

    // local procedure PopAssetFromStack(var TempStack: Record "Name/Value Buffer" temporary; var AssetNo: Code[20]): Boolean
    // begin
    //     TempStack.Reset();
    //     if not TempStack.FindLast() then
    //         exit(false);

    //     AssetNo := CopyStr(TempStack.Name, 1, 20);
    //     TempStack.Delete();
    //     exit(true);
    // end;
}
