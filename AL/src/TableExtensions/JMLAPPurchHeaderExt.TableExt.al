tableextension 70182421 "JML AP Purch. Header Ext" extends "Purchase Header"
{
    // Extension to add OnBeforeDelete trigger for cascading delete of asset lines

    trigger OnBeforeDelete()
    var
        PurchAssetLine: Record "JML AP Purch. Asset Line";
    begin
        // Delete all asset lines when header is deleted
        PurchAssetLine.SetRange("Document Type", "Document Type");
        PurchAssetLine.SetRange("Document No.", "No.");
        if not PurchAssetLine.IsEmpty() then
            PurchAssetLine.DeleteAll(true);
    end;
}
