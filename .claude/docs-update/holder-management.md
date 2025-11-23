---
id: holder-management
title: Holder Management
sidebar_position: 6
description: "Track asset location and custody in Business Central. Record who holds each asset - customers, vendors, locations, or employees - with complete audit trail and holder history."
keywords: ["asset holder tracking", "asset custody BC", "asset location management", "holder history", "asset accountability", "equipment location tracking business central", "dynamics-365", "asset-pro", "business-central"]
category: "Core Features"
---

Holder Management tracks **who has the asset right now** and maintains a complete **audit trail of all custody changes**.

## Understanding Holder Tracking

### Current Holder vs Holder History

Asset Pro maintains two types of holder information:

**1\. Current Holder (on Asset Card)**

*   Stores the **current** holder of the asset

*   Quick reference: "Where is this asset right now?"

*   Updated whenever asset custody changes

*   Fields:

    *   Current Holder Type

    *   Current Holder Code

    *   Current Holder Name

    *   Current Holder Since


**2\. Holder History (Holder Entries)**

*   Permanent **ledger** of all custody changes

*   Complete audit trail: "Who had this asset and when?"

*   Cannot be modified or deleted (ledger integrity)

*   Enables point-in-time holder lookup

*   Enables custody accountability reporting


### Enable Holder History Feature

Holder History is controlled by a feature toggle in Asset Setup.

**To enable/disable:**

1.  Choose the 🔎 icon, enter **Asset Setup**, and choose the related link

2.  Go to **Features** FastTab

3.  Toggle **Enable Holder History**

    *   ☑️ **Enabled** (default): All holder changes are automatically logged to Holder Entries ledger

    *   ☐ **Disabled**: Only Current Holder is maintained (no history tracking)


:::info When to Disable Holder History
Disable if:

*   You track custody externally in another system

*   You don't need audit trail for compliance

*   You want to simplify the system


Most organizations should **keep it enabled** for accountability and reporting.
:::

## Viewing Holder History

### From Asset Card

1.  Open the **Asset Card** for any asset

2.  Click **Holder History** action (ribbon)

3.  The **Holder Entries** page opens, filtered to the current asset


### From Holder Entries Page

1.  Choose the 🔎 icon, enter **Holder Entries**, and choose the related link

2.  View all holder movements across all assets

3.  Use filters to narrow by:

    *   Asset No.

    *   Holder Type/Code

    *   Posting Date range

    *   Entry Type


## Understanding Holder Entries

Each holder entry is a **permanent ledger record** documenting asset custody.

### Entry Types

Holder entries use three entry types:

#### 1\. Initial Balance

**Purpose**: Records the starting holder when first tracking an asset

**When Created**:

*   When asset is created with a holder assigned

*   When enabling Holder History for existing assets with holders

*   Manual posting of initial holder position


**Example Entry:**

Entry No.: 1
Asset No.: ASSET-0001
Posting Date: 2024-01-15
Entry Type: Initial Balance
Holder Type: Location
Holder Code: MAIN-WH
Holder Name: Main Warehouse
Transaction No.: (blank)

**Meaning**: "On 2024-01-15, this asset was initially recorded at Main Warehouse"

#### 2\. Transfer Out

**Purpose**: Records asset leaving a holder

**When Created**:

*   When asset custody is transferred away from current holder

*   Always paired with a "Transfer In" entry

*   Links to corresponding Transfer In via Transaction No.


**Example Entry:**

Entry No.: 2
Asset No.: ASSET-0001
Posting Date: 2024-02-20
Entry Type: Transfer Out
Holder Type: Location
Holder Code: MAIN-WH
Holder Name: Main Warehouse
Transaction No.: 1

**Meaning**: "On 2024-02-20, this asset left Main Warehouse (Transaction #1)"

#### 3\. Transfer In

**Purpose**: Records asset arriving at a new holder

**When Created**:

*   When asset custody is transferred to a new holder

*   Always paired with a "Transfer Out" entry

*   Links to corresponding Transfer Out via Transaction No.


