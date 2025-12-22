codeunit 70182381 "JML AP Setup Wizard"
{
    var
        AzureOpenAI: Codeunit "Azure OpenAI";
        AIHelper: Codeunit "JML AP AI Helper";
        SystemPromptTxt: Label 'You are an expert business asset management consultant. Based on the user''s business description, generate a complete asset management industry configuration. CRITICAL: Return ONLY raw JSON - no markdown, no code blocks, no ```json tags, no explanations. Start your response with { and end with }. Use this exact structure: {"industryCode":"XXXX","industryName":"Industry Name","classificationLevels":[{"levelNumber":1,"levelName":"Level 1 Name"},{"levelNumber":2,"levelName":"Level 2 Name"}],"classificationValues":[{"levelNumber":1,"code":"CODE1","description":"Description","parentCode":""},{"levelNumber":2,"code":"CODE2","description":"Description","parentCode":"CODE1"}],"attributes":[{"code":"ATTR1","description":"Attribute Name","dataType":"Text","mandatory":false,"textLength":50},{"code":"ATTR2","description":"Attribute Name","dataType":"Integer","mandatory":false}]}. Data types: Text, Integer, Decimal, Date, Boolean, Option. For Option type, include "optionString":"Value1,Value2,Value3". Generate 2-4 classification levels, 5-15 values with proper parent-child relationships, and 5-10 relevant attributes.';
        NoContextErr: Label 'Please provide a business description to generate the industry configuration.';
        GenerationFailedErr: Label 'Failed to generate industry configuration. Error: %1', Comment = '%1 = error message';
        InvalidJsonErr: Label 'The AI response was not in the expected format. Please try again.';
        SuccessMsg: Label 'Industry configuration created successfully! Created: %1 levels, %2 values, %3 attributes.', Comment = '%1 = level count, %2 = value count, %3 = attribute count';
        AzureOpenAIFailedDetailsTxt: Label 'Azure OpenAI call failed. Possible causes: 1) Invalid API key, 2) Deployment "assetpro-chat" not found, 3) Incorrect endpoint URL, 4) Token quota exceeded, 5) Model not deployed. Check Azure Portal for details.';
        EmptyResponseErr: Label 'AI returned empty response. Try again or check Azure OpenAI logs.';
        BusinessDescriptionTxt: Label 'Business Description: %1', Comment = '%1 = Business description';
        GenerateConfigInstructionTxt: Label 'Generate a complete asset management industry configuration with:';
        IndustryCodeInstructionTxt: Label '- Industry code (4-6 uppercase letters) and descriptive name';
        ClassificationLevelsInstructionTxt: Label '- 2-4 classification levels (hierarchy from general to specific)';
        ClassificationValuesInstructionTxt: Label '- 5-15 classification values with proper parent-child relationships';
        CustomAttributesInstructionTxt: Label '- 5-10 custom attributes relevant to this industry';
        ReturnJSONOnlyTxt: Label 'Return ONLY the JSON structure specified in the system prompt. No explanations.';

    /// <summary>
    /// Runs the guided setup wizard for Asset Pro.
    /// </summary>
    procedure RunSetupWizard()
    var
        AssetSetup: Record "JML AP Asset Setup";
    begin
        // Ensure setup record exists
        if not AssetSetup.Get() then begin
            AssetSetup.Init();
            AssetSetup.Insert();
        end;

        // Create default number series if not already configured
        if AssetSetup."Asset Nos." = '' then begin
            CreateNumberSeriesWithConfig(
                'ASSET', 'ASSET-00001', 'Asset Numbers',
                'TRANSFER', 'TRANS-00001', 'Transfer Order Numbers',
                'P-TRANSFER', 'PT-00001', 'Posted Transfer Numbers');
            AssetSetup.Get(); // Reload to get the updated number series values
        end;

        // Initialize default values
        AssetSetup."Enable Attributes" := true;
        AssetSetup.Modify();
    end;

    /// <summary>
    /// Generates an industry configuration using AI based on business description.
    /// </summary>
    /// <param name="BusinessDescription">Natural language description of the business and assets.</param>
    /// <param name="ConfigJson">Output parameter containing the generated JSON configuration.</param>
    /// <returns>True if generation successful, false otherwise.</returns>
    procedure GenerateIndustryFromAI(BusinessDescription: Text; var ConfigJson: Text): Boolean
    var
        ChatMessages: Codeunit "AOAI Chat Messages";
        ChatParams: Codeunit "AOAI Chat Completion Params";
        OperationResponse: Codeunit "AOAI Operation Response";
        SystemPrompt: SecretText;
        SystemPromptText: Text;
        UserPrompt: Text;
        ErrorMessage: Text;
    begin
        // Validate prerequisites
        if not ValidateCopilotSetup() then
            exit(false);

        // Build user prompt
        UserPrompt := BuildUserPrompt(BusinessDescription);
        if UserPrompt = '' then
            Error(NoContextErr);

        // Configure chat parameters
        ChatParams.SetTemperature(0.7);  // Balanced creativity
        ChatParams.SetMaxTokens(2000);   // Large response for complex JSON

        // Build conversation - convert Label to Text to SecretText
        SystemPromptText := SystemPromptTxt;
        SystemPrompt := SystemPromptText;
        ChatMessages.SetPrimarySystemMessage(SystemPrompt);
        ChatMessages.AddUserMessage(UserPrompt);

        // Call Azure OpenAI
        AzureOpenAI.GenerateChatCompletion(ChatMessages, ChatParams, OperationResponse);

        // Handle response with enhanced error details
        if not OperationResponse.IsSuccess() then begin
            ErrorMessage := OperationResponse.GetError();
            if ErrorMessage = '' then
                ErrorMessage := AzureOpenAIFailedDetailsTxt;
            Error(GenerationFailedErr, ErrorMessage);
        end;

        // Get the JSON response
        ConfigJson := OperationResponse.GetResult();
        if ConfigJson = '' then
            Error(EmptyResponseErr);

        // Clean markdown formatting if present (AI may wrap JSON in ```json blocks)
        ConfigJson := AIHelper.CleanJsonResponse(ConfigJson);

        exit(true);
    end;

    local procedure BuildUserPrompt(BusinessDescription: Text): Text
    var
        Prompt: Text;
        NL: Text;
    begin
        if BusinessDescription = '' then
            exit('');

        NL := AIHelper.NewLine();
        Prompt := StrSubstNo(BusinessDescriptionTxt, BusinessDescription) + NL + NL;
        Prompt += GenerateConfigInstructionTxt + NL;
        Prompt += IndustryCodeInstructionTxt + NL;
        Prompt += ClassificationLevelsInstructionTxt + NL;
        Prompt += ClassificationValuesInstructionTxt + NL;
        Prompt += CustomAttributesInstructionTxt + NL;
        Prompt += NL;
        Prompt += ReturnJSONOnlyTxt;

        exit(Prompt);
    end;

    local procedure ValidateCopilotSetup(): Boolean
    var
        CopilotCapability: Enum "Copilot Capability";
    begin
        CopilotCapability := CopilotCapability::"JML AP Asset Name Suggestion";

        // Configure JEMEL's Azure OpenAI credentials and capability
        // This uses JEMEL's subscription until Microsoft-managed AI becomes available (GA: Jan 2026)
        exit(AIHelper.ValidateCopilotSetup(AzureOpenAI, CopilotCapability));
    end;

    /// <summary>
    /// Creates industry configuration from AI-generated JSON.
    /// </summary>
    /// <param name="ConfigJson">JSON string containing the configuration.</param>
    /// <param name="IndustryCode">Output parameter for the created industry code.</param>
    /// <returns>True if creation successful, false otherwise.</returns>
    procedure CreateIndustryFromJSON(ConfigJson: Text; var IndustryCode: Code[20]): Boolean
    var
        ConfigObject: JsonObject;
        LevelCount: Integer;
        ValueCount: Integer;
        AttributeCount: Integer;
    begin
        // Parse JSON
        if not ConfigObject.ReadFrom(ConfigJson) then begin
            Message(InvalidJsonErr);
            exit(false);
        end;

        // Create records in order
        IndustryCode := CreateIndustryRecords(ConfigObject);
        LevelCount := CreateClassificationLevels(ConfigObject);
        ValueCount := CreateClassificationValues(ConfigObject);
        AttributeCount := CreateAttributeDefinitions(ConfigObject);

        // Show success message
        Message(SuccessMsg, LevelCount, ValueCount, AttributeCount);
        exit(true);
    end;

    local procedure CreateIndustryRecords(ConfigObject: JsonObject): Code[20]
    var
        Industry: Record "JML AP Asset Industry";
        IndustryCode: Text;
        IndustryName: Text;
        CodeToken: JsonToken;
        NameToken: JsonToken;
    begin
        // Extract industry code and name
        if ConfigObject.Get('industryCode', CodeToken) then
            IndustryCode := CodeToken.AsValue().AsText();
        if ConfigObject.Get('industryName', NameToken) then
            IndustryName := NameToken.AsValue().AsText();

        // Create or update industry record
        if not Industry.Get(CopyStr(IndustryCode, 1, 20)) then begin
            Industry.Init();
            Industry.Code := CopyStr(IndustryCode, 1, 20);
            Industry.Name := CopyStr(IndustryName, 1, 100);
            Industry.Insert(true);
        end;

        exit(CopyStr(IndustryCode, 1, 20));
    end;

    local procedure CreateClassificationLevels(ConfigObject: JsonObject): Integer
    var
        ClassLevel: Record "JML AP Classification Lvl";
        LevelsArray: JsonArray;
        LevelsToken: JsonToken;
        LevelToken: JsonToken;
        LevelObject: JsonObject;
        IndustryCode: Text;
        LevelNumber: Integer;
        LevelName: Text;
        CodeToken: JsonToken;
        NumToken: JsonToken;
        NameToken: JsonToken;
        i: Integer;
    begin
        // Get industry code
        if ConfigObject.Get('industryCode', CodeToken) then
            IndustryCode := CodeToken.AsValue().AsText();

        // Get levels array
        if not ConfigObject.Get('classificationLevels', LevelsToken) then
            exit(0);
        LevelsArray := LevelsToken.AsArray();

        // Create each level
        for i := 0 to LevelsArray.Count - 1 do begin
            LevelsArray.Get(i, LevelToken);
            LevelObject := LevelToken.AsObject();

            // Extract level data
            if LevelObject.Get('levelNumber', NumToken) then
                LevelNumber := NumToken.AsValue().AsInteger();
            if LevelObject.Get('levelName', NameToken) then
                LevelName := NameToken.AsValue().AsText();

            // Create level record
            if not ClassLevel.Get(CopyStr(IndustryCode, 1, 20), LevelNumber) then begin
                ClassLevel.Init();
                ClassLevel."Industry Code" := CopyStr(IndustryCode, 1, MaxStrLen(ClassLevel."Industry Code"));
                ClassLevel."Level Number" := LevelNumber;
                ClassLevel."Level Name" := CopyStr(LevelName, 1, MaxStrLen(ClassLevel."Level Name"));
                ClassLevel.Insert(true);
            end;
        end;

        exit(LevelsArray.Count);
    end;

    local procedure CreateClassificationValues(ConfigObject: JsonObject): Integer
    var
        ClassValue: Record "JML AP Classification Val";
        ValuesArray: JsonArray;
        ValuesToken: JsonToken;
        ValueToken: JsonToken;
        ValueObject: JsonObject;
        IndustryCode: Text;
        LevelNumber: Integer;
        ValueCode: Text;
        Description: Text;
        ParentCode: Text;
        CodeToken: JsonToken;
        LevelToken: JsonToken;
        ValueCodeToken: JsonToken;
        DescToken: JsonToken;
        ParentToken: JsonToken;
        i: Integer;
    begin
        // Get industry code
        if ConfigObject.Get('industryCode', CodeToken) then
            IndustryCode := CodeToken.AsValue().AsText();

        // Get values array
        if not ConfigObject.Get('classificationValues', ValuesToken) then
            exit(0);
        ValuesArray := ValuesToken.AsArray();

        // Create each value
        for i := 0 to ValuesArray.Count - 1 do begin
            ValuesArray.Get(i, ValueToken);
            ValueObject := ValueToken.AsObject();

            // Extract value data
            if ValueObject.Get('levelNumber', LevelToken) then
                LevelNumber := LevelToken.AsValue().AsInteger();
            if ValueObject.Get('code', ValueCodeToken) then
                ValueCode := ValueCodeToken.AsValue().AsText();
            if ValueObject.Get('description', DescToken) then
                Description := DescToken.AsValue().AsText();
            if ValueObject.Get('parentCode', ParentToken) then
                ParentCode := ParentToken.AsValue().AsText();

            // Create value record
            if not ClassValue.Get(CopyStr(IndustryCode, 1, 20), LevelNumber, CopyStr(ValueCode, 1, 20)) then begin
                ClassValue.Init();
                ClassValue."Industry Code" := CopyStr(IndustryCode, 1, 20);
                ClassValue."Level Number" := LevelNumber;
                ClassValue.Code := CopyStr(ValueCode, 1, 20);
                ClassValue.Description := CopyStr(Description, 1, 100);
                if ParentCode <> '' then
                    ClassValue."Parent Value Code" := CopyStr(ParentCode, 1, 20);
                ClassValue.Insert(true);
            end;
        end;

        exit(ValuesArray.Count);
    end;

    local procedure CreateAttributeDefinitions(ConfigObject: JsonObject): Integer
    var
        AttrDef: Record "JML AP Attribute Defn";
        AttrsArray: JsonArray;
        AttrsToken: JsonToken;
        AttrToken: JsonToken;
        AttrObject: JsonObject;
        IndustryCode: Text;
        AttrCode: Text;
        AttrName: Text;
        DataType: Text;
        Mandatory: Boolean;
        OptionString: Text;
        CodeToken: JsonToken;
        AttrCodeToken: JsonToken;
        DescToken: JsonToken;
        TypeToken: JsonToken;
        MandToken: JsonToken;
        OptionToken: JsonToken;
        i: Integer;
    begin
        // Get industry code
        if ConfigObject.Get('industryCode', CodeToken) then
            IndustryCode := CodeToken.AsValue().AsText();

        // Get attributes array
        if not ConfigObject.Get('attributes', AttrsToken) then
            exit(0);
        AttrsArray := AttrsToken.AsArray();

        // Create each attribute
        for i := 0 to AttrsArray.Count - 1 do begin
            AttrsArray.Get(i, AttrToken);
            AttrObject := AttrToken.AsObject();

            // Extract attribute data
            if AttrObject.Get('code', AttrCodeToken) then
                AttrCode := AttrCodeToken.AsValue().AsText();
            if AttrObject.Get('description', DescToken) then
                AttrName := DescToken.AsValue().AsText();
            if AttrObject.Get('dataType', TypeToken) then
                DataType := TypeToken.AsValue().AsText();
            if AttrObject.Get('mandatory', MandToken) then
                Mandatory := MandToken.AsValue().AsBoolean();
            if AttrObject.Get('optionString', OptionToken) then
                OptionString := OptionToken.AsValue().AsText();

            // Create attribute record
            if not AttrDef.Get(CopyStr(IndustryCode, 1, 20), 0, CopyStr(AttrCode, 1, 20)) then begin
                AttrDef.Init();
                AttrDef."Industry Code" := CopyStr(IndustryCode, 1, 20);
                AttrDef."Level Number" := 0;  // 0 = applies to all levels
                AttrDef."Attribute Code" := CopyStr(AttrCode, 1, 20);
                AttrDef."Attribute Name" := CopyStr(AttrName, 1, 50);
                AttrDef."Data Type" := ConvertDataType(DataType);
                AttrDef.Mandatory := Mandatory;

                // Set type-specific properties
                if (AttrDef."Data Type" = AttrDef."Data Type"::Option) and (OptionString <> '') then
                    AttrDef."Option String" := CopyStr(OptionString, 1, 250);

                AttrDef.Insert(true);
            end;
        end;

        exit(AttrsArray.Count);
    end;

    local procedure ConvertDataType(DataTypeText: Text): Enum "JML AP Attribute Type"
    var
        AttrDataType: Enum "JML AP Attribute Type";
    begin
        case DataTypeText of
            'Text':
                exit(AttrDataType::Text);
            'Integer':
                exit(AttrDataType::Integer);
            'Decimal':
                exit(AttrDataType::Decimal);
            'Date':
                exit(AttrDataType::Date);
            'Boolean':
                exit(AttrDataType::Boolean);
            'Option':
                exit(AttrDataType::Option);
            else
                exit(AttrDataType::Text);  // Default to Text
        end;
    end;

    /// <summary>
    /// Configures Asset Setup with the created industry and best practice defaults.
    /// </summary>
    /// <param name="IndustryCode">The industry code to set as default.</param>
    procedure ConfigureAssetSetup(IndustryCode: Code[20])
    var
        AssetSetup: Record "JML AP Asset Setup";
    begin
        if not AssetSetup.Get() then begin
            AssetSetup.Init();
            AssetSetup.Insert();
        end;

        // Set default industry to the one just created
        AssetSetup."Default Industry Code" := IndustryCode;

        // Block manual holder changes (force using journal/transfer orders)
        AssetSetup."Block Manual Holder Change" := true;

        // Enable attributes
        AssetSetup."Enable Attributes" := true;

        AssetSetup.Modify();
    end;

    /// <summary>
    /// Creates number series for assets and transfer orders and updates Asset Setup.
    /// </summary>
    procedure CreateNumberSeriesWithConfig(
        AssetSeriesCode: Code[20];
        AssetStartingNo: Code[20];
        AssetDescription: Text[100];
        TransferSeriesCode: Code[20];
        TransferStartingNo: Code[20];
        TransferDescription: Text[100];
        PostedSeriesCode: Code[20];
        PostedStartingNo: Code[20];
        PostedDescription: Text[100])
    var
        AssetSetup: Record "JML AP Asset Setup";
    begin
        // Create Asset number series
        CreateNumberSeries(AssetSeriesCode, AssetStartingNo, AssetDescription);

        // Create Transfer Order number series
        CreateNumberSeries(TransferSeriesCode, TransferStartingNo, TransferDescription);

        // Create Posted Transfer number series
        CreateNumberSeries(PostedSeriesCode, PostedStartingNo, PostedDescription);

        // Update Asset Setup with created series
        if AssetSetup.Get() then begin
            AssetSetup."Asset Nos." := AssetSeriesCode;
            AssetSetup."Transfer Order Nos." := TransferSeriesCode;
            AssetSetup."Posted Transfer Nos." := PostedSeriesCode;
            AssetSetup.Modify();
        end;
    end;

    local procedure CreateNumberSeries(SeriesCode: Code[20]; StartingNo: Code[20]; Description: Text[100])
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        EndingNo: Code[20];
    begin
        // Check if already exists - ensure it allows manual numbers for test independence
        if NoSeries.Get(SeriesCode) then begin
            if not NoSeries."Manual Nos." then begin
                NoSeries."Manual Nos." := true;
                NoSeries.Modify();
            end;
            exit;
        end;

        // Create No. Series header
        NoSeries.Init();
        NoSeries.Code := SeriesCode;
        NoSeries.Description := Description;
        NoSeries."Default Nos." := true;
        NoSeries."Manual Nos." := true; // Allow manual numbers for testing
        NoSeries.Insert();

        // Calculate ending number by respecting the Starting No. format
        // E.g., ASSET00001 → ASSET99999, AT00001 → AT99999, A-2024-0001 → A-2024-9999
        EndingNo := CalculateEndingNumber(StartingNo);

        // Create No. Series Line
        NoSeriesLine.Init();
        NoSeriesLine."Series Code" := SeriesCode;
        NoSeriesLine."Line No." := 10000;
        NoSeriesLine."Starting No." := StartingNo;
        NoSeriesLine."Ending No." := EndingNo;
        NoSeriesLine."Increment-by No." := 1;
        NoSeriesLine.Insert();
    end;

    local procedure CalculateEndingNumber(StartingNo: Code[20]): Code[20]
    var
        EndingNo: Text;
        i: Integer;
        DigitCount: Integer;
        LastDigitPos: Integer;
        Char: Char;
        Nines: Text;
    begin
        EndingNo := StartingNo;
        DigitCount := 0;
        LastDigitPos := 0;

        // Find the last sequence of digits in the Starting No.
        // Scan from right to left to find where digits end
        for i := StrLen(StartingNo) downto 1 do begin
            Char := StartingNo[i];
            if (Char >= '0') and (Char <= '9') then begin
                if LastDigitPos = 0 then
                    LastDigitPos := i;
                DigitCount += 1;
            end else begin
                // Found a non-digit after finding digits - we're done
                if LastDigitPos > 0 then
                    break;
            end;
        end;

        // If we found digits, replace them with 9's
        if (DigitCount > 0) and (LastDigitPos > 0) then begin
            // Build a string of 9's with the same length
            Nines := PadStr('', DigitCount, '9');

            // Replace the digit sequence with 9's
            EndingNo := CopyStr(StartingNo, 1, LastDigitPos - DigitCount) + Nines;
        end else begin
            // No digits found - fallback to adding 99999
            EndingNo := StartingNo + '99999';
        end;

        exit(CopyStr(EndingNo, 1, 20));
    end;

    /// <summary>
    /// Creates default journal batches for Asset Journal and Component Journal.
    /// </summary>
    procedure CreateDefaultJournalBatches()
    var
        AssetJnlBatch: Record "JML AP Asset Journal Batch";
        ComponentJnlBatch: Record "JML AP Component Jnl. Batch";
    begin
        // Create Asset Journal Batch "DEFAULT"
        if not AssetJnlBatch.Get('DEFAULT') then begin
            AssetJnlBatch.Init();
            AssetJnlBatch.Name := 'DEFAULT';
            AssetJnlBatch.Description := 'Default Asset Journal';
            AssetJnlBatch.Insert();
        end;

        // Create Component Journal Batch "DEFAULT"
        if not ComponentJnlBatch.Get('DEFAULT') then begin
            ComponentJnlBatch.Init();
            ComponentJnlBatch.Name := 'DEFAULT';
            ComponentJnlBatch.Description := 'Default Component Journal';
            ComponentJnlBatch.Insert();
        end;
    end;

    /// <summary>
    /// Creates a sample industry for demonstration.
    /// </summary>
    procedure CreateSampleIndustry()
    var
        Industry: Record "JML AP Asset Industry";
        ClassLevel: Record "JML AP Classification Lvl";
        ClassValue: Record "JML AP Classification Val";
    begin
        // Create Fleet Management industry
        if not Industry.Get('FLEET') then begin
            Industry.Code := 'FLEET';
            Industry.Name := 'Fleet Management';
            Industry.Insert();

            // Create Level 1
            ClassLevel."Industry Code" := 'FLEET';
            ClassLevel."Level Number" := 1;
            ClassLevel."Level Name" := 'Fleet Type';
            ClassLevel.Insert();

            // Create Level 2
            ClassLevel."Level Number" := 2;
            ClassLevel."Level Name" := 'Vessel Type';
            ClassLevel.Insert();

            // Create sample values
            ClassValue."Industry Code" := 'FLEET';
            ClassValue."Level Number" := 1;
            ClassValue.Code := 'COMM';
            ClassValue.Description := 'Commercial';
            ClassValue.Insert();

            ClassValue."Level Number" := 2;
            ClassValue.Code := 'CARGO';
            ClassValue.Description := 'Cargo Ship';
            ClassValue."Parent Value Code" := 'COMM';
            ClassValue.Insert();
        end;
    end;
}
