page 70182372 "JML AP Asset Mgmt. Headline"
{
    Caption = 'Headline';
    PageType = HeadlinePart;
    RefreshOnActivate = true;

    layout
    {
        area(content)
        {
            group(Control1)
            {
                ShowCaption = false;
                Visible = UserGreetingVisible;

                field(GreetingText; RCHeadlinesPageCommon.GetGreetingText())
                {
                    ApplicationArea = All;
                    Caption = 'Greeting headline';
                    Editable = false;
                    ToolTip = 'Specifies a greeting for the current user.';
                }
            }
            group(Control2)
            {
                ShowCaption = false;
                Visible = DefaultFieldsVisible;

                field(DocumentationText; DocumentationTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Documentation headline';
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies a link to documentation.';

                    trigger OnDrillDown()
                    begin
                        HyperLink(DocumentationUrlTxt);
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        RCHeadlinesPageCommon.HeadlineOnOpenPage(Page::"JML AP Asset Mgmt. Headline");
        DefaultFieldsVisible := RCHeadlinesPageCommon.AreDefaultFieldsVisible();
        UserGreetingVisible := RCHeadlinesPageCommon.IsUserGreetingVisible();
    end;

    var
        RCHeadlinesPageCommon: Codeunit "RC Headlines Page Common";
        DocumentationTxt: Label 'Want to learn more about Asset Pro?';
        DocumentationUrlTxt: Label 'https://jemel.lv/docs/asset-pro';
        DefaultFieldsVisible: Boolean;
        UserGreetingVisible: Boolean;
}
