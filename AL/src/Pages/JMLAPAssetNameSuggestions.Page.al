page 70182386 "JML AP Asset Name Suggestions"
{
    Caption = 'AI Asset Name Suggestions';
    Description = 'Displays AI-generated asset name suggestions for user selection.';
    PageType = List;
    SourceTable = "Name/Value Buffer";
    SourceTableTemporary = true;
    Extensible = false;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Instructions)
            {
                Caption = 'Instructions';
                InstructionalText = 'AI will generate professional asset name suggestions based on the asset''s classification, manufacturer, model, and other attributes. Select a suggestion to use it, or click Regenerate for different options.';
            }
            repeater(Suggestions)
            {
                Caption = 'Suggested Names';

                field(SuggestedName; Rec.Name)
                {
                    ApplicationArea = All;
                    Caption = 'Suggested Name';
                    ToolTip = 'AI-generated asset name suggestion. Select this suggestion to use it.';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Regenerate)
            {
                ApplicationArea = All;
                Caption = 'Regenerate';
                ToolTip = 'Generate new suggestions with different variations.';
                Image = Refresh;

                trigger OnAction()
                begin
                    GenerateSuggestions();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
                actionref(Regenerate_Promoted; Regenerate)
                {
                }
            }
        }
    }

    var
        AINameSuggester: Codeunit "JML AP AI Name Suggester";
        AssetRec: Record "JML AP Asset";
        GeneratingMsg: Label 'Generating AI suggestions...';

    procedure SetAsset(var Asset: Record "JML AP Asset")
    begin
        AssetRec.Copy(Asset);
    end;

    procedure GetSelectedSuggestion(): Text[100]
    begin
        exit(Rec.Name);
    end;

    local procedure GenerateSuggestions()
    var
        SuggestionList: List of [Text];
        Suggestion: Text;
        LineNo: Integer;
        ProgressDialog: Dialog;
    begin
        // Clear existing suggestions
        Rec.Reset();
        Rec.DeleteAll();

        // Show progress
        ProgressDialog.Open(GeneratingMsg);

        // Get AI suggestions
        if AINameSuggester.GetAssetNameSuggestions(AssetRec, SuggestionList) then begin
            // Populate temporary table
            LineNo := 10000;
            foreach Suggestion in SuggestionList do begin
                Rec.Init();
                Rec.ID := LineNo;
                Rec.Name := CopyStr(Suggestion, 1, MaxStrLen(Rec.Name));
                Rec.Insert();
                LineNo += 10000;
            end;
        end;

        ProgressDialog.Close();

        // Refresh page
        CurrPage.Update(false);
    end;

    trigger OnOpenPage()
    begin
        // Auto-generate suggestions when page opens
        GenerateSuggestions();
    end;
}
