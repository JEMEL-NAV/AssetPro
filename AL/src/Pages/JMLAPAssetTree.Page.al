page 70182343 "JML AP Asset Tree"
{
    Caption = 'Children Assets Tree';
    Description = 'Displays assets in a hierarchical tree structure showing parent-child relationships.';
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
                IndentationColumn = Rec.Indentation;
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

    trigger OnAfterGetCurrRecord()
    begin
        StyleText := Rec.GetStyleText();
    end;

    trigger OnAfterGetRecord()
    begin
        StyleText := Rec.GetStyleText();
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        StyleText := Rec.GetStyleText();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        StyleText := Rec.GetStyleText();
    end;

    trigger OnOpenPage()
    begin
        AssetTreeMgt.UpdatePresentationOrder(RootAssetNo);
    end;

    var
        AssetTreeMgt: Codeunit "JML AP Asset Tree Mgt";
        StyleText: Text;
        RootAssetNo: code[20];

    procedure SetRootAssetNo(NewRootAssetNo: code[20])
    begin
        RootAssetNo := NewRootAssetNo;
    end;
}