**Example Entry:**

Entry No.: 3
Asset No.: ASSET-0001
Posting Date: 2024-02-20
Entry Type: Transfer In
Holder Type: Customer
Holder Code: C00001
Holder Name: Contoso Ltd.
Transaction No.: 1

**Meaning**: "On 2024-02-20, this asset arrived at Contoso Ltd. (Transaction #1)"

### Transaction Linking

The **Transaction No.** field links paired Transfer Out/Transfer In entries.

**Example: Complete Transfer**

Transaction No. 1 (Asset moved from warehouse to customer):
  Entry No. 2: Transfer Out  - Location: MAIN-WH     (leaving)
  Entry No. 3: Transfer In   - Customer: C00001      (arriving)

Transaction No. 2 (Asset returned from customer to warehouse):
  Entry No. 4: Transfer Out  - Customer: C00001      (leaving)
  Entry No. 5: Transfer In   - Location: MAIN-WH     (arriving)

### Holder Entry Fields

#### Entry No.

*   Unique identifier, auto-incremented

*   Cannot be changed

*   Sequential across all holder entries


#### Asset No.

*   The asset this entry applies to

*   Links to Asset table

*   Required field


#### Asset Description (read-only)

*   FlowField from Asset table

*   Shows asset description for easy identification


#### Posting Date

*   Date of the custody change

*   Required field

*   Used for point-in-time holder queries


#### Entry Type

*   Initial Balance, Transfer Out, or Transfer In

*   Required field

*   Determines meaning of the entry


#### Holder Type / Holder Code / Holder Name

*   Who holds (or held) the asset

*   Holder Type: Customer, Vendor, Location

*   Holder Code: Identifier of the specific holder

*   Holder Name: Name for display (auto-populated)


#### Transaction No.

*   Links paired Transfer Out/Transfer In entries

*   Same number for both entries in a transfer

*   Empty for Initial Balance entries


#### Document Type / Document No. / Document Line No.

*   Links to source documents

*   Examples:

    *   Journal (from Asset Journal)

    *   Transfer Order (from Asset Transfer Order)

    *   Sales Order (future: from sales shipment integration)

    *   Purchase Order (future: from purchase receipt integration)

*   Document No. contains the document identifier

#### External Document No.

*   Customer's or vendor's document reference

*   Example: Customer's PO number, delivery note number

*   Optional field for external traceability


#### Reason Code

*   Business Central reason code

*   Categorizes why the transfer occurred

*   Examples: SALE, REPAIR, RELOCATION, RETURN

*   Optional field


#### Description

*   Free-text description of the movement

*   Examples: "Shipped for customer use", "Returned from service", "Relocated to new facility"

*   Optional field


#### User ID (read-only)

*   User who created the entry

*   Auto-populated from system

*   Audit trail for accountability


#### Source Code (read-only)

*   Business Central source code

*   Categorizes how entry was created

*   Set by posting codeunit


## How Holder Changes Are Recorded

Asset Pro provides **four methods** to record holder changes, each suited for different use cases.

### Method 1: Manual Holder Change (Asset Card)

**Use For**: Quick, simple holder updates

**How It Works**:

1.  Open the **Asset Card**

2.  Edit **Current Holder Type** and **Current Holder Code** fields

3.  System automatically:
    *   Creates holder entries (Transfer Out/Transfer In)
    *   Updates Current Holder fields
    *   Sets Current Holder Since date
    *   Transfers all child assets automatically
    *   Uses work date as posting date


**Characteristics**:
*   ✅ Fastest method for single assets
*   ✅ No separate posting step
*   ✅ Auto-registers when holder history enabled
*   ⚠️ Can be blocked in Asset Setup (see Manual Holder Change Control)

**Example Use Case**: Asset returned from customer, quickly update holder back to warehouse

:::info Manual Holder Change Control
Administrators can block manual holder changes via **Asset Setup → Block Manual Holder Change**.

