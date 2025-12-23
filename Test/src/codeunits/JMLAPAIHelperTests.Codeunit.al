codeunit 50121 "JML AP AI Helper Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";
        TestLibrary: Codeunit "JML AP Test Library";
        AIHelper: Codeunit "JML AP AI Helper";

    // ============================================================================
    // Story 1.4: AI Helper Utility Tests
    // ============================================================================

    [Test]
    procedure TestAIHelper_CleanJSONResponse_RemovesMarkdown()
    var
        RawJson: Text;
        CleanedJson: Text;
    begin
        // [SCENARIO] CleanJsonResponse removes markdown code block wrappers from JSON

        // [GIVEN] A JSON response wrapped in markdown code blocks
        RawJson := '```json' + AIHelper.NewLine() + '["Name1","Name2","Name3"]' + AIHelper.NewLine() + '```';

        // [WHEN] Cleaning the JSON response
        CleanedJson := AIHelper.CleanJsonResponse(RawJson);

        // [THEN] Markdown wrappers are removed, leaving only pure JSON
        LibraryAssert.AreEqual('["Name1","Name2","Name3"]', CleanedJson, 'Should remove markdown code blocks');
    end;

    [Test]
    procedure TestAIHelper_CleanJSONResponse_RemovesWrapperObject()
    var
        RawJson: Text;
        CleanedJson: Text;
        ExpectedJson: Text;
    begin
        // [SCENARIO] CleanJsonResponse removes wrapper objects with "content" property

        // [GIVEN] A JSON response with wrapper structure {"annotations":[],"content":"..."}
        RawJson := '{"annotations":[],"content":"[\"Name1\",\"Name2\"]"}';
        ExpectedJson := '["Name1","Name2"]';

        // [WHEN] Cleaning the JSON response
        CleanedJson := AIHelper.CleanJsonResponse(RawJson);

        // [THEN] Wrapper object is removed, leaving only the content
        LibraryAssert.AreEqual(ExpectedJson, CleanedJson, 'Should extract content from wrapper');
    end;

    [Test]
    procedure TestAIHelper_CleanJSONResponse_HandlesArrayWithMarkdown()
    var
        RawJson: Text;
        CleanedJson: Text;
    begin
        // [SCENARIO] CleanJsonResponse handles JSON arrays wrapped in markdown

        // [GIVEN] A JSON array wrapped in markdown with ```json prefix
        RawJson := '```json' + AIHelper.NewLine() +
                   '[{"code":"TEST","name":"Test Industry"}]' + AIHelper.NewLine() +
                   '```';

        // [WHEN] Cleaning the JSON response
        CleanedJson := AIHelper.CleanJsonResponse(RawJson);

        // [THEN] Markdown is removed and array is preserved
        LibraryAssert.IsTrue(CleanedJson.StartsWith('['), 'Should start with [');
        LibraryAssert.IsTrue(CleanedJson.EndsWith(']'), 'Should end with ]');
        LibraryAssert.IsFalse(CleanedJson.Contains('```'), 'Should not contain markdown');
    end;

    [Test]
    procedure TestAIHelper_CleanJSONResponse_HandlesObjectWithMarkdown()
    var
        RawJson: Text;
        CleanedJson: Text;
    begin
        // [SCENARIO] CleanJsonResponse handles JSON objects wrapped in markdown

        // [GIVEN] A JSON object wrapped in markdown
        RawJson := '```json' + AIHelper.NewLine() +
                   '{"industryCode":"TEST","industryName":"Test"}' + AIHelper.NewLine() +
                   '```';

        // [WHEN] Cleaning the JSON response
        CleanedJson := AIHelper.CleanJsonResponse(RawJson);

        // [THEN] Markdown is removed and object is preserved
        LibraryAssert.IsTrue(CleanedJson.StartsWith('{'), 'Should start with {');
        LibraryAssert.IsTrue(CleanedJson.EndsWith('}'), 'Should end with }');
        LibraryAssert.IsFalse(CleanedJson.Contains('```'), 'Should not contain markdown');
    end;

    [Test]
    procedure TestAIHelper_CleanJSONResponse_HandlesPlainJSON()
    var
        RawJson: Text;
        CleanedJson: Text;
    begin
        // [SCENARIO] CleanJsonResponse handles already clean JSON without modification

        // [GIVEN] A plain JSON response without any wrappers
        RawJson := '["Name1","Name2","Name3"]';

        // [WHEN] Cleaning the JSON response
        CleanedJson := AIHelper.CleanJsonResponse(RawJson);

        // [THEN] JSON is returned unchanged (only trimmed)
        LibraryAssert.AreEqual(RawJson, CleanedJson, 'Should return clean JSON unchanged');
    end;

    [Test]
    procedure TestAIHelper_CleanJSONResponse_TrimsWhitespace()
    var
        RawJson: Text;
        CleanedJson: Text;
    begin
        // [SCENARIO] CleanJsonResponse trims leading and trailing whitespace

        // [GIVEN] A JSON response with extra whitespace
        RawJson := '   ["Name1","Name2"]   ';

        // [WHEN] Cleaning the JSON response
        CleanedJson := AIHelper.CleanJsonResponse(RawJson);

        // [THEN] Whitespace is trimmed
        LibraryAssert.AreEqual('["Name1","Name2"]', CleanedJson, 'Should trim whitespace');
    end;

    [Test]
    procedure TestAIHelper_NewLine_ReturnsNewlineCharacter()
    var
        NewLineChar: Text;
    begin
        // [SCENARIO] NewLine helper returns correct newline character

        // [WHEN] Getting newline character
        NewLineChar := AIHelper.NewLine();

        // [THEN] Returns '\n' character
        LibraryAssert.AreEqual('\n', NewLineChar, 'Should return newline character');
    end;

    [Test]
    procedure TestAIHelper_IsConfigured_ReturnsTrue()
    begin
        // [SCENARIO] IsConfigured returns true when JEMEL credentials are set

        // [WHEN] Checking if AI is configured
        // [THEN] Returns true (credentials are hardcoded)
        LibraryAssert.IsTrue(AIHelper.IsConfigured(), 'Should return true when configured');
    end;

    [Test]
    procedure TestAIHelper_GetProviderInfo_ReturnsJEMELInfo()
    var
        ProviderInfo: Text;
    begin
        // [SCENARIO] GetProviderInfo returns information about current AI provider

        // [WHEN] Getting provider information
        ProviderInfo := AIHelper.GetProviderInfo();

        // [THEN] Returns JEMEL Azure OpenAI information
        LibraryAssert.IsTrue(ProviderInfo.Contains('JEMEL'), 'Should mention JEMEL');
        LibraryAssert.IsTrue(ProviderInfo.Contains('Azure OpenAI'), 'Should mention Azure OpenAI');
        LibraryAssert.IsTrue(ProviderInfo.Contains('Sweden Central'), 'Should mention region');
    end;

    [Test]
    procedure TestAIHelper_SetJEMELAuthorization_ConfiguresAzureOpenAI()
    var
        TestAzureOpenAI: Codeunit "Azure OpenAI";
        AuthResult: Boolean;
    begin
        // [SCENARIO] SetJEMELAuthorization configures Azure OpenAI with correct credentials

        // [WHEN] Setting JEMEL authorization
        AuthResult := AIHelper.SetJEMELAuthorization(TestAzureOpenAI);

        // [THEN] Authorization is set successfully
        LibraryAssert.IsTrue(AuthResult, 'Should successfully set authorization');
    end;

    [Test]
    procedure TestAIHelper_ValidateCopilotSetup_WithValidCapability_ReturnsTrue()
    var
        TestAzureOpenAI: Codeunit "Azure OpenAI";
        CopilotCapability: Enum "Copilot Capability";
        SetupResult: Boolean;
    begin
        // [SCENARIO] ValidateCopilotSetup successfully configures Azure OpenAI with capability

        // [GIVEN] A valid Copilot capability
        CopilotCapability := CopilotCapability::"JML AP Asset Name Suggestion";

        // [WHEN] Validating Copilot setup
        SetupResult := AIHelper.ValidateCopilotSetup(TestAzureOpenAI, CopilotCapability);

        // [THEN] Setup is successful
        LibraryAssert.IsTrue(SetupResult, 'Should successfully validate Copilot setup');
    end;

    [Test]
    procedure TestAIHelper_CleanJSONResponse_ComplexWrapper_ExtractsContent()
    var
        RawJson: Text;
        CleanedJson: Text;
    begin
        // [SCENARIO] CleanJsonResponse handles wrapper with nested array content

        // [GIVEN] A wrapper structure with annotations and array content
        RawJson := '{"annotations":[{"type":"link"}],"content":"[\"Value1\",\"Value2\",\"Value3\"]"}';

        // [WHEN] Cleaning the JSON response
        CleanedJson := AIHelper.CleanJsonResponse(RawJson);

        // [THEN] Content is extracted correctly
        LibraryAssert.IsTrue(CleanedJson.StartsWith('['), 'Should start with [');
        LibraryAssert.IsTrue(CleanedJson.Contains('Value1'), 'Should contain Value1 from content');
        LibraryAssert.IsFalse(CleanedJson.Contains('"annotations"'), 'Should not contain annotations property');
    end;

    [Test]
    procedure TestAIHelper_CleanJSONResponse_EmptyString_ReturnsEmpty()
    var
        RawJson: Text;
        CleanedJson: Text;
    begin
        // [SCENARIO] CleanJsonResponse handles empty string input

        // [GIVEN] An empty string
        RawJson := '';

        // [WHEN] Cleaning the JSON response
        CleanedJson := AIHelper.CleanJsonResponse(RawJson);

        // [THEN] Returns empty string
        LibraryAssert.AreEqual('', CleanedJson, 'Should return empty string for empty input');
    end;
}
