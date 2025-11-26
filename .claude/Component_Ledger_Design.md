# Component Ledger Design Document

**Project:** Asset Pro - Component Tracking with Posting
**Version:** 1.0
**Date:** 2025-11-26
**Status:** ⚠️ AWAITING APPROVAL

---

## 1. OBJECTIVE

Implement a simple, ledger-based component tracking system that:
- ✅ Records component Install/Remove/Replace operations
- ✅ Provides complete audit trail
- ✅ Supports posting from Asset Journal
- ✅ Supports posting from BC Purchase/Sales documents
- ✅ Follows Holder Entry pattern (proven architecture)

---

## 2. ARCHITECTURE OVERVIEW

### **Pattern: Ledger-Based (Like Holder Entries)**

```
User Action → Journal/Document → Posting Codeunit → Component Entry (Ledger)
```

**Key Principle:** Component Entry is a **ledger table** (append-only, never modify/delete)

### **Data Flow:**

```
┌─────────────────────────────────────────────────────────────┐
│                    POSTING SOURCES                          │
└─────────────────────────────────────────────────────────────┘
         │                    │                    │
         ▼                    ▼                    ▼
  Asset Journal      Sales Document       Purchase Document
  (Manual entry)     (Customer receives)  (Vendor supplies)
         │                    │                    │
         └────────────────────┴────────────────────┘
                              │
                              ▼
                 ┌─────────────────────────┐
                 │ Component Posting Logic  │
                 │ (Validation + Creation)  │
                 └─────────────────────────┘
                              │
                              ▼
                 ┌─────────────────────────┐
                 │  Component Entry Ledger  │
                 │  (Permanent Audit Trail) │
                 └─────────────────────────┘
                              │
                              ▼
                 ┌─────────────────────────┐
                 │  Current Components View │
                 │  (Calculated from ledger)│
                 └─────────────────────────┘
```

---

## 3. OBJECTS TO CREATE

### **Tables**

#### **Table 70182329: JML AP Component Entry**

**Purpose:** Ledger table - complete history of all component operations

```al
table 70182329 "JML AP Component Entry"
{
    Caption = 'Component Entry';
    DataClassification = CustomerContent;
    DrillDownPageId = "JML AP Component Entries";
    LookupPageId = "JML AP Component Entries";

    fields
    {
        // === PRIMARY KEY ===
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }

        // === ASSET REFERENCE ===
        field(10; "Asset No."; Code[20])
        {
            Caption = 'Asset No.';
            TableRelation = "JML AP Asset";
            NotBlank = true;
        }

        field(11; "Asset Description"; Text[100])
        {
            Caption = 'Asset Description';
            FieldClass = FlowField;
            CalcFormula = Lookup("JML AP Asset".Description where("No." = field("Asset No.")));
        }

        // === COMPONENT IDENTIFICATION ===
        field(20; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
            NotBlank = true;
        }

        field(21; "Item Description"; Text[100])
        {
            Caption = 'Item Description';
            FieldClass = FlowField;
            CalcFormula = Lookup(Item.Description where("No." = field("Item No.")));
        }

        field(22; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }

        // === ENTRY TYPE ===
        field(30; "Entry Type"; Enum "JML AP Component Entry Type")
        {
            Caption = 'Entry Type';
        }

        // === QUANTITY ===
        field(40; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0:5;
            // Positive for Install/Add, Negative for Remove
        }

        field(41; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }

        // === PHYSICAL DETAILS ===
        field(50; Position; Text[50])
        {
            Caption = 'Position';
        }

        field(51; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
        }

        field(52; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
        }

        // === DOCUMENT TRACKING ===
        field(60; "Document Type"; Enum "JML AP Document Type")
        {
            Caption = 'Document Type';
        }

        field(61; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }

        field(62; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
        }

        field(63; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }

        field(64; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
        }

        // === POSTING INFO ===
        field(70; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }

        field(71; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }

        field(72; "User ID"; Code[50])
        {
            Caption = 'User ID';
            Editable = false;
        }

        field(73; "Created DateTime"; DateTime)
        {
            Caption = 'Created Date Time';
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
        }
        key(Item; "Item No.", "Asset No.")
        {
        }
        key(Document; "Document Type", "Document No.")
        {
        }
        key(Transaction; "Transaction No.")
        {
        }
    }

    trigger OnInsert()
    begin
        "User ID" := CopyStr(UserId, 1, MaxStrLen("User ID"));
        "Created DateTime" := CurrentDateTime;
    end;
}
```

