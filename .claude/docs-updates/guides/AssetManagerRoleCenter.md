# Asset Manager Role Center - User Guide

**Module:** Asset Pro
**Feature:** Role Center
**Version:** 26.0.2.0
**Date:** 2025-11-27

---

## Overview

The **Asset Manager Role Center** provides a centralized workspace for managing all aspects of Asset Pro, including assets, transfers, holders, components, and document integration.

This role center is designed for users who need comprehensive access to Asset Pro functionality, including:
- Asset creation and management
- Transfer order processing
- Holder management and tracking
- Component installation and removal
- Document integration (Sales, Purchase, Transfer)

---

## Accessing the Role Center

### Assigning the Asset Manager Profile

1. Open **User Personalization** or **User Settings List**
2. Select the user who needs Asset Manager access
3. In the **Profile** field, select **"Asset Manager"**
4. Save the changes
5. The user must sign out and sign back in for the profile to take effect

### First-Time Setup

When you first access the Asset Manager Role Center, you'll see:
- **Headline Banner** - Personalized greeting and quick links
- **Activity Tiles** - Real-time KPIs showing key metrics
- **Navigation Sections** - Organized access to all Asset Pro functionality

---

## Activity Tiles (KPIs)

The Activity Tiles display real-time metrics calculated from your data:

### Assets Section
- **Total Assets** - Count of all assets in the system
  - Click to open the Asset List
- **Assets Without Holder** - Assets with no holder assigned
  - Helps identify data quality issues
- **Blocked Assets** - Assets marked as blocked
  - Quick view of exceptions requiring attention

### Transfers Section
- **Open Transfer Orders** - Transfer orders in Open status
  - Click to see orders awaiting release
- **Released Transfer Orders** - Transfer orders ready for posting
  - Shows workflow progress

### Components Section
- **Total Component Entries** - All component installations/removals recorded
  - Complete audit trail of component activity

### Today's Activity Section
- **Assets Modified Today** - Assets changed on the current date
  - Tracks recent activity

---

## Navigation Sections

### Assets
Access core asset management functionality:
- **Asset List** - View and manage all assets
- **Asset Card** - Create new assets or view details
- **Asset Tree** - Hierarchical view of asset relationships
- **Holder Entries** - Complete holder change history
- **Relationship Entries** - Asset attach/detach audit trail

### Transfers
Manage asset transfers between holders:
- **Transfer Orders** - View and manage transfer orders
- **New Transfer Order** - Create a new transfer order
- **Posted Transfers** - View completed transfers
- **Asset Journal** - Batch transfer processing
- **Asset Journal Batches** - Manage journal batches

### Components
Track component installations and removals:
- **Component Entries** - View complete component history
- **Component Journal** - Record component changes
- **Component Journal Batches** - Manage component journal batches

### Document Integration
Access documents with asset transfers:
- **Sales**
  - Posted Sales Shipments
  - Posted Return Receipts
- **Purchase**
  - Posted Purchase Receipts
  - Posted Return Shipments

### Setup & Configuration
Configure Asset Pro settings:
- **Asset Setup** - Core settings and number series
- **Classification Levels** - Define asset classification structure
- **Classification Values** - Asset classification values
- **Asset Industries** - Industry categories
- **Attribute Definitions** - Custom asset attributes

---

## Quick Actions

### From Activity Tiles
- **New Asset** - Create an asset directly from the Assets tile
- **New Transfer Order** - Create a transfer order from the Transfers tile
- **Asset Journal** - Open the journal from the Transfers tile
- **Component Journal** - Open component journal from the Components tile

### Creation Area
The bottom navigation bar provides quick creation actions:
- **Asset** - Create a new asset (with icon)
- **Transfer Order** - Create a new transfer order (with icon)

### Embedding Area
Quick access to frequently used lists:
- **Assets** - Direct link to Asset List
- **Transfer Orders** - Direct link to Transfer Orders list

---

## Tips and Best Practices

### Monitoring Data Quality
- Regularly check "Assets Without Holder" to ensure all assets have holders assigned
- Review "Blocked Assets" to manage exceptions
- Use "Assets Modified Today" to track recent activity

### Workflow Management
- Monitor "Released Transfer Orders" to process pending transfers
- Check "Open Transfer Orders" to identify orders awaiting release

### Navigation Efficiency
- Use the Embedding area links for frequent tasks
- Bookmark specific pages for your most common workflows
- Customize the Role Center using standard BC personalization

---

## Customization

### Personalizing the Role Center
1. Click **Settings (gear icon)** → **Personalize**
2. You can:
   - Rearrange sections
   - Hide/show specific tiles
   - Adjust tile sizes
3. Changes are saved per user

### Modifying KPI Tiles
The KPI tiles are calculated automatically from your data. To modify which KPIs are displayed, contact your system administrator.

---

## Troubleshooting

### Activity Tiles Show Zero
- **Cause:** No data exists yet
- **Solution:** Create assets, transfer orders, or components to populate the metrics

### "Assets Without Holder" is High
- **Cause:** Assets created without holder assignment
- **Solution:** Review the Asset List and assign holders to new assets

### Navigation Link Doesn't Work
- **Cause:** Missing permissions
- **Solution:** Contact your system administrator to assign the "JMLAssetPro" permission set

---

## Related Documentation

- [Asset Management Overview](../processes/AssetManagement.md)
- [Transfer Order Processing](../guides/TransferOrders.md)
- [Component Tracking](../guides/ComponentTracking.md)
- [Asset Setup](../setup/AssetProSetup.md)

---

**Last Updated:** 2025-11-27
**Updated By:** Claude Code (AI Implementation)