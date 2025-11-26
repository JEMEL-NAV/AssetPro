page 70182333 "JML AP Asset Card"
{
    Caption = 'Asset';
    PageType = Card;
    SourceTable = "JML AP Asset";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the asset number.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the asset.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies an additional description.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the status of the asset.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the asset is blocked.';
                }
            }

            group(Classification)
            {
                Caption = 'Classification';

                field("Industry Code"; Rec."Industry Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the industry code.';
                }
                field("Classification Code"; Rec."Classification Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the classification code.';
                }
                field("Classification Path"; ClassificationPathText)
                {
                    ApplicationArea = All;
                    Caption = 'Classification Path';
                    ToolTip = 'Shows the full classification path from root to current classification.';
                    Editable = false;
                    StyleExpr = true;
                }
            }

            group("Physical Hierarchy")
            {
                Caption = 'Physical Hierarchy';

                field("Parent Asset No."; Rec."Parent Asset No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the parent asset number.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ParentAssetNo: Code[20];
                    begin
                        ParentAssetNo := Rec."Parent Asset No.";
                        if Rec.LookupParentAsset(ParentAssetNo) then begin
                            Text := ParentAssetNo;
                            exit(true);
                        end;
                        exit(false);
                    end;
                }
                field("Hierarchy Level"; Rec."Hierarchy Level")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the hierarchy level.';
                }
                field("Root Asset No."; Rec."Root Asset No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the root asset number.';
                }
            }

            group("Current Holder")
            {
                Caption = 'Current Holder';

                field("Current Holder Type"; Rec."Current Holder Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the current holder type.';
                    Editable = false;
                }
                field("Current Holder Code"; Rec."Current Holder Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the current holder code.';
                    Editable = false;

                    trigger OnAssistEdit()
                    begin
                        Rec.OpenChangeHolderDialog();
                        CurrPage.Update(false);
                    end;
                }
                field("Current Holder Addr Code"; Rec."Current Holder Addr Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the ship-to address code (for customers) or order address code (for vendors).';
                    Editable = false;
                }
                field("Current Holder Name"; Rec."Current Holder Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the current holder name.';
                }
                field("Current Holder Since"; Rec."Current Holder Since")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date when the current holder received the asset.';
                }
            }

            group(Ownership)
            {
                Caption = 'Ownership';

                field("Owner Type"; Rec."Owner Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the owner type.';
                }
                field("Owner Code"; Rec."Owner Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the owner code.';
                }
                field("Owner Name"; Rec."Owner Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the owner name.';
                }
                field("Operator Type"; Rec."Operator Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the operator type.';
                }
                field("Operator Code"; Rec."Operator Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the operator code.';
                }
                field("Lessee Type"; Rec."Lessee Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the lessee type.';
                }
                field("Lessee Code"; Rec."Lessee Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the lessee code.';
                }
            }

            group(Dates)
            {
                Caption = 'Dates';

                field("Acquisition Date"; Rec."Acquisition Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the acquisition date.';
                }
                field("In-Service Date"; Rec."In-Service Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the in-service date.';
                }
                field("Last Service Date"; Rec."Last Service Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the last service date.';
                }
                field("Next Service Date"; Rec."Next Service Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the next service date.';
                }
            }

            group(Financial)
            {
                Caption = 'Financial';

                field("Acquisition Cost"; Rec."Acquisition Cost")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the acquisition cost.';
                }
                field("Current Book Value"; Rec."Current Book Value")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the current book value.';
                }
                field("Residual Value"; Rec."Residual Value")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the residual value.';
                }
            }

            group("Additional Information")
            {
                Caption = 'Additional Information';

                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the serial number.';
                }
                field("Manufacturer Code"; Rec."Manufacturer Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the manufacturer code.';
                }
                field("Model No."; Rec."Model No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the model number.';
                }
                field("Year of Manufacture"; Rec."Year of Manufacture")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the year of manufacture.';
                }
            }
        }
        area(FactBoxes)
        {
            part(AttributesFactBox; "JML AP Attributes FB")
            {
                ApplicationArea = All;
                SubPageLink = "Asset No." = field("No.");
            }
            systempart(LinksFactBox; Links)
            {
                ApplicationArea = All;
            }
            systempart(NotesFactBox; Notes)
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(HolderHistory)
            {
                ApplicationArea = All;
                Caption = 'Holder History';
                ToolTip = 'View the holder history for this asset.';
                Image = History;
                RunObject = page "JML AP Holder Entries";
                RunPageLink = "Asset No." = field("No.");
            }
            action(RelationshipHistory)
            {
                ApplicationArea = All;
                Caption = 'Relationship History';
                ToolTip = 'View the complete attach/detach history for this asset.';
                Image = History;
                RunObject = page "JML AP Relationship Entries";
                RunPageLink = "Asset No." = field("No.");
            }
            action(ComponentEntries)
            {
                ApplicationArea = All;
                Caption = 'Component Entries';
                ToolTip = 'View all component entries for this asset (installations, removals, replacements).';
                Image = Components;
                RunObject = page "JML AP Component Entries";
                RunPageLink = "Asset No." = field("No.");
            }
            action(ChildrenAssets)
            {
                ApplicationArea = All;
                Caption = 'Children Assets';
                ToolTip = 'View all child assets in a tree structure (children, grandchildren, etc.).';
                Image = Hierarchy;

                trigger OnAction()
                var
                    Asset: Record "JML AP Asset";
                    AssetTreePage: Page "JML AP Asset Tree";
                begin
                    Asset.SetRange("Root Asset No.", Rec."No.");
                    Asset.SetFilter("No.", '<>%1', Rec."No."); // Exclude self
                    AssetTreePage.SetTableView(Asset);
                    AssetTreePage.Run();
                end;
            }
        }
        area(Processing)
        {
            action(DetachFromParent)
            {
                ApplicationArea = All;
                Caption = 'Detach from Parent';
                ToolTip = 'Detach this asset from its parent asset and log the detach event.';
                Image = UnLinkAccount;
                Enabled = Rec."Parent Asset No." <> '';

                trigger OnAction()
                begin
                    Rec.DetachFromParent();
                    CurrPage.Update(false);
                    Message('Asset detached from parent.');
                end;
            }
            action(ChangeHolder)
            {
                ApplicationArea = All;
                Caption = 'Change Holder';
                ToolTip = 'Change the current holder of this asset (creates holder entry).';
                Image = ChangeTo;
                Visible = ManualHolderChangeAllowed;

                trigger OnAction()
                begin
                    Rec.OpenChangeHolderDialog();
                    CurrPage.Update(false);
                end;
            }
            action(TransferAsset)
            {
                ApplicationArea = All;
                Caption = 'Transfer Asset';
                ToolTip = 'Transfer this asset to a new holder.';
                Image = TransferOrder;

                trigger OnAction()
                begin
                    Message('Transfer functionality will be implemented.');
                end;
            }
        }
    }

    var
        ClassificationPathText: Text[250];
        ManualHolderChangeAllowed: Boolean;

    trigger OnOpenPage()
    var
        AssetSetup: Record "JML AP Asset Setup";
    begin
        AssetSetup.GetRecordOnce();
        ManualHolderChangeAllowed := not AssetSetup."Block Manual Holder Change";
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateClassificationPath();
    end;

    local procedure UpdateClassificationPath()
    begin
        if Rec."Classification Code" <> '' then
            ClassificationPathText := Rec.GetClassificationPath()
        else
            ClassificationPathText := '';
    end;
}