**Design Notes:**
- ✅ **Auto-increment Entry No.** - No manual assignment needed
- ✅ **Positive/Negative Quantity** - Install (+), Remove (-)
- ✅ **Transaction No.** - Groups related entries (like holder entries)
- ✅ **Immutable** - No OnModify, no OnDelete (ledger principle)

---

#### **Table 70182308: JML AP Component Journal Line**

**Purpose:** Temporary staging for component posting (reuse available ID)

```al
table 70182308 "JML AP Component Journal Line"
{
    Caption = 'Component Journal Line';
    DataClassification = CustomerContent;

    fields
    {
        // === PRIMARY KEY ===
        field(1; "Journal Batch"; Code[20])
        {
            Caption = 'Journal Batch';
            TableRelation = "JML AP Asset Journal Batch";
        }

        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }

        // === ASSET ===
        field(10; "Asset No."; Code[20])
        {
            Caption = 'Asset No.';
            TableRelation = "JML AP Asset";

            trigger OnValidate()
            var
                Asset: Record "JML AP Asset";
            begin
                if Asset.Get("Asset No.") then
                    "Asset Description" := Asset.Description;
            end;
        }

        field(11; "Asset Description"; Text[100])
        {
            Caption = 'Asset Description';
        }

        // === COMPONENT ===
        field(20; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;

            trigger OnValidate()
            var
                Item: Record Item;
            begin
                if Item.Get("Item No.") then begin
                    "Item Description" := Item.Description;
                    if "Unit of Measure Code" = '' then
                        "Unit of Measure Code" := Item."Base Unit of Measure";
                end;
            end;
        }

        field(21; "Item Description"; Text[100])
        {
            Caption = 'Item Description';
        }

        field(22; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }

        // === ENTRY TYPE ===
        field(30; "Entry Type"; Enum "JML AP Component Entry Type")
        {
            Caption = 'Entry Type';
        }

        // === QUANTITY ===
        field(40; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0:5;
        }

        field(41; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }

        // === PHYSICAL DETAILS ===
        field(50; Position; Text[50])
        {
            Caption = 'Position';
        }

        field(51; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
        }

        field(52; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
        }

        // === POSTING INFO ===
        field(60; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }

        field(61; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }

        field(62; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }

        field(63; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
    }

    keys
    {
        key(PK; "Journal Batch", "Line No.")
        {
            Clustered = true;
        }
    }
}
```

---

### **Enum**

#### **Enum 70182406: JML AP Component Entry Type** (Recreate)

```al
enum 70182406 "JML AP Component Entry Type"
{
    Caption = 'Component Entry Type';
    Extensible = true;

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; Install)
    {
        Caption = 'Install';
    }
    value(2; Remove)
    {
        Caption = 'Remove';
    }
    value(3; Replace)
    {
        Caption = 'Replace';
    }
    value(4; Adjustment)
    {
        Caption = 'Adjustment';
    }
}
```

---

### **Pages**

#### **Page 70182373: JML AP Component Entries**

**Purpose:** View component ledger (read-only)

```al
page 70182373 "JML AP Component Entries"
{
    Caption = 'Component Entries';
    PageType = List;
    SourceTable = "JML AP Component Entry";
    ApplicationArea = All;
    UsageCategory = History;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Entries)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the entry number.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the posting date.';
                }
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the entry type.';
                }
                field("Asset No."; Rec."Asset No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the asset number.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the item number.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the quantity.';
                }
                field(Position; Rec.Position)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the position.';
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the serial number.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the document number.';
                }
            }
        }
    }
}
```

---

#### **Page 70182374: JML AP Component Journal**

**Purpose:** Manual component posting

```al
page 70182374 "JML AP Component Journal"
{
    Caption = 'Component Journal';
    PageType = Worksheet;
    SourceTable = "JML AP Component Journal Line";
    ApplicationArea = All;
    UsageCategory = Tasks;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the posting date.';
                }
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the entry type (Install, Remove, Replace, Adjustment).';
                }
                field("Asset No."; Rec."Asset No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the asset number.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the item number.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the quantity (positive for Install, negative for Remove).';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unit of measure.';
                }
                field(Position; Rec.Position)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the position within the asset.';
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the serial number.';
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the reason code.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Post)
            {
                Caption = 'Post';
                Image = Post;
                ApplicationArea = All;
                ToolTip = 'Post the component journal lines.';

                trigger OnAction()
                var
                    ComponentJnlPost: Codeunit "JML AP Component Jnl.-Post";
                begin
                    ComponentJnlPost.Run(Rec);
                end;
            }
        }
    }
}
```