When enabled:
*   Users cannot change Current Holder directly on Asset Card
*   Error: "Manual holder changes are blocked. Use Asset Journal or Transfer Order."
*   Forces use of controlled transfer methods (Journal or Transfer Order)
*   Provides stronger audit control

See Manual Holder Change Control section below for details.
:::

### Method 2: Asset Journal (Batch Transfers)

**Use For**: Batch movements, periodic transfers, corrections

**How It Works**:

1.  Choose the 🔎 icon, enter **Asset Journal**

2.  Create journal lines for assets to transfer

3.  Specify From Holder, To Holder, Posting Date

4.  Post the journal batch

5.  System creates holder entries and updates assets


**Characteristics**:
*   ✅ Transfer multiple assets at once
*   ✅ Batch processing efficiency
*   ✅ Supports posting date control
*   ✅ Enhanced validation rules
*   ✅ Cannot backdate before last entry
*   ✅ Auto-transfers child assets

**Example Use Case**: Ship 10 assets to customer in one posting, or monthly location reconciliation

See Asset Journal for complete documentation.

### Method 3: Asset Transfer Orders (Document-Based)

**Use For**: Formal documented transfers, approval workflows

**How It Works**:

1.  Choose the 🔎 icon, enter **Asset Transfer Orders**

2.  Create new transfer order (header + lines)

3.  Specify From Holder, To Holder, add asset lines

4.  Release order (approval checkpoint)

5.  Post order

6.  System creates holder entries, posted document archived


**Characteristics**:
*   ✅ Document pattern (permanent archive)
*   ✅ Release/approval workflow
*   ✅ Open → Released → Posted lifecycle
*   ✅ Permanent posted document record
*   ✅ Links to external documents
*   ✅ Auto-transfers child assets

**Example Use Case**: Customer rental shipment with formal documentation and traceability

See Asset Transfer Orders for complete documentation.

### Method 4: BC Document Integration (Future)

**Coming in Phase 2 Stages 4-6:**

*   **Sales Shipment** - Auto-transfer assets to customer when shipping

*   **Purchase Receipt** - Auto-transfer assets from vendor when receiving

*   **Inventory Transfer** - Sync asset movements with inventory transfers


:::info Current Status
Methods 1-3 are **implemented and available now** (Phase 2 Stage 3.1 complete).

Method 4 (BC Document Integration) is planned for Phase 2 Stages 4, 5, and 6.
:::

## Manual Holder Change Control

Asset Pro provides optional **blocking of manual holder changes** to enforce stronger audit control.

### Block Manual Holder Change Setting

**Location**: Asset Setup → General FastTab → Block Manual Holder Change

**When Enabled (☑️)**:
*   Users **cannot** change Current Holder fields directly on Asset Card
*   System throws error: "Manual holder changes are blocked. Use Asset Journal or Transfer Order."
*   Forces use of controlled transfer methods
*   Provides centralized audit trail

**When Disabled (☐)** (default):
*   Users **can** change Current Holder on Asset Card
*   System automatically creates holder entries
*   Changes tracked with document prefix "MAN-" (Manual)
*   Provides flexibility and convenience

### When to Enable Blocking

**✅ Enable blocking if:**

*   Strict audit requirements
*   Need approval workflow for all transfers
*   Multiple users with different authorization levels
*   Want all transfers to go through journal or transfer orders
*   Compliance regulations require formal documentation

**❌ Keep disabled if:**

*   Small organization with trusted users
*   Need flexibility for quick corrections
*   Manual holder changes are infrequent
*   Trust users to use appropriate method

### Auto-Registration of Manual Changes

When blocking is **disabled** (manual changes allowed), Asset Pro automatically registers changes:

**Document Prefix**: Manual changes are documented with prefix "MAN-"

**Example Holder Entry:**
Document Type: Journal
Document No.: MAN-ASSET-0001-1
Posting Date: Work date
Description: Manual holder change

**Behavior**:
*   Uses journal posting pattern internally
*   All validation rules apply (posting date, children propagation)
*   Creates standard Transfer Out/Transfer In entries
*   Tracks user who made the change

