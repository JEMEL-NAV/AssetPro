---
id: asset-transfer-orders
title: Asset Transfer Orders
sidebar_position: 9
description: "Document-based asset transfers in Business Central. Create formal transfer documents with release workflow, approval process, and permanent posted records for audit trail."
keywords: ["asset transfer order BC", "asset transfer document", "transfer workflow", "release and post assets", "documented asset transfer", "business central transfer orders", "dynamics-365", "asset-pro", "business-central"]
category: "Core Features"
---

Asset Transfer Orders provide a **document-based approach** to transferring assets between holders, with formal workflow and permanent archived records.

## Understanding Transfer Orders

### When to Use Transfer Orders

**✅ Use Transfer Orders for:**

*   **Formal documented transfers** - Need permanent transfer document

*   **Approval workflows** - Release step before posting

*   **External transfers** - Customers, vendors, external parties

*   **Audited movements** - Compliance, traceability requirements

*   **Reference documentation** - Link to sales orders, purchase orders

*   **Archived records** - Keep posted document forever


**❌ Use Asset Journal instead for:**

*   **Quick ad-hoc transfers** - No approval needed

*   **Internal corrections** - Fixing data errors

*   **Batch movements** - Multiple unrelated transfers

*   **Simple movements** - No documentation required


### Transfer Order vs Asset Journal

| Feature | Transfer Order | Asset Journal |
| --- | --- | --- |
| **Pattern** | Document (Header + Lines) | Journal (Batch + Lines) |
| **Workflow** | Open → Released → Posted | Direct posting |
| **Approval** | Release step required | No approval |
| **Archive** | Posted document preserved | Only holder entries |
| **Document No.** | Number series assigned | Batch name + line |
| **Use Case** | Formal external transfers | Quick internal transfers |
| **Traceability** | Permanent document record | Holder entries only |

## Transfer Order Lifecycle

### Status Flow

Transfer orders go through a three-step lifecycle:

```
Open → Released → Posted (Archived)
```

**Open**
*   Initial creation state
*   Lines can be edited, added, removed
*   Header fields (From/To Holder) can be changed
*   Not yet committed

**Released**
*   Approved for posting
*   Lines and header locked (cannot edit)
*   Ready to execute transfer
*   Can be reopened if changes needed

**Posted (Archived)**
*   Transfer executed
*   Assets moved to new holder
*   Original document deleted
*   Posted document created (permanent archive)
*   Cannot be edited or deleted

### Actions by Status

| Action | Open | Released | Posted |
| --- | --- | --- | --- |
| **Edit Header/Lines** | ✅ Allowed | ❌ Blocked | ❌ N/A |
| **Release** | ✅ Available | ❌ Already released | ❌ N/A |
| **Reopen** | ❌ Already open | ✅ Available | ❌ N/A |
| **Post** | ❌ Must release first | ✅ Available | ❌ Already posted |
| **Delete** | ✅ Allowed | ⚠️ Must reopen first | ❌ Archived |

## Creating Transfer Orders

### Step 1: Create New Transfer Order

1.  Choose the 🔎 icon, enter **Asset Transfer Orders**, and choose the related link

2.  Click **New** to create new transfer order

3.  System assigns document number from number series

4.  Status = **Open** (editable)


### Step 2: Fill Header Fields

**Document No.** (auto-assigned)
*   Assigned from number series in Asset Setup
*   Example: TRANS-0001, TRANS-0002, etc.
*   Read-only field

**Posting Date**
*   Date when transfer will occur
*   Used for holder entries when posted
*   Defaults to work date
*   Subject to validation (cannot backdate before last holder entry)

**From Holder Type / Code**
*   Source holder - where assets currently are
*   Type: Customer, Vendor, Location
*   Code: Specific holder (lookup available)
*   Name auto-filled from code

**To Holder Type / Code**
*   Destination holder - where assets will go
*   Type: Customer, Vendor, Location
*   Code: Specific holder (lookup available)
*   Name auto-filled from code
*   **Must be different from From Holder**

