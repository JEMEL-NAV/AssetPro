report 70182301 "JML AP Asset Transfer Order"
{
    DefaultLayout = RDLC;
    RDLCLayout = './src/Layouts/JMLAPAssetTransferOrder.rdlc';
    WordMergeDataItem = "JML AP Asset Transfer Header";
    Caption = 'Asset Transfer Order';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;

    dataset
    {
        dataitem("JML AP Asset Transfer Header"; "JML AP Asset Transfer Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "From Holder Code", "To Holder Code", Status;
            RequestFilterHeading = 'Asset Transfer Order';

            column(No_TransferHeader; "No.")
            {
            }
            column(TransferOrderNoCaption; TransferOrderNoCaptionLbl)
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
                    column(DocumentDate_TransferHeader; Format("JML AP Asset Transfer Header"."Document Date", 0, 4))
                    {
                    }
                    column(PostingDate_TransferHeader; Format("JML AP Asset Transfer Header"."Posting Date", 0, 4))
                    {
                    }
                    column(Status_TransferHeader; Format("JML AP Asset Transfer Header".Status))
                    {
                    }
                    column(ExternalDocumentNo_TransferHeader; "JML AP Asset Transfer Header"."External Document No.")
                    {
                    }
                    column(ReasonCode_TransferHeader; "JML AP Asset Transfer Header"."Reason Code")
                    {
                    }
                    column(PageCaption; StrSubstNo(PageCaptionLbl, ''))
                    {
                    }
                    column(OutputNo; OutputNo)
                    {
                    }

                    dataitem("JML AP Asset Transfer Line"; "JML AP Asset Transfer Line")
                    {
                        DataItemLink = "Document No." = field("No.");
                        DataItemLinkReference = "JML AP Asset Transfer Header";
                        DataItemTableView = sorting("Document No.", "Line No.");

                        column(LineNo_TransferLine; "Line No.")
                        {
                        }
                        column(AssetNo_TransferLine; "Asset No.")
                        {
                            IncludeCaption = true;
                        }
                        column(AssetDescription_TransferLine; "Asset Description")
                        {
                            IncludeCaption = true;
                        }
                        column(Description_TransferLine; Description)
                        {
                            IncludeCaption = true;
                        }
                        column(CurrentHolderType_TransferLine; Format("Current Holder Type"))
                        {
                        }
                        column(CurrentHolderCode_TransferLine; "Current Holder Code")
                        {
                        }
                        column(CurrentHolderName_TransferLine; "Current Holder Name")
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
                FormatHolderAddress(
                    "From Holder Type",
                    "From Holder Code",
                    "From Holder Name",
                    "From Holder Addr Code",
                    FromHolderAddr);

                FormatHolderAddress(
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
        StatusCaption = 'Status';
        FromHolderCaption = 'From:';
        ToHolderCaption = 'To:';
        TotalAssetsCaption = 'Total Assets';
        ExternalDocumentNoCaption = 'External Document No.';
        ReasonCodeCaption = 'Reason Code';
        SignatureShippedCaption = 'Shipped by:';
        SignatureReceivedCaption = 'Received by:';
        SignatureDateCaption = 'Date:';
        ConditionCaption = 'Condition on Receipt:';
    }

    var
        FormatAddr: Codeunit "Format Address";
        FromHolderAddr: array[8] of Text[100];
        ToHolderAddr: array[8] of Text[100];
        NoOfCopies: Integer;
        NoOfLoops: Integer;
        OutputNo: Integer;
        TotalAssets: Integer;
        CopyText: Text[30];
        CopyLbl: Label 'COPY';
        CopyTextLbl: Label 'Asset Transfer Order %1', Comment = '%1 = Copy text (e.g., COPY)';
        PageCaptionLbl: Label 'Page %1', Comment = '%1 = Page number';
        TransferOrderNoCaptionLbl: Label 'Transfer Order No.';

    local procedure FormatHolderAddress(HolderType: Enum "JML AP Holder Type"; HolderCode: Code[20]; HolderName: Text[100]; AddrCode: Code[10]; var AddrArray: array[8] of Text[100])
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Location: Record Location;
        ShipToAddr: Record "Ship-to Address";
        OrderAddr: Record "Order Address";
        CompanyInfo: Record "Company Information";
    begin
        Clear(AddrArray);

        case HolderType of
            HolderType::Customer:
                begin
                    if Customer.Get(HolderCode) then begin
                        if AddrCode <> '' then begin
                            if ShipToAddr.Get(HolderCode, AddrCode) then
                                FormatAddr.FormatAddr(AddrArray, ShipToAddr.Name, ShipToAddr."Name 2", ShipToAddr.Contact,
                                    ShipToAddr.Address, ShipToAddr."Address 2", ShipToAddr.City, ShipToAddr."Post Code",
                                    ShipToAddr.County, ShipToAddr."Country/Region Code");
                        end else
                            FormatAddr.Customer(AddrArray, Customer);
                    end;
                end;
            HolderType::Vendor:
                begin
                    if Vendor.Get(HolderCode) then begin
                        if AddrCode <> '' then begin
                            if OrderAddr.Get(HolderCode, AddrCode) then
                                FormatAddr.FormatAddr(AddrArray, OrderAddr.Name, OrderAddr."Name 2", OrderAddr.Contact,
                                    OrderAddr.Address, OrderAddr."Address 2", OrderAddr.City, OrderAddr."Post Code",
                                    OrderAddr.County, OrderAddr."Country/Region Code");
                        end else
                            FormatAddr.Vendor(AddrArray, Vendor);
                    end;
                end;
            HolderType::Location:
                begin
                    if Location.Get(HolderCode) then
                        FormatAddr.Location(AddrArray, Location);
                end;
            HolderType::"Cost Center":
                begin
                    // Cost centers don't have physical addresses
                    AddrArray[1] := HolderName;
                    AddrArray[2] := StrSubstNo('%1: %2', Format(HolderType), HolderCode);
                    if CompanyInfo.Get() then begin
                        AddrArray[3] := CompanyInfo.Name;
                        AddrArray[4] := CompanyInfo.Address;
                        if CompanyInfo."Address 2" <> '' then
                            AddrArray[5] := CompanyInfo."Address 2";
                        AddrArray[6] := CompanyInfo.City + ' ' + CompanyInfo."Post Code";
                        if CompanyInfo."Country/Region Code" <> '' then
                            AddrArray[7] := CompanyInfo."Country/Region Code";
                    end;
                end;
        end;
    end;
}
