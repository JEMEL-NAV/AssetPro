tableextension 70182420 "JML AP Sales Header Ext" extends "Sales Header"
{
    // Extension to add OnBeforeDelete trigger for cascading delete of asset lines

    trigger OnBeforeDelete()
    var
        SalesAssetLine: Record "JML AP Sales Asset Line";
    begin
        // Delete all asset lines when header is deleted
        SalesAssetLine.SetRange("Document Type", "Document Type");
        SalesAssetLine.SetRange("Document No.", "No.");
        if not SalesAssetLine.IsEmpty() then
            SalesAssetLine.DeleteAll(true);
    end;
}
