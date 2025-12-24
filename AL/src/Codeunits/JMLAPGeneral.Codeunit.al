codeunit 70182300 "JML AP General"
{
    // SingleInstance ensures the SkipLicenseCheckForTesting flag persists across all calls in the session
    SingleInstance = true;

    var
        UnlicensedQst: Label 'Current user does not have license for JML AssetPro extension by JEMEL. Do you want to add licenses now?';
        PublisherIdTxt: label 'jemel', Locked = true;
        SkipLicenseCheckForTesting: Boolean;


    procedure IsAllowedToUse(Silent: Boolean): Boolean
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        // Allow during test execution
        if SkipLicenseCheckForTesting then
            exit(true);

        AllowHTTP();

        if EnvironmentInformation.IsOnPrem() then
            exit(true);

        if UserIsEntitled() then
            exit(true);

        if UserHasLicense() then
            exit(true);

        if not Silent then
            if Confirm(UnlicensedQst) then
                OpenExtensionMarketplace();
        exit(false);
    end;

    /// <summary>
    /// Enable test mode to bypass license checks during automated testing
    /// Only accessible from Test app via InternalsVisibleTo
    /// </summary>
    internal procedure SetSkipLicenseCheckForTesting(Skip: Boolean)
    begin
        SkipLicenseCheckForTesting := Skip;
    end;

    local procedure UserIsEntitled(): Boolean
    begin
        if NavApp.IsEntitled('JMLAssetPro_PerUserOfferPlan') or
           NavApp.IsEntitled('JMLAssetPro_DelegatedAdminAgent') or
           NavApp.IsEntitled('JMLAssetPro_DelegatedHelpdeskAgent')
        then
            exit(true);

        exit(false);
    end;

    local procedure UserHasLicense(): Boolean
    begin
        if CheckIfLicenseActive() then
            exit(true);

        exit(false);
    end;

    local procedure OpenExtensionMarketplace()
    var
        AppSourceProductList: page "AppSource Product List";
    begin
        AppSourceProductList.JMLPublisherFilterIDL(PublisherIdTxt);
        AppSourceProductList.Run();
    end;

    internal procedure AllowHTTP()
    var
        NAVAppSetting: Record "NAV App Setting";
        AppInfo: ModuleInfo;
    begin
        // We REQUIRE HTTP access, so we'll force it on, regardless of Sandbox
        NavApp.GetCurrentModuleInfo(AppInfo);
        if NAVAppSetting.Get(AppInfo.Id) then begin
            if not NAVAppSetting."Allow HttpClient Requests" then begin
                NAVAppSetting."Allow HttpClient Requests" := true;
                NAVAppSetting.Modify();
            end
        end else begin
            NAVAppSetting."App ID" := AppInfo.Id;
            NAVAppSetting."Allow HttpClient Requests" := true;
            NAVAppSetting.Insert();
        end;
    end;

    /// <summary>
    /// CheckIfLicenseActive.
    /// </summary>
    [NonDebuggable]
    local procedure CheckIfLicenseActive(): Boolean
    var
        EnvironmentInformation: Codeunit "Environment Information";
        AzureADTenant: Codeunit "Azure AD Tenant";
        AppInfo: ModuleInfo;
        ReqJson: JsonObject;
        ReturnValue: Text;
        LastDateCheck: Date;
        reqContentText: Text;
        client: HttpClient;
        response: HttpResponseMessage;
        headersRequest: HttpHeaders;
        headersContent: HttpHeaders;
        content: HttpContent;
        CheckUrlTxt: label 'https://prod-09.germanywestcentral.logic.azure.com:443/workflows/1a2eb403dadf491e83fc0d481a19b642/triggers/manual/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=f_Xd0sGghryqgZ1FneSEf0KdXXGRB0O3PwcoE7FVpBs', Locked = true;
    begin
        if EnvironmentInformation.IsOnPrem() then
            exit;

        NavApp.GetCurrentModuleInfo(AppInfo);

        if IsolatedStorage.Contains(AppInfo.Id, DataScope::Module) then begin
            IsolatedStorage.Get(AppInfo.Id, DataScope::Module, ReturnValue);
            if Evaluate(LastDateCheck, ReturnValue, 9) and (LastDateCheck = Today) then
                exit(true);
        end;

        ReqJson.Add('appId', LowerCase(DELCHR(AppInfo.Id, '<>', '{}')));
        ReqJson.Add('tenantId', AzureADTenant.GetAadTenantId());

        headersRequest := client.DefaultRequestHeaders;
        ReqJson.WriteTo(reqContentText);
        content.WriteFrom(reqContentText);
        content.GetHeaders(headersContent);
        headersContent.Remove('Content-Type');
        headersContent.Add('Content-Type', 'application/json');

        if not client.Post(CheckUrlTxt, content, response) then
            exit(false);
        if not response.IsSuccessStatusCode then
            exit(false);

        IsolatedStorage.Set(AppInfo.Id, format(Today, 0, 9), DataScope::Module);
        exit(true);
    end;
}
