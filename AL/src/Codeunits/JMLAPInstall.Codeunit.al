codeunit 70182388 "JML AP Install"
{
    Subtype = Install;
    Access = Internal;

    trigger OnInstallAppPerCompany()
    begin
        RegisterAssistedSetup();
        RegisterCopilotCapabilities();
    end;

    var
        LearnMoreTxt: label 'https://jemel.lv/docs/asset-pro', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", 'OnRegisterAssistedSetup', '', false, false)]
    local procedure OnRegisterAssistedSetup()
    var
        GuidedExperience: Codeunit "Guided Experience";
        AssistedSetupGroup: Enum "Assisted Setup Group";
        VideoCategory: Enum "Video Category";
        CurrentGlobalLanguage: Integer;
    begin
        CurrentGlobalLanguage := GlobalLanguage();
        GuidedExperience.InsertAssistedSetup(
            'Asset Pro Setup',
            'Asset Pro Setup',
            'Configure Asset Pro for your organization.',
            5,
            ObjectType::Page,
            Page::"JML AP Setup Wizard",
            AssistedSetupGroup::GettingStarted,
            '',
            VideoCategory::Uncategorized,
            ''
        );
        GlobalLanguage(CurrentGlobalLanguage);
    end;

    local procedure RegisterCopilotCapabilities()
    var
        CopilotCapability: Codeunit "Copilot Capability";
        Capability: Enum "Copilot Capability";
        CopilotAvailability: Enum "Copilot Availability";
        CopilotBillingType: Enum "Copilot Billing Type";
    begin
        // Register Asset Name Suggestion capability
        if not CopilotCapability.IsCapabilityRegistered(Capability::"JML AP Asset Name Suggestion") then
            CopilotCapability.RegisterCapability(
                Capability::"JML AP Asset Name Suggestion",
                CopilotAvailability::"Generally Available",
                CopilotBillingType::"Microsoft Billed",
                LearnMoreTxt);
    end;

    local procedure RegisterAssistedSetup()
    var
        GuidedExperience: Codeunit "Guided Experience";
        AssistedSetupGroup: Enum "Assisted Setup Group";
        VideoCategory: Enum "Video Category";
        CurrentGlobalLanguage: Integer;
    begin
        if not GuidedExperience.Exists("Guided Experience Type"::"Assisted Setup", ObjectType::Page, Page::"JML AP Setup Wizard") then begin
            CurrentGlobalLanguage := GlobalLanguage();
            GuidedExperience.InsertAssistedSetup(
                'Asset Pro Setup',
                'Asset Pro Setup',
                'Configure Asset Pro for your organization.',
                5,
                ObjectType::Page,
                Page::"JML AP Setup Wizard",
                AssistedSetupGroup::GettingStarted,
                '',
                VideoCategory::Uncategorized,
                ''
            );
            GlobalLanguage(CurrentGlobalLanguage);
        end;
    end;
}
