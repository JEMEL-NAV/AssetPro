page 70182343 "JML AP Asset Tree"
{
    Caption = 'Children Assets Tree';
    PageType = List;
    SourceTable = "JML AP Asset";
    Editable = false;
    ApplicationArea = All;
    SourceTableView = sorting("Root Asset No.", "Presentation Order");

    layout
    {
        area(Content)
        {
            repeater(Assets)
            {
                IndentationColumn = Indentation;
                IndentationControls = "No.";
                ShowAsTree = true;

                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the asset number.';
                    StyleExpr = StyleText;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the asset.';
                }
                field("Hierarchy Level"; Rec."Hierarchy Level")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the hierarchy level.';
                    Visible = false;
                }
                field("Parent Asset No."; Rec."Parent Asset No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the parent asset number.';
                }
                field("Classification Code"; Rec."Classification Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the classification code.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the status of the asset.';
                }
                field("Current Holder Name"; Rec."Current Holder Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the current holder name.';
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(OpenCard)
            {
                ApplicationArea = All;
                Caption = 'Open';
                ToolTip = 'Open the asset card.';
                Image = Card;
                ShortcutKey = Return;

                trigger OnAction()
                begin
                    Page.Run(Page::"JML AP Asset Card", Rec);
                end;
            }
        }
    }

    var
        StyleText: Text;
        Indentation: Integer;
        MinHierarchyLevel: Integer;
        AssetTreeMgt: Codeunit "JML AP Asset Tree Mgt";
        RootAssetNo: Code[20];

    trigger OnOpenPage()
    var
        Asset: Record "JML AP Asset";
    begin
        // Calculate minimum hierarchy level in the filtered set
        // This will be used as the base for relative indentation
        Asset.CopyFilters(Rec);
        if Asset.FindFirst() then begin
            MinHierarchyLevel := Asset."Hierarchy Level";
            RootAssetNo := Asset."Root Asset No.";

            // Update presentation order for this tree
            if RootAssetNo <> '' then
                AssetTreeMgt.UpdatePresentationOrder(RootAssetNo);
        end else
            MinHierarchyLevel := 1;
    end;

    trigger OnAfterGetRecord()
    begin
        // Calculate relative indentation (0-based from the root of this subtree)
        Indentation := Rec."Hierarchy Level" - MinHierarchyLevel;

        // Apply style based on relative hierarchy level for visual distinction
        case Indentation of
            0:
                StyleText := 'Strong';
            1:
                StyleText := 'Standard';
            else
                StyleText := 'Subordinate';
        end;
    end;
}
