report 70182305 "JML AP Posted Asset Transfer"
{
    DefaultLayout = RDLC;
    RDLCLayout = './src/Layouts/JMLAPPostedAssetTransfer.rdlc';
    Caption = 'Posted Asset Transfer';
    UsageCategory = None;
    ApplicationArea = All;

    dataset
    {
        dataitem("JML AP Posted Asset Transfer"; "JML AP Posted Asset Transfer")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Transfer Order No.", "Posting Date";
            RequestFilterHeading = 'Posted Asset Transfer';

            column(No_PostedTransfer; "No.")
            {
            }
            column(TransferOrderNo_PostedTransfer; "Transfer Order No.")
            {
            }
            column(PostedTransferNoCaption; PostedTransferNoCaptionLbl)
            {
            }

            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = sorting(Number);

                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));

                    column(CopyCaption; StrSubstNo(CopyTextLbl, CopyText))
                    {
                    }
                    column(FromHolderAddr1; FromHolderAddr[1])
                    {
                    }
                    column(FromHolderAddr2; FromHolderAddr[2])
                    {
                    }
                    column(FromHolderAddr3; FromHolderAddr[3])
                    {
                    }
                    column(FromHolderAddr4; FromHolderAddr[4])
                    {
                    }
                    column(FromHolderAddr5; FromHolderAddr[5])
                    {
                    }
                    column(FromHolderAddr6; FromHolderAddr[6])
                    {
                    }
                    column(FromHolderAddr7; FromHolderAddr[7])
                    {
                    }
                    column(FromHolderAddr8; FromHolderAddr[8])
                    {
                    }
                    column(ToHolderAddr1; ToHolderAddr[1])
                    {
                    }
                    column(ToHolderAddr2; ToHolderAddr[2])
                    {
                    }
                    column(ToHolderAddr3; ToHolderAddr[3])
                    {
                    }
                    column(ToHolderAddr4; ToHolderAddr[4])
                    {
                    }
                    column(ToHolderAddr5; ToHolderAddr[5])
                    {
                    }
                    column(ToHolderAddr6; ToHolderAddr[6])
                    {
                    }
                    column(ToHolderAddr7; ToHolderAddr[7])
                    {
                    }
                    column(ToHolderAddr8; ToHolderAddr[8])
                    {
                    }
                    column(DocumentDate_PostedTransfer; Format("JML AP Posted Asset Transfer"."Document Date", 0, 4))
                    {
                    }
                    column(PostingDate_PostedTransfer; Format("JML AP Posted Asset Transfer"."Posting Date", 0, 4))
                    {
                    }
                    column(ExternalDocumentNo_PostedTransfer; "JML AP Posted Asset Transfer"."External Document No.")
                    {
                    }
                    column(ReasonCode_PostedTransfer; "JML AP Posted Asset Transfer"."Reason Code")
                    {
                    }
                    column(UserID_PostedTransfer; "JML AP Posted Asset Transfer"."User ID")
                    {
                    }
                    column(StatusCaption; PostedStatusLbl)
                    {
                    }
                    column(PageCaption; StrSubstNo(PageCaptionLbl, ''))
                    {
                    }
                    column(OutputNo; OutputNo)
                    {
                    }

                    dataitem("JML AP Pstd. Asset Trans. Line"; "JML AP Pstd. Asset Trans. Line")
                    {
                        DataItemLink = "Document No." = field("No.");
                        DataItemLinkReference = "JML AP Posted Asset Transfer";
                        DataItemTableView = sorting("Document No.", "Line No.");

                        column(LineNo_PostedLine; "Line No.")
                        {
                        }
                        column(AssetNo_PostedLine; "Asset No.")
                        {
                            IncludeCaption = true;
                        }
                        column(AssetDescription_PostedLine; "Asset Description")
                        {
                            IncludeCaption = true;
                        }
                        column(FromHolderType_PostedLine; Format("From Holder Type"))
                        {
                        }
                        column(FromHolderCode_PostedLine; "From Holder Code")
                        {
                        }
                        column(FromHolderName_PostedLine; "From Holder Name")
                        {
                        }

                        trigger OnPreDataItem()
                        begin
                            TotalAssets := Count;
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        // No additional processing needed for PageLoop
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if Number > 1 then begin
                        CopyText := CopyLbl;
                        OutputNo += 1;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    NoOfLoops := Abs(NoOfCopies) + 1;
                    CopyText := '';
                    SetRange(Number, 1, NoOfLoops);
                    OutputNo := 1;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                ReportMgt.FormatHolderAddress(
                    "From Holder Type",
                    "From Holder Code",
                    "From Holder Name",
                    "From Holder Addr Code",
                    FromHolderAddr);

                ReportMgt.FormatHolderAddress(
                    "To Holder Type",
                    "To Holder Code",
                    "To Holder Name",
                    "To Holder Addr Code",
                    ToHolderAddr);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';

                    field(NoOfCopies; NoOfCopies)
                    {
                        ApplicationArea = All;
                        Caption = 'No. of Copies';
                        ToolTip = 'Specifies how many copies of the document to print.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
        DocumentDateCaption = 'Document Date';
        PostingDateCaption = 'Posting Date';
        PostedByCaption = 'Posted By';
        TransferOrderNoCaption = 'Original Transfer Order';
        FromHolderCaption = 'From:';
        ToHolderCaption = 'To:';
        TotalAssetsCaption = 'Total Assets Transferred';
        ExternalDocumentNoCaption = 'External Document No.';
        ReasonCodeCaption = 'Reason Code';
        SignatureReceivedCaption = 'Received by:';
        SignatureDateCaption = 'Date:';
        ConditionCaption = 'Condition on Receipt:';
    }

    var
        ReportMgt: Codeunit "JML AP Report Management";
        FromHolderAddr: array[8] of Text[100];
        ToHolderAddr: array[8] of Text[100];
        NoOfCopies: Integer;
        NoOfLoops: Integer;
        OutputNo: Integer;
        TotalAssets: Integer;
        CopyText: Text[30];
        CopyLbl: Label 'COPY';
        CopyTextLbl: Label 'Posted Asset Transfer %1', Comment = '%1 = Copy text (e.g., COPY)';
        PageCaptionLbl: Label 'Page %1', Comment = '%1 = Page number';
        PostedTransferNoCaptionLbl: Label 'Posted Transfer No.';
        PostedStatusLbl: Label 'POSTED - Cannot be modified';
}
