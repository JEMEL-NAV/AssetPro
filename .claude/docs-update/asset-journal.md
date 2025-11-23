---
id: asset-journal
title: Asset Journal
sidebar_position: 8
description: "Batch-based asset transfers in Business Central. Move multiple assets between holders efficiently with validation, posting date controls, and automatic child propagation."
keywords: ["asset journal BC", "batch asset transfer", "asset movement journal", "holder change posting", "asset transfer validation", "business central asset journal", "dynamics-365", "asset-pro", "business-central"]
category: "Core Features"
---

The Asset Journal provides a **batch-based approach** to transferring assets between holders, similar to how General Journal works for financial transactions.

## Understanding Asset Journal

### When to Use Asset Journal

**✅ Use Asset Journal for:**

*   **Batch transfers** - Moving multiple assets at once

*   **Periodic movements** - Regular scheduled transfers

*   **Manual corrections** - Fixing holder assignments

*   **Quick ad-hoc transfers** - Single or multiple assets

*   **Initial holder setup** - Recording starting positions


**❌ Use Asset Transfer Orders instead for:**

*   **Documented transfers** - When you need a formal document

*   **Workflow approval** - Release/approve before posting

*   **Archived records** - Permanent posted document history

*   **External references** - Linking to customer/vendor documents


### Asset Journal vs Transfer Orders

| Feature | Asset Journal | Asset Transfer Order |
| --- | --- | --- |
| **Style** | Batch/Journal pattern | Document pattern |
| **Workflow** | Direct posting | Open → Released → Posted |
| **Use Case** | Quick transfers, corrections | Formal documented transfers |
| **Approval** | No approval workflow | Release step before posting |
| **Archive** | Only holder entries remain | Posted document preserved |
| **Best For** | Internal movements | External/audited movements |

## Asset Journal Structure

### Journal Batches

Asset Journal uses a **batch-based structure**:

*   Each **batch** is a container for related journal lines

*   You can create multiple batches for different purposes

*   Lines are posted **by batch** (all lines in batch post together)

*   After posting, lines are deleted from batch


**Example Batches:**

*   `DEFAULT` - General purpose transfers

*   `MONTHLY` - Monthly location reconciliations

*   `RETURNS` - Customer returns processing

*   `CORRECTIONS` - Holder corrections


### Journal Lines

Each **journal line** represents one asset transfer:

*   **Asset No.** - The asset being transferred

*   **From Holder** - Current holder (auto-populated, read-only)

*   **To Holder Type/Code** - Destination holder

*   **Posting Date** - When the transfer occurs

*   **Description** - Transfer explanation


## Creating and Using Asset Journal

### Step 1: Access Asset Journal

1.  Choose the 🔎 icon, enter **Asset Journal**, and choose the related link

2.  The Asset Journal page opens

3.  Select a batch from the **Batch Name** dropdown (or create new batch)


### Step 2: Create Journal Lines

For each asset you want to transfer:

1.  Click **New** or press <kbd>Enter</kbd> on empty line

2.  Fill in **Asset No.** - Select the asset to transfer

    *   System auto-fills **From Holder** (current holder)

    *   System auto-fills **Asset Description**

3.  Fill in **Posting Date** - Date of transfer

    *   Defaults to work date

    *   Subject to validation (see Posting Date Validation below)

4.  Fill in **To Holder Type** - Customer, Vendor, or Location

5.  Fill in **To Holder Code** - Specific holder (lookup available)

    *   System auto-fills **To Holder Name**

6.  Optionally fill in **Description** - Reason for transfer

7.  Optionally fill in **Reason Code** - Business Central reason code


**Example Journal Lines:**

| Line | Asset No. | From Holder | To Holder Type | To Holder Code | Posting Date | Description |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | ASSET-0001 | MAIN-WH | Customer | C00001 | 2024-03-15 | Shipped to customer |
| 2 | ASSET-0002 | MAIN-WH | Customer | C00001 | 2024-03-15 | Shipped to customer |
| 3 | ASSET-0010 | C00002 | Location | MAIN-WH | 2024-03-15 | Return from customer |

### Step 3: Validate Lines

Before posting, verify:

*   ✅ **Asset exists** and is not blocked

*   ✅ **From Holder matches** current asset holder

*   ✅ **To Holder is different** from From Holder

*   ✅ **Posting Date is valid** (not backdated incorrectly)

*   ✅ **Asset is not a subasset** (cannot transfer subassets directly)


System performs these validations automatically during posting.

### Step 4: Post the Journal

1.  Click **Post** action (or **Post and Print**)

2.  Confirm posting dialog

3.  System processes each line:

    *   Validates all rules

    *   Creates holder entries (Transfer Out/Transfer In pairs)

    *   Updates asset Current Holder fields

    *   Transfers all child assets automatically

    *   Shows progress dialog for large batches

4.  Upon success:

    *   Lines are deleted from journal

    *   Success message shows count: "Posted 3 asset transfers successfully"

