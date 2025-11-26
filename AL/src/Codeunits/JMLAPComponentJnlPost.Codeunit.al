codeunit 70182396 "JML AP Component Jnl.-Post"
{
    TableNo = "JML AP Component Journal Line";

    trigger OnRun()
    begin
        ComponentJnlLine.Copy(Rec);
        Code();
        Rec := ComponentJnlLine;
    end;

    var
        ComponentJnlLine: Record "JML AP Component Journal Line";
        Window: Dialog;
        LineCount: Integer;
        NoOfRecords: Integer;
        SuppressSuccessMessage: Boolean;
        SuppressConfirmation: Boolean;
        PostingMsg: Label 'Posting component lines #1########## @2@@@@@@@@@@@@@';
        JournalPostedMsg: Label 'Component journal lines have been posted successfully.';
        ConfirmPostQst: Label 'Do you want to post %1 component journal line(s)?', Comment = '%1 = Number of lines';
        AssetDoesNotExistErr: Label 'Asset %1 does not exist.', Comment = '%1 = Asset No.';
        ItemDoesNotExistErr: Label 'Item %1 does not exist.', Comment = '%1 = Item No.';
        MissingFieldErr: Label '%1 must be specified in line %2.', Comment = '%1 = Field Name, %2 = Line No.';
        InvalidQuantitySignErr: Label 'Quantity must be %1 for Entry Type %2 in line %3.', Comment = '%1 = positive/negative, %2 = Entry Type, %3 = Line No.';

    local procedure Code()
    var
        AssetJnlBatch: Record "JML AP Asset Journal Batch";
    begin
        if ComponentJnlLine."Journal Batch" = '' then
            exit;

        AssetJnlBatch.Get(ComponentJnlLine."Journal Batch");

        ComponentJnlLine.SetRange("Journal Batch", ComponentJnlLine."Journal Batch");
        if not ComponentJnlLine.FindSet() then
            exit;

        NoOfRecords := ComponentJnlLine.Count;

        // Confirm posting unless suppressed
        if not SuppressConfirmation then
            if not Confirm(ConfirmPostQst, true, NoOfRecords) then
                exit;

        LineCount := 0;

        Window.Open(PostingMsg);

        repeat
            LineCount += 1;
            Window.Update(1, ComponentJnlLine."Line No.");
            Window.Update(2, Round(LineCount / NoOfRecords * 10000, 1));

            PostJournalLine(ComponentJnlLine);
        until ComponentJnlLine.Next() = 0;

        Window.Close();

        // Delete posted lines
        ComponentJnlLine.DeleteAll(true);

        if not SuppressSuccessMessage then
            Message(JournalPostedMsg);
    end;

    local procedure PostJournalLine(var JnlLine: Record "JML AP Component Journal Line")
    var
        TransactionNo: Integer;
    begin
        // Validate journal line
        CheckJournalLine(JnlLine);

        // Get next transaction number
        TransactionNo := GetNextTransactionNo();

        // Create component entry
        CreateComponentEntry(JnlLine, TransactionNo);
    end;

    local procedure CheckJournalLine(var JnlLine: Record "JML AP Component Journal Line")
    var
        Asset: Record "JML AP Asset";
        Item: Record Item;
        EntryTypeEnum: Enum "JML AP Component Entry Type";
    begin
        // Validate Asset No.
        if JnlLine."Asset No." = '' then
            Error(MissingFieldErr, JnlLine.FieldCaption("Asset No."), JnlLine."Line No.");

        if not Asset.Get(JnlLine."Asset No.") then
            Error(AssetDoesNotExistErr, JnlLine."Asset No.");

        // Validate Item No.
        if JnlLine."Item No." = '' then
            Error(MissingFieldErr, JnlLine.FieldCaption("Item No."), JnlLine."Line No.");

        if not Item.Get(JnlLine."Item No.") then
            Error(ItemDoesNotExistErr, JnlLine."Item No.");

        // Validate Entry Type
        if JnlLine."Entry Type" = EntryTypeEnum::" " then
            Error(MissingFieldErr, JnlLine.FieldCaption("Entry Type"), JnlLine."Line No.");

        // Validate Posting Date
        if JnlLine."Posting Date" = 0D then
            Error(MissingFieldErr, JnlLine.FieldCaption("Posting Date"), JnlLine."Line No.");

        // Validate Quantity
        if JnlLine.Quantity = 0 then
            Error(MissingFieldErr, JnlLine.FieldCaption(Quantity), JnlLine."Line No.");

        // Validate Quantity Sign based on Entry Type
        case JnlLine."Entry Type" of
            EntryTypeEnum::Install,
            EntryTypeEnum::Adjustment:
                if JnlLine.Quantity < 0 then
                    Error(InvalidQuantitySignErr, 'positive', JnlLine."Entry Type", JnlLine."Line No.");
            EntryTypeEnum::Remove:
                if JnlLine.Quantity > 0 then
                    Error(InvalidQuantitySignErr, 'negative', JnlLine."Entry Type", JnlLine."Line No.");
        end;
    end;

    local procedure CreateComponentEntry(JnlLine: Record "JML AP Component Journal Line"; TransactionNo: Integer)
    var
        ComponentEntry: Record "JML AP Component Entry";
    begin
        ComponentEntry.Init();
        ComponentEntry."Entry No." := GetNextEntryNo();
        ComponentEntry."Asset No." := JnlLine."Asset No.";
        ComponentEntry."Item No." := JnlLine."Item No.";
        ComponentEntry."Variant Code" := JnlLine."Variant Code";
        ComponentEntry."Entry Type" := JnlLine."Entry Type";
        ComponentEntry.Quantity := JnlLine.Quantity;
        ComponentEntry."Unit of Measure Code" := JnlLine."Unit of Measure Code";
        ComponentEntry.Position := JnlLine.Position;
        ComponentEntry."Serial No." := JnlLine."Serial No.";
        ComponentEntry."Lot No." := JnlLine."Lot No.";
        ComponentEntry."Posting Date" := JnlLine."Posting Date";
        ComponentEntry."Reason Code" := JnlLine."Reason Code";
        ComponentEntry."Document No." := JnlLine."Document No.";
        ComponentEntry."External Document No." := JnlLine."External Document No.";
        ComponentEntry."Transaction No." := TransactionNo;
        ComponentEntry.Insert(true);
    end;

    local procedure GetNextEntryNo(): Integer
    var
        ComponentEntry: Record "JML AP Component Entry";
    begin
        ComponentEntry.LockTable();
        if ComponentEntry.FindLast() then
            exit(ComponentEntry."Entry No." + 1);
        exit(1);
    end;

    local procedure GetNextTransactionNo(): Integer
    var
        ComponentEntry: Record "JML AP Component Entry";
    begin
        ComponentEntry.LockTable();
        if ComponentEntry.FindLast() then
            exit(ComponentEntry."Transaction No." + 1);
        exit(1);
    end;

    procedure SetSuppressSuccessMessage(NewSuppressSuccessMessage: Boolean)
    begin
        SuppressSuccessMessage := NewSuppressSuccessMessage;
    end;

    procedure SetSuppressConfirmation(NewSuppressConfirmation: Boolean)
    begin
        SuppressConfirmation := NewSuppressConfirmation;
    end;
}
