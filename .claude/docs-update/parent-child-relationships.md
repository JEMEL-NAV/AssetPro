---
id: parent-child-relationships
title: Parent-Child Relationships
sidebar_position: 7
description: "Track physical asset assembly and component structures with complete audit trail. Build parent-child hierarchies, track attach/detach events, and maintain relationship history for compliance and analysis."
keywords: ["asset hierarchy BC", "parent child assets", "component tracking", "asset assembly structure", "physical asset composition", "relationship history", "attach detach audit trail", "equipment components business central", "dynamics-365", "business-central", "asset-pro"]
category: "Core Features"
---

Parent-Child Relationships track the **physical assembly structure** of your assets - what components are physically inside or attached to other assets - with complete **relationship history audit trail**.

## Understanding Physical Hierarchy

### Classification vs Physical Hierarchy

Asset Pro uses **two separate structures** for different purposes:

| **Classification Hierarchy** | **Physical Hierarchy** |
| --- | --- |
| **Purpose**: Organizational taxonomy | **Purpose**: Physical composition |
| **Question**: "What TYPE is this asset?" | **Question**: "What's INSIDE this asset?" |
| **Example**: Commercial → Cargo Ship → Panamax | **Example**: Vessel → Engine → Turbocharger |
| **Structure**: Defined in Classification Levels/Values | **Structure**: Defined via Parent Asset No. on assets |
| **Unlimited levels** (up to 50) | **Unlimited depth** (up to 100 levels) |

Don't Confuse the Two
**Classification** is about **categorization**: "This is a Panamax Bulk Carrier"
**Physical Hierarchy** is about **composition**: "This vessel contains Engine #1"

They are **completely independent**:

*   A vessel can be classified as "Panamax" (classification)

*   AND contain an engine as a child asset (physical hierarchy)


### Real-World Example: Marine Vessel

**Classification Structure:**

Industry: Fleet Management
├─ Level 1: Fleet Type = "Commercial"
├─ Level 2: Vessel Category = "Cargo Ship"
└─ Level 3: Vessel Model = "Panamax Bulk Carrier"

**Physical Hierarchy:**

MV-001: Main Vessel (Panamax Bulk Carrier)
├─ ENG-001: Main Engine (Diesel Engine)
│  ├─ TC-001: Turbocharger (Turbo Component)
│  ├─ FP-001: Fuel Pump (Pump)
│  └─ OC-001: Oil Cooler (Cooling System)
├─ ENG-002: Auxiliary Engine (Generator)
└─ PROP-001: Propeller (Propulsion Component)

**Both structures coexist:**

*   Each asset has its own **classification** (what type it is)

