table 70182331 "JML AP Asset Mgmt. Cue"
{
    Caption = 'Asset Management Cue';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; "Total Assets"; Integer)
        {
            CalcFormula = count("JML AP Asset");
            Caption = 'Total Assets';
            FieldClass = FlowField;
            ToolTip = 'Specifies the total number of assets in the system.';
        }
        field(3; "Open Transfer Orders"; Integer)
        {
            CalcFormula = count("JML AP Asset Transfer Header" where(Status = const(Open)));
            Caption = 'Open Transfer Orders';
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of open asset transfer orders.';
        }
        field(4; "Released Transfer Orders"; Integer)
        {
            CalcFormula = count("JML AP Asset Transfer Header" where(Status = const(Released)));
            Caption = 'Released Transfer Orders';
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of released asset transfer orders ready for posting.';
        }
        field(5; "Assets Without Holder"; Integer)
        {
            CalcFormula = count("JML AP Asset" where("Current Holder Code" = const('')));
            Caption = 'Assets Without Holder';
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of assets that do not have a holder assigned.';
        }
        field(6; "Blocked Assets"; Integer)
        {
            CalcFormula = count("JML AP Asset" where(Blocked = const(true)));
            Caption = 'Blocked Assets';
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of blocked assets.';
        }
        field(7; "Total Component Entries"; Integer)
        {
            CalcFormula = count("JML AP Component Entry");
            Caption = 'Total Component Entries';
            FieldClass = FlowField;
            ToolTip = 'Specifies the total number of component entries recorded.';
        }
        field(8; "Assets Modified Today"; Integer)
        {
            CalcFormula = count("JML AP Asset" where("Last Date Modified" = field("Date Filter")));
            Caption = 'Assets Modified Today';
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of assets modified on the selected date.';
        }
        field(9; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
            ToolTip = 'Specifies a date filter for time-based calculations.';
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
