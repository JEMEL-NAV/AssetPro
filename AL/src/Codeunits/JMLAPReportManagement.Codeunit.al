codeunit 70182350 "JML AP Report Management"
{
    /// <summary>
    /// Shared report management procedures for Asset Pro reports.
    /// Provides common functionality for classification paths, address formatting, and report utilities.
    /// </summary>

    /// <summary>
    /// Builds the full classification path from root to leaf.
    /// </summary>
    /// <param name="IndustryCode">The industry code.</param>
    /// <param name="ClassificationCode">The classification code (leaf node).</param>
    /// <returns>Full path like "Commercial / Cargo Ship / Panamax"</returns>
    procedure BuildClassificationPath(IndustryCode: Code[20]; ClassificationCode: Code[20]): Text[250]
    var
        ClassValue: Record "JML AP Classification Val";
        Asset: Record "JML AP Asset";
        Path: Text[250];
        CurrentCode: Code[20];
        CurrentLevelNo: Integer;
        Separator: Text[3];
    begin
        if ClassificationCode = '' then
            exit('');

        // Find the classification level
        Asset.SetRange("Industry Code", IndustryCode);
        Asset.SetRange("Classification Code", ClassificationCode);
        if Asset.FindFirst() then begin
            Asset.CalcFields("Classification Level No.");
            CurrentLevelNo := Asset."Classification Level No.";
        end else begin
            // If no asset found, try to get level directly from classification value
            if ClassValue.Get(IndustryCode, 0, ClassificationCode) then
                CurrentLevelNo := ClassValue."Level Number"
            else
                exit(ClassificationCode);  // Fallback if not found
        end;

        CurrentCode := ClassificationCode;
        Separator := ' / ';

        // Build path from current up to root
        while (CurrentCode <> '') and (CurrentLevelNo > 0) do
            if ClassValue.Get(IndustryCode, CurrentLevelNo, CurrentCode) then begin
                if Path = '' then
                    Path := CopyStr(ClassValue.Description, 1, 250)
                else
                    Path := CopyStr(ClassValue.Description + Separator + Path, 1, 250);

                CurrentCode := ClassValue."Parent Value Code";
                CurrentLevelNo -= 1;
            end else
                CurrentCode := '';

        exit(Path);
    end;

    /// <summary>
    /// Formats holder address into 8-element array using BC's Format Address codeunit.
    /// Handles Customer (with Ship-to), Vendor (with Order Address), Location, and Cost Center.
    /// </summary>
    /// <param name="HolderType">The type of holder.</param>
    /// <param name="HolderCode">The holder code.</param>
    /// <param name="HolderName">The holder name.</param>
    /// <param name="AddrCode">The address code (Ship-to or Order Address).</param>
    /// <param name="AddrArray">Output array with 8 address lines.</param>
    procedure FormatHolderAddress(HolderType: Enum "JML AP Holder Type"; HolderCode: Code[20]; HolderName: Text[100]; AddrCode: Code[10]; var AddrArray: array[8] of Text[100])
    var
        FormatAddr: Codeunit "Format Address";
        Customer: Record Customer;
        Vendor: Record Vendor;
        Location: Record Location;
        ShipToAddr: Record "Ship-to Address";
        OrderAddr: Record "Order Address";
        CompanyInfo: Record "Company Information";
    begin
        Clear(AddrArray);

        case HolderType of
            HolderType::Customer:
                begin
                    if Customer.Get(HolderCode) then begin
                        if AddrCode <> '' then begin
                            if ShipToAddr.Get(HolderCode, AddrCode) then
                                FormatAddr.FormatAddr(AddrArray, ShipToAddr.Name, ShipToAddr."Name 2", ShipToAddr.Contact,
                                    ShipToAddr.Address, ShipToAddr."Address 2", ShipToAddr.City, ShipToAddr."Post Code",
                                    ShipToAddr.County, ShipToAddr."Country/Region Code");
                        end else
                            FormatAddr.Customer(AddrArray, Customer);
                    end;
                end;
            HolderType::Vendor:
                begin
                    if Vendor.Get(HolderCode) then begin
                        if AddrCode <> '' then begin
                            if OrderAddr.Get(HolderCode, AddrCode) then
                                FormatAddr.FormatAddr(AddrArray, OrderAddr.Name, OrderAddr."Name 2", OrderAddr.Contact,
                                    OrderAddr.Address, OrderAddr."Address 2", OrderAddr.City, OrderAddr."Post Code",
                                    OrderAddr.County, OrderAddr."Country/Region Code");
                        end else
                            FormatAddr.Vendor(AddrArray, Vendor);
                    end;
                end;
            HolderType::Location:
                begin
                    if Location.Get(HolderCode) then
                        FormatAddr.Location(AddrArray, Location);
                end;
            HolderType::"Cost Center":
                begin
                    // Cost centers don't have physical addresses - use company info
                    AddrArray[1] := HolderName;
                    AddrArray[2] := StrSubstNo('%1: %2', Format(HolderType), HolderCode);
                    if CompanyInfo.Get() then begin
                        AddrArray[3] := CompanyInfo.Name;
                        AddrArray[4] := CompanyInfo.Address;
                        if CompanyInfo."Address 2" <> '' then
                            AddrArray[5] := CompanyInfo."Address 2";
                        AddrArray[6] := CompanyInfo.City + ' ' + CompanyInfo."Post Code";
                        if CompanyInfo."Country/Region Code" <> '' then
                            AddrArray[7] := CompanyInfo."Country/Region Code";
                    end;
                end;
        end;
    end;

    /// <summary>
    /// Gets contact information for a holder (phone, email).
    /// Only applicable for Customer and Vendor holder types.
    /// </summary>
    /// <param name="HolderType">The type of holder.</param>
    /// <param name="HolderCode">The holder code.</param>
    /// <returns>Formatted contact info string, or empty if not applicable.</returns>
    procedure GetHolderContactInfo(HolderType: Enum "JML AP Holder Type"; HolderCode: Code[20]): Text[250]
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
    begin
        case HolderType of
            HolderType::Customer:
                if Customer.Get(HolderCode) then
                    exit(StrSubstNo('Phone: %1, Email: %2', Customer."Phone No.", Customer."E-Mail"));
            HolderType::Vendor:
                if Vendor.Get(HolderCode) then
                    exit(StrSubstNo('Phone: %1, Email: %2', Vendor."Phone No.", Vendor."E-Mail"));
        end;

        exit('');
    end;

    /// <summary>
    /// Formats a date range for display in report headers.
    /// </summary>
    /// <param name="FromDate">Start date.</param>
    /// <param name="ToDate">End date.</param>
    /// <returns>Formatted date range string.</returns>
    procedure FormatDateRange(FromDate: Date; ToDate: Date): Text[100]
    begin
        if (FromDate = 0D) and (ToDate = 0D) then
            exit('All Dates');

        if FromDate = 0D then
            exit(StrSubstNo('Through %1', ToDate));

        if ToDate = 0D then
            exit(StrSubstNo('From %1', FromDate));

        exit(StrSubstNo('%1 - %2', FromDate, ToDate));
    end;

    /// <summary>
    /// Counts distinct holders from a filtered asset recordset.
    /// Useful for grand total calculations in holder-based reports.
    /// </summary>
    /// <param name="Asset">Filtered asset record.</param>
    /// <returns>Count of distinct holders.</returns>
    procedure CountDistinctHolders(var Asset: Record "JML AP Asset"): Integer
    var
        TempHolder: Record "Name/Value Buffer" temporary;
        HolderKey: Text[50];
    begin
        if Asset.FindSet() then
            repeat
                HolderKey := Format(Asset."Current Holder Type") + '|' + Asset."Current Holder Code";
                if not TempHolder.Get(HolderKey) then begin
                    TempHolder.Init();
                    TempHolder.ID := TempHolder.Count + 1;
                    TempHolder.Name := HolderKey;
                    TempHolder.Insert();
                end;
            until Asset.Next() = 0;

        exit(TempHolder.Count());
    end;
}
