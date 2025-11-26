table 70182301 "JML AP Asset"
{
    Caption = 'Asset';
    DataClassification = CustomerContent;
    LookupPageId = "JML AP Asset List";
    DrillDownPageId = "JML AP Asset List";

    fields
    {
        // === PRIMARY IDENTIFICATION ===
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the asset number.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then
                    ValidateNumberSeries();
            end;
        }

        field(2; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            ToolTip = 'Specifies the number series used for this asset.';
            TableRelation = "No. Series";
            Editable = false;
        }

        field(10; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the asset.';
        }

        field(11; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            ToolTip = 'Specifies an additional description of the asset.';
        }

        field(12; "Search Description"; Code[100])
        {
            Caption = 'Search Description';
            ToolTip = 'Specifies a search-friendly description of the asset.';
        }

        // === CLASSIFICATION (STRUCTURE 1) ===
        // ARCHITECTURAL DECISION: Single classification field for truly unlimited levels
        // Asset stores the LEAF classification node (e.g., "PANAMAX")
        // Parent levels (e.g., CARGO → COMMERCIAL) are traversed via Classification Value table

        field(100; "Industry Code"; Code[20])
        {
            Caption = 'Industry';
            ToolTip = 'Specifies the industry this asset belongs to.';
            TableRelation = "JML AP Asset Industry";

            trigger OnValidate()
            begin
                if "Industry Code" <> xRec."Industry Code" then
                    "Classification Code" := '';
            end;
        }

        field(101; "Classification Code"; Code[20])
        {
            Caption = 'Classification';
            ToolTip = 'Specifies the classification of this asset (leaf node in classification tree).';
            TableRelation = "JML AP Classification Val".Code where("Industry Code" = field("Industry Code"));

            trigger OnValidate()
            begin
                if "Classification Code" <> '' then
                    ValidateClassification();
            end;
        }

        field(102; "Classification Level No."; Integer)
        {
            Caption = 'Classification Level No.';
            ToolTip = 'Specifies the level number of the classification.';
            FieldClass = FlowField;
            CalcFormula = Lookup("JML AP Classification Val"."Level Number"
                where("Industry Code" = field("Industry Code"),
                      Code = field("Classification Code")));
            Editable = false;
        }

        field(103; "Classification Description"; Text[100])
        {
            Caption = 'Classification Description';
            ToolTip = 'Specifies the description of the classification.';
            FieldClass = FlowField;
            CalcFormula = Lookup("JML AP Classification Val".Description
                where("Industry Code" = field("Industry Code"),
                      Code = field("Classification Code")));
            Editable = false;
        }

        // === PHYSICAL COMPOSITION (STRUCTURE 2) ===
        field(200; "Parent Asset No."; Code[20])
        {
            Caption = 'Parent Asset No.';
            ToolTip = 'Specifies the parent asset number if this is a component asset.';
            TableRelation = "JML AP Asset";

            trigger OnValidate()
            begin
                ValidateParentAsset();
            end;
        }

        field(201; "Has Children"; Boolean)
        {
            Caption = 'Has Children';
            ToolTip = 'Specifies whether this asset has child assets.';
            FieldClass = FlowField;
            CalcFormula = Exist("JML AP Asset" where("Parent Asset No." = field("No.")));
            Editable = false;
        }

        field(202; "Child Asset Count"; Integer)
        {
            Caption = 'Child Asset Count';
            ToolTip = 'Specifies the number of child assets.';
            FieldClass = FlowField;
            CalcFormula = Count("JML AP Asset" where("Parent Asset No." = field("No.")));
            Editable = false;
        }

        field(203; "Hierarchy Level"; Integer)
        {
            Caption = 'Hierarchy Level';
            ToolTip = 'Specifies the physical hierarchy depth (1 = root, 2 = child, 3 = grandchild, etc.).';
            Editable = false;
        }

        field(204; "Root Asset No."; Code[20])
        {
            Caption = 'Root Asset No.';
            ToolTip = 'Specifies the top-most parent asset in physical hierarchy.';
            TableRelation = "JML AP Asset";
            Editable = false;
        }

        field(205; "Presentation Order"; Integer)
        {
            Caption = 'Presentation Order';
            ToolTip = 'Specifies the order for tree view presentation (calculated automatically).';
            Editable = false;
        }

        // === CURRENT HOLDER (OWNERSHIP/LOCATION) ===
        field(300; "Current Holder Type"; Enum "JML AP Holder Type")
        {
            Caption = 'Current Holder Type';
            ToolTip = 'Specifies the type of entity currently holding the asset.';

            trigger OnValidate()
            begin
                if "Current Holder Type" <> xRec."Current Holder Type" then begin
                    "Current Holder Code" := '';
                    "Current Holder Addr Code" := '';
                end;
            end;
        }

        field(301; "Current Holder Code"; Code[20])
        {
            Caption = 'Current Holder Code';
            ToolTip = 'Specifies the code of the entity currently holding the asset.';
            TableRelation = if ("Current Holder Type" = const(Customer)) Customer."No."
            else if ("Current Holder Type" = const(Vendor)) Vendor."No."
            else if ("Current Holder Type" = const(Location)) Location.Code;

            trigger OnValidate()
            begin
                if "Current Holder Code" <> xRec."Current Holder Code" then
                    "Current Holder Addr Code" := '';
                UpdateCurrentHolderName();
            end;
        }

        field(302; "Current Holder Name"; Text[100])
        {
            Caption = 'Current Holder Name';
            ToolTip = 'Specifies the name of the entity currently holding the asset.';
            Editable = false;
        }

        field(303; "Current Holder Since"; Date)
        {
            Caption = 'Current Holder Since';
            ToolTip = 'Specifies the date when the current holder received the asset.';
        }

        field(304; "Current Holder Addr Code"; Code[10])
        {
            Caption = 'Current Holder Address Code';
            ToolTip = 'Specifies the ship-to address code (for customers) or order address code (for vendors).';
            DataClassification = CustomerContent;
            TableRelation = if ("Current Holder Type" = const(Customer)) "Ship-to Address".Code where("Customer No." = field("Current Holder Code"))
            else if ("Current Holder Type" = const(Vendor)) "Order Address".Code where("Vendor No." = field("Current Holder Code"));

            trigger OnValidate()
            begin
                // Clear address code if holder type doesn't support addresses
                if not ("Current Holder Type" in ["Current Holder Type"::Customer, "Current Holder Type"::Vendor]) then
                    "Current Holder Addr Code" := '';
            end;
        }

        // === OWNERSHIP ROLES ===
        // ARCHITECTURAL DECISION: Type + Code pattern for flexible ownership
        // Owner, Operator, Lessee can be Customer, Vendor, Our Company, Employee, etc.
        // Matches Current Holder Type pattern for consistency

        // Owner (Legal ownership)
        field(310; "Owner Type"; Enum "JML AP Owner Type")
        {
            Caption = 'Owner Type';
            ToolTip = 'Specifies the type of entity that owns the asset.';

            trigger OnValidate()
            begin
                if "Owner Type" <> xRec."Owner Type" then
                    "Owner Code" := '';
            end;
        }

        field(311; "Owner Code"; Code[20])
        {
            Caption = 'Owner Code';
            ToolTip = 'Specifies the code of the entity that owns the asset.';
            TableRelation = if ("Owner Type" = const(Customer)) Customer."No."
            else if ("Owner Type" = const(Vendor)) Vendor."No."
            else if ("Owner Type" = const(Employee)) Employee."No."
            else if ("Owner Type" = const("Responsibility Center")) "Responsibility Center";

            trigger OnValidate()
            begin
                UpdateOwnerName();
            end;
        }

        field(312; "Owner Name"; Text[100])
        {
            Caption = 'Owner Name';
            ToolTip = 'Specifies the name of the entity that owns the asset.';
            Editable = false;
        }

        // Operator (Day-to-day user)
        field(320; "Operator Type"; Enum "JML AP Owner Type")
        {
            Caption = 'Operator Type';
            ToolTip = 'Specifies the type of entity that operates the asset.';

            trigger OnValidate()
            begin
                if "Operator Type" <> xRec."Operator Type" then
                    "Operator Code" := '';
            end;
        }

        field(321; "Operator Code"; Code[20])
        {
            Caption = 'Operator Code';
            ToolTip = 'Specifies the code of the entity that operates the asset.';
            TableRelation = if ("Operator Type" = const(Customer)) Customer."No."
            else if ("Operator Type" = const(Vendor)) Vendor."No."
            else if ("Operator Type" = const(Employee)) Employee."No."
            else if ("Operator Type" = const("Responsibility Center")) "Responsibility Center";

            trigger OnValidate()
            begin
                UpdateOperatorName();
            end;
        }

        field(322; "Operator Name"; Text[100])
        {
            Caption = 'Operator Name';
            ToolTip = 'Specifies the name of the entity that operates the asset.';
            Editable = false;
        }

        // Lessee (If leased/rented)
        field(330; "Lessee Type"; Enum "JML AP Owner Type")
        {
            Caption = 'Lessee Type';
            ToolTip = 'Specifies the type of entity that leases the asset.';

            trigger OnValidate()
            begin
                if "Lessee Type" <> xRec."Lessee Type" then
                    "Lessee Code" := '';
            end;
        }

        field(331; "Lessee Code"; Code[20])
        {
            Caption = 'Lessee Code';
            ToolTip = 'Specifies the code of the entity that leases the asset.';
            TableRelation = if ("Lessee Type" = const(Customer)) Customer."No."
            else if ("Lessee Type" = const(Vendor)) Vendor."No."
            else if ("Lessee Type" = const(Employee)) Employee."No."
            else if ("Lessee Type" = const("Responsibility Center")) "Responsibility Center";

            trigger OnValidate()
            begin
                UpdateLesseeName();
            end;
        }

        field(332; "Lessee Name"; Text[100])
        {
            Caption = 'Lessee Name';
            ToolTip = 'Specifies the name of the entity that leases the asset.';
            Editable = false;
        }

        // === STATUS AND DATES ===
        field(400; Status; Enum "JML AP Asset Status")
        {
            Caption = 'Status';
            ToolTip = 'Specifies the status of the asset.';
        }

        field(410; "Acquisition Date"; Date)
        {
            Caption = 'Acquisition Date';
            ToolTip = 'Specifies the date when the asset was acquired.';
        }

        field(411; "In-Service Date"; Date)
        {
            Caption = 'In-Service Date';
            ToolTip = 'Specifies the date when the asset was put into service.';
        }

        field(412; "Last Service Date"; Date)
        {
            Caption = 'Last Service Date';
            ToolTip = 'Specifies the date of the last service.';
        }

        field(413; "Next Service Date"; Date)
        {
            Caption = 'Next Service Date';
            ToolTip = 'Specifies the date of the next scheduled service.';
        }

        field(414; "Decommission Date"; Date)
        {
            Caption = 'Decommission Date';
            ToolTip = 'Specifies the date when the asset was decommissioned.';
        }

        // === FINANCIAL ===
        field(500; "Acquisition Cost"; Decimal)
        {
            Caption = 'Acquisition Cost';
            ToolTip = 'Specifies the acquisition cost of the asset.';
            AutoFormatType = 1;
        }

        field(501; "Current Book Value"; Decimal)
        {
            Caption = 'Current Book Value';
            ToolTip = 'Specifies the current book value of the asset.';
            AutoFormatType = 1;
        }

        field(502; "Residual Value"; Decimal)
        {
            Caption = 'Residual Value';
            ToolTip = 'Specifies the residual value of the asset.';
            AutoFormatType = 1;
        }

        // === ADDITIONAL INFO ===
        field(600; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
            ToolTip = 'Specifies the serial number of the asset.';
        }

        field(601; "Manufacturer Code"; Code[10])
        {
            Caption = 'Manufacturer Code';
            ToolTip = 'Specifies the manufacturer of the asset.';
            TableRelation = Manufacturer;
        }

        field(602; "Model No."; Code[50])
        {
            Caption = 'Model No.';
            ToolTip = 'Specifies the model number of the asset.';
        }

        field(603; "Year of Manufacture"; Integer)
        {
            Caption = 'Year of Manufacture';
            ToolTip = 'Specifies the year the asset was manufactured.';
            MinValue = 1900;
            MaxValue = 2100;
        }

        field(604; "Warranty Expires"; Date)
        {
            Caption = 'Warranty Expires';
            ToolTip = 'Specifies the warranty expiration date.';
        }

        // === SYSTEM FIELDS ===
        field(900; Blocked; Boolean)
        {
            Caption = 'Blocked';
            ToolTip = 'Specifies whether the asset is blocked from use.';
        }

        field(910; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            ToolTip = 'Specifies the date when the asset was last modified.';
            Editable = false;
        }

        field(911; "Last Modified By"; Code[50])
        {
            Caption = 'Last Modified By';
            ToolTip = 'Specifies who last modified the asset.';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
        key(Industry; "Industry Code", "Classification Code")
        {
        }
        key(Holder; "Current Holder Type", "Current Holder Code")
        {
        }
        key(Parent; "Parent Asset No.")
        {
        }
        key(Tree; "Root Asset No.", "Presentation Order")
        {
        }
        key(Search; "Search Description")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description, "Industry Code", Status)
        {
        }
        fieldgroup(Brick; "No.", Description, "Current Holder Name", Status)
        {
        }
    }

    trigger OnInsert()
    begin
        InitializeAsset();
        "Last Date Modified" := Today;
        "Last Modified By" := CopyStr(UserId, 1, MaxStrLen("Last Modified By"));
    end;

    trigger OnModify()
    begin
        RegisterManualHolderChange();
        "Last Date Modified" := Today;
        "Last Modified By" := CopyStr(UserId, 1, MaxStrLen("Last Modified By"));
    end;

    trigger OnDelete()
    begin
        ValidateAssetCanBeDeleted();
        DeleteRelatedRecords();
    end;

    var
        AssetSetup: Record "JML AP Asset Setup";
        NoSeries: Codeunit "No. Series";

    // === VALIDATION PROCEDURES ===
    local procedure ValidateNumberSeries()
    begin
        AssetSetup.GetRecordOnce();
        NoSeries.TestManual(AssetSetup."Asset Nos.");
        "No. Series" := '';
    end;

    local procedure InitializeAsset()
    begin
        AssetSetup.GetRecordOnce();

        // Initialize number series
        if "No." = '' then begin
            AssetSetup.TestField("Asset Nos.");
            "No. Series" := AssetSetup."Asset Nos.";
            if NoSeries.AreRelated("No. Series", xRec."No. Series") then
                "No. Series" := xRec."No. Series";
            "No." := NoSeries.GetNextNo("No. Series", WorkDate());
        end;

        // Apply default industry if not set
        if ("Industry Code" = '') and (AssetSetup."Default Industry Code" <> '') then
            Validate("Industry Code", AssetSetup."Default Industry Code");

        // Initialize hierarchy
        CalculateHierarchyLevel();
        UpdateRootAssetNo();
    end;

    procedure AssistEdit(OldAsset: Record "JML AP Asset"): Boolean
    var
        Asset: Record "JML AP Asset";
    begin
        Asset := Rec;
        AssetSetup.Get();
        AssetSetup.TestField("Asset Nos.");
        if NoSeries.LookupRelatedNoSeries(AssetSetup."Asset Nos.", OldAsset."No. Series", Asset."No. Series") then begin
            Asset."No." := NoSeries.GetNextNo(Asset."No. Series");
            Rec := Asset;
            exit(true);
        end;
    end;

    /// <summary>
    /// Opens the Change Holder dialog to manually change the asset's holder.
    /// </summary>
    procedure OpenChangeHolderDialog()
    var
        ChangeHolderDialog: Page "JML AP Change Holder Dialog";
    begin
        ChangeHolderDialog.SetOldHolder(
            "Current Holder Type",
            "Current Holder Code",
            "Current Holder Name",
            "Current Holder Addr Code");
        ChangeHolderDialog.SetAssetNo("No.");
        ChangeHolderDialog.RunModal();
    end;

    /// <summary>
    /// Opens parent asset lookup with proper filtering.
    /// </summary>
    procedure LookupParentAsset(var ParentAssetNo: Code[20]): Boolean
    var
        Asset: Record "JML AP Asset";
        AssetList: Page "JML AP Asset List";
    begin
        // Filter potential parent assets
        FilterPotentialParents(Asset);

        AssetList.SetTableView(Asset);
        AssetList.LookupMode := true;
        if AssetList.RunModal() = Action::LookupOK then begin
            AssetList.GetRecord(Asset);
            ParentAssetNo := Asset."No.";
            exit(true);
        end;

        exit(false);
    end;

    /// <summary>
    /// Filters asset list to show only valid potential parent assets.
    /// </summary>
    local procedure FilterPotentialParents(var Asset: Record "JML AP Asset")
    begin
        // Exclude self
        Asset.SetFilter("No.", '<>%1', "No.");

        // Must be in same industry if industry is assigned
        if "Industry Code" <> '' then
            Asset.SetRange("Industry Code", "Industry Code");

        // Filter by hierarchy level:
        // - If classification is set, filter by classification hierarchy
        // - Otherwise, allow any hierarchy level (for flexible physical hierarchy)
        if "Classification Code" <> '' then begin
            // Classification-based filtering
            CalcFields("Classification Level No.");
            if "Classification Level No." > 1 then
                // Show assets at one classification level above
                Asset.SetRange("Classification Level No.", "Classification Level No." - 1)
            else
                // Level 1 - show only other Level 1 assets
                Asset.SetRange("Classification Level No.", 1);
        end;
        // Note: If no classification, no hierarchy filtering applied (flexible physical hierarchy)
    end;

    /// <summary>
    /// Detaches the asset from its parent asset and logs the detach event.
    /// </summary>
    procedure DetachFromParent()
    begin
        if "Parent Asset No." = '' then
            Error(NoParentToDetachErr);

        Validate("Parent Asset No.", ''); // Triggers OnValidate which logs detach
        Modify(true);
    end;

    local procedure ValidateClassification()
    var
        ClassValue: Record "JML AP Classification Val";
    begin
        CalcFields("Classification Level No.");

        if not ClassValue.Get("Industry Code", "Classification Level No.", "Classification Code") then
            Error(ClassificationNotFoundErr, "Classification Code", "Industry Code");
    end;

    local procedure ValidateParentAsset()
    var
        ParentAsset: Record "JML AP Asset";
        AssetValidator: Codeunit "JML AP Asset Validation";
        RelationshipMgt: Codeunit "JML AP Relationship Mgt";
    begin
        // Log attach event when parent is set (was blank, now populated)
        if (xRec."Parent Asset No." = '') and ("Parent Asset No." <> '') then
            RelationshipMgt.LogAttachEvent("No.", "Parent Asset No.", '', WorkDate());

        // Log detach event when parent is cleared (was populated, now blank)
        if (xRec."Parent Asset No." <> '') and ("Parent Asset No." = '') then
            RelationshipMgt.LogDetachEvent("No.", xRec."Parent Asset No.", '', WorkDate());

        if "Parent Asset No." = '' then begin
            "Hierarchy Level" := 1;
            UpdateRootAssetNo();
            exit;
        end;

        // Validate same holder if both assets have holders
        if ParentAsset.Get("Parent Asset No.") then begin
            if ("Current Holder Type" <> "Current Holder Type"::" ") and
               (ParentAsset."Current Holder Type" <> "Current Holder Type"::" ")
            then begin
                if ("Current Holder Type" <> ParentAsset."Current Holder Type") or
                   ("Current Holder Code" <> ParentAsset."Current Holder Code")
                then
                    Error(DifferentHolderErr, "No.", "Parent Asset No.",
                          ParentAsset."Current Holder Type", ParentAsset."Current Holder Code");
            end;
        end;

        AssetValidator.ValidateParentAssignment(Rec);
        CalculateHierarchyLevel();
        UpdateRootAssetNo();
    end;

    local procedure CalculateHierarchyLevel()
    var
        ParentAsset: Record "JML AP Asset";
    begin
        if ParentAsset.Get("Parent Asset No.") then
            "Hierarchy Level" := ParentAsset."Hierarchy Level" + 1
        else
            "Hierarchy Level" := 1;
    end;

    local procedure UpdateRootAssetNo()
    var
        CheckAsset: Record "JML AP Asset";
        CurrentAssetNo: Code[20];
        IterationCount: Integer;
    begin
        // If no parent, clear root (standalone asset)
        if "Parent Asset No." = '' then begin
            "Root Asset No." := '';
            exit;
        end;

        // Walk up the parent chain to find root
        CurrentAssetNo := "Parent Asset No.";
        IterationCount := 0;

        while (CurrentAssetNo <> '') and (IterationCount < GetMaxParentChainDepth()) do begin
            if CheckAsset.Get(CurrentAssetNo) then begin
                if CheckAsset."Parent Asset No." = '' then begin
                    // Found the root - asset with no parent
                    "Root Asset No." := CheckAsset."No.";
                    exit;
                end;
                CurrentAssetNo := CheckAsset."Parent Asset No.";
            end else begin
                // Parent doesn't exist - clear root
                "Root Asset No." := '';
                exit;
            end;

            IterationCount += 1;
        end;

        // If we get here, couldn't find root (circular ref or depth exceeded)
        // Clear root
        "Root Asset No." := '';
    end;

    local procedure UpdateCurrentHolderName()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Location: Record Location;
    begin
        "Current Holder Name" := '';

        case "Current Holder Type" of
            "Current Holder Type"::Customer:
                if Customer.Get("Current Holder Code") then
                    "Current Holder Name" := Customer.Name;
            "Current Holder Type"::Vendor:
                if Vendor.Get("Current Holder Code") then
                    "Current Holder Name" := Vendor.Name;
            "Current Holder Type"::Location:
                if Location.Get("Current Holder Code") then
                    "Current Holder Name" := Location.Name;
        end;
    end;

    local procedure UpdateOwnerName()
    begin
        "Owner Name" := GetOwnerTypeName("Owner Type", "Owner Code");
    end;

    local procedure UpdateOperatorName()
    begin
        "Operator Name" := GetOwnerTypeName("Operator Type", "Operator Code");
    end;

    local procedure UpdateLesseeName()
    begin
        "Lessee Name" := GetOwnerTypeName("Lessee Type", "Lessee Code");
    end;

    local procedure GetOwnerTypeName(OwnerType: Enum "JML AP Owner Type"; OwnerCode: Code[20]): Text[100]
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Employee: Record Employee;
        RespCenter: Record "Responsibility Center";
        CompanyInfo: Record "Company Information";
    begin
        if OwnerCode = '' then
            exit('');

        case OwnerType of
            OwnerType::"Our Company":
                if CompanyInfo.Get() then
                    exit(CompanyInfo.Name)
                else
                    exit('Our Company');
            OwnerType::Customer:
                if Customer.Get(OwnerCode) then
                    exit(Customer.Name);
            OwnerType::Vendor:
                if Vendor.Get(OwnerCode) then
                    exit(Vendor.Name);
            OwnerType::Employee:
                if Employee.Get(OwnerCode) then
                    exit(Employee."First Name" + ' ' + Employee."Last Name");
            OwnerType::"Responsibility Center":
                if RespCenter.Get(OwnerCode) then
                    exit(RespCenter.Name);
        end;

        exit('');
    end;

    local procedure ValidateAssetCanBeDeleted()
    var
        ChildAsset: Record "JML AP Asset";
        HolderEntry: Record "JML AP Holder Entry";
    begin
        // Cannot delete if has children
        ChildAsset.SetRange("Parent Asset No.", "No.");
        if not ChildAsset.IsEmpty then
            Error(CannotDeleteWithChildrenErr, "No.");

        // Cannot delete if holder history entries exist
        HolderEntry.SetRange("Asset No.", "No.");
        if not HolderEntry.IsEmpty then
            Error(CannotDeleteWithHolderHistoryErr, "No.");
    end;

    local procedure DeleteRelatedRecords()
    var
        AttributeValue: Record "JML AP Attribute Value";
    begin
        // Delete attribute values
        AttributeValue.SetRange("Asset No.", "No.");
        if not AttributeValue.IsEmpty then
            AttributeValue.DeleteAll(true);
    end;

    /// <summary>
    /// Gets the full classification path from root to current classification.
    /// </summary>
    /// <returns>Full path like "Commercial / Cargo Ship / Panamax"</returns>
    procedure GetClassificationPath(): Text[250]
    var
        ClassValue: Record "JML AP Classification Val";
        Path: Text[250];
        CurrentCode: Code[20];
        CurrentLevelNo: Integer;
        Separator: Text[3];
    begin
        if "Classification Code" = '' then
            exit('');

        CalcFields("Classification Level No.");
        CurrentCode := "Classification Code";
        CurrentLevelNo := "Classification Level No.";
        Separator := ' / ';

        // Build path from current up to root
        while (CurrentCode <> '') and (CurrentLevelNo > 0) do
            if ClassValue.Get("Industry Code", CurrentLevelNo, CurrentCode) then begin
                if Path = '' then
                    Path := CopyStr(ClassValue.Description, 1, 250)
                else
                    Path := CopyStr(ClassValue.Description + Separator + Path, 1, 250);

                CurrentCode := ClassValue."Parent Value Code";
                CurrentLevelNo -= 1;
            end else
                CurrentCode := '';

        exit(Path);
    end;

    /// <summary>
    /// Gets classification value at a specific parent level.
    /// </summary>
    /// <param name="LevelNo">The level to retrieve (1 = root)</param>
    /// <returns>Classification code at that level, or empty if not applicable</returns>
    procedure GetClassificationAtLevel(LevelNo: Integer): Code[20]
    var
        ClassValue: Record "JML AP Classification Val";
        CurrentCode: Code[20];
        CurrentLevelNo: Integer;
    begin
        if "Classification Code" = '' then
            exit('');

        CalcFields("Classification Level No.");

        // If requested level is deeper than asset's classification, return empty
        if LevelNo > "Classification Level No." then
            exit('');

        // If requested level is the current level, return it
        if LevelNo = "Classification Level No." then
            exit("Classification Code");

        // Walk up the tree to find the requested level
        CurrentCode := "Classification Code";
        CurrentLevelNo := "Classification Level No.";

        while (CurrentCode <> '') and (CurrentLevelNo > LevelNo) do
            if ClassValue.Get("Industry Code", CurrentLevelNo, CurrentCode) then begin
                CurrentCode := ClassValue."Parent Value Code";
                CurrentLevelNo -= 1;
            end else
                CurrentCode := '';

        if CurrentLevelNo = LevelNo then
            exit(CurrentCode)
        else
            exit('');
    end;

    /// <summary>
    /// Checks if this asset is classified under a specific parent classification.
    /// </summary>
    /// <param name="ParentClassCode">The parent classification code to check</param>
    /// <returns>True if asset's classification is under this parent</returns>
    procedure IsClassifiedUnder(ParentClassCode: Code[20]): Boolean
    var
        ClassValue: Record "JML AP Classification Val";
        CurrentCode: Code[20];
        MaxIterations: Integer;
        Iterations: Integer;
    begin
        if ("Classification Code" = '') or (ParentClassCode = '') then
            exit(false);

        if "Classification Code" = ParentClassCode then
            exit(true);

        CalcFields("Classification Level No.");
        CurrentCode := "Classification Code";
        MaxIterations := 50; // Safety limit
        Iterations := 0;

        // Walk up parent chain
        while (CurrentCode <> '') and (Iterations < MaxIterations) do begin
            if ClassValue.Get("Industry Code", ClassValue."Level Number", CurrentCode) then begin
                if ClassValue."Parent Value Code" = ParentClassCode then
                    exit(true);
                CurrentCode := ClassValue."Parent Value Code";
            end else
                CurrentCode := '';

            Iterations += 1;
        end;

        exit(false);
    end;

    local procedure RegisterManualHolderChange()
    var
        AssetJnlPost: Codeunit "JML AP Asset Jnl.-Post";
    begin
        // Check if holder fields changed
        if (xRec."Current Holder Type" = "Current Holder Type") and
           (xRec."Current Holder Code" = "Current Holder Code")
        then
            exit; // No holder change

        // Skip if new holder code is empty (incomplete user input - user is still configuring)
        // This prevents premature journal posting when only Type is changed but Code not yet set
        if "Current Holder Code" = '' then
            exit;

        // Get setup
        AssetSetup.GetRecordOnce();

        // R7: Block manual holder change if enabled
        if AssetSetup."Block Manual Holder Change" then
            Error(ManualHolderChangeBlockedErr);

        // R8: Auto-register manual holder change via journal
        // This includes initial holder assignment
        // Pass OLD holder values (xRec) and NEW holder values (Rec)
        AssetJnlPost.CreateAndPostManualChange(
            Rec,
            xRec."Current Holder Type",
            xRec."Current Holder Code",
            xRec."Current Holder Addr Code",
            "Current Holder Type",
            "Current Holder Code",
            "Current Holder Addr Code");
    end;

    // === CONSTANTS ===
    var
        CannotDeleteWithChildrenErr: Label 'Cannot delete asset %1 because it has child assets.', Comment = '%1 = Asset No.';
        CannotDeleteWithHolderHistoryErr: Label 'Cannot delete asset %1 because it has holder history entries.', Comment = '%1 = Asset No.';
        ClassificationNotFoundErr: Label 'Classification %1 does not exist in industry %2.', Comment = '%1 = Classification Code, %2 = Industry Code';
        ManualHolderChangeBlockedErr: Label 'Manual holder changes are blocked in setup. Use Asset Journal or Transfer Orders to change holders.';
        DifferentHolderErr: Label 'Cannot assign asset %1 to parent %2. Parent is at %3 %4, but child is at different holder. Both assets must be at same location to create parent-child relationship.', Comment = '%1 = Child Asset No., %2 = Parent Asset No., %3 = Parent Holder Type, %4 = Parent Holder Code';
        NoParentToDetachErr: Label 'This asset is not attached to a parent.';

    local procedure GetMaxParentChainDepth(): Integer
    begin
        exit(100);
    end;
}