---

### **Codeunits**

#### **Codeunit 70182394: JML AP Component Jnl.-Post**

**Purpose:** Post component journal lines to ledger

```al
codeunit 70182394 "JML AP Component Jnl.-Post"
{
    TableNo = "JML AP Component Journal Line";

    trigger OnRun()
    begin
        PostJournalLines(Rec);
    end;

    local procedure PostJournalLines(var ComponentJnlLine: Record "JML AP Component Journal Line")
    var
        TempJnlLine: Record "JML AP Component Journal Line" temporary;
        TransactionNo: Integer;
    begin
        // Validate all lines first
        ComponentJnlLine.SetRange("Journal Batch", ComponentJnlLine."Journal Batch");
        if ComponentJnlLine.FindSet() then
            repeat
                ValidateJournalLine(ComponentJnlLine);
            until ComponentJnlLine.Next() = 0;

        // Get transaction number
        TransactionNo := GetNextTransactionNo();

        // Post all lines
        ComponentJnlLine.FindSet();
        repeat
            CreateComponentEntry(ComponentJnlLine, TransactionNo);
        until ComponentJnlLine.Next() = 0;

        // Delete posted lines
        ComponentJnlLine.DeleteAll(true);

        Message('Component journal posted successfully.');
    end;

    local procedure ValidateJournalLine(var ComponentJnlLine: Record "JML AP Component Journal Line")
    var
        Asset: Record "JML AP Asset";
        Item: Record Item;
    begin
        // Validate required fields
        ComponentJnlLine.TestField("Asset No.");
        ComponentJnlLine.TestField("Item No.");
        ComponentJnlLine.TestField("Entry Type");
        ComponentJnlLine.TestField("Posting Date");
        ComponentJnlLine.TestField(Quantity);

        // Validate Asset exists
        if not Asset.Get(ComponentJnlLine."Asset No.") then
            Error('Asset %1 does not exist.', ComponentJnlLine."Asset No.");

        // Validate Item exists
        if not Item.Get(ComponentJnlLine."Item No.") then
            Error('Item %1 does not exist.', ComponentJnlLine."Item No.");

        // Validate quantity sign based on entry type
        case ComponentJnlLine."Entry Type" of
            ComponentJnlLine."Entry Type"::Install,
            ComponentJnlLine."Entry Type"::Adjustment:
                if ComponentJnlLine.Quantity <= 0 then
                    Error('Quantity must be positive for Install/Adjustment operations.');
            ComponentJnlLine."Entry Type"::Remove:
                if ComponentJnlLine.Quantity >= 0 then
                    Error('Quantity must be negative for Remove operations.');
        end;
    end;

    local procedure CreateComponentEntry(var ComponentJnlLine: Record "JML AP Component Journal Line"; TransactionNo: Integer)
    var
        ComponentEntry: Record "JML AP Component Entry";
    begin
        ComponentEntry.Init();
        ComponentEntry."Asset No." := ComponentJnlLine."Asset No.";
        ComponentEntry."Item No." := ComponentJnlLine."Item No.";
        ComponentEntry."Variant Code" := ComponentJnlLine."Variant Code";
        ComponentEntry."Entry Type" := ComponentJnlLine."Entry Type";
        ComponentEntry.Quantity := ComponentJnlLine.Quantity;
        ComponentEntry."Unit of Measure Code" := ComponentJnlLine."Unit of Measure Code";
        ComponentEntry.Position := ComponentJnlLine.Position;
        ComponentEntry."Serial No." := ComponentJnlLine."Serial No.";
        ComponentEntry."Lot No." := ComponentJnlLine."Lot No.";
        ComponentEntry."Document Type" := ComponentEntry."Document Type"::Journal;
        ComponentEntry."Document No." := ComponentJnlLine."Document No.";
        ComponentEntry."External Document No." := ComponentJnlLine."External Document No.";
        ComponentEntry."Transaction No." := TransactionNo;
        ComponentEntry."Posting Date" := ComponentJnlLine."Posting Date";
        ComponentEntry."Reason Code" := ComponentJnlLine."Reason Code";
        ComponentEntry.Insert(true);
    end;

    local procedure GetNextTransactionNo(): Integer
    var
        ComponentEntry: Record "JML AP Component Entry";
    begin
        if ComponentEntry.FindLast() then
            exit(ComponentEntry."Transaction No." + 1)
        else
            exit(1);
    end;
}
```

