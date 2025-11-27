tableextension 70182422 "JML AP Transfer Header Ext" extends "Transfer Header"
{
    trigger OnDelete()
    var
        TransferAssetLine: Record "JML AP Transfer Asset Line";
    begin
        // Cascade delete asset lines when transfer order is deleted
        TransferAssetLine.SetRange("Document No.", Rec."No.");
        TransferAssetLine.DeleteAll(true);
    end;
}
