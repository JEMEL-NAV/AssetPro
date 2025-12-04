page 70182331 "JML AP Setup Wizard"
{
    Caption = 'Asset Setup Wizard';
    Description = 'Guided setup wizard for configuring the asset management system and initial data.';
    PageType = NavigatePage;
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(Welcome)
            {
                Caption = 'Welcome to Asset Pro Setup';

                group(Instructions)
                {
                    Caption = '';

                    label(WelcomeText)
                    {
                        ApplicationArea = All;
                        Caption = 'This wizard will help you configure Asset Pro for your organization.';
                    }
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RunSetup)
            {
                ApplicationArea = All;
                Caption = 'Run Setup';
                ToolTip = 'Run the setup wizard to configure Asset Pro.';
                Image = Setup;
                InFooterBar = true;

                trigger OnAction()
                var
                    SetupWizard: Codeunit "JML AP Setup Wizard";
                begin
                    SetupWizard.RunSetupWizard();
                    CurrPage.Close();
                end;
            }
        }
    }
}