**Example Use Case**: User changes asset holder on Asset Card from MAIN-WH to C00001
*   System validates change
*   Creates holder entries via internal journal posting
*   Document No. = MAN-ASSET-0001-1
*   All children transferred automatically
*   Posted with work date

## Choosing the Right Transfer Method

| Scenario | Recommended Method | Reason |
| --- | --- | --- |
| Single asset quick update | Manual (Asset Card) | Fastest, if not blocked |
| Transfer 5-20 assets | Asset Journal | Batch efficiency |
| Customer shipment (formal) | Transfer Order | Document archive |
| Monthly reconciliation | Asset Journal | Batch corrections |
| Need approval workflow | Transfer Order | Release step |
| Correction/fix data error | Asset Journal | Controlled posting date |
| Initial holder setup (100s) | Asset Journal | Batch processing |
| External reference needed | Transfer Order | External Document No. field |
| Strict audit requirements | Transfer Order | Permanent document |

## Point-in-Time Holder Lookup

One powerful feature of holder history is answering: **"Who had this asset on a specific date?"**

### Use Cases

*   **Billing**: "Which customer had the asset during January?"

*   **Compliance**: "Where was this asset on inspection date?"

*   **Investigation**: "Who had custody when incident occurred?"

*   **Reconciliation**: "What assets were at Location X on year-end?"


### Lookup Logic

The system walks backward through holder entries from the query date:

1.  **Filter** entries for the asset up to query date

2.  **Find** the last entry on or before that date

3.  **If Transfer Out**: Find corresponding Transfer In to get new holder

4.  **If Transfer In or Initial Balance**: That entry shows the holder

5.  **Return** the holder at that point in time


**Example:**

Query: Who held Asset ASSET-0001 on 2024-02-15?

Holder Entries:
  2024-01-15: Initial Balance - Location: MAIN-WH
  2024-02-20: Transfer Out    - Location: MAIN-WH    (Transaction 1)
  2024-02-20: Transfer In     - Customer: C00001     (Transaction 1)
  2024-03-10: Transfer Out    - Customer: C00001     (Transaction 2)
  2024-03-10: Transfer In     - Location: MAIN-WH    (Transaction 2)

Answer: Location MAIN-WH
Reason: Last entry on or before 2024-02-15 is Initial Balance at MAIN-WH

:::info Future Reporting
Point-in-time holder reports and custody timeline visualizations are planned for future phases.
:::

## Working with Holder Entries

### Viewing and Filtering

**Filter by Asset**

*   See complete history for one asset

*   Access from Asset Card → Holder History action


**Filter by Holder**

*   See all assets that passed through a customer

*   Filter: Holder Type = Customer, Holder Code = C00001


**Filter by Date Range**

*   See all movements in a period

*   Filter: Posting Date = 01/01/2024..01/31/2024


**Filter by Transaction**

*   See paired Transfer Out/In entries

*   Filter: Transaction No. = 1


**Filter by Document**

*   See all assets transferred via specific document

*   Filter: Document No. = TRANS-0042


### Analyzing Holder History

**Custody Trail**

*   Sort by Entry No. to see chronological custody changes

*   Identify patterns: frequent moves, long-term holders


**Audit Reconciliation**

*   Compare holder entries to physical inventory

*   Verify Current Holder matches latest entry

*   Identify discrepancies


**Accountability**

*   User ID shows who recorded each transfer

*   Posting Date shows when transfer occurred

*   Document No. links to source document
*   Supports compliance and investigations


## Holder History Best Practices

### Enable from Day 1

*   Turn on **Enable Holder History** before creating assets

*   Ensures complete audit trail from the beginning

*   Difficult to reconstruct history retroactively


### Accurate Posting Dates

*   Use **actual transfer date**, not data entry date

*   Posting Date should reflect physical custody change

*   Enables accurate point-in-time queries


### Use Descriptions

*   Add meaningful Description to entries (in journal/transfer order)

