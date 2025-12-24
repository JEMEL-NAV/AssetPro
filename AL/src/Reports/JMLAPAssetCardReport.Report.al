report 70182306 "JML AP Asset Card Report"
{
    DefaultLayout = RDLC;
    RDLCLayout = './src/Layouts/JMLAPAssetCardReport.rdlc';
    Caption = 'Asset Card Report';
    UsageCategory = None;
    ApplicationArea = All;

    dataset
    {
        dataitem("JML AP Asset"; "JML AP Asset")
        {
            RequestFilterFields = "No.";

            // === SECTION 1: ASSET DETAILS ===
            column(AssetNo; "No.")
            {
            }
            column(Description; Description)
            {
            }
            column(Description2; "Description 2")
            {
            }
            column(Status; Format(Status))
            {
            }
            column(IndustryCode; "Industry Code")
            {
            }
            column(ClassificationPath; ClassificationPath)
            {
            }
            column(ParentAssetNo; "Parent Asset No.")
            {
            }
            column(HierarchyLevel; "Hierarchy Level")
            {
            }
            column(SerialNo; "Serial No.")
            {
            }
            column(AcquisitionDate; Format("Acquisition Date", 0, 4))
            {
            }
            column(LastDateModified; Format("Last Date Modified", 0, 4))
            {
            }
            column(AcquisitionCost; "Acquisition Cost")
            {
            }
            column(CurrentBookValue; "Current Book Value")
            {
            }

            // === SECTION 2: CURRENT HOLDER ===
            column(CurrentHolderType; Format("Current Holder Type"))
            {
            }
            column(CurrentHolderName; "Current Holder Name")
            {
            }
            column(CurrentHolderSince; Format("Current Holder Since", 0, 4))
            {
            }
            column(CurrentHolderAddr1; CurrentHolderAddr[1])
            {
            }
            column(CurrentHolderAddr2; CurrentHolderAddr[2])
            {
            }
            column(CurrentHolderAddr3; CurrentHolderAddr[3])
            {
            }
            column(CurrentHolderAddr4; CurrentHolderAddr[4])
            {
            }
            column(OwnerType; Format("Owner Type"))
            {
            }
            column(OwnerName; "Owner Name")
            {
            }
            column(OperatorType; Format("Operator Type"))
            {
            }
            column(OperatorName; "Operator Name")
            {
            }
            column(LesseeType; Format("Lessee Type"))
            {
            }
            column(LesseeName; "Lessee Name")
            {
            }
            column(DaysWithCurrentHolder; DaysWithCurrentHolder)
            {
            }
            column(CompanyName; CompanyInfo.Name)
            {
            }
            column(ReportTitle; ReportTitleLbl)
            {
            }

            // === SECTION 3: HOLDER HISTORY ===
            dataitem("JML AP Holder Entry"; "JML AP Holder Entry")
            {
                DataItemLink = "Asset No." = field("No.");
                DataItemTableView = sorting("Asset No.", "Posting Date") order(descending);

                column(HolderEntryNo; "Entry No.")
                {
                }
                column(HolderPostingDate; Format("Posting Date", 0, 4))
                {
                }
                column(HolderEntryType; Format("Entry Type"))
                {
                }
                column(HolderType; Format("Holder Type"))
                {
                }
                column(HolderName; "Holder Name")
                {
                }

                trigger OnPreDataItem()
                begin
                    if not IncludeHolderHistory then
                        SetRange("Entry No.", 0); // Will return empty
                end;
            }

            trigger OnAfterGetRecord()
            begin
                ClassificationPath := ReportMgt.BuildClassificationPath("Industry Code", "Classification Code");

                ReportMgt.FormatHolderAddress(
                    "Current Holder Type",
                    "Current Holder Code",
                    "Current Holder Name",
                    "Current Holder Addr Code",
                    CurrentHolderAddr);

                if "Current Holder Since" <> 0D then
                    DaysWithCurrentHolder := Today - "Current Holder Since"
                else
                    DaysWithCurrentHolder := 0;
            end;

            trigger OnPreDataItem()
            begin
                if Count > 1 then
                    Error(OnlyOneAssetErr);
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

                    field(IncludeHolderHistory; IncludeHolderHistory)
                    {
                        ApplicationArea = All;
                        Caption = 'Include Holder History';
                        ToolTip = 'Include complete holder history.';
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
        AssetDetailsCaption = 'Asset Details';
        AssetNoCaption = 'Asset No.';
        DescriptionCaption = 'Description';
        StatusCaption = 'Status';
        IndustryCaption = 'Industry';
        ClassificationCaption = 'Classification';
        ParentAssetCaption = 'Parent Asset';
        SerialNoCaption = 'Serial No.';
        AcquisitionDateCaption = 'Acquisition Date';
        ModifiedDateCaption = 'Last Modified';
        CurrentHolderCaption = 'Current Holder';
        HolderHistoryCaption = 'Holder History';
        PostingDateCaption = 'Posting Date';
        EntryTypeCaption = 'Entry Type';
        DaysWithHolderCaption = 'Days with Current Holder';
        OwnerCaption = 'Owner';
        OperatorCaption = 'Operator';
        LesseeCaption = 'Lessee';
    }

    var
        CompanyInfo: Record "Company Information";
        ReportMgt: Codeunit "JML AP Report Management";
        ClassificationPath: Text[250];
        CurrentHolderAddr: array[8] of Text[100];
        DaysWithCurrentHolder: Integer;
        IncludeHolderHistory: Boolean;
        ReportTitleLbl: Label 'Asset Card Report';
        OnlyOneAssetErr: Label 'You can only print one asset at a time. Please filter to a single asset.';

    trigger OnPreReport()
    begin
        CompanyInfo.Get();
    end;
}