**Description** (optional)
*   Transfer purpose or reason
*   Example: "Customer shipment - Order SO-12345"

**External Document No.** (optional)
*   Customer's or vendor's document reference
*   Example: Customer PO number, delivery note

**Reason Code** (optional)
*   Business Central reason code
*   Examples: SALE, RETURN, RELOCATION


### Step 3: Add Transfer Lines

On the **Lines** section:

1.  Click **New** or press <kbd>Enter</kbd> on empty line

2.  **Asset No.** - Select asset to transfer

    *   System validates:
        *   Asset exists and is not blocked
        *   Asset's current holder matches header's From Holder
        *   Asset is not a subasset (cannot transfer children directly)

3.  **Asset Description** - Auto-filled from asset

4.  **Current Holder** - Auto-filled (read-only, for verification)

5.  Repeat for each asset to transfer


**Example Transfer Order:**

Header:
  Document No.: TRANS-0042
  Posting Date: 2024-03-20
  From Holder: Location MAIN-WH
  To Holder: Customer C00001 (Contoso Ltd.)
  Description: Shipment for rental contract RC-2024-03

Lines:
  Line 1: Asset ASSET-0150 (Excavator CAT 320D)
  Line 2: Asset ASSET-0151 (Loader CAT 950M)
  Line 3: Asset ASSET-0152 (Dump Truck Volvo A40G)

### Step 4: Release Transfer Order

Before posting, you must release the order:

1.  Click **Release** action

2.  System validates:

    *   From Holder and To Holder are filled
    *   From Holder ≠ To Holder
    *   At least one line exists
    *   All assets on lines are valid
    *   All assets' current holder matches From Holder

3.  If validation passes:

    *   Status changes to **Released**
    *   Header and lines become read-only
    *   Order is ready to post

4.  If validation fails:

    *   Error message indicates problem
    *   Fix error and try releasing again


### Step 5: Post Transfer Order

Once released, you can post the transfer:

1.  Click **Post** action

2.  Confirm posting dialog

3.  System executes transfer via journal pattern:

    *   Validates posting date rules
    *   Creates journal lines internally
    *   Posts via Asset Jnl.-Post codeunit
    *   Creates holder entries for all assets
    *   Transfers child assets automatically
    *   Updates asset Current Holder fields
    *   Creates posted transfer document (archive)
    *   Deletes original transfer order

4.  Success message:

    "Transfer Order TRANS-0042 has been posted successfully."
    "Posted Transfer: PTRANS-0042"

5.  System navigates to posted document (optional)


## Transfer Order Lines

### Line Fields

**Line No.** (auto-assigned)
*   Sequential line number
*   Auto-incremented (10000, 20000, 30000, etc.)
*   Read-only

**Asset No.** (required)
*   The asset being transferred
*   Lookup to Asset table
*   Validated against From Holder

**Asset Description** (read-only)
*   FlowField from Asset table
*   For display and verification

**Current Holder Type/Code/Name** (read-only)
*   Shows asset's current holder
*   Must match header's From Holder
*   For verification before posting

### Line Validation

When you enter Asset No., system validates:

**Rule 1: Asset Must Exist**
*   Error: "Asset ASSET-9999 does not exist"

**Rule 2: Asset Not Blocked**
*   Error: "Asset ASSET-0001 is blocked and cannot be transferred"

**Rule 3: Asset Cannot Be Subasset**
*   Error: "Cannot transfer asset ASSET-0002 because it is a subasset. Transfer the parent asset ASSET-0001 instead."
*   **Reason**: Children transfer automatically with parent

**Rule 4: Asset Current Holder Must Match Header's From Holder**
*   Error: "Asset ASSET-0001 current holder (Location: EAST-WH) does not match transfer order From Holder (Location: MAIN-WH)"
*   **Solution**: Either update header's From Holder, or select different asset

### Adding Multiple Lines

**Manual Entry:**
*   Add lines one by one
*   Type or lookup Asset No. for each line

