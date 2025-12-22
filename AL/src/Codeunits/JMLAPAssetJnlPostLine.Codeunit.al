codeunit 70182391 "JML AP Asset Jnl.-Post Line"
{
    TableNo = "JML AP Asset Journal Line";

    trigger OnRun()
    begin
        PostJournalLine(Rec);
    end;

    var
        GlobalTransactionNo: Integer;
        PostingDateErr: Label 'Posting date %1 cannot be before last entry date %2 for asset %3 or its children.', Comment = '%1 = Posting Date, %2 = Last Entry Date, %3 = Asset No.';
        PostingDateBeforeRangeErr: Label 'Posting date %1 is before allowed range start date %2.', Comment = '%1 = Posting Date, %2 = Allow Posting From';
        PostingDateAfterRangeErr: Label 'Posting date %1 is after allowed range end date %2.', Comment = '%1 = Posting Date, %2 = Allow Posting To';
        SubassetErr: Label 'Cannot transfer subasset %1. It is attached to parent %2. Detach first.', Comment = '%1 = Asset No., %2 = Parent Asset No.';
        SameHolderAddressErr: Label 'New holder and address must be different from current holder and address for asset %1. Specify a different address for same-holder transfers.', Comment = '%1 = Asset No.';


    procedure PostJournalLine(
        var JnlLine: Record "JML AP Asset Journal Line")
    var
        Asset: Record "JML AP Asset";
        DocumentType: Enum "JML AP Document Type";
    begin
        // Validate journal line
        CheckJournalLine(JnlLine);

        // Get asset
        Asset.Get(JnlLine."Asset No.");

        // Validate posting date
        ValidatePostingDate(Asset."No.", JnlLine."Posting Date");

        // Transfer asset with children
        DocumentType := DocumentType::Journal;

        // Get next transaction number (shared by parent and all children)
        GlobalTransactionNo := GetNextTransactionNo();

        TransferAssetWithChildren(
            Asset,
            JnlLine."New Holder Type",
            JnlLine."New Holder Code",
            JnlLine."New Holder Addr Code",
            DocumentType,
            JnlLine."Document No.",
            JnlLine."Reason Code",
            JnlLine."Posting Date",
            JnlLine.Description);
    end;

    local procedure CheckJournalLine(var JnlLine: Record "JML AP Asset Journal Line")
    var
        Asset: Record "JML AP Asset";
    begin
        JnlLine.TestField("Asset No.");
        JnlLine.TestField("New Holder Type");
        JnlLine.TestField("New Holder Code");
        JnlLine.TestField("Posting Date");
        JnlLine.TestField("Document No.");

        // Validate asset exists and not blocked
        Asset.Get(JnlLine."Asset No.");
        Asset.TestField(Blocked, false);

        // Cannot transfer subasset independently
        if Asset."Parent Asset No." <> '' then
            Error(SubassetErr, Asset."No.", Asset."Parent Asset No.");

        // Validate not transferring to same holder and address
        if (JnlLine."New Holder Type" = JnlLine."Current Holder Type") and
           (JnlLine."New Holder Code" = JnlLine."Current Holder Code") and
           (JnlLine."New Holder Addr Code" = JnlLine."Current Holder Addr Code")
        then
            Error(SameHolderAddressErr, Asset."No.");
    end;

    internal procedure ValidatePostingDate(AssetNo: Code[20]; PostingDate: Date)
    var
        Asset: Record "JML AP Asset";
        HolderEntry: Record "JML AP Holder Entry";
        UserSetup: Record "User Setup";
        MaxPostingDate: Date;
    begin
        Asset.Get(AssetNo);

        // Check last entry date for this asset
        HolderEntry.SetCurrentKey("Asset No.", "Posting Date");
        HolderEntry.SetRange("Asset No.", AssetNo);
        if HolderEntry.FindLast() then
            MaxPostingDate := HolderEntry."Posting Date";

        // Check last entry date for all subassets (recursive)
        CheckChildrenLastPostingDate(AssetNo, MaxPostingDate);

        // Validate not before max date
        if PostingDate < MaxPostingDate then
            Error(PostingDateErr, PostingDate, MaxPostingDate, AssetNo);

        // Check user allowed posting date range
        if UserSetup.Get(UserId) then begin
            if UserSetup."Allow Posting From" <> 0D then
                if PostingDate < UserSetup."Allow Posting From" then
                    Error(PostingDateBeforeRangeErr, PostingDate, UserSetup."Allow Posting From");

            if UserSetup."Allow Posting To" <> 0D then
                if PostingDate > UserSetup."Allow Posting To" then
                    Error(PostingDateAfterRangeErr, PostingDate, UserSetup."Allow Posting To");
        end;
    end;

    local procedure CheckChildrenLastPostingDate(ParentAssetNo: Code[20]; var MaxPostingDate: Date)
    var
        ChildAsset: Record "JML AP Asset";
        HolderEntry: Record "JML AP Holder Entry";
    begin
        ChildAsset.SetRange("Parent Asset No.", ParentAssetNo);
        if ChildAsset.FindSet() then
            repeat
                // Check this child's last entry
                HolderEntry.SetCurrentKey("Asset No.", "Posting Date");
                HolderEntry.SetRange("Asset No.", ChildAsset."No.");
                if HolderEntry.FindLast() then
                    if HolderEntry."Posting Date" > MaxPostingDate then
                        MaxPostingDate := HolderEntry."Posting Date";

                // Recursive check for grandchildren
                CheckChildrenLastPostingDate(ChildAsset."No.", MaxPostingDate);
            until ChildAsset.Next() = 0;
    end;

    internal procedure TransferAssetWithChildren(
        var Asset: Record "JML AP Asset";
        NewHolderType: Enum "JML AP Holder Type";
        NewHolderCode: Code[20];
        NewHolderAddrCode: Code[10];
        DocumentType: Enum "JML AP Document Type";
        DocumentNo: Code[20];
        ReasonCode: Code[10];
        PostingDate: Date;
        Description: Text[100])
    var
        ChildAsset: Record "JML AP Asset";
    begin

        // Transfer parent asset
        TransferAssetSingle(
            Asset,
            NewHolderType,
            NewHolderCode,
            NewHolderAddrCode,
            DocumentType,
            DocumentNo,
            ReasonCode,
            PostingDate,
            Description);

        // Automatically transfer all children (recursive)
        ChildAsset.SetRange("Parent Asset No.", Asset."No.");
        if ChildAsset.FindSet() then
            repeat
                TransferAssetWithChildren(
                    ChildAsset,
                    NewHolderType,
                    NewHolderCode,
                    NewHolderAddrCode,
                    DocumentType,
                    DocumentNo,
                    ReasonCode,
                    PostingDate,
                    Description);
            until ChildAsset.Next() = 0;
    end;

    local procedure TransferAssetSingle(
        var Asset: Record "JML AP Asset";
        NewHolderType: Enum "JML AP Holder Type";
        NewHolderCode: Code[20];
        NewHolderAddrCode: Code[10];
        DocumentType: Enum "JML AP Document Type";
        DocumentNo: Code[20];
        ReasonCode: Code[10];
        PostingDate: Date;
        Description: Text[100])
    var
        HolderEntry: Record "JML AP Holder Entry";
        HolderName: Text[100];
    begin
        // Create Transfer Out entry (from old holder)
        HolderEntry.Init();
        HolderEntry."Entry No." := FindNextEntryNo();
        HolderEntry."Asset No." := Asset."No.";
        HolderEntry."Posting Date" := PostingDate;
        HolderEntry."Entry Type" := HolderEntry."Entry Type"::"Transfer Out";
        HolderEntry."Holder Type" := Asset."Current Holder Type";
        HolderEntry."Holder Code" := Asset."Current Holder Code";
        HolderEntry."Holder Name" := Asset."Current Holder Name";
        HolderEntry."Holder Addr Code" := Asset."Current Holder Addr Code";
        HolderEntry."Transaction No." := GlobalTransactionNo;
        HolderEntry."Document Type" := DocumentType;
        HolderEntry."Document No." := DocumentNo;
        HolderEntry."Reason Code" := ReasonCode;
        HolderEntry.Description := Description;
        HolderEntry."User ID" := CopyStr(UserId, 1, MaxStrLen(HolderEntry."User ID"));
        HolderEntry.Insert(true);

        // Get new holder name
        HolderName := GetHolderName(NewHolderType, NewHolderCode);

        // Create Transfer In entry (to new holder)
        HolderEntry.Init();
        HolderEntry."Entry No." := FindNextEntryNo();
        HolderEntry."Asset No." := Asset."No.";
        HolderEntry."Posting Date" := PostingDate;
        HolderEntry."Entry Type" := HolderEntry."Entry Type"::"Transfer In";
        HolderEntry."Holder Type" := NewHolderType;
        HolderEntry."Holder Code" := NewHolderCode;
        HolderEntry."Holder Name" := HolderName;
        HolderEntry."Holder Addr Code" := NewHolderAddrCode;
        HolderEntry."Transaction No." := GlobalTransactionNo;
        HolderEntry."Document Type" := DocumentType;
        HolderEntry."Document No." := DocumentNo;
        HolderEntry."Reason Code" := ReasonCode;
        HolderEntry.Description := Description;
        HolderEntry."User ID" := CopyStr(UserId, 1, MaxStrLen(HolderEntry."User ID"));
        HolderEntry.Insert(true);

        // Update asset current holder
        Asset."Current Holder Type" := NewHolderType;
        Asset."Current Holder Code" := NewHolderCode;
        Asset."Current Holder Name" := HolderName;
        Asset."Current Holder Addr Code" := NewHolderAddrCode;
        Asset."Current Holder Since" := PostingDate;
        Asset.Modify(true);
    end;

    local procedure GetNextTransactionNo(): Integer
    var
        HolderEntry: Record "JML AP Holder Entry";
    begin
        HolderEntry.LockTable();
        if HolderEntry.FindLast() then
            exit(HolderEntry."Transaction No." + 1)
        else
            exit(1);
    end;

    local procedure FindNextEntryNo(): Integer
    var
        HolderEntry: Record "JML AP Holder Entry";
    begin
        HolderEntry.LockTable();
        if HolderEntry.FindLast() then
            exit(HolderEntry."Entry No." + 1)
        else
            exit(1);
    end;

    local procedure GetHolderName(HolderType: Enum "JML AP Holder Type"; HolderCode: Code[20]): Text[100]
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Location: Record Location;
    begin
        case HolderType of
            HolderType::Customer:
                if Customer.Get(HolderCode) then
                    exit(Customer.Name);
            HolderType::Vendor:
                if Vendor.Get(HolderCode) then
                    exit(Vendor.Name);
            HolderType::Location:
                if Location.Get(HolderCode) then
                    exit(Location.Name);
        end;
        exit('');
    end;

    procedure GetTransactionNo(): Integer
    begin
        exit(GlobalTransactionNo)
    end;
}
