codeunit 70182391 "JML AP Asset Transfer-Post"
{
    TableNo = "JML AP Asset Transfer Header";

    trigger OnRun()
    begin
        TransferHeader.Copy(Rec);
        Code();
        Rec := TransferHeader;
    end;

    var
        TransferHeader: Record "JML AP Asset Transfer Header";
        AssetJnlPost: Codeunit "JML AP Asset Jnl.-Post";
        Window: Dialog;
        NotReleasedErr: Label 'Transfer Order %1 must be released before posting.', Comment = '%1 = Document No.';
        NoLinesErr: Label 'There are no lines to post in Transfer Order %1.', Comment = '%1 = Document No.';
        PostingMsg: Label 'Posting Transfer Order #1########## @2@@@@@@@@@@@@@';
        PostedMsg: Label 'Transfer Order %1 has been posted as %2.', Comment = '%1 = Transfer Order No., %2 = Posted Document No.';
        SameHolderAddressErr: Label 'From Holder and To Holder cannot be identical (same type, code, and address). Specify a different address for same-holder transfers.';
        ConfirmPostQst: Label 'Do you want to post Transfer Order %1?', Comment = '%1 = Transfer Order No.';

    local procedure Code()
    var
        PostedTransferNo: Code[20];
    begin
        CheckTransferOrder(TransferHeader);

        // Confirm posting
        if not Confirm(ConfirmPostQst, true, TransferHeader."No.") then
            exit;

        Window.Open(PostingMsg);
        Window.Update(1, TransferHeader."No.");

        PostedTransferNo := PostTransferOrder(TransferHeader);

        Window.Close();
        Message(PostedMsg, TransferHeader."No.", PostedTransferNo);
    end;

    local procedure CheckTransferOrder(var TransferHdr: Record "JML AP Asset Transfer Header")
    var
        TransferLine: Record "JML AP Asset Transfer Line";
    begin
        TransferHdr.TestField("No.");
        TransferHdr.TestField("From Holder Type");
        TransferHdr.TestField("From Holder Code");
        TransferHdr.TestField("To Holder Type");
        TransferHdr.TestField("To Holder Code");
        TransferHdr.TestField("Posting Date");

        if TransferHdr.Status <> TransferHdr.Status::Released then
            Error(NotReleasedErr, TransferHdr."No.");

        // Allow same holder if address changes
        if (TransferHdr."From Holder Type" = TransferHdr."To Holder Type") and
           (TransferHdr."From Holder Code" = TransferHdr."To Holder Code") and
           (TransferHdr."From Holder Addr Code" = TransferHdr."To Holder Addr Code")
        then
            Error(SameHolderAddressErr);

        // Must have lines
        TransferLine.SetRange("Document No.", TransferHdr."No.");
        if TransferLine.IsEmpty then
            Error(NoLinesErr, TransferHdr."No.");
    end;

    local procedure PostTransferOrder(var TransferHdr: Record "JML AP Asset Transfer Header"): Code[20]
    var
        AssetJnlBatch: Record "JML AP Asset Journal Batch";
        AssetJnlLine: Record "JML AP Asset Journal Line";
        TransferLine: Record "JML AP Asset Transfer Line";
        NoSeries: Codeunit "No. Series";
        PostingNo: Code[20];
        LineNo: Integer;
    begin
        // Get posting number
        if TransferHdr."Posting No." = '' then begin
            TransferHdr.TestField("Posting No. Series");
            PostingNo := NoSeries.GetNextNo(TransferHdr."Posting No. Series");
            TransferHdr."Posting No." := PostingNo;
            TransferHdr.Modify();
        end else
            PostingNo := TransferHdr."Posting No.";

        // Get or create system journal batch
        GetSystemJournalBatch(AssetJnlBatch);

        // Clear any existing lines in system batch
        AssetJnlLine.SetRange("Journal Batch Name", AssetJnlBatch.Name);
        AssetJnlLine.DeleteAll(true);

        // Create journal lines from transfer lines
        TransferLine.SetRange("Document No.", TransferHdr."No.");
        LineNo := 10000;
        if TransferLine.FindSet() then begin
            repeat
                CreateJournalLineFromTransferLine(
                    AssetJnlBatch,
                    TransferLine,
                    TransferHdr,
                    PostingNo,
                    LineNo);
                LineNo += 10000;
                Window.Update(2, Round(TransferLine."Line No." / LineNo * 10000, 1));
            until TransferLine.Next() = 0;
        end;

        // Post journal (creates holder entries)
        // Suppress journal success message and confirmation - Transfer Order has its own
        AssetJnlPost.SetSuppressSuccessMessage(true);
        AssetJnlPost.SetSuppressConfirmation(true);
        AssetJnlLine.SetRange("Journal Batch Name", AssetJnlBatch.Name);
        if AssetJnlLine.FindFirst() then
            AssetJnlPost.Run(AssetJnlLine);

        // Create posted document
        CreatePostedHeader(TransferHdr, PostingNo);
        CreatePostedLines(TransferHdr."No.", PostingNo);

        // Delete source document
        TransferLine.SetRange("Document No.", TransferHdr."No.");
        TransferLine.DeleteAll(true);
        TransferHdr.Delete(true);

        Commit();
        exit(PostingNo);
    end;

    local procedure GetSystemJournalBatch(var AssetJnlBatch: Record "JML AP Asset Journal Batch")
    begin
        // Use system batch for posting (like BC uses "POSTING" in Gen. Journal)
        if not AssetJnlBatch.Get('POSTING') then begin
            AssetJnlBatch.Init();
            AssetJnlBatch.Name := 'POSTING';
            AssetJnlBatch.Description := 'System batch for document posting';
            AssetJnlBatch.Insert();
        end;
    end;

    local procedure CreateJournalLineFromTransferLine(
        var AssetJnlBatch: Record "JML AP Asset Journal Batch";
        var TransferLine: Record "JML AP Asset Transfer Line";
        var TransferHdr: Record "JML AP Asset Transfer Header";
        PostingNo: Code[20];
        LineNo: Integer)
    var
        AssetJnlLine: Record "JML AP Asset Journal Line";
        Asset: Record "JML AP Asset";
    begin
        AssetJnlLine.Init();
        AssetJnlLine."Journal Batch Name" := AssetJnlBatch.Name;
        AssetJnlLine."Line No." := LineNo;
        AssetJnlLine."Posting Date" := TransferHdr."Posting Date";
        AssetJnlLine."Document No." := PostingNo;
        AssetJnlLine."External Document No." := TransferHdr."External Document No.";
        AssetJnlLine."Asset No." := TransferLine."Asset No.";

        // Get asset info for validation
        if Asset.Get(TransferLine."Asset No.") then begin
            AssetJnlLine."Asset Description" := Asset.Description;
            AssetJnlLine."Current Holder Type" := Asset."Current Holder Type";
            AssetJnlLine."Current Holder Code" := Asset."Current Holder Code";
        end;

        AssetJnlLine."New Holder Type" := TransferHdr."To Holder Type";
        AssetJnlLine."New Holder Code" := TransferHdr."To Holder Code";
        AssetJnlLine."New Holder Addr Code" := TransferHdr."To Holder Addr Code";
        AssetJnlLine."Reason Code" := TransferLine.Description <> '' ? TransferLine.Description : TransferHdr."Reason Code";
        AssetJnlLine.Description := TransferLine.Description;

        AssetJnlLine.Insert(true);
    end;

    local procedure CreatePostedHeader(var TransferHdr: Record "JML AP Asset Transfer Header"; PostingNo: Code[20])
    var
        PostedTransfer: Record "JML AP Posted Asset Transfer";
    begin
        PostedTransfer.Init();
        PostedTransfer."No." := PostingNo;
        PostedTransfer."Transfer Order No." := TransferHdr."No.";
        PostedTransfer."From Holder Type" := TransferHdr."From Holder Type";
        PostedTransfer."From Holder Code" := TransferHdr."From Holder Code";
        PostedTransfer."From Holder Name" := TransferHdr."From Holder Name";
        PostedTransfer."From Holder Addr Code" := TransferHdr."From Holder Addr Code";
        PostedTransfer."To Holder Type" := TransferHdr."To Holder Type";
        PostedTransfer."To Holder Code" := TransferHdr."To Holder Code";
        PostedTransfer."To Holder Name" := TransferHdr."To Holder Name";
        PostedTransfer."To Holder Addr Code" := TransferHdr."To Holder Addr Code";
        PostedTransfer."Posting Date" := TransferHdr."Posting Date";
        PostedTransfer."Document Date" := TransferHdr."Document Date";
        PostedTransfer."No. Series" := TransferHdr."Posting No. Series";
        PostedTransfer."Reason Code" := TransferHdr."Reason Code";
        PostedTransfer."External Document No." := TransferHdr."External Document No.";
        PostedTransfer."User ID" := UserId;
        PostedTransfer.Insert(true);
    end;

    local procedure CreatePostedLines(SourceDocNo: Code[20]; PostingNo: Code[20])
    var
        TransferLine: Record "JML AP Asset Transfer Line";
        PostedLine: Record "JML AP Pstd. Asset Trans. Line";
        HolderEntry: Record "JML AP Holder Entry";
        Asset: Record "JML AP Asset";
        LineNo: Integer;
    begin
        TransferLine.SetRange("Document No.", SourceDocNo);
        LineNo := 10000;
        if TransferLine.FindSet() then begin
            repeat
                PostedLine.Init();
                PostedLine."Document No." := PostingNo;
                PostedLine."Line No." := LineNo;
                PostedLine."Asset No." := TransferLine."Asset No.";
                PostedLine."Asset Description" := TransferLine."Asset Description";
                PostedLine."From Holder Type" := TransferLine."Current Holder Type";
                PostedLine."From Holder Code" := TransferLine."Current Holder Code";
                PostedLine."From Holder Name" := TransferLine."Current Holder Name";
                PostedLine."From Holder Addr Code" := TransferLine."Current Holder Addr Code";
                PostedLine.Description := TransferLine.Description;

                // Get Transaction No. from holder entry
                HolderEntry.SetCurrentKey("Asset No.", "Posting Date");
                HolderEntry.SetRange("Asset No.", TransferLine."Asset No.");
                HolderEntry.SetRange("Document No.", PostingNo);
                if HolderEntry.FindFirst() then
                    PostedLine."Transaction No." := HolderEntry."Transaction No.";

                PostedLine.Insert(true);
                LineNo += 10000;
            until TransferLine.Next() = 0;
        end;
    end;
}