**Future Enhancements:**
*   Bulk add from Asset list
*   Copy lines from another transfer order
*   Add by asset filter/criteria

## Release and Reopen

### Release Order

**Purpose**: Mark order as approved and ready to post

**Action**: Click **Release** in ribbon or action bar

**Effect**:
*   Status changes from Open to Released
*   Header fields become read-only
*   Lines become read-only
*   Cannot add/edit/delete lines
*   Post action becomes available

**When Release Fails:**

Error: "From Holder and To Holder cannot be the same"
Solution: Change To Holder to different holder

Error: "Transfer order must have at least one line"
Solution: Add asset lines before releasing

Error: "Asset ASSET-0001 current holder does not match From Holder"
Solution: Update asset or fix From Holder field

### Reopen Order

**Purpose**: Unlock released order for editing

**Action**: Click **Reopen** in ribbon

**Effect**:
*   Status changes from Released back to Open
*   Header and lines become editable
*   Can modify, add, delete lines
*   Must release again before posting

**Use Cases:**
*   Realized From/To Holder was wrong
*   Need to add or remove assets
*   Need to change posting date
*   Customer changed their mind

## Posting Transfer Orders

### Posting Process

When you post a released transfer order:

**Step 1: Validation**
*   Checks order status = Released
*   Validates From Holder ≠ To Holder
*   Validates at least one line exists
*   Validates all assets still match From Holder
*   Validates posting date rules (see below)

**Step 2: Journal Pattern Posting**
*   Creates internal journal batch "POSTING"
*   Converts transfer lines to journal lines
*   Calls Asset Jnl.-Post codeunit
*   Inherits all journal validation rules

**Step 3: Holder Entries Creation**
*   For each asset (including children):
    *   Creates Transfer Out entry (From Holder)
    *   Creates Transfer In entry (To Holder)
    *   Links with Transaction No.
    *   Sets Document Type = Transfer Order
    *   Sets Document No. = Posted document number

**Step 4: Posted Document Creation**
*   Creates Posted Asset Transfer header (permanent record)
*   Creates Posted Asset Transfer Lines
*   Copies all header and line fields
*   Assigns Transaction No. for traceability
*   Stores in permanent archive

**Step 5: Cleanup**
*   Deletes original transfer order
*   Updates asset Current Holder fields
*   Updates Current Holder Since dates

### Posting Date Validation

Same validation rules as Asset Journal apply:

**Rule 1: Cannot Backdate Before Last Entry**
*   Error: "Posting date 2024-02-01 is before the last holder entry date 2024-02-15 for asset ASSET-0001"
*   **Solution**: Use current date or date after last holder entry

**Rule 2: Must Respect User Setup Date Range**
*   Error: "Posting date is outside your allowed posting date range"
*   **Solution**: Ask admin to adjust User Setup, or use date within range

**Rule 3: Validates All Children Recursively**
*   Error: "Cannot post transfer for asset ASSET-0001 because child asset ASSET-0002 has a later holder entry (2024-03-20)"
*   **Solution**: Use posting date later than all children's last entries

See Asset Journal - Posting Date Validation for detailed explanation.

## Automatic Child Transfer

Transfer orders **automatically transfer all child assets** with their parents.

### How It Works

**Transfer Order Lines:**
*   Line 1: Asset MV-001 (Main Vessel)

**Asset Hierarchy:**
MV-001
├─ ENG-001 (Engine)
│  └─ TC-001 (Turbocharger)
└─ PROP-001 (Propeller)

**Posting Result:**
*   MV-001 transferred to new holder
*   ENG-001 automatically transferred (child)
*   TC-001 automatically transferred (grandchild)
*   PROP-001 automatically transferred (child)

**All 4 assets moved in one operation, but you only specified the parent (MV-001) on the transfer order.**

### Why Automatic Propagation?

**Physical Reality**: Components move with their parent assembly

**Data Integrity**: Prevents split assemblies (parent at one location, children at another)

**User Convenience**: Specify parent once instead of every component

