table 70182308 "JML AP Holder Entry"
{
    Caption = 'Asset Holder Entry';
    DataClassification = CustomerContent;
    LookupPageId = "JML AP Holder Entries";
    DrillDownPageId = "JML AP Holder Entries";

    fields
    {
        // === PRIMARY KEY ===
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the entry number.';
        }

        // === ASSET IDENTIFICATION ===
        field(10; "Asset No."; Code[20])
        {
            Caption = 'Asset No.';
            ToolTip = 'Specifies the asset number.';
            TableRelation = "JML AP Asset";
            NotBlank = true;
        }

        field(11; "Asset Description"; Text[100])
        {
            Caption = 'Asset Description';
            ToolTip = 'Specifies the asset description.';
            FieldClass = FlowField;
            CalcFormula = Lookup("JML AP Asset".Description where("No." = field("Asset No.")));
            Editable = false;
        }

        // === POSTING INFORMATION ===
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the posting date.';
            NotBlank = true;
        }

        field(22; "Entry Type"; Enum "JML AP Holder Entry Type")
        {
            Caption = 'Entry Type';
            ToolTip = 'Specifies the entry type (Initial Balance, Transfer Out, Transfer In).';
            NotBlank = true;
        }

        // === HOLDER INFORMATION ===
        field(30; "Holder Type"; Enum "JML AP Holder Type")
        {
            Caption = 'Holder Type';
            ToolTip = 'Specifies the holder type.';
        }

        field(31; "Holder Code"; Code[20])
        {
            Caption = 'Holder Code';
            ToolTip = 'Specifies the holder code.';
            TableRelation = if ("Holder Type" = const(Customer)) Customer."No."
                            else if ("Holder Type" = const(Vendor)) Vendor."No."
                            else if ("Holder Type" = const(Location)) Location.Code;
        }

        field(32; "Holder Name"; Text[100])
        {
            Caption = 'Holder Name';
            ToolTip = 'Specifies the holder name.';
        }

        field(33; "Holder Addr Code"; Code[10])
        {
            Caption = 'Holder Address Code';
            ToolTip = 'Specifies the ship-to address code (for customers) or order address code (for vendors).';
        }

        // === TRANSACTION LINKING ===
        field(40; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            ToolTip = 'Specifies the transaction number that links paired Transfer Out/Transfer In entries.';
        }

        field(41; "Document Type"; Enum "JML AP Document Type")
        {
            Caption = 'Document Type';
            ToolTip = 'Specifies the document type.';
        }

        field(42; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the document number.';
        }

        field(43; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
            ToolTip = 'Specifies the document line number.';
        }

        field(44; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            ToolTip = 'Specifies the external document number.';
        }

        // === REASON AND NOTES ===
        field(50; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            ToolTip = 'Specifies the reason code.';
            TableRelation = "Reason Code";
        }

        field(51; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description.';
        }

        // === USER TRACKING ===
        field(60; "User ID"; Code[50])
        {
            Caption = 'User ID';
            ToolTip = 'Specifies who created the entry.';
            Editable = false;
        }

        field(61; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            ToolTip = 'Specifies the source code.';
            TableRelation = "Source Code";
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Asset; "Asset No.", "Posting Date")
        {
            // Enables efficient holder lookup at specific date
        }
        key(Transaction; "Transaction No.", "Entry Type")
        {
            // Links paired entries
        }
        key(Document; "Document Type", "Document No.")
        {
        }
        key(Holder; "Holder Type", "Holder Code", "Posting Date")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "Asset No.", "Posting Date", "Holder Name")
        {
        }
    }

    trigger OnInsert()
    begin
        "User ID" := CopyStr(UserId, 1, MaxStrLen("User ID"));
    end;

    /// <summary>
    /// Gets the current holder of an asset on a specific date.
    /// </summary>
    /// <param name="AssetNo">The asset number to query.</param>
    /// <param name="OnDate">The date to check holder status.</param>
    /// <param name="HolderType">Output: The holder type on that date.</param>
    /// <param name="HolderCode">Output: The holder code on that date.</param>
    /// <returns>True if holder found, False if no holder entries exist.</returns>
    procedure GetHolderOnDate(AssetNo: Code[20]; OnDate: Date; var HolderType: Enum "JML AP Holder Type"; var HolderCode: Code[20]): Boolean
    var
        HolderEntry: Record "JML AP Holder Entry";
    begin
        // Find the last entry for this asset up to the specified date
        HolderEntry.SetCurrentKey("Asset No.", "Posting Date");
        HolderEntry.SetRange("Asset No.", AssetNo);
        HolderEntry.SetRange("Posting Date", 0D, OnDate);
        if HolderEntry.FindLast() then
            // For Transfer Out entry, we need to find corresponding Transfer In
            if HolderEntry."Entry Type" = HolderEntry."Entry Type"::"Transfer Out" then begin
                HolderEntry.SetRange("Transaction No.", HolderEntry."Transaction No.");
                HolderEntry.SetRange("Entry Type", HolderEntry."Entry Type"::"Transfer In");
                if HolderEntry.FindFirst() then begin
                    HolderType := HolderEntry."Holder Type";
                    HolderCode := HolderEntry."Holder Code";
                    exit(true);
                end;
            end else begin
                // Initial Balance or Transfer In
                HolderType := HolderEntry."Holder Type";
                HolderCode := HolderEntry."Holder Code";
                exit(true);
            end;

        // No holder found
        Clear(HolderType);
        HolderCode := '';
        exit(false);
    end;
}
