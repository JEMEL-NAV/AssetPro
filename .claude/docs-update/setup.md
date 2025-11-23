---
id: setup
title: Setup
sidebar_position: 2
description: "Configure Asset Pro extension in Business Central. Set up number series, transfer order controls, default values, enable attributes and holder history features for your asset management system."
keywords: ["asset pro setup", "BC extension configuration", "asset number series", "transfer order setup", "business central asset setup", "enable holder history", "configure asset tracking", "asset-pro", "dynamics-365", "business-central"]
category: "Setup"
---

After installation of Asset Pro extension into Microsoft Dynamics 365 Business Central, perform these setup tasks to configure the system for your organization.

## Asset Pro Setup Page

1.  Choose the 🔎 icon, enter **Asset Setup**, and then choose the related link.

2.  This will open the Asset Pro Setup page with configuration options.


### On the General FastTab

#### Asset Numbering

**Asset Nos.**

*   Select the number series to use for automatic asset numbering

*   Create a new number series if needed (e.g., "ASSET", starting from ASSET-0001)

*   This field is **required** before creating assets


#### Default Values

**Default Industry Code**

*   Optionally select a default industry that will be pre-filled when creating new assets

*   Leave blank if your organization uses multiple industries equally

*   You can change the industry on each asset individually


#### Holder Change Control

**Block Manual Holder Change**

*   Controls whether users can change the Current Holder directly on the Asset Card

*   ☐ **Disabled** (default): Users can change Current Holder on Asset Card (changes are auto-registered with "MAN-" document prefix)

*   ☑️ **Enabled**: Users cannot change Current Holder directly, must use Asset Journal or Transfer Order


**When to Enable:**

*   Strict audit requirements - Need formal documentation for all holder changes

*   Multiple users with different authorization levels

*   Compliance regulations require approval workflow

*   Want centralized control over all asset movements


**When to Disable (Default):**

*   Small organization with trusted users

*   Need flexibility for quick corrections

*   Manual holder changes are infrequent

*   Users understand when to use appropriate transfer method


:::info Manual Holder Change Auto-Registration
When **Block Manual Holder Change** is disabled, users can change Current Holder on Asset Card. The system automatically:

*   Creates holder entries via journal pattern
*   Documents with "MAN-" prefix (e.g., MAN-ASSET-0001-1)
*   Applies all validation rules (posting date, children propagation)
*   Maintains full audit trail

This provides flexibility while maintaining data integrity.
:::

### On the Numbering FastTab

Asset Pro uses number series for automatic document numbering.

**Transfer Order Nos.**

*   Number series for Asset Transfer Orders

*   Example: "TRANS" starting from TRANS-0001

*   Required for creating transfer orders

*   Separate from asset numbers to distinguish document types


**Posted Transfer Nos.**

*   Number series for Posted Asset Transfers (archived documents)

*   Example: "PTRANS" starting from PTRANS-0001

*   Typically uses different prefix to distinguish posted from open documents

*   Required for posting transfer orders


**Setup Example:**

Transfer Order Nos.: TRANS (TRANS-0001, TRANS-0002, ...)
Posted Transfer Nos.: PTRANS (PTRANS-0001, PTRANS-0002, ...)

**Creating Number Series:**

If you don't have these number series yet:

1.  Choose the 🔎 icon, enter **No. Series**, and choose the related link

2.  Click **New** to create new number series

3.  For Transfer Orders:
    *   **Code**: TRANS
    *   **Description**: Asset Transfer Orders
    *   **Starting No.**: TRANS-0001
    *   **Ending No.**: TRANS-99999
    *   **Increment-by No.**: 1
    *   **Default Nos.**: ✅ (checked)

4.  For Posted Transfers:
    *   **Code**: PTRANS
    *   **Description**: Posted Asset Transfers
    *   **Starting No.**: PTRANS-0001
    *   **Ending No.**: PTRANS-99999
    *   **Increment-by No.**: 1
    *   **Default Nos.**: ✅ (checked)

5.  Return to Asset Setup and select these number series


:::tip Number Series Best Practices
Use different prefixes for different document types:

*   ASSET- for assets
*   TRANS- for open transfer orders
*   PTRANS- for posted transfer orders

This makes document types immediately recognizable in lists and reports.
:::

### On the Features FastTab

Asset Pro has two optional features that can be enabled or disabled based on your needs:

**Enable Attributes**

*   **Purpose**: Allows you to define custom fields per industry/classification level

