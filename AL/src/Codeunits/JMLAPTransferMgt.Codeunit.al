codeunit 70182385 "JML AP Transfer Mgt"
{
    /// <summary>
    /// Transfers an asset to a new holder, creating ledger entries.
    /// </summary>
    procedure TransferAsset(
        var Asset: Record "JML AP Asset";
        NewHolderType: Enum "JML AP Holder Type";
        NewHolderCode: Code[20];
        DocumentType: Enum "JML AP Document Type";
        DocumentNo: Code[20];
        ReasonCode: Code[10]): Boolean
    var
        TransactionNo: Integer;
    begin
        // Validate transfer
        ValidateTransfer(Asset, NewHolderType, NewHolderCode);

        // Get next transaction number
        TransactionNo := GetNextTransactionNo();

        // Create Transfer Out entry (from old holder)
        CreateTransferOutEntry(
            Asset,
            TransactionNo,
            DocumentType,
            DocumentNo,
            ReasonCode);

        // Create Transfer In entry (to new holder)
        CreateTransferInEntry(
            Asset,
            NewHolderType,
            NewHolderCode,
            TransactionNo,
            DocumentType,
            DocumentNo,
            ReasonCode);

        // Update asset current holder
        UpdateAssetHolder(Asset, NewHolderType, NewHolderCode);

        exit(true);
    end;

    local procedure ValidateTransfer(
        var Asset: Record "JML AP Asset";
        NewHolderType: Enum "JML AP Holder Type";
        NewHolderCode: Code[20])
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Location: Record Location;
    begin
        if NewHolderCode = '' then
            Error(HolderCodeRequiredErr);

        // Validate holder exists
        case NewHolderType of
            NewHolderType::Customer:
                if not Customer.Get(NewHolderCode) then
                    Error(CustomerNotFoundErr, NewHolderCode);
            NewHolderType::Vendor:
                if not Vendor.Get(NewHolderCode) then
                    Error(VendorNotFoundErr, NewHolderCode);
            NewHolderType::Location:
                if not Location.Get(NewHolderCode) then
                    Error(LocationNotFoundErr, NewHolderCode);
        end;

        // Cannot transfer to same holder
        if (Asset."Current Holder Type" = NewHolderType) and
           (Asset."Current Holder Code" = NewHolderCode) then
            Error(AlreadyAtHolderErr);
    end;

    local procedure GetNextTransactionNo(): Integer
    var
        HolderEntry: Record "JML AP Holder Entry";
    begin
        if HolderEntry.FindLast() then
            exit(HolderEntry."Transaction No." + 1)
        else
            exit(1);
    end;

    local procedure CreateTransferOutEntry(
        var Asset: Record "JML AP Asset";
        TransactionNo: Integer;
        DocumentType: Enum "JML AP Document Type";
        DocumentNo: Code[20];
        ReasonCode: Code[10])
    var
        HolderEntry: Record "JML AP Holder Entry";
    begin
        HolderEntry.Init();
        HolderEntry."Entry No." := GetNextEntryNo();
        HolderEntry."Asset No." := Asset."No.";
        HolderEntry."Posting Date" := Today;
        HolderEntry."Entry Type" := HolderEntry."Entry Type"::"Transfer Out";
        HolderEntry."Holder Type" := Asset."Current Holder Type";
        HolderEntry."Holder Code" := Asset."Current Holder Code";
        HolderEntry."Holder Name" := Asset."Current Holder Name";
        HolderEntry."Transaction No." := TransactionNo;
        HolderEntry."Document Type" := DocumentType;
        HolderEntry."Document No." := DocumentNo;
        HolderEntry."Reason Code" := ReasonCode;
        HolderEntry.Insert(true);
    end;

    local procedure CreateTransferInEntry(
        var Asset: Record "JML AP Asset";
        NewHolderType: Enum "JML AP Holder Type";
        NewHolderCode: Code[20];
        TransactionNo: Integer;
        DocumentType: Enum "JML AP Document Type";
        DocumentNo: Code[20];
        ReasonCode: Code[10])
    var
        HolderEntry: Record "JML AP Holder Entry";
        HolderName: Text[100];
    begin
        HolderName := GetHolderName(NewHolderType, NewHolderCode);

        HolderEntry.Init();
        HolderEntry."Entry No." := GetNextEntryNo();
        HolderEntry."Asset No." := Asset."No.";
        HolderEntry."Posting Date" := Today;
        HolderEntry."Entry Type" := HolderEntry."Entry Type"::"Transfer In";
        HolderEntry."Holder Type" := NewHolderType;
        HolderEntry."Holder Code" := NewHolderCode;
        HolderEntry."Holder Name" := HolderName;
        HolderEntry."Transaction No." := TransactionNo;
        HolderEntry."Document Type" := DocumentType;
        HolderEntry."Document No." := DocumentNo;
        HolderEntry."Reason Code" := ReasonCode;
        HolderEntry.Insert(true);
    end;

    local procedure UpdateAssetHolder(
        var Asset: Record "JML AP Asset";
        NewHolderType: Enum "JML AP Holder Type";
        NewHolderCode: Code[20])
    begin
        Asset.Validate("Current Holder Type", NewHolderType);
        Asset.Validate("Current Holder Code", NewHolderCode);
        Asset.Validate("Current Holder Since", Today);
        Asset.Modify(true);
    end;

    local procedure GetNextEntryNo(): Integer
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

    var
        HolderCodeRequiredErr: Label 'Holder code is required.';
        CustomerNotFoundErr: Label 'Customer %1 does not exist.', Comment = '%1 = Customer No.';
        VendorNotFoundErr: Label 'Vendor %1 does not exist.', Comment = '%1 = Vendor No.';
        LocationNotFoundErr: Label 'Location %1 does not exist.', Comment = '%1 = Location Code';
        AlreadyAtHolderErr: Label 'Asset is already at this holder.';
}
