codeunit 70182398 "JML AP Sales Integration"
{

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnPostItemJnlLineOnAfterCopyTrackingFromSpec', '', false, false)]
    local procedure OnPostItemJnlLineOnAfterCopyTrackingFromSpec(var ItemJnlLine: Record "Item Journal Line"; SalesLine: Record "Sales Line"; QtyToBeShipped: Decimal; IsATO: Boolean)
    var
        SalesLineWithAsset: Record "Sales Line";
    begin
        // Get the extended Sales Line record with Asset No. field
        if not SalesLineWithAsset.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.") then
            exit;

        // Transfer Asset No. from Sales Line to Item Journal Line
        // This will trigger the Item Journal integration (codeunit 70182397) when the Item Journal Line is posted
        if SalesLineWithAsset."JML AP Asset No." <> '' then
            ItemJnlLine."JML AP Asset No." := SalesLineWithAsset."JML AP Asset No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterSalesShptLineInsert', '', false, false)]
    local procedure OnAfterSalesShptLineInsert(var SalesShipmentLine: Record "Sales Shipment Line"; SalesLine: Record "Sales Line"; ItemShptLedEntryNo: Integer; WhseShip: Boolean; WhseReceive: Boolean; CommitIsSuppressed: Boolean; SalesInvoiceHeader: Record "Sales Invoice Header"; var TempWhseShptHeader: Record "Warehouse Shipment Header" temporary; var TempWhseRcptHeader: Record "Warehouse Receipt Header" temporary; SalesShptHeader: Record "Sales Shipment Header"; SalesHeader: Record "Sales Header")
    var
        SalesLineWithAsset: Record "Sales Line";
    begin
        // Transfer Asset No. to posted shipment line
        if SalesLineWithAsset.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.") then
            if SalesLineWithAsset."JML AP Asset No." <> '' then begin
                SalesShipmentLine."JML AP Asset No." := SalesLineWithAsset."JML AP Asset No.";
                SalesShipmentLine.Modify();
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterSalesInvLineInsert', '', false, false)]
    local procedure OnAfterSalesInvLineInsert(var SalesInvLine: Record "Sales Invoice Line"; SalesInvHeader: Record "Sales Invoice Header"; SalesLine: Record "Sales Line"; ItemLedgShptEntryNo: Integer; WhseShip: Boolean; WhseReceive: Boolean; CommitIsSuppressed: Boolean; var SalesHeader: Record "Sales Header"; var TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary; var TempWhseShptHeader: Record "Warehouse Shipment Header" temporary; var TempWhseRcptHeader: Record "Warehouse Receipt Header" temporary; PreviewMode: Boolean)
    var
        SalesLineWithAsset: Record "Sales Line";
    begin
        // Transfer Asset No. to posted invoice line
        if SalesLineWithAsset.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.") then
            if SalesLineWithAsset."JML AP Asset No." <> '' then begin
                SalesInvLine."JML AP Asset No." := SalesLineWithAsset."JML AP Asset No.";
                SalesInvLine.Modify();
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterSalesCrMemoLineInsert', '', false, false)]
    local procedure OnAfterSalesCrMemoLineInsert(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var TempItemChargeAssgntSales: Record "Item Charge Assignment (Sales)" temporary; CommitIsSuppressed: Boolean; WhseShip: Boolean; WhseReceive: Boolean; var TempWhseShptHeader: Record "Warehouse Shipment Header" temporary; var TempWhseRcptHeader: Record "Warehouse Receipt Header" temporary)
    var
        SalesLineWithAsset: Record "Sales Line";
    begin
        // Transfer Asset No. to posted credit memo line
        if SalesLineWithAsset.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.") then
            if SalesLineWithAsset."JML AP Asset No." <> '' then begin
                SalesCrMemoLine."JML AP Asset No." := SalesLineWithAsset."JML AP Asset No.";
                SalesCrMemoLine.Modify();
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterReturnRcptLineInsert', '', false, false)]
    local procedure OnAfterReturnRcptLineInsert(var ReturnRcptLine: Record "Return Receipt Line"; ReturnRcptHeader: Record "Return Receipt Header"; SalesLine: Record "Sales Line"; ItemShptLedEntryNo: Integer; WhseShip: Boolean; WhseReceive: Boolean; CommitIsSuppressed: Boolean; SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var TempWhseShptHeader: Record "Warehouse Shipment Header" temporary; var TempWhseRcptHeader: Record "Warehouse Receipt Header" temporary; var SalesHeader: Record "Sales Header")
    var
        SalesLineWithAsset: Record "Sales Line";
    begin
        // Transfer Asset No. to posted return receipt line
        if SalesLineWithAsset.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.") then
            if SalesLineWithAsset."JML AP Asset No." <> '' then begin
                ReturnRcptLine."JML AP Asset No." := SalesLineWithAsset."JML AP Asset No.";
                ReturnRcptLine.Modify();
            end;
    end;

    // ========================================
    // Asset Holder Transfer Integration (Stage 5)
    // ========================================

    // Event subscribers for Sales posting integration with both:
    // 1. Component Ledger (Stage 4.5) - Asset No. on Sales Line
    // 2. Asset Holder Transfer (Stage 5) - Separate Sales Asset Lines

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Sales Document", OnBeforeSalesLineFind, '', false, false)]
    local procedure ReleaseSalesDocumentOnBeforeSalesLineFind(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"; var LinesWereModified: Boolean; var IsHandled: Boolean)
    var
        SalesAssetLine: Record "JML AP Sales Asset Line";
    begin
        SalesAssetLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesAssetLine.SetRange("Document No.", SalesHeader."No.");
        if not SalesAssetLine.IsEmpty() then
            // Prevent standard shipment/invoice release if there are asset lines to process
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnAfterCheckTrackingAndWarehouseForShip, '', false, false)]
    local procedure SalesPostOnAfterCheckTrackingAndWarehouseForShip(var SalesHeader: Record "Sales Header"; var Ship: Boolean; CommitIsSuppressed: Boolean; var TempWhseShptHeader: Record "Warehouse Shipment Header" temporary; var TempWhseRcptHeader: Record "Warehouse Receipt Header" temporary; var TempSalesLine: Record "Sales Line" temporary)
    var
        SalesAssetLine: Record "JML AP Sales Asset Line";
    begin
        SalesAssetLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesAssetLine.SetRange("Document No.", SalesHeader."No.");
        SalesAssetLine.SetFilter("Quantity to Ship", '>%1', 0);
        if not SalesAssetLine.IsEmpty() then
            // Force shipment processing if there are asset lines to ship
            Ship := true;
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterSalesShptHeaderInsert', '', false, false)]
    local procedure OnAfterSalesShptHeaderInsert(var SalesShipmentHeader: Record "Sales Shipment Header"; SalesHeader: Record "Sales Header")
    begin
        // Post asset holder transfers for shipment (delivery to customer)
        PostSalesShipmentAssets(SalesHeader, SalesShipmentHeader);
    end;

    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterSalesInvHeaderInsert', '', false, false)]
    // local procedure OnAfterSalesInvHeaderInsertAssetTransfer(var SalesInvHeader: Record "Sales Invoice Header"; SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean; WhseShip: Boolean; WhseReceive: Boolean; var TempWhseShptHeader: Record "Warehouse Shipment Header" temporary; var TempWhseRcptHeader: Record "Warehouse Receipt Header" temporary)
    // var
    //     TempSalesShipmentHeader: Record "Sales Shipment Header" temporary;
    // begin
    //     // Post asset holder transfers for invoice (if no prior shipment)
    //     // This supports invoice-only scenarios (Q2 clarification)
    //     PostSalesInvoiceAssets(SalesHeader, SalesInvHeader, TempSalesShipmentHeader);
    // end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterReturnRcptHeaderInsert', '', false, false)]
    local procedure OnAfterReturnRcptHeaderInsert(var ReturnReceiptHeader: Record "Return Receipt Header"; SalesHeader: Record "Sales Header")
    begin
        // Post asset returns (customer returning asset back to location)
        PostReturnReceiptAssets(SalesHeader, ReturnReceiptHeader);
    end;

    local procedure PostSalesShipmentAssets(SalesHeader: Record "Sales Header"; SalesShptHeader: Record "Sales Shipment Header")
    var
        SalesAssetLine: Record "JML AP Sales Asset Line";
        Asset: Record "JML AP Asset";
        JMLAPGeneral: Codeunit "JML AP General";
        TransactionNo: Integer;
    begin
        // License check
        if not JMLAPGeneral.IsAllowedToUse(true) then
            error('');

        // Get asset lines to ship
        SalesAssetLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesAssetLine.SetRange("Document No.", SalesHeader."No.");
        SalesAssetLine.SetFilter("Quantity to Ship", '>0');

        if SalesAssetLine.IsEmpty() then
            exit;

        // Post each asset transfer via Asset Journal
        if SalesAssetLine.FindSet(true) then
            repeat
                Asset.Get(SalesAssetLine."Asset No.");

                // Transfer asset to customer using journal pattern
                PostAssetTransferViaJournal(
                    Asset,
                    "JML AP Holder Type"::Customer,
                    SalesHeader."Sell-to Customer No.",
                    SalesShptHeader."No.",
                    SalesAssetLine."Reason Code",
                    SalesShptHeader."Posting Date",
                    TransactionNo);

                // Create posted shipment asset line
                CreatePostedShipmentAssetLine(SalesAssetLine, SalesShptHeader, SalesHeader, TransactionNo);

                // Update source line
                SalesAssetLine."Quantity Shipped" += SalesAssetLine."Quantity to Ship";
                SalesAssetLine."Quantity to Ship" := 0;
                SalesAssetLine.Modify();
            until SalesAssetLine.Next() = 0;
    end;

    // local procedure PostSalesInvoiceAssets(SalesHeader: Record "Sales Header"; SalesInvHeader: Record "Sales Invoice Header"; var TempSalesShptHeader: Record "Sales Shipment Header" temporary)
    // var
    //     SalesAssetLine: Record "JML AP Sales Asset Line";
    //     Asset: Record "JML AP Asset";
    //     TransactionNo: Integer;
    // begin
    //     // Only post if no prior shipment exists (invoice-only scenario)
    //     SalesAssetLine.SetRange("Document Type", SalesHeader."Document Type");
    //     SalesAssetLine.SetRange("Document No.", SalesHeader."No.");
    //     SalesAssetLine.SetFilter("Quantity Shipped", '=0'); // Not yet shipped

    //     if SalesAssetLine.IsEmpty() then
    //         exit;

    //     if SalesAssetLine.FindSet(true) then
    //         repeat
    //             Asset.Get(SalesAssetLine."Asset No.");

    //             // Transfer asset to customer
    //             PostAssetTransferViaJournal(
    //                 Asset,
    //                 "JML AP Holder Type"::Customer,
    //                 SalesHeader."Sell-to Customer No.",
    //                 SalesInvHeader."No.",
    //                 SalesAssetLine."Reason Code",
    //                 SalesInvHeader."Posting Date",
    //                 TransactionNo);

    //             // Mark as shipped
    //             SalesAssetLine."Quantity Shipped" := 1;
    //             SalesAssetLine."Quantity to Ship" := 0;
    //             SalesAssetLine.Modify();
    //         until SalesAssetLine.Next() = 0;
    // end;

    local procedure PostReturnReceiptAssets(SalesHeader: Record "Sales Header"; ReturnRcptHeader: Record "Return Receipt Header")
    var
        SalesAssetLine: Record "JML AP Sales Asset Line";
        Asset: Record "JML AP Asset";
        JMLAPGeneral: Codeunit "JML AP General";
        TransactionNo: Integer;
        LocationCode: Code[10];
    begin
        // License check
        if not JMLAPGeneral.IsAllowedToUse(true) then
            error('');

        // Get asset lines to receive
        SalesAssetLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesAssetLine.SetRange("Document No.", SalesHeader."No.");
        SalesAssetLine.SetFilter("Quantity to Receive", '>0');

        if SalesAssetLine.IsEmpty() then
            exit;

        // Determine return location (default to header location, or blank if not specified)
        LocationCode := SalesHeader."Location Code";

        // Post each asset return
        if SalesAssetLine.FindSet(true) then
            repeat
                Asset.Get(SalesAssetLine."Asset No.");

                // Transfer asset back to location
                PostAssetTransferViaJournal(
                    Asset,
                    "JML AP Holder Type"::Location,
                    LocationCode,
                    ReturnRcptHeader."No.",
                    SalesAssetLine."Reason Code",
                    ReturnRcptHeader."Posting Date",
                    TransactionNo);

                // Create posted return receipt asset line
                CreatePostedReturnReceiptAssetLine(SalesAssetLine, ReturnRcptHeader, SalesHeader, LocationCode, TransactionNo);

                // Update source line
                SalesAssetLine."Quantity Received" += SalesAssetLine."Quantity to Receive";
                SalesAssetLine."Quantity to Receive" := 0;
                SalesAssetLine.Modify();
            until SalesAssetLine.Next() = 0;
    end;

    local procedure PostAssetTransferViaJournal(var Asset: Record "JML AP Asset"; NewHolderType: Enum "JML AP Holder Type"; NewHolderCode: Code[20]; DocumentNo: Code[20]; ReasonCode: Code[10]; PostingDate: Date; var TransactionNo: Integer)
    var
        TempAssetJournalLine: Record "JML AP Asset Journal Line" temporary;
        AssetJnlPostLine: Codeunit "JML AP Asset Jnl.-Post Line";
    begin
        // Create journal line
        TempAssetJournalLine.Init();
        TempAssetJournalLine."Journal Batch Name" := '';
        TempAssetJournalLine."Line No." := 10000;
        TempAssetJournalLine."Posting Date" := PostingDate;
        TempAssetJournalLine."Document No." := DocumentNo;
        TempAssetJournalLine."Asset No." := Asset."No.";
        TempAssetJournalLine."New Holder Type" := NewHolderType;
        TempAssetJournalLine."New Holder Code" := NewHolderCode;
        TempAssetJournalLine."Reason Code" := ReasonCode;

        // Post journal
        AssetJnlPostLine.Run(TempAssetJournalLine);
        TransactionNo := AssetJnlPostLine.GetTransactionNo();
    end;

    local procedure CreatePostedShipmentAssetLine(SalesAssetLine: Record "JML AP Sales Asset Line"; SalesShptHeader: Record "Sales Shipment Header"; SalesHeader: Record "Sales Header"; TransactionNo: Integer)
    var
        PostedAssetLine: Record "JML AP Pstd Sales Shpt Ast Ln";
        Customer: Record Customer;
        LineNo: Integer;
    begin
        // Get next line number
        PostedAssetLine.SetRange("Document No.", SalesShptHeader."No.");
        if PostedAssetLine.FindLast() then
            LineNo := PostedAssetLine."Line No." + 10000
        else
            LineNo := 10000;

        // Get customer name
        if Customer.Get(SalesHeader."Sell-to Customer No.") then;

        // Create posted line
        PostedAssetLine.Init();
        PostedAssetLine."Document No." := SalesShptHeader."No.";
        PostedAssetLine."Line No." := LineNo;
        PostedAssetLine."Asset No." := SalesAssetLine."Asset No.";
        PostedAssetLine."Asset Description" := SalesAssetLine."Asset Description";
        PostedAssetLine."Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
        PostedAssetLine."Sell-to Customer Name" := Customer.Name;
        PostedAssetLine."Reason Code" := SalesAssetLine."Reason Code";
        PostedAssetLine.Description := SalesAssetLine.Description;
        PostedAssetLine."Posting Date" := SalesShptHeader."Posting Date";
        PostedAssetLine."Transaction No." := TransactionNo;
        PostedAssetLine.Insert(true);
    end;

    local procedure CreatePostedReturnReceiptAssetLine(SalesAssetLine: Record "JML AP Sales Asset Line"; ReturnRcptHeader: Record "Return Receipt Header"; SalesHeader: Record "Sales Header"; LocationCode: Code[10]; TransactionNo: Integer)
    var
        PostedAssetLine: Record "JML AP Pstd Ret Rcpt Ast Ln";
        Customer: Record Customer;
        LineNo: Integer;
    begin
        // Get next line number
        PostedAssetLine.SetRange("Document No.", ReturnRcptHeader."No.");
        if PostedAssetLine.FindLast() then
            LineNo := PostedAssetLine."Line No." + 10000
        else
            LineNo := 10000;

        // Get customer name
        if Customer.Get(SalesHeader."Sell-to Customer No.") then;

        // Create posted line
        PostedAssetLine.Init();
        PostedAssetLine."Document No." := ReturnRcptHeader."No.";
        PostedAssetLine."Line No." := LineNo;
        PostedAssetLine."Asset No." := SalesAssetLine."Asset No.";
        PostedAssetLine."Asset Description" := SalesAssetLine."Asset Description";
        PostedAssetLine."Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
        PostedAssetLine."Sell-to Customer Name" := Customer.Name;
        PostedAssetLine."Location Code" := LocationCode;
        PostedAssetLine."Reason Code" := SalesAssetLine."Reason Code";
        PostedAssetLine.Description := SalesAssetLine.Description;
        PostedAssetLine."Posting Date" := ReturnRcptHeader."Posting Date";
        PostedAssetLine."Transaction No." := TransactionNo;
        PostedAssetLine.Insert(true);
    end;
}
