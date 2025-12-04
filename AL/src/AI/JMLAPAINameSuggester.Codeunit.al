codeunit 70182401 "JML AP AI Name Suggester"
{
    var
        AzureOpenAI: Codeunit "Azure OpenAI";
        SystemPromptTxt: Label 'You are an expert business asset naming assistant. Generate 5 professional, concise asset names based on the provided description. Names should be: (1) 2-4 words maximum, (2) descriptive and meaningful, (3) suitable for business inventory management, (4) unique and professional. Return ONLY a JSON array of strings with exactly 5 names. Format: ["Name1", "Name2", "Name3", "Name4", "Name5"]';
        NoContextErr: Label 'Please fill in at least the Classification or Manufacturer field to get meaningful name suggestions.';
        AINotEnabledErr: Label 'AI features are not enabled. Please contact your administrator to configure Azure OpenAI integration.';
        AINotAuthorizedErr: Label 'Azure OpenAI is not configured. Please contact your administrator to set up the AI service.';
        SuggestionFailedErr: Label 'Failed to generate name suggestions. Error: %1', Comment = '%1 = error message';

    procedure GetAssetNameSuggestions(var Asset: Record "JML AP Asset"; var SuggestionList: List of [Text]): Boolean
    var
        ChatMessages: Codeunit "AOAI Chat Messages";
        ChatParams: Codeunit "AOAI Chat Completion Params";
        OperationResponse: Codeunit "AOAI Operation Response";
        SystemPrompt: SecretText;
        SystemPromptText: Text;
        UserPrompt: Text;
    begin
        // Validate prerequisites
        if not ValidateCopilotSetup() then
            exit(false);

        // Build user prompt from asset data
        UserPrompt := BuildAssetPrompt(Asset);
        if UserPrompt = '' then
            Error(NoContextErr);

        // Configure chat parameters
        ChatParams.SetTemperature(0.7);  // Balanced creativity
        ChatParams.SetMaxTokens(300);     // Limit response length

        // Build conversation - convert Label to Text to SecretText
        SystemPromptText := SystemPromptTxt;
        SystemPrompt := SystemPromptText;
        ChatMessages.SetPrimarySystemMessage(SystemPrompt);
        ChatMessages.AddUserMessage(UserPrompt);

        // Call Azure OpenAI
        AzureOpenAI.GenerateChatCompletion(ChatMessages, ChatParams, OperationResponse);

        // Handle response
        if not OperationResponse.IsSuccess() then begin
            Error(SuggestionFailedErr, OperationResponse.GetError());
        end;

        // Parse suggestions from JSON response
        exit(ParseSuggestions(OperationResponse.GetResult(), SuggestionList));
    end;

    local procedure ValidateCopilotSetup(): Boolean
    var
        CopilotCapability: Enum "Copilot Capability";
    begin
        CopilotCapability := CopilotCapability::"JML AP Asset Name Suggestion";

        // Check if capability is enabled
        if not AzureOpenAI.IsEnabled(CopilotCapability, false) then begin
            Message(AINotEnabledErr);
            exit(false);
        end;

        // Check if authorization is configured
        if not AzureOpenAI.IsAuthorizationConfigured(Enum::"AOAI Model Type"::"Chat Completions") then begin
            Message(AINotAuthorizedErr);
            exit(false);
        end;

        // Set capability context for this operation
        AzureOpenAI.SetCopilotCapability(CopilotCapability);

        exit(true);
    end;

    local procedure BuildAssetPrompt(var Asset: Record "JML AP Asset"): Text
    var
        ClassificationPath: Text;
        Prompt: Text;
    begin
        Prompt := 'Generate professional asset names based on:' + NewLine();

        // Add classification information
        if Asset."Classification Code" <> '' then begin
            ClassificationPath := Asset.GetClassificationPath();
            if ClassificationPath <> '' then
                Prompt += 'Classification: ' + ClassificationPath + NewLine()
            else
                Prompt += 'Classification: ' + Asset."Classification Code" + NewLine();
        end;

        // Add industry
        if Asset."Industry Code" <> '' then
            Prompt += 'Industry: ' + Asset."Industry Code" + NewLine();

        // Add manufacturer
        if Asset."Manufacturer Code" <> '' then
            Prompt += 'Manufacturer: ' + Asset."Manufacturer Code" + NewLine();

        // Add model
        if Asset."Model No." <> '' then
            Prompt += 'Model: ' + Asset."Model No." + NewLine();

        // Add year
        if Asset."Year of Manufacture" <> 0 then
            Prompt += 'Year: ' + Format(Asset."Year of Manufacture") + NewLine();

        // Add serial number (if available)
        if Asset."Serial No." <> '' then
            Prompt += 'Serial No.: ' + Asset."Serial No." + NewLine();

        // Add existing description if available
        if Asset.Description <> '' then
            Prompt += 'Current Description: ' + Asset.Description + NewLine();

        if Prompt = 'Generate professional asset names based on:' + NewLine() then
            exit('');

        exit(Prompt);
    end;

    local procedure ParseSuggestions(JsonResponse: Text; var SuggestionList: List of [Text]): Boolean
    var
        JsonArray: JsonArray;
        JsonToken: JsonToken;
        i: Integer;
    begin
        Clear(SuggestionList);

        // Try to parse JSON array
        if not JsonArray.ReadFrom(JsonResponse) then begin
            Message('Invalid response format from AI service.');
            exit(false);
        end;

        // Extract suggestions
        for i := 0 to JsonArray.Count - 1 do begin
            JsonArray.Get(i, JsonToken);
            if JsonToken.IsValue then
                SuggestionList.Add(JsonToken.AsValue().AsText());
        end;

        exit(SuggestionList.Count > 0);
    end;

    local procedure NewLine(): Text
    begin
        exit('\n');
    end;
}
