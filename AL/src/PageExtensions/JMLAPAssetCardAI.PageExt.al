pageextension 70182300 "JML AP Asset Card AI" extends "JML AP Asset Card"
{
    actions
    {
        addafter(ChangeHolder)
        {
            action(SuggestNameWithAI)
            {
                ApplicationArea = All;
                Caption = 'Suggest Name with AI';
                ToolTip = 'Use AI to generate professional asset name suggestions based on classification, manufacturer, and other attributes.';
                Image = Sparkle;
                Enabled = HasMinimumContext;

                trigger OnAction()
                var
                    SuggestionsPage: Page "JML AP Asset Name Suggestions";
                    SuggestedName: Text[100];
                begin
                    // Pass current asset to suggestions page
                    SuggestionsPage.SetAsset(Rec);
                    SuggestionsPage.LookupMode := true;

                    // Show suggestions dialog
                    if SuggestionsPage.RunModal() = Action::LookupOK then begin
                        SuggestedName := SuggestionsPage.GetSelectedSuggestion();

                        // Apply selected suggestion
                        if SuggestedName <> '' then begin
                            Rec.Validate(Description, SuggestedName);
                            CurrPage.Update(false);
                            Message('Asset name updated to: %1', SuggestedName);
                        end;
                    end;
                end;
            }
        }
    }

    var
        HasMinimumContext: Boolean;

    trigger OnAfterGetCurrRecord()
    begin
        // Enable AI action only when there's enough context
        HasMinimumContext := (Rec."Classification Code" <> '') or
                             (Rec."Manufacturer Code" <> '') or
                             (Rec."Model No." <> '');
    end;
}
