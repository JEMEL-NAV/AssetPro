codeunit 50126 "JML AP Test Library"
{
    // ============================================================================
    // CENTRALIZED TEST LIBRARY
    // Provides reusable helper functions for all Asset Pro test codeunits
    // Created: 2025-12-23 as part of EPIC 7: Test Infrastructure Improvements
    // ============================================================================

    // ============================================================================
    // MODULE 1: Setup & Configuration
    // ============================================================================

    var
        IsInitialized: Boolean;

    procedure Initialize()
    var
        AssetSetup: Record "JML AP Asset Setup";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        InTransitLoc: Record Location;
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        // BC Test Framework provides automatic test isolation
        // Each test gets a clean database state and changes roll back automatically

        if IsInitialized then
            exit;

        // Ensure Asset Setup exists with number series
        EnsureSetupExists(AssetSetup);

        // Create number series if not exists or empty
        if AssetSetup."Asset Nos." = '' then begin
            CreateTestNumberSeries(NoSeries, NoSeriesLine, 'TEST-ASSET', 'TST-A-00001', 'TST-A-99999');
            AssetSetup.Validate("Asset Nos.", NoSeries.Code);
            AssetSetup.Modify(true);
        end;

        // Create Transfer Order number series if not exists or empty
        if AssetSetup."Transfer Order Nos." = '' then begin
            CreateTestNumberSeries(NoSeries, NoSeriesLine, 'TEST-TRANS', 'TST-T-00001', 'TST-T-99999');
            AssetSetup.Validate("Transfer Order Nos.", NoSeries.Code);
            AssetSetup.Modify(true);
        end;

        // Create Posted Transfer number series if not exists or empty
        if AssetSetup."Posted Transfer Nos." = '' then begin
            CreateTestNumberSeries(NoSeries, NoSeriesLine, 'TEST-PSTTR', 'TST-PT-00001', 'TST-PT-99999');
            AssetSetup.Validate("Posted Transfer Nos.", NoSeries.Code);
            AssetSetup.Modify(true);
        end;

        // Create In-Transit location required for Transfer Orders (reused across tests)
        if not InTransitLoc.Get('INTRANS') then begin
            InTransitLoc.Init();
            InTransitLoc.Code := 'INTRANS';
            InTransitLoc.Name := 'In-Transit';
            InTransitLoc."Use As In-Transit" := true;
            InTransitLoc.Insert(true);

            // Create Inventory Posting Setup for INTRANS location
            if not InventoryPostingSetup.Get('INTRANS', 'RESALE') then begin
                InventoryPostingSetup.Init();
                InventoryPostingSetup."Location Code" := 'INTRANS';
                InventoryPostingSetup."Invt. Posting Group Code" := 'RESALE';
                InventoryPostingSetup."Inventory Account" := '2130';
                InventoryPostingSetup.Insert(true);
            end;
        end;

        IsInitialized := true;
        Commit(); // Commit setup data so it's available across test isolation boundaries
    end;

    procedure EnsureSetupExists(var AssetSetup: Record "JML AP Asset Setup")
    begin
        if not AssetSetup.Get() then begin
            AssetSetup.Init();
            AssetSetup.Insert(true);
        end;
    end;

    local procedure CreateTestNumberSeries(var NoSeries: Record "No. Series"; var NoSeriesLine: Record "No. Series Line"; SeriesCode: Code[20]; StartingNo: Code[20]; EndingNo: Code[20])
    begin
        NoSeries.Init();
        NoSeries.Code := SeriesCode;
        NoSeries.Description := 'Test Number Series ' + SeriesCode;
        NoSeries."Default Nos." := true;
        if not NoSeries.Insert() then
            NoSeries.Modify();

        NoSeriesLine.SetRange("Series Code", NoSeries.Code);
        if not NoSeriesLine.FindFirst() then begin
            NoSeriesLine.Init();
            NoSeriesLine."Series Code" := NoSeries.Code;
            NoSeriesLine."Line No." := 10000;
            NoSeriesLine."Starting No." := StartingNo;
            NoSeriesLine."Ending No." := EndingNo;
            NoSeriesLine."Increment-by No." := 1;
            NoSeriesLine.Insert();
        end;
    end;

    procedure GetNextTestNumber(Prefix: Code[5]): Code[20]
    begin
        // Generate unique test number using GUID
        exit(CopyStr(Prefix + '-' + Format(CreateGuid()), 1, 20));
    end;

    // ============================================================================
    // MODULE 2: Entity Creation - Master Data
    // ============================================================================

    procedure CreateTestAsset(Description: Text[100]): Record "JML AP Asset"
    var
        Asset: Record "JML AP Asset";
        AssetSetup: Record "JML AP Asset Setup";
    begin
        EnsureSetupExists(AssetSetup);

        Asset.Init();
        Asset.Validate(Description, CopyStr(Description, 1, MaxStrLen(Asset.Description)));
        Asset.Insert(true);
        exit(Asset);
    end;

    procedure CreateTestLocation(LocationCode: Code[10]): Record Location
    var
        Location: Record Location;
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        if Location.Get(LocationCode) then
            exit(Location);

        Location.Init();
        Location.Code := LocationCode;
        Location.Name := 'Test Location ' + LocationCode;
        Location.Insert(true);

        // Create Inventory Posting Setup for this location if it doesn't exist
        if not InventoryPostingSetup.Get(LocationCode, 'RESALE') then begin
            InventoryPostingSetup.Init();
            InventoryPostingSetup."Location Code" := LocationCode;
            InventoryPostingSetup."Invt. Posting Group Code" := 'RESALE';
            InventoryPostingSetup."Inventory Account" := '2130'; // Standard Inventory GL account
            InventoryPostingSetup.Insert(true);
        end;

        exit(Location);
    end;

    procedure CreateTestCustomer(Name: Text[100]): Record Customer
    var
        Customer: Record Customer;
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        // Ensure posting groups exist
        if not GenBusPostingGroup.Get('DOMESTIC') then begin
            GenBusPostingGroup.Init();
            GenBusPostingGroup.Code := 'DOMESTIC';
            GenBusPostingGroup.Description := 'Domestic';
            GenBusPostingGroup.Insert(true);
        end;

        if not CustomerPostingGroup.Get('DOMESTIC') then begin
            CustomerPostingGroup.Init();
            CustomerPostingGroup.Code := 'DOMESTIC';
            CustomerPostingGroup.Description := 'Domestic customers';
            CustomerPostingGroup."Receivables Account" := '1300'; // Standard receivables account
            CustomerPostingGroup.Insert(true);
        end;

        Customer.Init();
        Customer."No." := GetNextTestNumber('CUST');
        Customer.Name := CopyStr(Name, 1, MaxStrLen(Customer.Name));
        Customer."Gen. Bus. Posting Group" := 'DOMESTIC';
        Customer."Customer Posting Group" := 'DOMESTIC';
        Customer.Insert(true);
        exit(Customer);
    end;

    procedure CreateTestVendor(Name: Text[100]): Record Vendor
    var
        Vendor: Record Vendor;
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        // Ensure posting groups exist
        if not GenBusPostingGroup.Get('DOMESTIC') then begin
            GenBusPostingGroup.Init();
            GenBusPostingGroup.Code := 'DOMESTIC';
            GenBusPostingGroup.Description := 'Domestic';
            GenBusPostingGroup.Insert(true);
        end;

        if not VendorPostingGroup.Get('DOMESTIC') then begin
            VendorPostingGroup.Init();
            VendorPostingGroup.Code := 'DOMESTIC';
            VendorPostingGroup.Description := 'Domestic vendors';
            VendorPostingGroup."Payables Account" := '2300'; // Standard payables account
            VendorPostingGroup.Insert(true);
        end;

        Vendor.Init();
        Vendor."No." := GetNextTestNumber('VEND');
        Vendor.Name := CopyStr(Name, 1, MaxStrLen(Vendor.Name));
        Vendor."Gen. Bus. Posting Group" := 'DOMESTIC';
        Vendor."Vendor Posting Group" := 'DOMESTIC';
        Vendor.Insert(true);
        exit(Vendor);
    end;

    procedure CreateTestEmployee(FirstName: Text[30]; LastName: Text[30]): Record Employee
    var
        Employee: Record Employee;
    begin
        Employee.Init();
        Employee."No." := GetNextTestNumber('EMP');
        Employee."First Name" := CopyStr(FirstName, 1, MaxStrLen(Employee."First Name"));
        Employee."Last Name" := CopyStr(LastName, 1, MaxStrLen(Employee."Last Name"));
        Employee.Insert(true);
        exit(Employee);
    end;

    procedure CreateTestItem(Description: Text[100]): Record Item
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        // Create Unit of Measure if it doesn't exist
        if not UnitOfMeasure.Get('PCS') then begin
            UnitOfMeasure.Init();
            UnitOfMeasure.Code := 'PCS';
            UnitOfMeasure.Description := 'Pieces';
            UnitOfMeasure.Insert(true);
        end;

        Item.Init();
        Item."No." := GetNextTestNumber('ITEM');
        Item.Description := CopyStr(Description, 1, MaxStrLen(Item.Description));
        Item.Type := Item.Type::Inventory;
        Item."Base Unit of Measure" := 'PCS';
        Item."Gen. Prod. Posting Group" := 'RETAIL';
        Item."Inventory Posting Group" := 'RESALE';
        Item.Insert(true);

        // Create Item Unit of Measure record
        if not ItemUnitOfMeasure.Get(Item."No.", 'PCS') then begin
            ItemUnitOfMeasure.Init();
            ItemUnitOfMeasure."Item No." := Item."No.";
            ItemUnitOfMeasure.Code := 'PCS';
            ItemUnitOfMeasure."Qty. per Unit of Measure" := 1;
            ItemUnitOfMeasure.Insert(true);
        end;

        exit(Item);
    end;

    procedure CreateTestResponsibilityCenter(Name: Text[100]): Record "Responsibility Center"
    var
        RespCenter: Record "Responsibility Center";
    begin
        RespCenter.Init();
        RespCenter.Code := CopyStr(GetNextTestNumber('RC'), 1, MaxStrLen(RespCenter.Code));
        RespCenter.Name := CopyStr(Name, 1, MaxStrLen(RespCenter.Name));
        RespCenter.Insert(true);
        exit(RespCenter);
    end;

    // ============================================================================
    // MODULE 3: Specialized Asset Creation
    // ============================================================================

    procedure CreateAssetAtLocation(Description: Text[100]; LocationCode: Code[10]): Record "JML AP Asset"
    var
        Asset: Record "JML AP Asset";
        AssetSetup: Record "JML AP Asset Setup";
    begin
        EnsureSetupExists(AssetSetup);

        Asset.Init();
        Asset.Validate(Description, CopyStr(Description, 1, MaxStrLen(Asset.Description)));
        Asset."Current Holder Type" := Asset."Current Holder Type"::Location;
        Asset."Current Holder Code" := LocationCode;
        Asset.Insert(true);
        exit(Asset);
    end;

    procedure CreateAssetAtCustomer(Description: Text[100]; CustomerNo: Code[20]): Record "JML AP Asset"
    var
        Asset: Record "JML AP Asset";
        AssetSetup: Record "JML AP Asset Setup";
    begin
        EnsureSetupExists(AssetSetup);

        Asset.Init();
        Asset.Validate(Description, CopyStr(Description, 1, MaxStrLen(Asset.Description)));
        Asset."Current Holder Type" := Asset."Current Holder Type"::Customer;
        Asset."Current Holder Code" := CustomerNo;
        Asset.Insert(true);
        exit(Asset);
    end;

    procedure CreateAssetAtVendor(Description: Text[100]; VendorNo: Code[20]): Record "JML AP Asset"
    var
        Asset: Record "JML AP Asset";
        AssetSetup: Record "JML AP Asset Setup";
    begin
        EnsureSetupExists(AssetSetup);

        Asset.Init();
        Asset.Validate(Description, CopyStr(Description, 1, MaxStrLen(Asset.Description)));
        Asset."Current Holder Type" := Asset."Current Holder Type"::Vendor;
        Asset."Current Holder Code" := VendorNo;
        Asset.Insert(true);
        exit(Asset);
    end;

    procedure CreateAssetWithParent(Description: Text[100]; ParentAssetNo: Code[20]): Record "JML AP Asset"
    var
        Asset: Record "JML AP Asset";
        ParentAsset: Record "JML AP Asset";
        AssetSetup: Record "JML AP Asset Setup";
    begin
        EnsureSetupExists(AssetSetup);

        // Get parent asset to inherit holder info
        ParentAsset.Get(ParentAssetNo);

        Asset.Init();
        Asset.Validate(Description, CopyStr(Description, 1, MaxStrLen(Asset.Description)));
        Asset."Parent Asset No." := ParentAssetNo;
        Asset."Current Holder Type" := ParentAsset."Current Holder Type";
        Asset."Current Holder Code" := ParentAsset."Current Holder Code";
        Asset.Insert(true);
        exit(Asset);
    end;

    // ============================================================================
    // MODULE 4: Document Creation
    // ============================================================================

    procedure CreateSalesOrderHeader(CustomerNo: Code[20]): Record "Sales Header"
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader."No." := '';
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", CustomerNo);
        SalesHeader.Modify(true);
        exit(SalesHeader);
    end;

    procedure CreateSalesReturnOrderHeader(CustomerNo: Code[20]): Record "Sales Header"
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::"Return Order";
        SalesHeader."No." := '';
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", CustomerNo);
        SalesHeader.Modify(true);
        exit(SalesHeader);
    end;

    procedure CreatePurchaseOrderHeader(VendorNo: Code[20]): Record "Purchase Header"
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchHeader.Init();
        PurchHeader."Document Type" := PurchHeader."Document Type"::Order;
        PurchHeader."No." := '';
        PurchHeader.Insert(true);
        PurchHeader.Validate("Buy-from Vendor No.", VendorNo);
        PurchHeader.Modify(true);
        exit(PurchHeader);
    end;

    procedure CreatePurchaseReturnOrderHeader(VendorNo: Code[20]): Record "Purchase Header"
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchHeader.Init();
        PurchHeader."Document Type" := PurchHeader."Document Type"::"Return Order";
        PurchHeader."No." := '';
        PurchHeader.Insert(true);
        PurchHeader.Validate("Buy-from Vendor No.", VendorNo);
        PurchHeader.Modify(true);
        exit(PurchHeader);
    end;

    procedure CreateTransferOrderHeader(FromLoc: Code[10]; ToLoc: Code[10]): Record "Transfer Header"
    var
        TransferHeader: Record "Transfer Header";
    begin
        TransferHeader.Init();
        TransferHeader."No." := '';
        TransferHeader.Insert(true);
        TransferHeader.Validate("Transfer-from Code", FromLoc);
        TransferHeader.Validate("Transfer-to Code", ToLoc);
        TransferHeader.Validate("In-Transit Code", 'INTRANS'); // Use standard in-transit location
        TransferHeader.Modify(true);
        exit(TransferHeader);
    end;

    procedure AddDummyItemLine(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        // Add minimal item line to satisfy BC posting requirements
        Item := CreateTestItem('Dummy Item');

        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := 10000;
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine.Validate("No.", Item."No.");
        SalesLine.Validate(Quantity, 1);
        if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then
            SalesLine.Validate("Qty. to Ship", 1)
        else
            SalesLine.Validate("Return Qty. to Receive", 1);
        SalesLine.Insert(true);
    end;

    procedure AddDummyItemLine(var PurchHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
        Item: Record Item;
    begin
        // Add minimal item line to satisfy BC posting requirements
        Item := CreateTestItem('Dummy Item');

        PurchLine.Init();
        PurchLine."Document Type" := PurchHeader."Document Type";
        PurchLine."Document No." := PurchHeader."No.";
        PurchLine."Line No." := 10000;
        PurchLine.Type := PurchLine.Type::Item;
        PurchLine.Validate("No.", Item."No.");
        PurchLine.Validate(Quantity, 1);
        if PurchHeader."Document Type" = PurchHeader."Document Type"::Order then
            PurchLine.Validate("Qty. to Receive", 1)
        else
            PurchLine.Validate("Return Qty. to Ship", 1);
        PurchLine.Insert(true);
    end;

    procedure AddDummyTransferLine(var TransferHeader: Record "Transfer Header")
    var
        TransferLine: Record "Transfer Line";
        Item: Record Item;
    begin
        // Add minimal item line to satisfy BC posting requirements
        Item := CreateTestItem('Dummy Item');

        TransferLine.Init();
        TransferLine."Document No." := TransferHeader."No.";
        TransferLine."Line No." := 10000;
        TransferLine.Validate("Item No.", Item."No.");
        TransferLine.Validate(Quantity, 1);
        TransferLine.Validate("Qty. to Ship", 1);
        TransferLine.Insert(true);
    end;

    procedure AddSalesAssetLine(var SalesHeader: Record "Sales Header"; AssetNo: Code[20]; LineNo: Integer): Record "JML AP Sales Asset Line"
    var
        SalesAssetLine: Record "JML AP Sales Asset Line";
    begin
        SalesAssetLine.Init();
        SalesAssetLine."Document Type" := SalesHeader."Document Type";
        SalesAssetLine."Document No." := SalesHeader."No.";
        SalesAssetLine."Line No." := LineNo;
        SalesAssetLine.Validate("Asset No.", AssetNo);
        if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then
            SalesAssetLine."Quantity to Ship" := 1
        else
            SalesAssetLine."Quantity to Receive" := 1;
        SalesAssetLine.Insert(true);
        exit(SalesAssetLine);
    end;

    procedure AddPurchaseAssetLine(var PurchHeader: Record "Purchase Header"; AssetNo: Code[20]; LineNo: Integer): Record "JML AP Purch. Asset Line"
    var
        PurchAssetLine: Record "JML AP Purch. Asset Line";
    begin
        PurchAssetLine.Init();
        PurchAssetLine."Document Type" := PurchHeader."Document Type";
        PurchAssetLine."Document No." := PurchHeader."No.";
        PurchAssetLine."Line No." := LineNo;
        PurchAssetLine.Validate("Asset No.", AssetNo);
        if PurchHeader."Document Type" = PurchHeader."Document Type"::Order then
            PurchAssetLine."Quantity to Receive" := 1
        else
            PurchAssetLine."Quantity to Ship" := 1;
        PurchAssetLine.Insert(true);
        exit(PurchAssetLine);
    end;

    procedure PostSalesShipment(var SalesHeader: Record "Sales Header"): Code[20]
    var
        SalesPost: Codeunit "Sales-Post";
        SalesShptHeader: Record "Sales Shipment Header";
    begin
        SalesHeader.Ship := true;
        SalesHeader.Invoice := false;
        SalesPost.Run(SalesHeader);

        SalesShptHeader.SetRange("Order No.", SalesHeader."No.");
        if SalesShptHeader.FindFirst() then
            exit(SalesShptHeader."No.");

        exit('');
    end;

    procedure PostSalesReturnReceipt(var SalesHeader: Record "Sales Header"): Code[20]
    var
        SalesPost: Codeunit "Sales-Post";
        ReturnRcptHeader: Record "Return Receipt Header";
    begin
        SalesHeader.Receive := true;
        SalesHeader.Invoice := false;
        SalesPost.Run(SalesHeader);

        ReturnRcptHeader.SetRange("Return Order No.", SalesHeader."No.");
        if ReturnRcptHeader.FindFirst() then
            exit(ReturnRcptHeader."No.");

        exit('');
    end;

    procedure PostPurchaseReceipt(var PurchHeader: Record "Purchase Header"): Code[20]
    var
        PurchPost: Codeunit "Purch.-Post";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        PurchHeader.Receive := true;
        PurchHeader.Invoice := false;
        PurchPost.Run(PurchHeader);

        PurchRcptHeader.SetRange("Order No.", PurchHeader."No.");
        if PurchRcptHeader.FindFirst() then
            exit(PurchRcptHeader."No.");

        exit('');
    end;

    procedure PostPurchaseReturnShipment(var PurchHeader: Record "Purchase Header"): Code[20]
    var
        PurchPost: Codeunit "Purch.-Post";
        ReturnShptHeader: Record "Return Shipment Header";
    begin
        PurchHeader.Ship := true;
        PurchHeader.Invoice := false;
        PurchPost.Run(PurchHeader);

        ReturnShptHeader.SetRange("Return Order No.", PurchHeader."No.");
        if ReturnShptHeader.FindFirst() then
            exit(ReturnShptHeader."No.");

        exit('');
    end;

    // ============================================================================
    // MODULE 5: Assertion Helpers
    // ============================================================================

    procedure AssertHolderEntryExists(AssetNo: Code[20]; ExpectedCount: Integer)
    var
        HolderEntry: Record "JML AP Holder Entry";
        LibraryAssert: Codeunit "Library Assert";
    begin
        HolderEntry.SetRange("Asset No.", AssetNo);
        LibraryAssert.RecordCount(HolderEntry, ExpectedCount);
    end;

    procedure AssertAssetAtHolder(AssetNo: Code[20]; HolderType: Enum "JML AP Holder Type"; HolderCode: Code[20])
    var
        Asset: Record "JML AP Asset";
        LibraryAssert: Codeunit "Library Assert";
    begin
        Asset.Get(AssetNo);
        LibraryAssert.AreEqual(HolderType, Asset."Current Holder Type", 'Asset holder type mismatch');
        LibraryAssert.AreEqual(HolderCode, Asset."Current Holder Code", 'Asset holder code mismatch');
    end;

    procedure AssertPostedAssetLineExists(DocumentNo: Code[20]; AssetNo: Code[20])
    var
        PostedSalesAssetLine: Record "JML AP Pstd Sales Shpt Ast Ln";
        PostedPurchAssetLine: Record "JML AP Pstd Purch Rcpt Ast Ln";
        LibraryAssert: Codeunit "Library Assert";
        Found: Boolean;
    begin
        // Try sales shipment lines
        PostedSalesAssetLine.SetRange("Document No.", DocumentNo);
        PostedSalesAssetLine.SetRange("Asset No.", AssetNo);
        Found := PostedSalesAssetLine.FindFirst();

        if not Found then begin
            // Try purchase receipt lines
            PostedPurchAssetLine.SetRange("Document No.", DocumentNo);
            PostedPurchAssetLine.SetRange("Asset No.", AssetNo);
            Found := PostedPurchAssetLine.FindFirst();
        end;

        LibraryAssert.IsTrue(Found, 'Posted asset line should exist for document ' + DocumentNo + ' and asset ' + AssetNo);
    end;

    procedure AssertAssetHasParent(AssetNo: Code[20]; ParentAssetNo: Code[20])
    var
        Asset: Record "JML AP Asset";
        LibraryAssert: Codeunit "Library Assert";
    begin
        Asset.Get(AssetNo);
        LibraryAssert.AreEqual(ParentAssetNo, Asset."Parent Asset No.", 'Asset should have correct parent');
    end;

    procedure AssertTransactionNoLinked(AssetNo: Code[20]; TransactionNo: Integer)
    var
        HolderEntry: Record "JML AP Holder Entry";
        LibraryAssert: Codeunit "Library Assert";
    begin
        HolderEntry.SetRange("Asset No.", AssetNo);
        HolderEntry.SetRange("Transaction No.", TransactionNo);
        LibraryAssert.IsTrue(HolderEntry.Count > 0, 'Holder entries should exist for transaction ' + Format(TransactionNo));
    end;

    // ============================================================================
    // MODULE 7: Industry and Classification Setup
    // ============================================================================

    procedure CreateIndustry(IndustryCode: Code[20]; IndustryName: Text[100]): Record "JML AP Asset Industry"
    var
        Industry: Record "JML AP Asset Industry";
    begin
        if Industry.Get(IndustryCode) then begin
            Industry.Name := CopyStr(IndustryName, 1, MaxStrLen(Industry.Name));
            Industry.Modify(true);
            exit(Industry);
        end;

        Industry.Init();
        Industry.Code := IndustryCode;
        Industry.Name := CopyStr(IndustryName, 1, MaxStrLen(Industry.Name));
        Industry.Insert(true);
        exit(Industry);
    end;

    procedure CreateClassificationLevel(IndustryCode: Code[20]; LevelNo: Integer; LevelName: Text[100]): Record "JML AP Classification Lvl"
    var
        ClassLevel: Record "JML AP Classification Lvl";
    begin
        if ClassLevel.Get(IndustryCode, LevelNo) then begin
            ClassLevel."Level Name" := CopyStr(LevelName, 1, MaxStrLen(ClassLevel."Level Name"));
            ClassLevel.Modify(true);
            exit(ClassLevel);
        end;

        ClassLevel.Init();
        ClassLevel."Industry Code" := IndustryCode;
        ClassLevel."Level Number" := LevelNo;
        ClassLevel."Level Name" := CopyStr(LevelName, 1, MaxStrLen(ClassLevel."Level Name"));
        ClassLevel.Insert(true);
        exit(ClassLevel);
    end;

    procedure CreateClassificationValue(IndustryCode: Code[20]; LevelNo: Integer; ValueCode: Code[20]; ValueDesc: Text[100]; ParentCode: Code[20]; ParentLevelNo: Integer): Record "JML AP Classification Val"
    var
        ClassValue: Record "JML AP Classification Val";
    begin
        if ClassValue.Get(IndustryCode, LevelNo, ValueCode) then begin
            ClassValue.Description := CopyStr(ValueDesc, 1, MaxStrLen(ClassValue.Description));
            ClassValue."Parent Value Code" := ParentCode;
            ClassValue."Parent Level Number" := ParentLevelNo;
            ClassValue.Modify(true);
            exit(ClassValue);
        end;

        ClassValue.Init();
        ClassValue."Industry Code" := IndustryCode;
        ClassValue."Level Number" := LevelNo;
        ClassValue.Code := ValueCode;
        ClassValue.Description := CopyStr(ValueDesc, 1, MaxStrLen(ClassValue.Description));
        ClassValue."Parent Value Code" := ParentCode;
        ClassValue."Parent Level Number" := ParentLevelNo;
        ClassValue.Insert(true);
        exit(ClassValue);
    end;

    procedure CreateCustomer(): Record Customer
    begin
        exit(CreateTestCustomer('Test Customer ' + Format(CreateGuid())));
    end;

    procedure CreateVendor(): Record Vendor
    begin
        exit(CreateTestVendor('Test Vendor ' + Format(CreateGuid())));
    end;

    // ============================================================================
    // MODULE 8: Asset Transfer Order Helpers
    // ============================================================================

    procedure CreateTransferOrder(FromCode: Code[20]; ToCode: Code[20]): Record "JML AP Asset Transfer Header"
    var
        TransferHeader: Record "JML AP Asset Transfer Header";
    begin
        TransferHeader.Init();
        TransferHeader."No." := '';
        TransferHeader.Insert(true);
        TransferHeader.Validate("From Holder Type", TransferHeader."From Holder Type"::Location);
        TransferHeader.Validate("From Holder Code", FromCode);
        TransferHeader.Validate("To Holder Type", TransferHeader."To Holder Type"::Location);
        TransferHeader.Validate("To Holder Code", ToCode);
        TransferHeader.Modify(true);
        exit(TransferHeader);
    end;

    procedure CreateTransferLine(var TransferLine: Record "JML AP Asset Transfer Line"; DocumentNo: Code[20]; AssetNo: Code[20])
    var
        LastLineNo: Integer;
    begin
        TransferLine.SetRange("Document No.", DocumentNo);
        if TransferLine.FindLast() then
            LastLineNo := TransferLine."Line No."
        else
            LastLineNo := 0;

        TransferLine.Init();
        TransferLine."Document No." := DocumentNo;
        TransferLine."Line No." := LastLineNo + 10000;
        TransferLine.Validate("Asset No.", AssetNo);
        TransferLine.Insert(true);
    end;

    procedure CreateTransferLineForOrder(var TransferHeader: Record "JML AP Asset Transfer Header"; AssetNo: Code[20])
    var
        TransferLine: Record "JML AP Asset Transfer Line";
    begin
        CreateTransferLine(TransferLine, TransferHeader."No.", AssetNo);
    end;

    procedure ReleaseTransferOrder(var TransferHeader: Record "JML AP Asset Transfer Header")
    begin
        TransferHeader.Status := TransferHeader.Status::Released;
        TransferHeader.Modify(true);
    end;

    procedure ReleaseAndPostTransferOrder(var TransferHeader: Record "JML AP Asset Transfer Header"): Record "JML AP Asset Transfer Header"
    var
        AssetTransferPost: Codeunit "JML AP Asset Transfer-Post";
    begin
        ReleaseTransferOrder(TransferHeader);
        AssetTransferPost.SetSuppressConfirmation(true);
        AssetTransferPost.SetSuppressMessage(true);
        AssetTransferPost.Run(TransferHeader);
        exit(TransferHeader);
    end;

    procedure CreateAndPostTransferOrder(AssetNo: Code[20]; FromCode: Code[20]; ToCode: Code[20]): Record "JML AP Asset Transfer Header"
    var
        TransferHeader: Record "JML AP Asset Transfer Header";
        TransferLine: Record "JML AP Asset Transfer Line";
    begin
        TransferHeader := CreateTransferOrder(FromCode, ToCode);
        CreateTransferLine(TransferLine, TransferHeader."No.", AssetNo);
        TransferHeader := ReleaseAndPostTransferOrder(TransferHeader);
        exit(TransferHeader);
    end;
}