5.  If error occurs:

    *   Posting stops at first error

    *   Error message indicates which line and problem

    *   Fix error and re-post


## Posting Date Validation

Asset Journal enforces **strict posting date rules** to maintain chronological integrity.

### Rule 1: Cannot Backdate Before Last Entry

**Error**: "Posting date 2024-02-01 is before the last holder entry date 2024-02-15 for asset ASSET-0001"

**Cause**: Trying to post with a date earlier than the asset's most recent holder entry

**Why**: Ensures holder history remains chronological and accurate for point-in-time queries

**Solution**: Use current or future date (or date after last entry)

### Rule 2: Must Respect User Setup Date Range

**Error**: "Posting date 2024-03-15 is outside your allowed posting date range"

**Cause**: Posting Date is outside the range defined in User Setup (Allow Posting From/To)

**Why**: Business Central security and period control

**Solution**:
*   Ask administrator to adjust User Setup date range, OR
*   Use a date within your allowed range

### Rule 3: Validates All Children Recursively

**Error**: "Cannot post transfer for asset ASSET-0001 because child asset ASSET-0002 has a later holder entry (2024-03-20)"

**Cause**: Parent asset has child assets, and one child's last entry is AFTER the parent's proposed posting date

**Why**: Ensures parent and children stay synchronized chronologically

**Solution**: Use posting date that is later than all children's last entries

:::tip Best Practice for Posting Dates
Always use **actual transfer date**, not data entry date. This ensures:
*   Accurate point-in-time holder queries
*   Proper chronological sequence
*   Compliance with audit requirements
:::

## Automatic Child Transfer

When you transfer an asset in the journal, **all child assets transfer automatically**.

### How It Works

1.  You create journal line for parent asset:

    Asset No.: MV-001
    To Holder: Customer C00001

2.  System detects MV-001 has children:

    MV-001 (Main Vessel)
    ├─ ENG-001 (Engine)
    └─ PROP-001 (Propeller)

3.  During posting, system automatically:

    *   Transfers MV-001 to C00001

    *   Transfers ENG-001 to C00001

    *   Transfers PROP-001 to C00001

    *   Uses same Posting Date for all

    *   Links all with same Transaction No.


### Multi-Level Propagation

Works recursively for unlimited depth:

MV-001 (transferring to C00001)
├─ ENG-001 (auto-transferred)
│  ├─ TC-001 (auto-transferred)
│  └─ FP-001 (auto-transferred)
└─ PROP-001 (auto-transferred)

**All 5 assets transfer together in one operation.**

### Why Automatic Propagation?

**Physical Reality**: When a vessel moves to a customer, the engine inside moves too

**Data Integrity**: Prevents inconsistent holder states (parent at one location, children at another)

**Simplified Data Entry**: Transfer parent once instead of manually transferring each component

:::warning Subasset Transfer Blocking
**You cannot transfer a subasset (child) directly** - you must transfer its parent asset.

**Error**: "Cannot transfer asset ASSET-0002 because it is a subasset. Transfer the parent asset ASSET-0001 instead."

**Reason**: Maintains hierarchy integrity - components should move with their parent assembly.

**Solution**: Transfer the root or parent asset instead.
:::

## Journal Batches

### Viewing Journal Batches

1.  Choose the 🔎 icon, enter **Asset Journal Batches**, and choose the related link

2.  View all available batches

3.  Create, rename, or delete batches as needed


### Creating a New Batch

1.  On **Asset Journal Batches** page, click **New**

2.  Fill in **Name** - Batch identifier (e.g., "MONTHLY")

3.  Fill in **Description** - Batch purpose (e.g., "Monthly Location Reconciliation")

4.  Click **OK**

5.  New batch is now available in Asset Journal


### Switching Between Batches

*   In Asset Journal page, use **Batch Name** dropdown

*   Each batch has independent set of lines

*   You can prepare multiple batches and post them separately


## Common Use Cases

### Use Case 1: Ship Multiple Assets to Customer

**Scenario**: Customer ordered 5 assets, ship them all at once

**Steps**:

1.  Create 5 journal lines, one per asset

2.  Set same To Holder: Customer C00001

3.  Set same Posting Date: 2024-03-15

4.  Add Description: "Order SO-12345 shipment"

5.  Post batch


**Result**: All 5 assets transferred to customer in one posting

### Use Case 2: Customer Return

**Scenario**: Customer returned 2 assets to warehouse

**Steps**:

1.  Create 2 journal lines

2.  Asset No.: ASSET-0010, ASSET-0011

3.  From Holder: Customer C00001 (auto-filled)

4.  To Holder: Location MAIN-WH

5.  Description: "Return - RMA-456"

6.  Post batch


**Result**: Assets return to warehouse, holder history recorded

### Use Case 3: Initial Holder Assignment

**Scenario**: Setting up Asset Pro, need to record where 100 assets currently are

**Steps**:

1.  Create a batch "INITIAL"

2.  Create journal lines for all 100 assets

3.  To Holder: Current actual location for each

4.  Posting Date: Today's date (or system go-live date)

