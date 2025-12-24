codeunit 70182390 "JML AP Asset Jnl.-Post"
{
    TableNo = "JML AP Asset Journal Line";

    trigger OnRun()
    begin
        AssetJnlLine.Copy(Rec);
        Code();
        Rec := AssetJnlLine;
    end;

    var
        AssetJnlLine: Record "JML AP Asset Journal Line";
        Window: Dialog;
        LineCount: Integer;
        NoOfRecords: Integer;
        SuppressSuccessMessage: Boolean;
        SuppressConfirmation: Boolean;
        PostingMsg: Label 'Posting journal lines #1########## @2@@@@@@@@@@@@@', Comment = '#1 = Line No., @2 = Percentage Complete';
        JournalPostedMsg: Label 'Journal lines have been posted successfully.';
        ConfirmPostQst: Label 'Do you want to post %1 journal line(s)?', Comment = '%1 = Number of lines';
        HolderChangeSuccessMsg: Label 'Holder changed successfully for Asset %1 to %2.', Comment = '%1 = Asset No., %2 = New Holder Code';

    local procedure Code()
    var
        AssetJnlBatch: Record "JML AP Asset Journal Batch";
        JnlPostLine: Codeunit "JML AP Asset Jnl.-Post Line";
        JMLAPGeneral: Codeunit "JML AP General";
    begin
        // License check
        if GuiAllowed then begin
            if not JMLAPGeneral.IsAllowedToUse(false) then
                error('');
        end else
            if not JMLAPGeneral.IsAllowedToUse(true) then
                error('');

        if AssetJnlLine."Journal Batch Name" = '' then
            exit;

        AssetJnlBatch.Get(AssetJnlLine."Journal Batch Name");

        AssetJnlLine.SetRange("Journal Batch Name", AssetJnlLine."Journal Batch Name");
        if not AssetJnlLine.FindSet() then
            exit;

        NoOfRecords := AssetJnlLine.Count;

        // Confirm posting unless suppressed
        if not SuppressConfirmation then
            if not Confirm(ConfirmPostQst, true, NoOfRecords) then
                exit;

        LineCount := 0;

        Window.Open(PostingMsg);

        repeat
            LineCount += 1;
            Window.Update(1, AssetJnlLine."Line No.");
            Window.Update(2, Round(LineCount / NoOfRecords * 10000, 1));

            JnlPostLine.PostJournalLine(AssetJnlLine);
        until AssetJnlLine.Next() = 0;

        Window.Close();

        // Delete posted lines
        AssetJnlLine.DeleteAll(true);

        if not SuppressSuccessMessage then
            Message(JournalPostedMsg);
    end;

    /// <summary>
    /// Suppresses the success message when posting journal lines.
    /// Used when posting from documents that have their own success message.
    /// </summary>
    internal procedure SetSuppressSuccessMessage(Suppress: Boolean)
    begin
        SuppressSuccessMessage := Suppress;
    end;

    /// <summary>
    /// Suppresses the confirmation dialog when posting journal lines.
    /// Used for automated posting scenarios (API, document posting, manual holder changes, testing).
    /// </summary>
    procedure SetSuppressConfirmation(Suppress: Boolean)
    begin
        SuppressConfirmation := Suppress;
    end;

    /// <summary>
    /// API for manual holder changes from Asset Card.
    /// Creates a temporary journal line and posts it through standard validation.
    /// </summary>
    internal procedure CreateAndPostManualChange(
        var Asset: Record "JML AP Asset";
        OldHolderType: Enum "JML AP Holder Type";
        OldHolderCode: Code[20];
        OldHolderAddrCode: Code[10];
        NewHolderType: Enum "JML AP Holder Type";
        NewHolderCode: Code[20];
        NewHolderAddrCode: Code[10])
    var
        TempJnlLine: Record "JML AP Asset Journal Line" temporary;
        JnlPostLine: Codeunit "JML AP Asset Jnl.-Post Line";
        AssetSetup: Record "JML AP Asset Setup";
        JMLAPGeneral: Codeunit "JML AP General";
        DocumentNo: Code[20];
        ManualHolderChangeBlockedErr: Label 'Manual holder changes are blocked in setup. Use Asset Journal or Transfer Orders to change holders.';
    begin
        // License check
        if GuiAllowed then begin
            if not JMLAPGeneral.IsAllowedToUse(false) then
                error('');
        end else
            if not JMLAPGeneral.IsAllowedToUse(true) then
                error('');

        // Validate manual holder changes are not blocked
        AssetSetup.GetRecordOnce();
        if AssetSetup."Block Manual Holder Change" then
            Error(ManualHolderChangeBlockedErr);

        // Generate document number with timestamp
        DocumentNo := 'MAN-' + Format(CurrentDateTime, 0, '<Year4><Month,2><Day,2><Hours24,2><Minutes,2><Seconds,2>');

        // Create temporary journal line
        TempJnlLine."Line No." := 10000;
        TempJnlLine."Asset No." := Asset."No.";
        TempJnlLine."Asset Description" := Asset.Description;
        TempJnlLine."Current Holder Type" := OldHolderType;  // OLD holder
        TempJnlLine."Current Holder Code" := OldHolderCode;  // OLD holder
        TempJnlLine."New Holder Type" := NewHolderType;
        TempJnlLine."New Holder Code" := NewHolderCode;
        TempJnlLine."New Holder Addr Code" := NewHolderAddrCode;
        TempJnlLine."Posting Date" := WorkDate();
        TempJnlLine."Document No." := DocumentNo;
        TempJnlLine.Description := 'Manual holder change';
        TempJnlLine.Insert();

        // Post through standard journal posting (includes all validation)
        JnlPostLine.PostJournalLine(TempJnlLine);

        // Refresh asset record after posting
        Asset.Get(Asset."No.");

        if GuiAllowed and not SuppressSuccessMessage then
            Message(HolderChangeSuccessMsg, Asset."No.", NewHolderCode);
    end;

    /// <summary>
    /// Validates posting date for an asset journal entry.
    /// Ensures posting date is not before the last entry date for the asset or its children.
    /// </summary>
    procedure ValidatePostingDate(AssetNo: Code[20]; PostingDate: Date)
    var
        JnlPostLine: Codeunit "JML AP Asset Jnl.-Post Line";
    begin
        JnlPostLine.ValidatePostingDate(AssetNo, PostingDate);
    end;
}