:::warning Subasset Transfer Blocking
**You cannot add a subasset (child asset) directly to a transfer order line.**

**Error**: "Cannot transfer asset ASSET-0002 because it is a subasset. Transfer the parent asset ASSET-0001 instead."

**Reason**: Maintains hierarchy integrity and enforces logical transfer patterns.

**Solution**: Add the parent or root asset to the line instead - children will transfer automatically.
:::

## Posted Transfer Documents

### Viewing Posted Transfers

1.  Choose the 🔎 icon, enter **Asset Posted Transfers**, and choose the related link

2.  View all posted (archived) transfer documents

3.  Filter by date range, holder, document number, etc.


### Posted Document Structure

**Header Fields:**
*   Document No. - Posted transfer number (PTRANS-0042)
*   Original Document No. - Original transfer order number (TRANS-0042)
*   Posting Date - When transfer occurred
*   From Holder Type/Code/Name - Source holder
*   To Holder Type/Code/Name - Destination holder
*   Description, External Document No., Reason Code
*   Transaction No. - Links to holder entries
*   User ID - Who posted the transfer

**Lines:**
*   Asset No., Description
*   Current Holder at posting time
*   Line No.
*   Transaction No. (links to holder entries)

### Posted Document Uses

**Audit Trail:**
*   Permanent record of transfer document
*   Cannot be edited or deleted
*   Supports compliance requirements

**Traceability:**
*   Link holder entries back to source document
*   Trace which transfer order created which entries
*   Cross-reference with external documents

**Reporting:**
*   Generate transfer history reports
*   Analyze transfer patterns by holder
*   Billing and invoicing references

**Investigation:**
*   Research "When did this asset move?"
*   Find "What was transferred on this date?"
*   Verify "Who authorized this transfer?"

## Common Use Cases

### Use Case 1: Customer Rental Shipment

**Scenario**: Ship 3 construction machines to customer for 6-month rental

**Steps**:

1.  Create new transfer order

2.  Header:
    *   Posting Date: 2024-03-15
    *   From Holder: Location MAIN-YARD
    *   To Holder: Customer C00025 (ABC Construction)
    *   External Document No.: CUST-PO-2024-789
    *   Description: "6-month rental contract RC-2024-03"

3.  Lines:
    *   Asset No.: ASSET-0150 (Excavator)
    *   Asset No.: ASSET-0151 (Loader)
    *   Asset No.: ASSET-0152 (Dump Truck)

4.  Release order

5.  Post order

**Result**: 3 assets (plus any child components) transferred to customer, posted document PTRANS-0042 archived

### Use Case 2: Customer Return

**Scenario**: Customer returning 2 assets at end of rental period

**Steps**:

1.  Create new transfer order

2.  Header:
    *   From Holder: Customer C00025
    *   To Holder: Location MAIN-YARD
    *   External Document No.: RETURN-2024-456
    *   Description: "End of rental - contract RC-2024-03"

3.  Lines:
    *   Asset No.: ASSET-0150 (Excavator)
    *   Asset No.: ASSET-0151 (Loader)

4.  Release and post

**Result**: Assets returned to warehouse, complete audit trail

### Use Case 3: Inter-Location Transfer

**Scenario**: Move 10 assets from east warehouse to west warehouse

**Steps**:

1.  Create transfer order

2.  Header:
    *   From Holder: Location EAST-WH
    *   To Holder: Location WEST-WH
    *   Description: "Rebalancing inventory between warehouses"

3.  Add 10 asset lines

4.  Release and post

**Result**: All assets moved, documented transfer record

### Use Case 4: Vendor Return for Repair

**Scenario**: Sending defective component back to vendor for warranty repair

**Steps**:

1.  Create transfer order

2.  Header:
    *   From Holder: Location MAIN-WH
    *   To Holder: Vendor V00100 (CAT Equipment)
    *   External Document No.: RMA-2024-1234
    *   Description: "Warranty repair - turbocharger failure"

