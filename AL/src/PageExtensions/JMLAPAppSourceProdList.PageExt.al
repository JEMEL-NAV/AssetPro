pageextension 70182300 "JML AP AppSource Prod.List" extends "AppSource Product List"
{

    trigger OnAfterGetRecord()
    begin
        if PublisherFilter <> '' then
            Rec.setfilter(PublisherID, PublisherFilter);
    end;

    procedure JMLPublisherFilterIDL(NewFilter: Text)
    begin
        PublisherFilter := NewFilter;
    end;

    var
        PublisherFilter: Text;
}