*   **When to Enable**: If you need industry-specific data fields (e.g., "Vessel Flag Country" for ships, "MRI Field Strength" for medical equipment)

*   **When to Disable**: If you only need standard fields, disabling improves performance

*   **Default**: Enabled


**Enable Holder History**

*   **Purpose**: Tracks complete audit trail of asset location/custody changes

*   **When to Enable**: If you need to know who held an asset and when (compliance, billing, audit trail)

*   **When to Disable**: If you track holder information externally

*   **Default**: Enabled

*   **Creates**: Holder Entries ledger with Transfer Out/Transfer In records


:::info Core Features Always Available
**Classification** and **Parent-Child Relationships** are core architectural features that define Asset Pro. They are always available - simply leave fields blank if you don't need them for specific assets.

**Asset Journal** and **Asset Transfer Orders** are always available for holder transfers.

**Relationship Tracking** (attach/detach audit trail) is always available for parent-child relationships.
:::

## Setup Workflow

After configuring the Asset Pro Setup page, follow these steps:

### Step 1: Create Number Series (if needed)

If you don't have number series yet:

**Asset Number Series:**

1.  Choose the 🔎 icon, enter **No. Series**, and choose the related link

2.  Click **New** to create a new number series

3.  Fill in:

    *   **Code**: ASSET

    *   **Description**: Asset Numbers

    *   **Starting No.**: ASSET-0001

    *   **Ending No.**: ASSET-99999

    *   **Increment-by No.**: 1

    *   **Default Nos.**: ✅ (checked)

4.  Click **OK** to save


**Transfer Order Number Series:**

Repeat above steps for:
*   Transfer Order Nos.: Code "TRANS", Starting No. "TRANS-0001"
*   Posted Transfer Nos.: Code "PTRANS", Starting No. "PTRANS-0001"

### Step 2: Configure Industries

See Industry Configuration for detailed instructions on setting up your first industry.

### Step 3: Set Up Classification Structure

See Classification Setup for instructions on creating your organizational taxonomy.

### Step 4: Configure Attributes (Optional)

If **Enable Attributes** is turned on, see Attributes Configuration for instructions on adding custom fields.

### Step 5: Configure Holder Change Control (Optional)

Decide whether to enable **Block Manual Holder Change**:

*   Leave **disabled** (default) for flexible, auto-registered manual changes
*   Enable for strict audit control requiring Asset Journal or Transfer Orders

---

## Quick Start Checklist

Before you can create your first asset and use transfer features, ensure:

**Required Setup:**

*   [ ] Asset number series selected in **Asset Nos.** field

*   [ ] Transfer Order Nos. series selected (for transfer orders)

*   [ ] Posted Transfer Nos. series selected (for posting transfers)

*   [ ] At least one Industry created

*   [ ] At least one Classification Level defined for that industry

*   [ ] At least one Classification Value created at Level 1


**Optional Configuration:**

*   [ ] **Enable Attributes** - ON if you need custom fields

*   [ ] **Enable Holder History** - ON for audit trail (recommended)

*   [ ] **Block Manual Holder Change** - ON for strict audit control


Want to get started quickly? Create a simple industry with just 2 levels:

*   Industry: EQUIPMENT

*   Level 1: Category (Values: Office, Production, Vehicles)

*   Level 2: Type (Values: Computer, Printer, Copier under Office, etc.)


This gives you a working system in minutes!

## Transfer Methods Available

After setup, you have multiple methods to transfer assets between holders:

### Method 1: Manual Holder Change (if not blocked)

*   Change Current Holder directly on Asset Card
*   Auto-registered with "MAN-" document prefix
*   Fastest for single assets
*   See holder-management

### Method 2: Asset Journal

*   Batch-based transfers
*   Multiple assets at once
*   Enhanced validation (posting date control)
*   See asset-journal

### Method 3: Asset Transfer Orders

*   Document-based transfers
*   Release/approval workflow
*   Permanent posted document archive
*   See asset-transfer-orders

## What's Next?

After completing setup:

1.  **Create your first assets** - See Asset Management

2.  **Build asset hierarchies** - See Parent-Child Relationships

3.  **Track holder movements** - See Holder Management

4.  **Use transfer features**:
    *   Asset Journal for batch transfers
    *   Transfer Orders for documented transfers

5.  **Configure custom attributes** - See Attributes Configuration (if enabled)

6.  **Link component BOMs** - See Component BOM

7.  **Generate reports** - See Reporting and Analysis

---
