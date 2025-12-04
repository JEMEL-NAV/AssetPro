page 70182373 "JML AP Change Holder Dialog"
{
    PageType = StandardDialog;
    Caption = 'Change Asset Holder';
    Description = 'Dialog for changing the current holder of selected assets with transfer date and reason.';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(CurrentHolder)
            {
                Caption = 'Current Holder';
                Editable = false;

                field(OldHolderType; OldHolderType)
                {
                    Caption = 'Type';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the current holder type.';
                    Editable = false;
                }
                field(OldHolderCode; OldHolderCode)
                {
                    Caption = 'Code';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the current holder code.';
                    Editable = false;
                }
                field(OldHolderAddrCode; OldHolderAddrCode)
                {
                    Caption = 'Address Code';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the current ship-to address code (for customers) or order address code (for vendors).';
                    Editable = false;
                }
                field(OldHolderName; OldHolderName)
                {
                    Caption = 'Name';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the current holder name.';
                    Editable = false;
                }
            }

            group(NewHolder)
            {
                Caption = 'New Holder';

                field(NewHolderType; NewHolderType)
                {
                    Caption = 'Type';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the new holder type.';

                    trigger OnValidate()
                    begin
                        if NewHolderType <> xNewHolderType then begin
                            NewHolderCode := '';
                            NewHolderAddrCode := '';
                            xNewHolderType := NewHolderType;
                        end;
                    end;
                }
                field(NewHolderCode; NewHolderCode)
                {
                    Caption = 'Code';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the new holder code.';

                    trigger OnValidate()
                    var
                        Customer: Record Customer;
                        Vendor: Record Vendor;
                        Location: Record Location;
                    begin
                        if NewHolderCode <> xNewHolderCode then begin
                            NewHolderAddrCode := '';
                            xNewHolderCode := NewHolderCode;
                        end;

                        // Update holder name
                        NewHolderName := '';
                        case NewHolderType of
                            NewHolderType::Customer:
                                if Customer.Get(NewHolderCode) then
                                    NewHolderName := Customer.Name;
                            NewHolderType::Vendor:
                                if Vendor.Get(NewHolderCode) then
                                    NewHolderName := Vendor.Name;
                            NewHolderType::Location:
                                if Location.Get(NewHolderCode) then
                                    NewHolderName := Location.Name;
                        end;
                    end;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Customer: Record Customer;
                        Vendor: Record Vendor;
                        Location: Record Location;
                    begin
                        case NewHolderType of
                            NewHolderType::Customer:
                                if Page.RunModal(Page::"Customer List", Customer) = Action::LookupOK then begin
                                    NewHolderCode := Customer."No.";
                                    NewHolderName := Customer.Name;
                                end;
                            NewHolderType::Vendor:
                                if Page.RunModal(Page::"Vendor List", Vendor) = Action::LookupOK then begin
                                    NewHolderCode := Vendor."No.";
                                    NewHolderName := Vendor.Name;
                                end;
                            NewHolderType::Location:
                                if Page.RunModal(Page::"Location List", Location) = Action::LookupOK then begin
                                    NewHolderCode := Location.Code;
                                    NewHolderName := Location.Name;
                                end;
                        end;
                    end;
                }

                field(NewHolderAddrCode; NewHolderAddrCode)
                {
                    Caption = 'Address Code';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the ship-to address code (for customers) or order address code (for vendors).';

                    trigger OnValidate()
                    begin
                        // Clear address code if holder type doesn't support addresses
                        if not (NewHolderType in [NewHolderType::Customer, NewHolderType::Vendor]) then
                            NewHolderAddrCode := '';
                    end;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ShipToAddress: Record "Ship-to Address";
                        OrderAddress: Record "Order Address";
                    begin
                        case NewHolderType of
                            NewHolderType::Customer:
                                begin
                                    ShipToAddress.SetRange("Customer No.", NewHolderCode);
                                    if Page.RunModal(Page::"Ship-to Address List", ShipToAddress) = Action::LookupOK then
                                        NewHolderAddrCode := ShipToAddress.Code;
                                end;
                            NewHolderType::Vendor:
                                begin
                                    OrderAddress.SetRange("Vendor No.", NewHolderCode);
                                    if Page.RunModal(Page::"Order Address List", OrderAddress) = Action::LookupOK then
                                        NewHolderAddrCode := OrderAddress.Code;
                                end;
                        end;
                    end;
                }
                field(NewHolderName; NewHolderName)
                {
                    Caption = 'Name';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the new holder name.';
                    Editable = false;
                }
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Asset: Record "JML AP Asset";
        AssetJnlPost: Codeunit "JML AP Asset Jnl.-Post";
    begin
        // Only process on OK action (not on Cancel or other close actions)
        if CloseAction <> Action::OK then
            exit(true);

        // Validate new holder values
        ValidateNewHolder();

        // Get asset record
        if not Asset.Get(AssetNo) then
            Error(AssetNotFoundErr, AssetNo);

        // Post holder change via journal (R8)
        AssetJnlPost.CreateAndPostManualChange(
            Asset,
            OldHolderType,
            OldHolderCode,
            OldHolderAddrCode,
            NewHolderType,
            NewHolderCode,
            NewHolderAddrCode);

        exit(true);
    end;

    var
        OldHolderType: Enum "JML AP Holder Type";
        OldHolderCode: Code[20];
        OldHolderName: Text[100];
        OldHolderAddrCode: Code[10];
        NewHolderType: Enum "JML AP Holder Type";
        NewHolderCode: Code[20];
        NewHolderName: Text[100];
        NewHolderAddrCode: Code[10];
        xNewHolderType: Enum "JML AP Holder Type";
        xNewHolderCode: Code[20];
        AssetNo: Code[20];
        SameHolderErr: Label 'The new holder must be different from the current holder.';
        NewHolderNotSpecifiedErr: Label 'You must specify the new holder type and code.';
        AssetNotFoundErr: Label 'Asset %1 not found.', Comment = '%1 = Asset No.';

    /// <summary>
    /// Sets the current holder values to display in the dialog.
    /// </summary>
    procedure SetOldHolder(HolderType: Enum "JML AP Holder Type"; HolderCode: Code[20]; HolderName: Text[100]; HolderAddrCode: Code[10])
    begin
        OldHolderType := HolderType;
        OldHolderCode := HolderCode;
        OldHolderName := HolderName;
        OldHolderAddrCode := HolderAddrCode;

        // Initialize new holder with old values
        NewHolderType := HolderType;
        NewHolderCode := HolderCode;
        NewHolderName := HolderName;
        NewHolderAddrCode := HolderAddrCode;
        xNewHolderType := HolderType;
        xNewHolderCode := HolderCode;
    end;

    /// <summary>
    /// Sets the asset number for the holder change.
    /// </summary>
    procedure SetAssetNo(NewAssetNo: Code[20])
    begin
        AssetNo := NewAssetNo;
    end;

    local procedure ValidateNewHolder()
    begin
        // Validate new holder is specified
        if (NewHolderType = OldHolderType::" ") or (NewHolderCode = '') then
            Error(NewHolderNotSpecifiedErr);

        // Validate new holder is different from old holder
        if (NewHolderType = OldHolderType) and
           (NewHolderCode = OldHolderCode) and
           (NewHolderAddrCode = OldHolderAddrCode)
        then
            Error(SameHolderErr);
    end;
}
