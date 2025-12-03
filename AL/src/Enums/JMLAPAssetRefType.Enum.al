enum 70182410 "JML AP Asset Ref Type"
{
    Caption = 'Asset Reference Type';
    Extensible = true;

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; Customer)
    {
        Caption = 'Customer';
    }
    value(2; Vendor)
    {
        Caption = 'Vendor';
    }
    value(3; Barcode)
    {
        Caption = 'Barcode';
    }
    value(4; Internal)
    {
        Caption = 'Internal';
    }
    value(5; External)
    {
        Caption = 'External';
    }
}