*   Explain why: "Shipped to customer for 6-month lease"

*   Helps future investigations and analysis


### Link Documents When Possible

*   Use Transfer Orders for formal transfers (permanent document)

*   Fill in External Document No. for customer/vendor references

*   Creates traceability: holder entry → transfer order → customer PO


### Choose Appropriate Method

*   Use Asset Journal for batch transfers and corrections

*   Use Transfer Orders for formal documented transfers

*   Consider enabling Block Manual Holder Change for strict audit control


### Regular Reconciliation

**Monthly:**

*   Review Current Holder vs physical location

*   Update any incorrect assignments via Asset Journal

*   Investigate discrepancies


**Quarterly:**

*   Generate custody report by holder

*   Reconcile with customer/location records

*   Verify high-value asset locations


**Annually:**

*   Audit holder history completeness

*   Review compliance with custody policies

*   Analyze transfer patterns for process improvement


## Holder Entry Integrity

### Ledger Principles

Holder Entries follow **ledger principles**:

**✅ Cannot Modify**: Entries cannot be edited after creation
**✅ Cannot Delete**: Entries cannot be removed (except deleting asset)
**✅ Chronological**: Entry No. ensures sequence
**✅ Balanced**: Transfers always have paired Out/In entries
**✅ Traceable**: User ID and Source Code track origin

### Data Consistency Rules

**Rule 1: Asset's Current Holder matches latest entry**

*   Current Holder on Asset Card = Holder from latest Transfer In or Initial Balance entry

*   If inconsistency detected, indicates data issue


**Rule 2: Transfer Out always paired with Transfer In**

*   Same Transaction No. links them

*   Same Posting Date for both

*   Different holders (from/to)


**Rule 3: No gaps in custody**

*   Every Transfer Out must have corresponding Transfer In

*   No undefined custody periods

*   Supports continuous accountability


### What Happens When Asset is Deleted

When an asset is deleted:

**If Holder Entries Exist:**

*   ❌ **Deletion is blocked**

*   Error: "Cannot delete asset because it has holder history entries"

*   **Reason**: Preserves audit trail and ledger integrity


**If No Holder Entries:**

*   ✅ **Deletion is allowed**

*   Asset had no custody tracking

*   Safe to remove


:::tip Alternative to Deletion
Instead of deleting assets with history:

1.  Set **Status** = Disposed

2.  Check **Blocked** = true

3.  Set **Decommission Date**

4.  Keep record for historical reporting


This preserves audit trail while removing asset from active use.
:::

## Troubleshooting

### Current Holder Doesn't Match Holder History

**Problem**: Asset Card shows different holder than latest holder entry

**Causes**:

1.  Holder changed directly on Asset Card without triggering history entry

2.  Data corruption or direct database modification

3.  Feature toggle changed mid-use


**Solution**:

1.  Enable **Enable Holder History** in Asset Setup

2.  Verify Current Holder on Asset Card

3.  If incorrect, update to correct holder via Asset Journal (will create new entry)

4.  Review holder entries for gaps


### Cannot Find Holder History Action

**Problem**: Holder History action not visible on Asset Card

**Cause**: Feature not enabled in Asset Setup

**Solution**:

1.  Go to **Asset Setup**

2.  Features FastTab

3.  Enable **Enable Holder History**

4.  Refresh Asset Card


### Transfer Entries Out of Sequence

**Problem**: Transfer Out and Transfer In have different posting dates or wrong order

**Cause**: Manual entry error or legacy data

**Prevention**:

*   Use Asset Journal or Transfer Orders (automatic pairing)

*   Validates Transaction No. links correctly

*   Enforces same posting date

### Cannot Change Holder on Asset Card

**Problem**: Error "Manual holder changes are blocked"

**Cause**: Asset Setup → Block Manual Holder Change is enabled

**Solution**:
*   Use **Asset Journal** for batch transfers, OR
*   Use **Asset Transfer Order** for documented transfers
*   Or ask administrator to disable blocking setting

---
