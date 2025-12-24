report 70182304 "JML AP Assets by Holder"
{
    DefaultLayout = RDLC;
    RDLCLayout = './src/Layouts/JMLAPAssetsByHolder.rdlc';
    Caption = 'Assets by Holder';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;

    dataset
    {
        dataitem(HolderGroup; "Integer")
        {
            DataItemTableView = sorting(Number);

            column(HolderType; Format(CurrentHolderType))
            {
            }
            column(HolderName; CurrentHolderName)
            {
            }
            column(HolderContactInfo; HolderContactInfo)
            {
            }
            column(AssetCountForHolder; AssetCountForHolder)
            {
            }
            column(DateRangeText; DateRangeText)
            {
            }
            column(ShowContactInfo; IncludeContactInfo)
            {
            }
            column(CompanyName; CompanyInfo.Name)
            {
            }
            column(ReportTitle; ReportTitleLbl)
            {
            }

            dataitem("JML AP Asset"; "JML AP Asset")
            {
                DataItemTableView = sorting("Current Holder Type", "Current Holder Code");
                RequestFilterFields = "Current Holder Type", "Current Holder Code",
                                      Status, "Industry Code", "Current Holder Since";

                column(AssetNo_Asset; "No.")
                {
                    IncludeCaption = true;
                }
                column(Description_Asset; Description)
                {
                    IncludeCaption = true;
                }
                column(ClassificationPath; ClassificationPath)
                {
                }
                column(Status_Asset; Format(Status))
                {
                }
                column(DateAcquiredByHolder; Format("Current Holder Since", 0, 4))
                {
                }
                column(DaysWithHolder; DaysWithHolder)
                {
                }
                column(SerialNo_Asset; "Serial No.")
                {
                    IncludeCaption = true;
                }
                column(ShowDaysWithHolder; ShowDaysWithHolder)
                {
                }

                trigger OnPreDataItem()
                begin
                    SetRange("Current Holder Type", CurrentHolderType);
                    SetRange("Current Holder Code", CurrentHolderCode);
                end;

                trigger OnAfterGetRecord()
                begin
                    ClassificationPath := ReportMgt.BuildClassificationPath("Industry Code", "Classification Code");
                    CalculateDaysWithHolder();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if not GetNextHolder() then
                    CurrReport.Break();

                LoadHolderInfo();
                CountAssetsForHolder();
            end;

            trigger OnPreDataItem()
            begin
                InitializeHolderList();
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

                    field(IncludeContactInfo; IncludeContactInfo)
                    {
                        ApplicationArea = All;
                        Caption = 'Include Contact Information';
                        ToolTip = 'Include phone and email for Customer/Vendor holders.';
                    }

                    field(ShowDaysWithHolder; ShowDaysWithHolder)
                    {
                        ApplicationArea = All;
                        Caption = 'Show Days with Holder';
                        ToolTip = 'Calculate and display how many days each asset has been with the holder.';
                    }

                    field(MinimumAssetCount; MinimumAssetCount)
                    {
                        ApplicationArea = All;
                        Caption = 'Minimum Asset Count';
                        ToolTip = 'Only show holders with at least this many assets.';
                        MinValue = 0;
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
        HolderTypeCaption = 'Holder Type';
        HolderNameCaption = 'Holder Name';
        ContactInfoCaption = 'Contact Information';
        AssetCountCaption = 'Asset Count';
        ClassificationCaption = 'Classification';
        StatusCaption = 'Status';
        DateAcquiredCaption = 'Date Acquired';
        DaysWithHolderCaption = 'Days with Holder';
        TotalAssetsCaption = 'Total Assets';
        TotalHoldersCaption = 'Total Holders';
        PageCaption = 'Page';
    }

    var
        CompanyInfo: Record "Company Information";
        TempHolderBuffer: Record "Name/Value Buffer" temporary;
        ReportMgt: Codeunit "JML AP Report Management";
        CurrentHolderType: Enum "JML AP Holder Type";
        CurrentHolderCode: Code[20];
        CurrentHolderName: Text[100];
        HolderContactInfo: Text[250];
        ClassificationPath: Text[250];
        DateRangeText: Text[100];
        AssetCountForHolder: Integer;
        DaysWithHolder: Integer;
        HolderIterator: Integer;
        TotalHolders: Integer;
        TotalAssets: Integer;
        MinimumAssetCount: Integer;
        IncludeContactInfo: Boolean;
        ShowDaysWithHolder: Boolean;
        ReportTitleLbl: Label 'Assets by Holder Report';

    trigger OnPreReport()
    begin
        CompanyInfo.Get();
        DateRangeText := GetDateRangeText();
    end;

    local procedure InitializeHolderList()
    var
        Asset: Record "JML AP Asset";
        TempHolder: Record "Name/Value Buffer" temporary;
        HolderKey: Text[50];
    begin
        // Build distinct list of holders from filtered assets
        Asset.CopyFilters("JML AP Asset");
        if Asset.FindSet() then
            repeat
                if (Asset."Current Holder Type" <> Asset."Current Holder Type"::" ") and
                   (Asset."Current Holder Code" <> '')
                then begin
                    HolderKey := Format(Asset."Current Holder Type") + '|' + Asset."Current Holder Code";
                    if not TempHolder.Get(HolderKey) then begin
                        TempHolder.Init();
                        TempHolder.ID := TempHolder.Count + 1;
                        TempHolder.Name := HolderKey;
                        TempHolder.Value := Asset."Current Holder Name";
                        TempHolder.Insert();
                    end;
                end;
            until Asset.Next() = 0;

        TempHolderBuffer.Copy(TempHolder, true);
        HolderIterator := 0;
        TotalHolders := TempHolderBuffer.Count();
    end;

    local procedure GetNextHolder(): Boolean
    var
        HolderParts: List of [Text];
    begin
        HolderIterator += 1;
        if not TempHolderBuffer.Get(HolderIterator) then
            exit(false);

        HolderParts := TempHolderBuffer.Name.Split('|');
        Evaluate(CurrentHolderType, HolderParts.Get(1));
        CurrentHolderCode := CopyStr(HolderParts.Get(2), 1, 20);
        CurrentHolderName := TempHolderBuffer.Value;

        exit(true);
    end;

    local procedure LoadHolderInfo()
    begin
        HolderContactInfo := '';

        if IncludeContactInfo then
            HolderContactInfo := ReportMgt.GetHolderContactInfo(CurrentHolderType, CurrentHolderCode);
    end;

    local procedure CountAssetsForHolder()
    var
        Asset: Record "JML AP Asset";
    begin
        Asset.CopyFilters("JML AP Asset");
        Asset.SetRange("Current Holder Type", CurrentHolderType);
        Asset.SetRange("Current Holder Code", CurrentHolderCode);
        AssetCountForHolder := Asset.Count();

        if AssetCountForHolder < MinimumAssetCount then
            CurrReport.Skip();

        TotalAssets += AssetCountForHolder;
    end;

    local procedure CalculateDaysWithHolder()
    begin
        if "JML AP Asset"."Current Holder Since" <> 0D then
            DaysWithHolder := Today - "JML AP Asset"."Current Holder Since"
        else
            DaysWithHolder := 0;
    end;

    local procedure GetDateRangeText(): Text[100]
    var
        FromDate: Date;
        ToDate: Date;
        FilterText: Text;
    begin
        FilterText := "JML AP Asset".GetFilter("Current Holder Since");
        if FilterText = '' then
            exit('All Dates');

        // Simple date range extraction
        exit('Date Filter: ' + FilterText);
    end;
}
