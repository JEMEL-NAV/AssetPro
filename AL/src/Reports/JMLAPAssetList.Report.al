report 70182302 "JML AP Asset List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './src/Layouts/JMLAPAssetList.rdlc';
    Caption = 'Asset List';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;

    dataset
    {
        dataitem("JML AP Asset"; "JML AP Asset")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "Industry Code", "Classification Code", Status,
                                  "Current Holder Type", "Current Holder Code",
                                  "Last Date Modified";
            PrintOnlyIfDetail = false;

            column(No_Asset; "No.")
            {
                IncludeCaption = true;
            }
            column(Description_Asset; Description)
            {
                IncludeCaption = true;
            }
            column(IndustryCode_Asset; "Industry Code")
            {
                IncludeCaption = true;
            }
            column(ClassificationPath; ClassificationPath)
            {
            }
            column(Status_Asset; Format(Status))
            {
            }
            column(ParentAssetNo_Asset; "Parent Asset No.")
            {
                IncludeCaption = true;
            }
            column(CurrentHolderType_Asset; Format("Current Holder Type"))
            {
            }
            column(CurrentHolderName_Asset; "Current Holder Name")
            {
                IncludeCaption = true;
            }
            column(SerialNo_Asset; "Serial No.")
            {
                IncludeCaption = true;
            }
            column(LastDateModified_Asset; Format("Last Date Modified", 0, 4))
            {
            }
            column(GroupByField; GroupByFieldValue)
            {
            }
            column(AssetCount; 1)
            {
            }
            column(ShowGroupHeaders; GroupByOption <> GroupByOption::None)
            {
            }
            column(CompanyName; CompanyInfo.Name)
            {
            }
            column(ReportTitle; ReportTitleLbl)
            {
            }
            column(FiltersApplied; GetFiltersApplied())
            {
            }
            column(GroupByOptionText; Format(GroupByOption))
            {
            }

            trigger OnAfterGetRecord()
            begin
                if ShowClassificationPath then
                    ClassificationPath := ReportMgt.BuildClassificationPath("Industry Code", "Classification Code")
                else
                    ClassificationPath := "Classification Code";

                BuildGroupByFieldValue();
            end;

            trigger OnPreDataItem()
            begin
                if not IncludeBlocked then
                    SetRange(Blocked, false);
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

                    field(GroupBy; GroupByOption)
                    {
                        ApplicationArea = All;
                        Caption = 'Group By';
                        ToolTip = 'Specifies how to group the assets.';
                        OptionCaption = 'None,Industry,Classification,Status,Current Holder';
                    }

                    field(ShowClassificationPath; ShowClassificationPath)
                    {
                        ApplicationArea = All;
                        Caption = 'Show Full Classification Path';
                        ToolTip = 'Show the complete classification hierarchy (Level 1 / Level 2 / Level 3).';
                    }

                    field(IncludeBlocked; IncludeBlocked)
                    {
                        ApplicationArea = All;
                        Caption = 'Include Blocked Assets';
                        ToolTip = 'Include assets marked as blocked.';
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
        AssetNoCaption = 'Asset No.';
        DescriptionCaption = 'Description';
        IndustryCaption = 'Industry';
        ClassificationCaption = 'Classification';
        StatusCaption = 'Status';
        ParentAssetCaption = 'Parent Asset';
        CurrentHolderCaption = 'Current Holder';
        SerialNoCaption = 'Serial No.';
        ModifiedDateCaption = 'Modified Date';
        TotalAssetsCaption = 'Total Assets';
        GroupedByCaption = 'Grouped By';
        FiltersCaption = 'Filters';
        PageCaption = 'Page';
    }

    var
        CompanyInfo: Record "Company Information";
        ReportMgt: Codeunit "JML AP Report Management";
        ClassificationPath: Text[250];
        GroupByFieldValue: Text[250];
        GroupByOption: Option "None",Industry,Classification,Status,"Current Holder";
        ShowClassificationPath: Boolean;
        IncludeBlocked: Boolean;
        ReportTitleLbl: Label 'Asset List Report';

    trigger OnPreReport()
    begin
        CompanyInfo.Get();
    end;

    local procedure BuildGroupByFieldValue()
    begin
        case GroupByOption of
            GroupByOption::None:
                GroupByFieldValue := '';
            GroupByOption::Industry:
                GroupByFieldValue := "JML AP Asset"."Industry Code";
            GroupByOption::Classification:
                GroupByFieldValue := ClassificationPath;
            GroupByOption::Status:
                GroupByFieldValue := Format("JML AP Asset".Status);
            GroupByOption::"Current Holder":
                GroupByFieldValue := StrSubstNo('%1: %2',
                    Format("JML AP Asset"."Current Holder Type"),
                    "JML AP Asset"."Current Holder Name");
        end;
    end;

    local procedure GetFiltersApplied(): Text[500]
    var
        FilterText: Text[500];
    begin
        FilterText := "JML AP Asset".GetFilters();
        if FilterText = '' then
            exit('No filters applied');
        exit(FilterText);
    end;
}