*   Each asset may have a **parent** (what it's physically inside)


## Creating Parent-Child Relationships

### Assigning a Parent Asset

1.  Open the **Asset Card** for the child asset

2.  Go to **Physical Hierarchy** group

3.  In **Parent Asset No.** field, select the parent asset

4.  System automatically:

    *   Calculates **Hierarchy Level** - Depth in tree (1, 2, 3, etc.)

    *   Calculates **Root Asset No.** - Top-most ancestor

    *   **Creates relationship entry** - Logs attach event with timestamp


**Example: Adding Engine to Vessel**

Before:
  Asset: ENG-001 (Main Engine)
  Parent Asset No.: (blank)
  Hierarchy Level: 1
  Root Asset No.: (blank)

After assigning parent:
  Asset: ENG-001 (Main Engine)
  Parent Asset No.: MV-001
  Hierarchy Level: 2 (child of vessel)
  Root Asset No.: MV-001 (top-most parent)
  Relationship Entry: Attach event created

### Detaching from Parent

Asset Pro provides explicit **Detach** functionality to remove child assets from their parent.

**From Asset Card:**

1.  Open the **Asset Card** for child asset

2.  Click **Detach from Parent** action in ribbon

3.  System confirms: "Are you sure you want to detach this asset from its parent?"

4.  Upon confirmation:

    *   Clears **Parent Asset No.** field

    *   Resets **Hierarchy Level** to 1 (becomes root asset)

    *   Clears **Root Asset No.**

    *   **Creates relationship entry** - Logs detach event with timestamp

    *   Asset becomes standalone


**From Asset List (Batch Detach):**

1.  Open **Assets** list

2.  Select multiple assets to detach

3.  Click **Detach from Parent** action in ribbon

4.  System detaches all selected assets

5.  Each detach creates separate relationship entry


**Use Cases for Detach:**
*   Component removed for maintenance
*   Asset relocated to different assembly
*   Equipment returned from rental (was attached to parent)
*   Physical disassembly of equipment

### Creating Multi-Level Hierarchies

You can create unlimited levels by assigning parents in sequence.

**Step 1: Create Vessel** (root asset)

Asset: MV-001 (Main Vessel)
Parent Asset No.: (blank)
Hierarchy Level: 1
Root Asset No.: (blank)

**Step 2: Create Engine as child of Vessel**

Asset: ENG-001 (Main Engine)
Parent Asset No.: MV-001
Hierarchy Level: 2
Root Asset No.: MV-001
Relationship Entry: Attach to MV-001

**Step 3: Create Turbocharger as child of Engine**

Asset: TC-001 (Turbocharger)
Parent Asset No.: ENG-001
Hierarchy Level: 3
Root Asset No.: MV-001
Relationship Entry: Attach to ENG-001

**Result: Three-level hierarchy**

MV-001 (Level 1, Root)
└─ ENG-001 (Level 2, Root: MV-001)
   └─ TC-001 (Level 3, Root: MV-001)

## Relationship History Tracking

Asset Pro maintains a **complete audit trail** of all attach/detach events for parent-child relationships.

### What is Relationship History?

**Purpose**: Record when assets are attached to or detached from parent assets

**Audit Trail**: Permanent ledger of relationship changes

**Use Cases**:
*   Compliance: Track when components were installed/removed
*   Maintenance: Historical record of assembly changes
*   Billing: Determine component rental periods
*   Investigation: "When was this component added to the assembly?"
*   Analysis: Track component swap frequency

### Relationship Entry Types

Relationship history uses two entry types:

#### Attach Event

**When Created**:
*   Asset's Parent Asset No. changes from blank to populated
*   Asset's Parent Asset No. changes from one parent to different parent

**What It Records**:
*   Child Asset No. and Description
*   Parent Asset No. and Description
*   Child's Current Holder at time of attach
*   Posting Date (when attachment occurred)
*   User ID (who performed attach)
*   Reason Code (optional)

**Example Entry:**

Entry No.: 42
Entry Type: Attach
Posting Date: 2024-03-15
Asset No.: ENG-001
Asset Description: Main Engine
Parent Asset No.: MV-001
Parent Asset Description: Main Vessel
Child Holder: Location MAIN-WH
User ID: JOHN
Description: Engine installed during vessel assembly

**Meaning**: "On 2024-03-15, Engine ENG-001 was attached to Vessel MV-001 while at MAIN-WH"

#### Detach Event

**When Created**:
*   Asset's Parent Asset No. changes from populated to blank
*   Asset's Parent Asset No. changes from one parent to different parent (creates detach from old, attach to new)
*   User clicks "Detach from Parent" action

**What It Records**:
*   Child Asset No. and Description
*   Parent Asset No. and Description (the parent it's being detached FROM)
*   Child's Current Holder at time of detach
*   Posting Date (when detachment occurred)
*   User ID (who performed detach)
*   Reason Code (optional)

**Example Entry:**

Entry No.: 58
Entry Type: Detach
Posting Date: 2024-04-20
Asset No.: ENG-001
Asset Description: Main Engine
Parent Asset No.: MV-001
Parent Asset Description: Main Vessel
Child Holder: Location SERVICE-WH
User ID: MARY
Description: Engine removed for overhaul

**Meaning**: "On 2024-04-20, Engine ENG-001 was detached from Vessel MV-001 while at SERVICE-WH"

### Viewing Relationship History

**From Asset Card:**

1.  Open **Asset Card** for any asset

2.  Click **Relationship History** action in ribbon

3.  **Relationship Entries** page opens, filtered to current asset

4.  View complete history of attach/detach events


**From Asset List:**

1.  Select one or more assets

2.  Click **Relationship History** action

3.  View relationship history for selected assets


**From Relationship Entries Page:**

1.  Choose the 🔎 icon, enter **Relationship Entries**

2.  View all relationship events across all assets

3.  Filter by:
    *   Asset No. - See history for specific asset
    *   Parent Asset No. - See all children attached to specific parent
    *   Posting Date range - Events in time period
    *   Entry Type - Only Attach or only Detach events
    *   User ID - Events by specific user


### Relationship Entry Fields

**Entry No.**
*   Unique identifier, auto-incremented
*   Cannot be changed
*   Sequential across all relationship entries

**Entry Type**
*   Attach or Detach
*   Required field

**Posting Date**
*   Date when relationship change occurred
*   Defaults to work date
*   Used for historical analysis

**Asset No. / Asset Description**
*   The child asset (the one being attached/detached)
*   Required field

**Parent Asset No. / Parent Asset Description**
*   The parent asset (the one being attached TO or detached FROM)
*   Required field

**Child Holder Type / Code / Name**
*   Where the child asset was located at moment of relationship change
*   Captures holder context for audit purposes
*   Auto-populated from asset's Current Holder

**Transaction No.**
*   Optional linking field for grouping related changes
*   Future use: Link multiple attach/detach in single operation

**Reason Code**
*   Business Central reason code
*   Optional categorization
*   Examples: INSTALL, REMOVE, MAINT, SWAP

**Description**
*   Free-text explanation of relationship change
*   Optional but recommended
*   Examples: "Installed during initial assembly", "Removed for preventive maintenance"

**User ID**
*   User who performed the relationship change
*   Auto-populated
*   Audit accountability

### Automatic Relationship Logging

Relationship events are **automatically logged** when you change the Parent Asset No. field:

**Scenario 1: Attach (blank → populated)**

Action: Set Parent Asset No. from (blank) to MV-001
Result: Creates Attach relationship entry

**Scenario 2: Detach (populated → blank)**

Action: Clear Parent Asset No. from ENG-001 to (blank)
Result: Creates Detach relationship entry

**Scenario 3: Re-parent (one parent → different parent)**

Action: Change Parent Asset No. from MV-001 to MV-002
Result: Creates TWO relationship entries:
  1. Detach from MV-001
  2. Attach to MV-002

**No Manual Entry Required**: System automatically creates entries when you modify Parent Asset No. field on Asset Card or via code.

## Physical Hierarchy Fields

### Parent Asset No.

**Purpose**: Links this asset to its physical parent

**Behavior**:

*   Leave blank for **standalone assets** (root assets)

*   Select another asset to make this a **child asset**

*   System validates to prevent circular references

*   **Triggers relationship entry creation** when changed


**Validation Rules**:

*   ❌ Cannot assign asset as its own parent

*   ❌ Cannot create circular references (A→B→C→A)

*   ❌ Parent must exist

*   ✅ Can change parent (re-parents the asset, logs detach+attach)

*   ✅ Can clear parent (makes asset standalone, logs detach)


**When you change parent**:

*   Hierarchy Level recalculates

*   Root Asset No. recalculates

*   Entire sub-tree moves with the asset

*   **Relationship entries created** (detach from old parent, attach to new parent)


### Hierarchy Level (Read-Only)

**Purpose**: Shows depth in physical assembly tree

**Values**:

*   **1** = Root asset (no parent)

*   **2** = Direct child of root

*   **3** = Grandchild of root

*   **4+** = Deeper levels


**Calculation**:

*   Automatically calculated when Parent Asset No. is set

*   Parent's Level + 1

*   Recalculates when parent changes


**Use Cases**:

*   Filter assets by level (e.g., "Show only root assets" = Level 1)

*   Reports: "All Level 2 components across all vessels"

*   Identify depth of assembly structures


### Root Asset No. (Read-Only)

**Purpose**: Points to the top-most parent in the hierarchy

**Calculation**:

*   System walks up parent chain until it finds asset with no parent

*   That asset is the **root**

*   All descendants share the same root


**Example:**

MV-001 (Root Asset No. = blank)
├─ ENG-001 (Root Asset No. = MV-001)
│  └─ TC-001 (Root Asset No. = MV-001)
└─ PROP-001 (Root Asset No. = MV-001)

**Use Cases**:

*   **Group all components**: Filter by Root Asset No. = MV-001

*   **Complete assembly view**: Show all assets belonging to one root

*   **Bulk operations**: Transfer entire assembly by root

*   **Reporting**: "All components under Vessel MV-001"


### Has Children (FlowField)

**Purpose**: Indicates if this asset has child assets

**Calculation**:

*   FlowField: Checks if any assets have Parent Asset No. = this asset's No.

*   ☑️ True = Has children

*   ☐ False = No children (leaf asset)


**Use Cases**:

*   Identify parent vs leaf assets

*   Prevent deletion of assets with children

*   Reports: "All parent assets in the system"


### Child Asset Count (FlowField)

**Purpose**: Counts how many direct children this asset has

**Calculation**:

*   FlowField: Count of assets where Parent Asset No. = this asset's No.

*   **Direct children only** (not grandchildren)


**Example:**

MV-001
├─ ENG-001
│  ├─ TC-001
│  └─ FP-001
└─ PROP-001

Child Asset Count:
  MV-001: 2 (ENG-001, PROP-001)
  ENG-001: 2 (TC-001, FP-001)
  TC-001: 0

## Validation Rules and Safeguards

Asset Pro enforces strict validation to maintain hierarchy integrity.

### Rule 1: No Self-Parenting

**Error**: "Asset ASSET-0001 cannot be its own parent."

**Cause**: Trying to assign an asset as its own parent

**Example:**

Asset: ENG-001
Parent Asset No.: ENG-001 ❌ ERROR

**Solution**: Select a different asset as parent

### Rule 2: No Circular References

**Error**: "Circular reference detected: Asset ASSET-0001 appears in its own parent chain."

**Cause**: Creating a circular loop in the parent chain

**Example:**

ENG-001 → Parent: MV-001 ✅
MV-001 → Parent: PROP-001 ✅
PROP-001 → Parent: ENG-001 ❌ ERROR (circular: ENG→MV→PROP→ENG)

**Detection**:

*   System walks up parent chain

*   If it encounters the current asset, it's circular

*   Checks up to 100 levels deep


**Solution**: Break the loop by assigning a different parent

### Rule 3: Parent Must Exist

**Error**: "Parent asset ASSET-9999 does not exist."

**Cause**: Selected parent asset doesn't exist in Asset table

**Solution**: Select a valid existing asset

### Rule 4: Maximum Depth Limit

**Error**: "Maximum parent chain depth of 100 levels exceeded for asset ASSET-0001."

**Cause**: Parent chain exceeds 100 levels

**Why**: Safety limit to prevent:

*   Circular references that evade detection

*   Performance issues with extremely deep trees

*   Data corruption scenarios


**Solution**:

*   Review hierarchy structure

*   Flatten excessive nesting

*   Investigate possible circular reference


### Rule 5: Cannot Delete Parent with Children

**Error**: "Cannot delete asset ASSET-0001 because it has child assets."

**Cause**: Trying to delete an asset that has child assets

**Solution**:

1.  Detach all child assets first (use **Detach from Parent** action)

2.  Then delete the parent asset


**Why**: Prevents orphaned assets with invalid Parent Asset No.

### Rule 6: Subasset Transfer Protection

When holder changes occur (transfers), **subassets (children) cannot be transferred directly**.

**Error**: "Cannot transfer asset ASSET-0002 because it is a subasset. Transfer the parent asset ASSET-0001 instead."

**Reason**: Children should move with their parent assembly, maintaining hierarchy integrity

**Behavior**: When you transfer a parent asset via Asset Journal or Transfer Order:
*   Parent transfers to new holder
*   All children **automatically** transfer to same holder
*   Maintains assembly integrity
*   Prevents split assemblies

**Solution**: Transfer the root or parent asset - children will follow automatically

See Holder Management for transfer details.

## Working with Hierarchies

### Viewing Child Assets

**From Asset Card:**

1.  Open parent asset's Asset Card

2.  Note the **Child Asset Count** field

3.  To see children:

    *   Go to **Assets** list

    *   Filter: `Parent Asset No. = (current asset No.)`

    *   Shows all direct children


**Future Enhancement:**

*   Dedicated "Child Assets" FactBox on Asset Card

*   Tree view of hierarchy

*   Drill-down navigation


### Viewing Entire Assembly

**Show all components under a root asset:**

1.  Note the **Root Asset No.** of any asset in the assembly

2.  Go to **Assets** list

3.  Filter: `Root Asset No. = (root asset number)`

4.  Result: All assets in the entire assembly tree


**Example:**

Filter: Root Asset No. = MV-001

Results:
  ENG-001 (Level 2)
  TC-001 (Level 3)
  FP-001 (Level 3)
  OC-001 (Level 3)
  ENG-002 (Level 2)
  PROP-001 (Level 2)

### Re-Parenting Assets

You can change the parent of an asset at any time.

**Effect of Re-Parenting:**

*   Asset moves to new parent

*   Hierarchy Level recalculates

*   Root Asset No. recalculates

*   **Entire sub-tree moves with the asset**

*   **Two relationship entries created**: Detach from old parent, Attach to new parent


**Example: Move Engine to Different Vessel**

Before:
  MV-001
  └─ ENG-001
     └─ TC-001

Change: ENG-001 → Parent Asset No. = MV-002

After:
  MV-001 (empty now)

  MV-002
  └─ ENG-001 (moved)
     └─ TC-001 (moved automatically with parent)

Relationship Entries Created:
  Entry 1: Detach ENG-001 from MV-001
  Entry 2: Attach ENG-001 to MV-002

**Use Cases:**

*   Component replacement/swapping

*   Asset relocations

*   Maintenance cycles (remove/reinstall components)

*   Equipment reconfiguration


### Making Asset Standalone

To remove an asset from a hierarchy:

1.  Open the Asset Card

2.  Click **Detach from Parent** action, OR

3.  Clear **Parent Asset No.** field manually

4.  System updates:

    *   Hierarchy Level = 1

    *   Root Asset No. = (blank)

    *   **Detach relationship entry created**


**Effect:**

*   Asset becomes a root asset

*   Any child assets remain attached (they stay children of this asset)


**Example:**

Before:
  MV-001
  └─ ENG-001
     └─ TC-001

Detach: ENG-001 from MV-001

After:
  MV-001 (no children)

  ENG-001 (now root)
  └─ TC-001 (still child of ENG-001)

Relationship Entry:
  Detach ENG-001 from MV-001

## Relationship History Use Cases

### Use Case 1: Component Maintenance History

**Scenario**: Track when turbocharger was removed and reinstalled

**Relationship Entries:**

Entry 42: Attach TC-001 to ENG-001 (2024-01-15) - Initial installation
Entry 58: Detach TC-001 from ENG-001 (2024-03-20) - Removed for service
Entry 61: Attach TC-001 to ENG-001 (2024-03-25) - Reinstalled after service

**Analysis**: Turbocharger was out for service for 5 days

### Use Case 2: Asset Rental Period Calculation

**Scenario**: Customer rented excavator with attachments, calculate component rental periods

**Relationship Entries:**

Entry 100: Attach BUCKET-24 to EX-320D (2024-02-01) - Customer started using bucket
Entry 105: Attach HAMMER-H120 to EX-320D (2024-02-15) - Customer added hammer later
Entry 110: Detach BUCKET-24 from EX-320D (2024-03-31) - Rental ended
Entry 111: Detach HAMMER-H120 from EX-320D (2024-03-31) - Rental ended

**Billing Analysis**:
*   BUCKET-24: 59 days (Feb 1 - Mar 31)
*   HAMMER-H120: 45 days (Feb 15 - Mar 31)

### Use Case 3: Compliance Audit

**Scenario**: Regulatory inspection requires proof of when component was installed

**Relationship Entries:**

Entry 42: Attach COOL-001 (Cryogenic Cooling) to MRI-750W (2023-06-15)
User ID: TECH-JOHN
Description: Initial installation during MRI commissioning
Child Holder: Location HOSPITAL-RADIOLOGY

**Audit Answer**: Cooling system was installed on 2023-06-15 by TECH-JOHN at HOSPITAL-RADIOLOGY

### Use Case 4: Component Swap Analysis

**Scenario**: How many times has this component been swapped between parent assets?

**Filter**: Asset No. = TC-001

**Results**:
Entry 10: Attach TC-001 to ENG-001 (2024-01-10)
Entry 15: Detach TC-001 from ENG-001 (2024-02-05)
Entry 16: Attach TC-001 to ENG-002 (2024-02-05)
Entry 22: Detach TC-001 from ENG-002 (2024-03-10)
Entry 23: Attach TC-001 to ENG-003 (2024-03-10)

**Analysis**: Component swapped 3 times across different engines in 2 months

## Use Cases and Examples

### Use Case 1: Marine Vessel Components

**Scenario**: Track all components of a cargo vessel with full audit trail

**Structure:**

MV-PANAMA-001 (Panamax Bulk Carrier)
├─ ENG-MAIN-001 (Main Propulsion Engine) - Attached 2024-01-15
│  ├─ TC-HIGH-001 (High Pressure Turbocharger) - Attached 2024-01-20
│  ├─ TC-LOW-001 (Low Pressure Turbocharger) - Attached 2024-01-20
│  ├─ FP-MAIN-001 (Main Fuel Pump) - Attached 2024-01-22
│  └─ OC-ENG-001 (Engine Oil Cooler) - Attached 2024-01-22
├─ ENG-AUX-001 (Auxiliary Generator Engine) - Attached 2024-01-25
├─ ENG-AUX-002 (Auxiliary Generator Engine) - Attached 2024-01-25
├─ PROP-001 (Fixed Pitch Propeller) - Attached 2024-02-01
└─ NAV-001 (Navigation Equipment Suite) - Attached 2024-02-05
   ├─ RADAR-001 (Radar System) - Attached 2024-02-06
   ├─ GPS-001 (GPS System) - Attached 2024-02-06
   └─ AIS-001 (AIS Transponder) - Attached 2024-02-06

**Benefits:**

*   Complete bill of materials for vessel

*   Track when each component was installed (relationship history)

*   Maintenance planning per component

*   Component replacement audit trail

*   Spare parts management


### Use Case 2: Medical Equipment Assembly

**Scenario**: Track components of MRI machine with compliance audit trail

**Structure:**

MRI-750W-EAST (GE MRI Scanner)
├─ MAGNET-001 (Superconducting Magnet)
│  └─ COOL-001 (Cryogenic Cooling System)
├─ RF-001 (RF Coil System)
│  ├─ COIL-HEAD-001 (Head Coil)
│  ├─ COIL-BODY-001 (Body Coil)
│  └─ COIL-KNEE-001 (Knee Coil)
├─ COMP-001 (Computer System)
└─ TABLE-001 (Patient Table)

**Benefits:**

*   Track expensive modular components

*   Component-specific maintenance schedules

*   Regulatory compliance (when installed, by whom)

*   Replacement cost tracking with install dates

*   Warranty management per component


### Use Case 3: Construction Equipment

**Scenario**: Track interchangeable attachments for excavator

**Structure:**

EX-320D-003 (CAT 320D Excavator)
├─ BUCKET-24IN (24" Digging Bucket) - Currently attached
├─ BUCKET-36IN (36" Digging Bucket) - Detached (in storage)
├─ HAMMER-H120 (Hydraulic Hammer) - Detached (in storage)
└─ GRAPPLE-001 (Grapple Attachment) - Detached (in storage)

**Relationship History Shows:**
*   BUCKET-24IN attached/detached 15 times (frequent swaps)
*   HAMMER-H120 attached/detached 8 times
*   Usage patterns for billing customers

**Benefits:**

*   Track which attachments are currently installed

*   Attachment swap history for billing

*   Maintenance per attachment based on usage

*   Inventory of available attachments


## Best Practices

### When to Use Parent-Child

**✅ Use for:**

*   **Physical components**: Engine is inside vessel

*   **Installed attachments**: Bucket on excavator

*   **Rack-mounted equipment**: Server in rack

*   **Modular assemblies**: Coils in MRI machine

*   **Removable parts**: Swappable components


**❌ Don't use for:**

*   **Classification**: Use Classification Levels instead

*   **Location tracking**: Use Current Holder instead

*   **Organizational structure**: Use Classification instead

*   **Related assets**: Not the same as "related to"


### Hierarchy Design Tips

**Start Shallow:**

*   Begin with 1-2 levels: Parent → Child

*   Add deeper levels as needed

*   Don't over-engineer initially


**Logical Grouping:**

*   Group by physical containment

*   Match how assets are actually assembled

*   Think: "If I disassemble this, what comes out?"


**Practical Depth:**

*   Most hierarchies are 2-4 levels deep

*   Going deeper than 5 levels is rare

*   If approaching 10+ levels, reconsider structure


**Component Naming:**

*   Include parent reference in child description

*   Example: "Main Engine - Turbocharger" (not just "Turbocharger")

*   Helps identification when viewing flat asset lists


### Relationship History Best Practices

**Use Descriptions:**

*   Document WHY attachment/detachment occurred

*   Example: "Removed for annual overhaul", "Installed as upgrade"

*   Helps future investigations


**Use Reason Codes:**

*   INSTALL - Initial installation

*   REMOVE - Removal for maintenance

*   MAINT - Maintenance cycle detach/attach

*   UPGRADE - Component upgrade

*   SWAP - Swapping between parent assets


**Use Detach Action:**

*   Use explicit **Detach from Parent** action instead of clearing field manually

*   More intentional, creates clearer audit trail

*   Batch detach for multiple assets


**Regular Review:**

*   Quarterly: Review relationship history for accuracy

*   Verify physical assembly matches system records

*   Clean up orphaned relationship entries (from deleted test data)


### Maintenance and Updates

**Document Changes:**

*   Use Description field when attaching/detaching

*   Record maintenance work orders, service tickets

*   Links to external systems


**Handle Removed Components:**

*   When component removed temporarily: Detach (don't delete asset)

*   Relationship history preserves removal event

*   When reinstalled: Re-attach (creates new attach event)


**Component Swaps:**

*   Detach from original parent (creates detach entry)

*   Attach to new parent (creates attach entry)

*   Full audit trail of component movement


## Reporting and Analysis

### Common Reports

**Component Count by Root Asset**

*   Filter: `Root Asset No. = specific asset`

*   Group by: Hierarchy Level

*   Shows: Complete assembly structure


**Parent Assets Report**

*   Filter: `Has Children = Yes`

*   Shows: All assets that contain components

*   Use: Identify major assemblies


**Relationship Event Timeline**

*   Filter: Asset No. or Parent Asset No.

*   Sort by: Posting Date

*   Shows: Chronological attach/detach events


**Component Swap Frequency**

*   Group by: Asset No.

*   Count: Relationship entries (attach + detach)

*   Identifies: Frequently moved components


**Attachment Duration Analysis**

*   For each asset: Time between attach and detach events

*   Calculate: Average duration attached to parent

*   Use: Billing, utilization analysis


**Orphaned Assets Check**

*   Filter: `Parent Asset No. <> blank`

*   Cross-check: Parent asset exists

*   Purpose: Data quality validation


**Hierarchy Depth Analysis**

*   Group by: Hierarchy Level

*   Shows: Distribution of assets by level

*   Identifies: Overly complex structures


## Future Enhancements

Phase 2 includes core parent-child structure and relationship tracking. Future phases will add:

*   **Tree View**: Visual hierarchy browser

*   **FactBoxes**: Show children on Asset Card

*   **Drag-Drop**: Reorganize hierarchy visually

*   **Bulk Operations**: Move entire branches

*   **BOM Reports**: Complete assembly reports with relationship timeline

*   **Cost Rollup**: Sum component costs to parent

*   **Relationship Timeline Chart**: Visual timeline of attach/detach events

*   **Component-as-of-Date Query**: "What components were attached to this parent on specific date?"

---
