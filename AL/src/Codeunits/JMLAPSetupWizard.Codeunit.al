codeunit 70182381 "JML AP Setup Wizard"
{
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

        // Initialize default values
        AssetSetup."Enable Attributes" := true;
        AssetSetup.Modify();
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