3.  Line:
    *   Asset No.: TC-001 (Turbocharger)

4.  Release and post

**Result**: Asset transferred to vendor, RMA documented

## Transfer Order Best Practices

### Workflow Discipline

**Always Release Before Posting:**
*   Don't skip the release step
*   Release serves as approval checkpoint
*   Catches errors before commitment

**Review Before Release:**
*   Verify From/To Holders correct
*   Check all asset lines valid
*   Confirm posting date appropriate
*   Review description and references

### Documentation

**Use Description Field:**
*   Explain WHY transfer is occurring
*   Reference related documents
*   Include contract numbers, project IDs

**Fill External Document No.:**
*   Customer PO numbers
*   Vendor RMA numbers
*   Delivery note numbers
*   Links to external systems

**Use Reason Codes:**
*   SALE - Sold to customer
*   RENT - Rental/lease
*   RETURN - Return from customer/vendor
*   RELOCATE - Inter-location transfer
*   REPAIR - Sent for maintenance

### Error Prevention

**Verify Asset Current Holder:**
*   Before adding asset to line, check asset's Current Holder
*   Ensure it matches transfer order's From Holder
*   Prevents posting failures

**Check Asset Hierarchy:**
*   If transferring parent asset, understand children will transfer too
*   Don't add both parent AND child to same transfer order
*   System will transfer children automatically

**Use Appropriate Posting Date:**
*   Use actual transfer date, not data entry date
*   Ensure date is after all assets' last holder entries
*   Check User Setup date range before posting

### Archival and Reporting

**Keep Posted Transfers:**
*   Never delete posted transfer documents
*   They are permanent audit trail
*   Supports compliance and investigations

**Regular Review:**
*   Monthly: Review posted transfers for accuracy
*   Quarterly: Analyze transfer patterns
*   Annually: Audit trail verification

**Link to Holder Entries:**
*   Use Transaction No. to link posted transfer to holder entries
*   Verify holder entry Document No. references posted transfer
*   Cross-check for data integrity

## Integration Points

### Future BC Document Integration

Transfer orders will integrate with standard Business Central documents:

**Sales Orders:**
*   Shipment posting triggers asset transfer to customer
*   Auto-create transfer order on sales shipment
*   Link via Document No.

**Purchase Orders:**
*   Receipt posting triggers asset transfer from vendor
*   Auto-create transfer order on purchase receipt
*   Track vendor to location movements

**Transfer Orders (Inventory):**
*   Location-to-location transfers for inventory items
*   Sync asset transfers with item transfers
*   Coordinate physical movements

:::info Phase 2 Stages 4-6
Document integration is planned for Phase 2 Stages 4, 5, and 6:
*   Stage 4: Sales document integration
*   Stage 5: Purchase document integration
*   Stage 6: Inventory transfer integration

Currently (Stage 3.1 complete), transfer orders work standalone.
:::

## Troubleshooting

### Cannot Release - "From Holder and To Holder cannot be the same"

**Problem**: Trying to release order where From Holder = To Holder

**Solution**: Change To Holder to a different holder

**Why**: Pointless to transfer asset to itself

### Cannot Release - "Asset current holder does not match"

**Problem**: Asset's actual current holder doesn't match order's From Holder

**Cause**: Asset was moved since line was created

**Solution**:
1.  Go to Asset Card, verify Current Holder
2.  Update transfer order's From Holder to match, OR
3.  Remove line and add different asset

### Cannot Post - "Must release first"

**Problem**: Trying to post order with Status = Open

**Solution**: Click **Release** action first, then post

**Why**: Release step is required approval gate

### Posted Transfer Not Found

**Problem**: After posting, cannot find posted document

**Solution**:
1.  Go to **Asset Posted Transfers** list
2.  Filter by Document No. = PTRANSxxxx (with "P" prefix)
3.  Or filter by Posting Date

### Lines Become Read-Only

**Problem**: Cannot edit lines after releasing

**Solution**: This is intentional - click **Reopen** to edit, then release again

---
