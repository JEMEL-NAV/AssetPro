codeunit 70182398 "JML AP Sales Integration"
{
    // Event subscriber for Sales posting integration with Component Ledger
    // Transfers Asset No. from Sales Line to Item Journal Line during posting
    // This triggers the Item Journal integration (Stage 4.4) which creates component entries

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
}
