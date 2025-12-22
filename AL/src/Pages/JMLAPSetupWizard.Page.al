page 70182331 "JML AP Setup Wizard"
{
    Caption = 'Asset Pro AI Setup Wizard';
    Description = 'AI-powered guided setup wizard for configuring the asset management system with natural language industry generation.';
    PageType = NavigatePage;
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            // Step 1: Welcome & Business Description
            group(Step1_Welcome)
            {
                Visible = CurrentStep = 1;
                Caption = '';

                group(Step1_Header)
                {
                    Caption = 'Welcome to Asset Pro';
                    InstructionalText = 'This AI-powered wizard will help you set up your asset management system in minutes. Simply describe your business and let AI generate a complete industry configuration.';
                }

                group(Step1_Content)
                {
                    Caption = 'Tell us about your business';

                    field(BusinessDescription; BusinessDescription)
                    {
                        ApplicationArea = All;
                        Caption = 'Business Description';
                        ToolTip = 'Describe your business and the types of assets you manage. For example: "I manage a fleet of container ships and cargo vessels" or "We track IT equipment like laptops, servers, and network devices".';
                        MultiLine = true;
                        ShowMandatory = true;
                    }
                }

                group(Step1_Examples)
                {
                    Caption = 'Examples';
                    InstructionalText = 'Fleet: "I manage a fleet of commercial vessels including cargo ships, tankers, and tugboats"\\IT: "We manage computers, servers, network equipment, and mobile devices for our organization"\\Manufacturing: "We track production machines, conveyor systems, and quality testing equipment"';
                }
            }

            // Step 2: AI Generation
            group(Step2_Generation)
            {
                Visible = CurrentStep = 2;
                Caption = '';

                group(Step2_Header)
                {
                    Caption = 'Generating Your Configuration';
                    InstructionalText = 'AI is analyzing your business description and creating a customized industry configuration...';
                }

                group(Step2_Progress)
                {
                    Caption = '';

                    field(GenerationStatus; GenerationStatus)
                    {
                        ApplicationArea = All;
                        Caption = 'Status';
                        ToolTip = 'Shows the current status of the AI configuration generation process.';
                        Editable = false;
                        Style = Strong;
                    }
                }
            }

            // Step 3: Review Industry Structure
            group(Step3_Review)
            {
                Visible = CurrentStep = 3;
                Caption = '';

                group(Step3_Header)
                {
                    Caption = 'Review Generated Configuration';
                    InstructionalText = 'AI has generated the following industry structure. Review and click Next to accept, or Back to regenerate.';
                }

                group(Step3_Content)
                {
                    Caption = 'Industry Configuration';

                    field(IndustryCodeDisplay; IndustryCodeDisplay)
                    {
                        ApplicationArea = All;
                        Caption = 'Industry Code';
                        ToolTip = 'The unique code identifier for the generated industry configuration.';
                        Editable = false;
                    }

                    field(IndustryNameDisplay; IndustryNameDisplay)
                    {
                        ApplicationArea = All;
                        Caption = 'Industry Name';
                        ToolTip = 'The descriptive name for the generated industry configuration.';
                        Editable = false;
                    }

                    field(LevelCountDisplay; LevelCountDisplay)
                    {
                        ApplicationArea = All;
                        Caption = 'Classification Levels';
                        ToolTip = 'The number of hierarchical classification levels created for organizing assets (e.g., Type, Category, Subcategory).';
                        Editable = false;
                    }

                    field(ValueCountDisplay; ValueCountDisplay)
                    {
                        ApplicationArea = All;
                        Caption = 'Classification Values';
                        ToolTip = 'The total number of classification values created across all levels (e.g., specific vessel types, equipment categories).';
                        Editable = false;
                    }

                    field(AttributeCountDisplay; AttributeCountDisplay)
                    {
                        ApplicationArea = All;
                        Caption = 'Custom Attributes';
                        ToolTip = 'The number of custom attribute definitions created for tracking industry-specific asset properties.';
                        Editable = false;
                    }
                }

                group(Step3_JSON)
                {
                    Caption = 'Preview (JSON)';

                    field(ConfigJsonPreview; ConfigJsonPreview)
                    {
                        ApplicationArea = All;
                        Caption = 'Configuration';
                        ToolTip = 'A preview of the generated configuration in JSON format showing the structure of industries, classifications, and attributes.';
                        Editable = false;
                        MultiLine = true;
                    }
                }
            }

            // Step 4: Number Series Configuration
            group(Step4_NumberSeries)
            {
                Visible = CurrentStep = 4;
                Caption = '';

                group(Step4_Header)
                {
                    Caption = 'Number Series Configuration';
                    InstructionalText = 'Configure number series for transfer orders and journal batches. You can customize these values or skip if you prefer to configure manually later.';
                }

                field(CreateNumberSeries; CreateNumberSeries)
                {
                    ApplicationArea = All;
                    Caption = 'Create Number Series';
                    ToolTip = 'Specify whether to automatically create number series. If disabled, configure manually later in Asset Setup.';
                }

                group(AssetConfig)
                {
                    Caption = 'Assets';
                    Visible = CreateNumberSeries;

                    field(AssetSeriesCode; AssetSeriesCode)
                    {
                        ApplicationArea = All;
                        Caption = 'Series Code';
                        ToolTip = 'Code for asset number series (e.g., ASSET).';
                        ShowMandatory = CreateNumberSeries;
                    }

                    field(AssetStartingNo; AssetStartingNo)
                    {
                        ApplicationArea = All;
                        Caption = 'Starting No.';
                        ToolTip = 'First number to use (e.g., ASSET00001).';
                        ShowMandatory = CreateNumberSeries;
                    }
                }

                group(TransferOrderConfig)
                {
                    Caption = 'Asset Transfer Orders';
                    Visible = CreateNumberSeries;

                    field(TransferOrderSeriesCode; TransferOrderSeriesCode)
                    {
                        ApplicationArea = All;
                        Caption = 'Series Code';
                        ToolTip = 'Code for asset transfer order number series (e.g., APTR).';
                        ShowMandatory = CreateNumberSeries;
                    }

                    field(TransferOrderStartingNo; TransferOrderStartingNo)
                    {
                        ApplicationArea = All;
                        Caption = 'Starting No.';
                        ToolTip = 'First number to use (e.g., APTR00001).';
                        ShowMandatory = CreateNumberSeries;
                    }
                }

                group(PostedTransferConfig)
                {
                    Caption = 'Posted Asset Transfers';
                    Visible = CreateNumberSeries;

                    field(PostedTransferSeriesCode; PostedTransferSeriesCode)
                    {
                        ApplicationArea = All;
                        Caption = 'Series Code';
                        ToolTip = 'Code for posted asset transfer number series (e.g., PAPTR).';
                        ShowMandatory = CreateNumberSeries;
                    }

                    field(PostedTransferStartingNo; PostedTransferStartingNo)
                    {
                        ApplicationArea = All;
                        Caption = 'Starting No.';
                        ToolTip = 'First number to use (e.g., PAPTR00001).';
                        ShowMandatory = CreateNumberSeries;
                    }
                }

                field(CreateJournalBatches; CreateJournalBatches)
                {
                    ApplicationArea = All;
                    Caption = 'Create Default Journal Batches';
                    ToolTip = 'Create DEFAULT batches for Asset Journal and Component Journal.';
                }
            }

            // Step 5: Completion
            group(Step5_Complete)
            {
                Visible = CurrentStep = 5;
                Caption = '';

                group(Step5_Header)
                {
                    Caption = 'Setup Complete!';
                    InstructionalText = 'Your Asset Pro system has been configured successfully. You can now start creating assets.';
                }

                group(Step5_Summary)
                {
                    Caption = 'What was created';

                    field(CompletionSummary; CompletionSummary)
                    {
                        ApplicationArea = All;
                        Caption = 'Summary';
                        ToolTip = 'Summary of all items created during the setup wizard including industry, classification levels, values, and custom attributes.';
                        Editable = false;
                        MultiLine = true;
                        Style = Favorable;
                    }
                }

                group(Step5_NextSteps)
                {
                    Caption = 'Next Steps';
                    InstructionalText = '1. Go to Asset Industry to review classifications\\2. Go to Attribute Definitions to customize attributes\\3. Start creating your first assets';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionBack)
            {
                ApplicationArea = All;
                Caption = 'Back';
                ToolTip = 'Go to the previous step.';
                Image = PreviousRecord;
                InFooterBar = true;
                Enabled = BackEnabled;

                trigger OnAction()
                begin
                    GoBack();
                end;
            }

            action(ActionNext)
            {
                ApplicationArea = All;
                Caption = 'Next';
                ToolTip = 'Go to the next step.';
                Image = NextRecord;
                InFooterBar = true;
                Enabled = NextEnabled;

                trigger OnAction()
                begin
                    GoNext();
                end;
            }

            action(ActionFinish)
            {
                ApplicationArea = All;
                Caption = 'Finish';
                ToolTip = 'Complete the setup wizard.';
                Image = Approve;
                InFooterBar = true;
                Enabled = FinishEnabled;

                trigger OnAction()
                begin
                    FinishSetup();
                end;
            }

            action(ActionRegenerate)
            {
                ApplicationArea = All;
                Caption = 'Regenerate';
                ToolTip = 'Generate a new industry configuration with different AI suggestions.';
                Image = Refresh;
                InFooterBar = true;
                Visible = CurrentStep = 3;

                trigger OnAction()
                begin
                    CurrentStep := 2;
                    GenerateConfiguration();
                end;
            }

            action(ActionCancel)
            {
                ApplicationArea = All;
                Caption = 'Cancel';
                ToolTip = 'Cancel the setup wizard.';
                Image = Cancel;
                InFooterBar = true;

                trigger OnAction()
                begin
                    CurrPage.Close();
                end;
            }
        }
    }

    var
        SetupWizard: Codeunit "JML AP Setup Wizard";
        CurrentStep: Integer;
        BusinessDescription: Text;
        GenerationStatus: Text;
        ConfigJson: Text;
        ConfigJsonPreview: Text;
        IndustryCodeDisplay: Text;
        IndustryNameDisplay: Text;
        LevelCountDisplay: Text;
        ValueCountDisplay: Text;
        AttributeCountDisplay: Text;
        CompletionSummary: Text;
        BackEnabled: Boolean;
        NextEnabled: Boolean;
        FinishEnabled: Boolean;
        CreateNumberSeries: Boolean;
        AssetSeriesCode: Code[20];
        AssetStartingNo: Code[20];
        TransferOrderSeriesCode: Code[20];
        TransferOrderStartingNo: Code[20];
        PostedTransferSeriesCode: Code[20];
        PostedTransferStartingNo: Code[20];
        CreateJournalBatches: Boolean;
        CreatedIndustryCode: Code[20];
        BusinessDescriptionRequiredErr: Label 'Please enter a business description to continue.';
        GenerationFailedErr: Label 'Failed to generate configuration. Please try again with a different description.';

    trigger OnOpenPage()
    begin
        CurrentStep := 1;

        // Number series defaults
        CreateNumberSeries := true;
        AssetSeriesCode := 'ASSET';
        AssetStartingNo := 'ASSET00001';
        TransferOrderSeriesCode := 'APTR';
        TransferOrderStartingNo := 'APTR00001';
        PostedTransferSeriesCode := 'PAPTR';
        PostedTransferStartingNo := 'PAPTR00001';
        CreateJournalBatches := true;

        UpdateControls();
    end;

    local procedure GoBack()
    begin
        if CurrentStep > 1 then begin
            CurrentStep -= 1;
            UpdateControls();
            CurrPage.Update(false);
        end;
    end;

    local procedure GoNext()
    begin
        case CurrentStep of
            1:
                GenerateConfiguration();
            2:
                ReviewConfiguration();
            3:
                begin
                    // Move to number series configuration
                    CurrentStep := 4;
                    UpdateControls();
                    CurrPage.Update(false);
                end;
            4:
                // Validate and apply configuration
                if ValidateNumberSeriesConfig() then
                    ApplyConfiguration();

        end;
    end;

    local procedure GenerateConfiguration()
    begin
        // Validate input
        if BusinessDescription = '' then begin
            Message(BusinessDescriptionRequiredErr);
            exit;
        end;

        // Move to generation step
        CurrentStep := 2;
        GenerationStatus := 'Connecting to AI service...';
        UpdateControls();
        CurrPage.Update(false);

        // Generate configuration
        GenerationStatus := 'Generating industry structure...';
        CurrPage.Update(false);

        if SetupWizard.GenerateIndustryFromAI(BusinessDescription, ConfigJson) then begin
            GenerationStatus := 'Configuration generated successfully!';
            CurrentStep := 3;
            ParseConfigurationForDisplay();
        end else begin
            GenerationStatus := 'Generation failed. Please try again.';
            CurrentStep := 1;
        end;

        UpdateControls();
        CurrPage.Update(false);
    end;

    local procedure ReviewConfiguration()
    begin
        CurrentStep += 1;
        UpdateControls();
        CurrPage.Update(false);
    end;

    local procedure ApplyConfiguration()
    begin
        if SetupWizard.CreateIndustryFromJSON(ConfigJson, CreatedIndustryCode) then begin
            // Configure Asset Setup with the created industry
            SetupWizard.ConfigureAssetSetup(CreatedIndustryCode);

            // Create number series if requested
            if CreateNumberSeries then
                SetupWizard.CreateNumberSeriesWithConfig(
                    AssetSeriesCode,
                    AssetStartingNo,
                    'Assets',
                    TransferOrderSeriesCode,
                    TransferOrderStartingNo,
                    'Asset Transfer Orders',
                    PostedTransferSeriesCode,
                    PostedTransferStartingNo,
                    'Posted Asset Transfers');

            // Create journal batches if requested
            if CreateJournalBatches then
                SetupWizard.CreateDefaultJournalBatches();

            CurrentStep := 5;
            BuildCompletionSummary();
            UpdateControls();
            CurrPage.Update(false);
        end else
            Message(GenerationFailedErr);
    end;

    local procedure FinishSetup()
    begin
        CurrPage.Close();
    end;

    local procedure UpdateControls()
    begin
        BackEnabled := CurrentStep > 1;
        NextEnabled := (CurrentStep < 5) and (CurrentStep <> 2);
        FinishEnabled := CurrentStep = 5;
    end;

    local procedure ParseConfigurationForDisplay()
    var
        ConfigObject: JsonObject;
        CodeToken: JsonToken;
        NameToken: JsonToken;
        LevelsToken: JsonToken;
        ValuesToken: JsonToken;
        AttrsToken: JsonToken;
        LevelsArray: JsonArray;
        ValuesArray: JsonArray;
        AttrsArray: JsonArray;
    begin
        if not ConfigObject.ReadFrom(ConfigJson) then
            exit;

        // Extract display values
        if ConfigObject.Get('industryCode', CodeToken) then
            IndustryCodeDisplay := CodeToken.AsValue().AsText();
        if ConfigObject.Get('industryName', NameToken) then
            IndustryNameDisplay := NameToken.AsValue().AsText();

        if ConfigObject.Get('classificationLevels', LevelsToken) then begin
            LevelsArray := LevelsToken.AsArray();
            LevelCountDisplay := Format(LevelsArray.Count);
        end;

        if ConfigObject.Get('classificationValues', ValuesToken) then begin
            ValuesArray := ValuesToken.AsArray();
            ValueCountDisplay := Format(ValuesArray.Count);
        end;

        if ConfigObject.Get('attributes', AttrsToken) then begin
            AttrsArray := AttrsToken.AsArray();
            AttributeCountDisplay := Format(AttrsArray.Count);
        end;

        // Show preview (limited to first 500 chars)
        ConfigJsonPreview := CopyStr(ConfigJson, 1, 500);
        if StrLen(ConfigJson) > 500 then
            ConfigJsonPreview += '... (truncated)';
    end;

    local procedure ValidateNumberSeriesConfig(): Boolean
    begin
        if not CreateNumberSeries then
            exit(true);

        if AssetSeriesCode = '' then begin
            Message('Please enter an Asset Series Code.');
            exit(false);
        end;

        if AssetStartingNo = '' then begin
            Message('Please enter an Asset Starting No.');
            exit(false);
        end;

        if TransferOrderSeriesCode = '' then begin
            Message('Please enter a Transfer Order Series Code.');
            exit(false);
        end;

        if TransferOrderStartingNo = '' then begin
            Message('Please enter a Transfer Order Starting No.');
            exit(false);
        end;

        if PostedTransferSeriesCode = '' then begin
            Message('Please enter a Posted Transfer Series Code.');
            exit(false);
        end;

        if PostedTransferStartingNo = '' then begin
            Message('Please enter a Posted Transfer Starting No.');
            exit(false);
        end;

        if (AssetSeriesCode = TransferOrderSeriesCode) or
           (AssetSeriesCode = PostedTransferSeriesCode) or
           (TransferOrderSeriesCode = PostedTransferSeriesCode) then begin
            Message('All number series codes must be different.');
            exit(false);
        end;

        exit(true);
    end;

    local procedure BuildCompletionSummary()
    var
        NL: Text[2];
    begin
        NL := '\\';
        CompletionSummary := 'Successfully created:' + NL +
                            '- Industry: ' + IndustryNameDisplay + ' (' + IndustryCodeDisplay + ')' + NL +
                            '- ' + LevelCountDisplay + ' classification levels' + NL +
                            '- ' + ValueCountDisplay + ' classification values' + NL +
                            '- ' + AttributeCountDisplay + ' custom attributes';

        if CreateNumberSeries then
            CompletionSummary += NL + '- Number Series: ' + AssetSeriesCode + ', ' + TransferOrderSeriesCode + ', ' + PostedTransferSeriesCode;

        if CreateJournalBatches then
            CompletionSummary += NL + '- Default journal batches created';
    end;
}
