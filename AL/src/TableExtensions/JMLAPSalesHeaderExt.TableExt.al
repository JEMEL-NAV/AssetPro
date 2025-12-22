tableextension 70182420 "JML AP Sales Header Ext" extends "Sales Header"
{
    // Extension to add OnBeforeDelete trigger for cascading delete of asset lines

    trigger OnBeforeDelete()
    var
        SalesAssetLine: Record "JML AP Sales Asset Line";
    begin
        // Delete only unposted asset lines when header is deleted
        // Posted lines cannot be deleted (Quantity Shipped/Received > 0)
        SalesAssetLine.SetRange("Document Type", "Document Type");
        SalesAssetLine.SetRange("Document No.", "No.");

        // For Orders: only delete lines where Quantity Shipped = 0
        if "Document Type" = "Document Type"::Order then begin
            SalesAssetLine.SetRange("Quantity Shipped", 0);
        end
        // For Return Orders: only delete lines where Quantity Received = 0
        else if "Document Type" = "Document Type"::"Return Order" then begin
            SalesAssetLine.SetRange("Quantity Received", 0);
        end;

        if SalesAssetLine.FindSet() then
            repeat
                SalesAssetLine.Delete(true);
            until SalesAssetLine.Next() = 0;
    end;
}