5.  Description: "Initial holder setup"

6.  Post batch


**Result**: All assets have starting holder position recorded

### Use Case 4: Monthly Reconciliation

**Scenario**: Monthly physical inventory reveals 3 assets at wrong location

**Steps**:

1.  Create batch "RECON-MAR24"

2.  Create journal lines for 3 assets

3.  To Holder: Correct actual location

4.  Description: "Monthly reconciliation - March 2024"

5.  Post batch


**Result**: Holder positions corrected, audit trail maintained

## Holder Entries Created

When you post the Asset Journal, it creates holder entries in the same way as other transfer methods.

### Entry Pattern

For each asset in journal:

**Entry 1: Transfer Out**
Entry Type: Transfer Out
Holder: From Holder (old holder)
Posting Date: From journal line
Transaction No.: Unique number linking paired entries
Document Type: Journal
Document No.: Batch name + line counter

**Entry 2: Transfer In**
Entry Type: Transfer In
Holder: To Holder (new holder)
Posting Date: From journal line
Transaction No.: Same as Transfer Out
Document Type: Journal
Document No.: Batch name + line counter

### Example Holder Entries

Posted journal line:
  Batch: DEFAULT
  Asset No.: ASSET-0001
  From: Location MAIN-WH
  To: Customer C00001
  Posting Date: 2024-03-15

Creates holder entries:
  Entry 100: Transfer Out - Location MAIN-WH - Transaction 50 - JOURNAL/DEFAULT-1
  Entry 101: Transfer In  - Customer C00001  - Transaction 50 - JOURNAL/DEFAULT-1

## Validation Rules Summary

During posting, Asset Journal validates:

| Rule | Description | Error Prevention |
| --- | --- | --- |
| **Asset Exists** | Asset No. must exist | Invalid asset reference |
| **Asset Not Blocked** | Asset.Blocked must be false | Posting to blocked assets |
| **Not a Subasset** | Parent Asset No. must be blank | Child transfer without parent |
| **From Holder Matches** | Current holder = line's From Holder | Stale data, concurrent changes |
| **To Holder Different** | To Holder ≠ From Holder | Pointless transfers |
| **To Holder Valid** | To Holder Code exists | Invalid holder reference |
| **Posting Date** | See Posting Date Validation section | Chronological integrity |

## Best Practices

### Batch Organization

**Purpose-Based Batches:**

*   Create batches for specific purposes (shipments, returns, corrections)

*   Easier to track what was posted when

*   Better audit trail


**Date-Based Batches:**

*   Use batch name with period: "MAR2024"

*   Helps identify when reconciliation occurred

*   Useful for monthly processes


### Line Descriptions

**Be Specific:**

*   Good: "Shipped to customer - Order SO-12345"

*   Bad: "Transfer"


**Include References:**

*   Sales Order numbers

*   Return Material Authorization (RMA) numbers

*   Customer PO numbers

*   Reason for correction


### Error Handling

**Review Before Posting:**

*   Verify From Holder matches expected current holder

*   Check asset is at correct starting location

*   Confirm To Holder is correct destination


**If Posting Fails:**

*   Read error message carefully

*   Fix the specific line mentioned in error

*   Re-post batch


**Large Batches:**

*   For 50+ assets, consider splitting into multiple batches

*   Easier error recovery if issues arise

*   Progress dialog shows posting status


### Regular Reconciliation

**Monthly:**

*   Compare asset Current Holder with physical locations

*   Create correction journal batch if discrepancies found

*   Document reasons in Description field


**After Major Events:**

*   After bulk shipment, verify all assets posted correctly

*   Review holder entries for transaction linking

*   Reconcile with external systems (if applicable)


## Troubleshooting

### Journal Line Disappears After Posting

**Problem**: Lines vanish after clicking Post

**Cause**: **This is normal behavior** - journal lines are deleted after successful posting

**Verification**: Check holder entries to confirm assets transferred successfully

**Solution**: N/A - working as designed

### Cannot Post - "From Holder doesn't match"

**Problem**: Error indicates From Holder field doesn't match asset's current holder

**Causes**:
1.  Asset holder was changed since line was created
2.  Another user/process transferred the asset
3.  Concurrent posting in another journal batch

**Solution**:
1.  Refresh the page
2.  Re-validate the line (select asset again)
3.  From Holder will update to current value
4.  Adjust To Holder if needed
5.  Re-post

### Posting Date Validation Fails

**Problem**: "Posting date is before last holder entry"

**Cause**: See Posting Date Validation section above

**Solutions**:
*   Use current date or date after asset's last entry
*   Check child assets' last entry dates
*   Verify User Setup date range

### Asset Not Found in Lookup

**Problem**: Asset doesn't appear when looking up Asset No.

**Causes**:
1.  Asset is blocked
2.  Asset doesn't exist
3.  Incorrect filter applied

**Solution**:
1.  Go to Assets list
2.  Verify asset exists and is not blocked
3.  Check asset No. spelling
4.  Clear any filters on journal page

---