---

## 4. INTEGRATION WITH BC DOCUMENTS

### **Phase 1: Purchase Document Integration**

When posting a Purchase Receipt, create component entries for items received.

**Approach:**
1. Add "Component Asset No." field to Purchase Line (table extension)
2. On Purchase Receipt posting, if "Component Asset No." is populated:
   - Create Component Journal Line
   - Post via Component Jnl.-Post codeunit
   - Entry Type = Install, Quantity = Positive

---

### **Phase 2: Sales Document Integration**

When posting a Sales Shipment, create component entries for items shipped.

**Approach:**
1. Add "Component Asset No." field to Sales Line (table extension)
2. On Sales Shipment posting, if "Component Asset No." is populated:
   - Create Component Journal Line
   - Post via Component Jnl.-Post codeunit
   - Entry Type = Remove, Quantity = Negative

---

## 5. CURRENT COMPONENTS VIEW (Future Enhancement)

**Optional:** Create a "Current Components" page that shows installed components by aggregating entries.

**Query Logic:**
```sql
SUM(Quantity) GROUP BY Asset No., Item No. HAVING SUM(Quantity) > 0
```

**Deferred:** Not required for MVP, can be added later if needed.

---

## 6. OBJECT ID ALLOCATION

| ID | Type | Name |
|----|------|------|
| **70182308** | Table | JML AP Component Journal Line (reuse available ID) |
| **70182329** | Table | JML AP Component Entry |
| **70182373** | Page | JML AP Component Entries |
| **70182374** | Page | JML AP Component Journal |
| **70182394** | Codeunit | JML AP Component Jnl.-Post |
| **70182406** | Enum | JML AP Component Entry Type (recreate) |

**Total New Objects:** 6 (2 tables, 2 pages, 1 codeunit, 1 enum)

---

## 7. IMPLEMENTATION STAGES

### **Stage 1: Core Component Ledger**
- Create Component Entry table
- Create Component Entry Type enum
- Create Component Entries page (read-only)
- **Test:** View empty entries page

### **Stage 2: Manual Posting**
- Create Component Journal Line table
- Create Component Journal page
- Create Component Jnl.-Post codeunit
- **Test:** Post manual component entries

### **Stage 3: Purchase Integration**
- Extend Purchase Line with Component Asset No.
- Subscribe to Purchase Receipt posting
- Create component entries on receipt
- **Test:** Receive item, verify component entry created

### **Stage 4: Sales Integration**
- Extend Sales Line with Component Asset No.
- Subscribe to Sales Shipment posting
- Create component entries on shipment
- **Test:** Ship item, verify component entry created

---

## 8. SUCCESS CRITERIA

✅ Can manually post component Install/Remove operations
✅ Component Entry ledger stores complete history
✅ Entries immutable (no modify/delete)
✅ Purchase receipt creates component entries
✅ Sales shipment creates component entries
✅ All entries linked via Transaction No.
✅ Posting date validation works
✅ Audit trail complete (who, when, why, what)

---

## 9. TESTING STRATEGY

**Unit Tests:**
- Post component journal (happy path)
- Validate quantity signs (error case)
- Missing required fields (error case)

**Integration Tests:**
- Purchase receipt → component entry created
- Sales shipment → component entry created
- Transaction No. grouping correct

---

## 10. APPROVAL REQUIRED

⚠️ **Before proceeding to implementation, please approve:**

1. ✅ Ledger-based architecture (vs. master table)
2. ✅ Object ID allocation (70182308, 70182329, 70182373, 70182374, 70182394, 70182406)
3. ✅ 4-stage implementation approach
4. ✅ Integration with Purchase/Sales documents
5. ✅ Defer "Current Components View" to future

**Respond with "Approved" to proceed to Phase 3 (Implementation).**

---

**END OF DESIGN DOCUMENT**
