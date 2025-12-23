codeunit 50112 "JML AP Item Journal Int. Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";
        TestLibrary: Codeunit "JML AP Test Library";
        IsInitialized: Boolean;

    [Test]
    procedure TestItemJnlSale_WithAsset_CreatesInstallEntry()
    var
        Asset: Record "JML AP Asset";
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ComponentEntry: Record "JML AP Component Entry";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
    begin
        // [SCENARIO] Item Journal Sale with Asset No. creates Component Install entry

        // [GIVEN] An asset and an item
        TestLibrary.Initialize();
        Asset := TestLibrary.CreateTestAsset('Test Asset');
        Item := TestLibrary.CreateTestItem('Test Item');

        // [GIVEN] Item Journal Line: Entry Type = Sale, Negative Qty, Asset No. populated
        CreateItemJournalLine(ItemJnlLine, Item."No.", ItemJnlLine."Entry Type"::Sale, -5);
        ItemJnlLine."JML AP Asset No." := Asset."No.";
        ItemJnlLine.Modify();

        // [WHEN] Post item journal line
        ItemJnlPostLine.RunWithCheck(ItemJnlLine);

        // [THEN] Item Ledger Entry created
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        LibraryAssert.RecordIsNotEmpty(ItemLedgerEntry);
        ItemLedgerEntry.FindFirst();

        // [THEN] Component Entry created with Entry Type = Install, Positive Qty
        ComponentEntry.SetRange("Asset No.", Asset."No.");
        ComponentEntry.SetRange("Item No.", Item."No.");
        LibraryAssert.RecordIsNotEmpty(ComponentEntry);
        ComponentEntry.FindFirst();
        LibraryAssert.AreEqual(ComponentEntry."Entry Type"::Install, ComponentEntry."Entry Type", 'Entry Type should be Install');
        LibraryAssert.IsTrue(ComponentEntry.Quantity > 0, 'Quantity should be positive for Install');
        LibraryAssert.AreEqual(ItemLedgerEntry."Entry No.", ComponentEntry."Item Ledger Entry No.", 'Item Ledger Entry No. should match');
    end;

    [Test]
    procedure TestItemJnlPositiveAdjmt_WithAsset_CreatesRemoveEntry()
    var
        Asset: Record "JML AP Asset";
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ComponentEntry: Record "JML AP Component Entry";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
    begin
        // [SCENARIO] Item Journal Positive Adjmt. with Asset No. creates Component Remove entry

        // [GIVEN] An asset and an item
        TestLibrary.Initialize();
        Asset := TestLibrary.CreateTestAsset('Test Asset');
        Item := TestLibrary.CreateTestItem('Test Item');

        // [GIVEN] Item Journal Line: Entry Type = Positive Adjmt., Positive Qty, Asset No. populated
        CreateItemJournalLine(ItemJnlLine, Item."No.", ItemJnlLine."Entry Type"::"Positive Adjmt.", 10);
        ItemJnlLine."JML AP Asset No." := Asset."No.";
        ItemJnlLine.Modify();

        // [WHEN] Post item journal line
        ItemJnlPostLine.RunWithCheck(ItemJnlLine);

        // [THEN] Component Entry created with Entry Type = Remove, Negative Qty
        ComponentEntry.SetRange("Asset No.", Asset."No.");
        ComponentEntry.SetRange("Item No.", Item."No.");
        LibraryAssert.RecordIsNotEmpty(ComponentEntry);
        ComponentEntry.FindFirst();
        LibraryAssert.AreEqual(ComponentEntry."Entry Type"::Remove, ComponentEntry."Entry Type", 'Entry Type should be Remove');
        LibraryAssert.IsTrue(ComponentEntry.Quantity < 0, 'Quantity should be negative for Remove');
    end;

    [Test]
    procedure TestItemJnlNegativeAdjmt_WithAsset_CreatesInstallEntry()
    var
        Asset: Record "JML AP Asset";
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ComponentEntry: Record "JML AP Component Entry";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
    begin
        // [SCENARIO] Item Journal Negative Adjmt. with Asset No. creates Component Install entry

        // [GIVEN] An asset and an item
        TestLibrary.Initialize();
        Asset := TestLibrary.CreateTestAsset('Test Asset');
        Item := TestLibrary.CreateTestItem('Test Item');

        // [GIVEN] Item Journal Line: Entry Type = Negative Adjmt., Negative Qty, Asset No. populated
        CreateItemJournalLine(ItemJnlLine, Item."No.", ItemJnlLine."Entry Type"::"Negative Adjmt.", -8);
        ItemJnlLine."JML AP Asset No." := Asset."No.";
        ItemJnlLine.Modify();

        // [WHEN] Post item journal line
        ItemJnlPostLine.RunWithCheck(ItemJnlLine);

        // [THEN] Component Entry created with Entry Type = Install, Positive Qty
        ComponentEntry.SetRange("Asset No.", Asset."No.");
        ComponentEntry.SetRange("Item No.", Item."No.");
        LibraryAssert.RecordIsNotEmpty(ComponentEntry);
        ComponentEntry.FindFirst();
        LibraryAssert.AreEqual(ComponentEntry."Entry Type"::Install, ComponentEntry."Entry Type", 'Entry Type should be Install');
        LibraryAssert.IsTrue(ComponentEntry.Quantity > 0, 'Quantity should be positive for Install');
    end;

    [Test]
    procedure TestItemJnlPurchase_WithAsset_NoComponentEntry()
    var
        Asset: Record "JML AP Asset";
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ComponentEntry: Record "JML AP Component Entry";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
    begin
        // [SCENARIO] Item Journal Purchase with Asset No. does NOT create Component Entry

        // [GIVEN] An asset and an item
        TestLibrary.Initialize();
        Asset := TestLibrary.CreateTestAsset('Test Asset');
        Item := TestLibrary.CreateTestItem('Test Item');

        // [GIVEN] Item Journal Line: Entry Type = Purchase, Asset No. populated
        CreateItemJournalLine(ItemJnlLine, Item."No.", ItemJnlLine."Entry Type"::Purchase, 10);
        ItemJnlLine."JML AP Asset No." := Asset."No.";
        ItemJnlLine.Modify();

        // [WHEN] Post item journal line
        ItemJnlPostLine.RunWithCheck(ItemJnlLine);

        // [THEN] NO Component Entry created (Purchase not integrated)
        ComponentEntry.SetRange("Asset No.", Asset."No.");
        ComponentEntry.SetRange("Item No.", Item."No.");
        LibraryAssert.RecordIsEmpty(ComponentEntry);
    end;

    [Test]
    procedure TestItemJnlSale_WithoutAsset_NoComponentEntry()
    var
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ComponentEntry: Record "JML AP Component Entry";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
    begin
        // [SCENARIO] Item Journal Sale without Asset No. does NOT create Component Entry

        // [GIVEN] An item
        TestLibrary.Initialize();
        Item := TestLibrary.CreateTestItem('Test Item');

        // [GIVEN] Item Journal Line: Entry Type = Sale, Asset No. = blank
        CreateItemJournalLine(ItemJnlLine, Item."No.", ItemJnlLine."Entry Type"::Sale, -5);
        // Asset No. not set

        // [WHEN] Post item journal line
        ItemJnlPostLine.RunWithCheck(ItemJnlLine);

        // [THEN] NO Component Entry created
        ComponentEntry.SetRange("Item No.", Item."No.");
        LibraryAssert.RecordIsEmpty(ComponentEntry);
    end;

    [Test]
    procedure TestItemJnl_DocumentNoLinking()
    var
        Asset: Record "JML AP Asset";
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ComponentEntry: Record "JML AP Component Entry";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
    begin
        // [SCENARIO] Component Entry links to Item Ledger Entry for traceability

        // [GIVEN] An asset and an item
        TestLibrary.Initialize();
        Asset := TestLibrary.CreateTestAsset('Test Asset');
        Item := TestLibrary.CreateTestItem('Test Item');

        // [GIVEN] Item Journal Line with Asset No.
        CreateItemJournalLine(ItemJnlLine, Item."No.", ItemJnlLine."Entry Type"::Sale, -3);
        ItemJnlLine."JML AP Asset No." := Asset."No.";
        ItemJnlLine.Modify();

        // [WHEN] Post item journal line
        ItemJnlPostLine.RunWithCheck(ItemJnlLine);

        // [THEN] Component Entry."Item Ledger Entry No." = Item Ledger Entry."Entry No."
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.FindFirst();

        ComponentEntry.SetRange("Asset No.", Asset."No.");
        ComponentEntry.SetRange("Item No.", Item."No.");
        ComponentEntry.FindFirst();

        LibraryAssert.AreEqual(ItemLedgerEntry."Entry No.", ComponentEntry."Item Ledger Entry No.",
            'Component Entry should link to Item Ledger Entry');
        LibraryAssert.AreEqual(Format(ItemLedgerEntry."Entry No."), ComponentEntry."Document No.",
            'Document No. should contain Item Ledger Entry No.');
    end;

    [Test]
    procedure TestItemJnl_MultipleLines_BatchPosting()
    var
        Asset1: Record "JML AP Asset";
        Asset2: Record "JML AP Asset";
        Item1: Record Item;
        Item2: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ComponentEntry: Record "JML AP Component Entry";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
    begin
        // [SCENARIO] Multiple Item Journal Lines with different assets create multiple Component Entries

        // [GIVEN] Two assets and two items
        TestLibrary.Initialize();
        CreateAsset(Asset1);
        CreateAsset(Asset2);
        CreateItem(Item1);
        CreateItem(Item2);

        // [GIVEN] Two Item Journal Lines with different assets
        CreateItemJournalLine(ItemJnlLine, Item1."No.", ItemJnlLine."Entry Type"::Sale, -5);
        ItemJnlLine."JML AP Asset No." := Asset1."No.";
        ItemJnlLine.Modify();
        ItemJnlPostLine.RunWithCheck(ItemJnlLine);

        CreateItemJournalLine(ItemJnlLine, Item2."No.", ItemJnlLine."Entry Type"::"Negative Adjmt.", -7);
        ItemJnlLine."JML AP Asset No." := Asset2."No.";
        ItemJnlLine.Modify();

        // [WHEN] Post second journal line
        ItemJnlPostLine.RunWithCheck(ItemJnlLine);

        // [THEN] Two Component Entries created (one for each asset)
        ComponentEntry.SetRange("Asset No.", Asset1."No.");
        LibraryAssert.RecordCount(ComponentEntry, 1);

        ComponentEntry.SetRange("Asset No.", Asset2."No.");
        LibraryAssert.RecordCount(ComponentEntry, 1);
    end;

    // [Test] - Consumption requires production order setup, skipped for basic integration testing
    // procedure TestItemJnlConsumption_WithAsset_CreatesInstallEntry()
    // var
    //     Asset: Record "JML AP Asset";
    //     Item: Record Item;
    //     ItemJnlLine: Record "Item Journal Line";
    //     ComponentEntry: Record "JML AP Component Entry";
    //     ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
    // begin
    //     // [SCENARIO] Item Journal Consumption with Asset No. creates Component Install entry
    //     // NOTE: Consumption entry type requires Order Type = Production and full production order setup
    //     // This test is commented out as it requires complex production order infrastructure

    //     // [GIVEN] An asset and an item
    //     Initialize();
    //     CreateAsset(Asset);
    //     CreateItem(Item);

    //     // [GIVEN] Item Journal Line: Entry Type = Consumption, Negative Qty, Asset No. populated
    //     CreateItemJournalLine(ItemJnlLine, Item."No.", ItemJnlLine."Entry Type"::Consumption, -4);
    //     ItemJnlLine."JML AP Asset No." := Asset."No.";
    //     ItemJnlLine.Modify();

    //     // [WHEN] Post item journal line
    //     ItemJnlPostLine.RunWithCheck(ItemJnlLine);

    //     // [THEN] Component Entry created with Entry Type = Install, Positive Qty
    //     ComponentEntry.SetRange("Asset No.", Asset."No.");
    //     ComponentEntry.SetRange("Item No.", Item."No.");
    //     LibraryAssert.RecordIsNotEmpty(ComponentEntry);
    //     ComponentEntry.FindFirst();
    //     LibraryAssert.AreEqual(ComponentEntry."Entry Type"::Install, ComponentEntry."Entry Type", 'Entry Type should be Install');
    //     LibraryAssert.IsTrue(ComponentEntry.Quantity > 0, 'Quantity should be positive for Install');
    // end;

    local procedure CreateItemJournalLine(var ItemJnlLine: Record "Item Journal Line"; ItemNo: Code[20]; EntryType: Enum "Item Ledger Entry Type"; Quantity: Decimal)
    var
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
    begin
        // Get or create journal template
        ItemJnlTemplate.SetRange(Type, ItemJnlTemplate.Type::Item);
        ItemJnlTemplate.SetRange(Recurring, false);
        if not ItemJnlTemplate.FindFirst() then begin
            ItemJnlTemplate.Init();
            ItemJnlTemplate.Name := 'ITEM';
            ItemJnlTemplate.Type := ItemJnlTemplate.Type::Item;
            ItemJnlTemplate.Description := 'Item Journal';
            ItemJnlTemplate.Insert(true);
        end;

        // Get or create journal batch
        ItemJnlBatch.SetRange("Journal Template Name", ItemJnlTemplate.Name);
        if not ItemJnlBatch.FindFirst() then begin
            ItemJnlBatch.Init();
            ItemJnlBatch."Journal Template Name" := ItemJnlTemplate.Name;
            ItemJnlBatch.Name := 'DEFAULT';
            ItemJnlBatch.Description := 'Default Batch';
            ItemJnlBatch.Insert(true);
        end;

        // Create journal line
        ItemJnlLine.Init();
        ItemJnlLine."Journal Template Name" := ItemJnlBatch."Journal Template Name";
        ItemJnlLine."Journal Batch Name" := ItemJnlBatch.Name;
        ItemJnlLine."Line No." := GetNextLineNo(ItemJnlBatch."Journal Template Name", ItemJnlBatch.Name);
        ItemJnlLine."Entry Type" := EntryType;
        ItemJnlLine."Posting Date" := WorkDate();
        ItemJnlLine."Document No." := 'TEST-' + Format(Random(9999));
        ItemJnlLine.Validate("Item No.", ItemNo);
        ItemJnlLine.Validate(Quantity, Quantity);
        ItemJnlLine.Insert(true);
    end;

    local procedure GetNextLineNo(TemplateName: Code[10]; BatchName: Code[10]): Integer
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        ItemJnlLine.SetRange("Journal Template Name", TemplateName);
        ItemJnlLine.SetRange("Journal Batch Name", BatchName);
        if ItemJnlLine.FindLast() then
            exit(ItemJnlLine."Line No." + 10000)
        else
            exit(10000);
    end;

    local procedure GetOrCreateGenProdPostingGroup(): Code[20]
    var
        GenProdPostingGroup: Record "Gen. Product Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        // Try to find an existing posting group with valid posting setup
        if GenProdPostingGroup.FindFirst() then begin
            // Check if General Posting Setup exists for this combination (empty bus. posting group)
            if GeneralPostingSetup.Get('', GenProdPostingGroup.Code) then
                if (GeneralPostingSetup."COGS Account" <> '') and
                   (GeneralPostingSetup."Direct Cost Applied Account" <> '')
                then
                    exit(GenProdPostingGroup.Code);
        end;

        // Create a test posting group if none exists
        if not GenProdPostingGroup.Get('TEST') then begin
            GenProdPostingGroup.Init();
            GenProdPostingGroup.Code := 'TEST';
            GenProdPostingGroup.Description := 'Test Posting Group';
            GenProdPostingGroup.Insert(true);
        end;

        // Create General Posting Setup for empty bus. posting group + this prod. posting group
        if not GeneralPostingSetup.Get('', 'TEST') then begin
            GeneralPostingSetup.Init();
            GeneralPostingSetup."Gen. Bus. Posting Group" := '';
            GeneralPostingSetup."Gen. Prod. Posting Group" := 'TEST';
            GeneralPostingSetup."COGS Account" := GetOrCreateGLAccount('99999');
            GeneralPostingSetup."Direct Cost Applied Account" := GetOrCreateGLAccount('99998');
            GeneralPostingSetup."Inventory Adjmt. Account" := GetOrCreateGLAccount('99997');
            GeneralPostingSetup.Insert(true);
        end else begin
            // Update existing setup with GL accounts if missing
            if (GeneralPostingSetup."COGS Account" = '') or
               (GeneralPostingSetup."Direct Cost Applied Account" = '')
            then begin
                GeneralPostingSetup."COGS Account" := GetOrCreateGLAccount('99999');
                GeneralPostingSetup."Direct Cost Applied Account" := GetOrCreateGLAccount('99998');
                GeneralPostingSetup."Inventory Adjmt. Account" := GetOrCreateGLAccount('99997');
                GeneralPostingSetup.Modify(true);
            end;
        end;

        exit('TEST');
    end;

    local procedure GetOrCreateGLAccount(AccountNo: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        if not GLAccount.Get(AccountNo) then begin
            GLAccount.Init();
            GLAccount."No." := AccountNo;
            GLAccount.Name := 'Test Account ' + AccountNo;
            GLAccount."Account Type" := GLAccount."Account Type"::Posting;
            GLAccount."Income/Balance" := GLAccount."Income/Balance"::"Balance Sheet";
            GLAccount."Direct Posting" := true;
            GLAccount.Insert(true);
        end;
        exit(GLAccount."No.");
    end;

    local procedure GetOrCreateInventoryPostingGroup(): Code[20]
    var
        InventoryPostingGroup: Record "Inventory Posting Group";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        LocationCode: Code[10];
    begin
        // Try to find an existing inventory posting group with valid setup
        if InventoryPostingGroup.FindFirst() then begin
            // Check if Inventory Posting Setup exists with Inventory Account
            if InventoryPostingSetup.Get('', InventoryPostingGroup.Code) then
                if InventoryPostingSetup."Inventory Account" <> '' then
                    exit(InventoryPostingGroup.Code);
        end;

        // Create a test inventory posting group if none exists
        if not InventoryPostingGroup.Get('TEST') then begin
            InventoryPostingGroup.Init();
            InventoryPostingGroup.Code := 'TEST';
            InventoryPostingGroup.Description := 'Test Inventory Posting Group';
            InventoryPostingGroup.Insert(true);
        end;

        // Create Inventory Posting Setup for empty location + this inventory posting group
        LocationCode := '';
        if not InventoryPostingSetup.Get(LocationCode, 'TEST') then begin
            InventoryPostingSetup.Init();
            InventoryPostingSetup."Location Code" := LocationCode;
            InventoryPostingSetup."Invt. Posting Group Code" := 'TEST';
            InventoryPostingSetup."Inventory Account" := GetOrCreateGLAccount('99996');
            InventoryPostingSetup.Insert(true);
        end else begin
            // Update existing setup with Inventory Account if missing
            if InventoryPostingSetup."Inventory Account" = '' then begin
                InventoryPostingSetup."Inventory Account" := GetOrCreateGLAccount('99996');
                InventoryPostingSetup.Modify(true);
            end;
        end;

        exit('TEST');
    end;
}
