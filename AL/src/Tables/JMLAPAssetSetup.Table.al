table 70182300 "JML AP Asset Setup"
{
    Caption = 'Asset Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }

        // Numbering
        field(10; "Asset Nos."; Code[20])
        {
            Caption = 'Asset Nos.';
            ToolTip = 'Specifies the number series for asset numbers.';
            TableRelation = "No. Series";
        }

        field(11; "Transfer Order Nos."; Code[20])
        {
            Caption = 'Transfer Order Nos.';
            ToolTip = 'Specifies the number series for asset transfer orders.';
            TableRelation = "No. Series";
        }

        field(12; "Posted Transfer Nos."; Code[20])
        {
            Caption = 'Posted Transfer Nos.';
            ToolTip = 'Specifies the number series for posted asset transfers.';
            TableRelation = "No. Series";
        }

        // Defaults
        field(20; "Default Industry Code"; Code[20])
        {
            Caption = 'Default Industry Code';
            ToolTip = 'Specifies the default industry code for new assets.';
            TableRelation = "JML AP Asset Industry";
        }

        // Feature Toggles (Optional Features Only)
        // Note: Classification and Parent-Child are core features, always available
        field(31; "Enable Attributes"; Boolean)
        {
            Caption = 'Enable Attributes';
            ToolTip = 'Specifies whether custom attributes are enabled. Disable to improve performance if custom attributes are not needed.';
            InitValue = true;
        }

        field(32; "Enable Holder History"; Boolean)
        {
            Caption = 'Enable Holder History';
            ToolTip = 'Specifies whether holder history tracking is enabled. Disable if holder tracking is managed externally.';
            InitValue = true;
        }

        field(33; "Block Manual Holder Change"; Boolean)
        {
            Caption = 'Block Manual Holder Change';
            ToolTip = 'Specifies whether manual changes to Current Holder on Asset Card are blocked. When enabled, holders can only be changed via Asset Journal or Transfer Orders.';
            InitValue = false;
        }

        // System
        // Note: Validation limits (Max Circular Check Depth, Max Classification Levels)
        // are now constants in JML AP Asset Validation codeunit, not user-configurable
        // Note: "Current Industry Context" field removed - CaptionClass resolves per-asset using asset's Industry Code
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    /// <summary>
    /// Gets the setup record, creating it if it doesn't exist.
    /// Uses singleton pattern to ensure only one record exists.
    /// </summary>
    procedure GetRecordOnce()
    begin
        if not IsInitialized then begin
            if not Get() then begin
                Init();
                Insert();
            end;
            IsInitialized := true;
        end;
    end;

    var
        IsInitialized: Boolean;
}
