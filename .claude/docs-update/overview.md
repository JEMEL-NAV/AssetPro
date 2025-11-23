---
id: overview
title: Asset Pro for Microsoft Dynamics 365 Business Central
slug: /
sidebar_position: 1
description: "Universal asset management extension for Business Central. Track any asset, any industry with unlimited classification hierarchy, parent-child relationships, custom attributes, and complete transfer workflow with audit trail."
keywords: ["asset pro", "business central asset management", "BC asset tracking", "fixed assets extension", "equipment management BC", "machinery tracking", "fleet management business central", "asset transfer management", "relationship tracking", "asset-pro", "business-central", "dynamics-365"]
category: "Overview"
---

**Track any asset, any industry, your way** - with unlimited flexibility, complete terminology adaptation, and comprehensive transfer workflow with audit trail.

This guide is intended for asset-intensive businesses and system administrators who want to manage physical assets, equipment, and machinery within Microsoft Dynamics 365 Business Central.

## What's Inside

| ✅ **Core Features** |
| --- |
| **Universal Industry Support** - Configure Asset Pro to work with any industry using custom terminology |
| **Unlimited Classification Hierarchy** - Create up to 50 levels of organizational taxonomy per industry |
| **Physical Parent-Child Relationships** - Track asset composition and assembly structures with complete audit trail |
| **Flexible Holder Tracking** - Monitor asset location across customers, vendors, locations, and more |
| **Custom Attributes** - Add industry-specific fields without code changes |
| **Complete Audit Trail** - Track all asset holder movements with detailed history |
| **Relationship History** - Track attach/detach events for parent-child relationships with timestamps and user accountability |

| ✅ **Transfer & Document Features** |
| --- |
| **Asset Journal** - Batch-based asset transfers with posting date validation and automatic child propagation |
| **Asset Transfer Orders** - Document-based transfers with release workflow and permanent archive |
| **Manual Holder Change Control** - Optional blocking with auto-registration and audit trail |
| **Posting Date Validation** - Cannot backdate transfers before last entry, ensures chronological integrity |
| **Automatic Child Propagation** - Transfer parent assets and children follow automatically |
| **Subasset Protection** - Prevents direct transfer of child assets, maintains hierarchy integrity |

## Why Asset Pro?

Traditional asset management solutions force businesses into rigid structures. Asset Pro introduces a revolutionary **dual-structure architecture** that separates concerns:

### Structure 1: Classification Hierarchy (What IS it?)

Organize your assets using unlimited configurable levels with dynamic terminology:

*   **Fleet Management Example**: Fleet → Vessel Type → Vessel Model

*   **Medical Equipment Example**: Department → Equipment Category → Device Model

*   **Construction Example**: Division → Equipment Type → Manufacturer → Model


### Structure 2: Physical Composition (What's INSIDE it?)

Track actual physical assembly and component relationships with complete attach/detach audit trail:

*   Vessel → Engine → Turbocharger

*   MRI Machine → Cooling System → Compressor

*   Excavator → Hydraulic System → Pump


**Relationship History**: Track when components were attached to or detached from parent assets, who made the change, and where the assets were located.

### Structure 3: Component BOM (What standard PARTS does it use?)

Link assets to standard Business Central Items for parts inventory:

*   Vessel → Propeller Blades (Item), Navigation Lights (Item)

*   MRI Machine → Helium Tank (Item), RF Coils (Item)

*   Excavator → Hydraulic Oil (Item), Filters (Item)


## Key Innovations

### Separation of Classification from Composition

Unlike traditional systems that confuse organizational categories with physical assembly, Asset Pro keeps them separate and clear.

### Comprehensive Transfer Workflow

Asset Pro provides multiple transfer methods suited for different use cases:

**Asset Journal** - Batch transfers for efficiency:
*   Move multiple assets at once
*   Enhanced posting date validation
*   Cannot backdate before last holder entry
*   Automatic child asset propagation
*   Ideal for: Periodic movements, corrections, batch operations

**Asset Transfer Orders** - Document-based transfers for formal processes:
*   Open → Released → Posted workflow
*   Release step for approval control
*   Permanent posted document archive
*   External document references
*   Ideal for: Customer shipments, formal documented transfers, compliance

**Manual Holder Change** (optional) - Quick updates on Asset Card:
*   Direct holder field changes
*   Auto-registered with "MAN-" prefix
*   Can be blocked for strict audit control
*   Ideal for: Quick corrections, trusted user environments

### Complete Audit Trail

**Holder History**:
*   Every transfer creates paired Transfer Out/Transfer In entries
*   Point-in-time holder queries: "Who had this asset on specific date?"
*   Transaction linking for traceability
*   Document references (journal, transfer order, sales, purchase)

**Relationship History**:
*   Attach events when component added to parent
*   Detach events when component removed from parent
*   Captures who, when, where for every relationship change
*   Supports compliance, billing, maintenance history

### Validation and Data Integrity

**Posting Date Validation**:
*   Cannot backdate transfers before asset's last holder entry
*   Recursive validation for all child assets
*   Respects User Setup date ranges
*   Ensures chronological consistency for audit trail

**Hierarchy Integrity**:
*   Prevents circular references
*   Maximum depth limit (100 levels)
*   Cannot delete parent with children
*   Subasset transfer blocking (children move with parent)

## Who Should Use Asset Pro?

*   **Multi-industry businesses** with diverse asset types

*   **Companies with 100-100,000+ assets** to manage

*   **Industries**: Marine, Medical, Construction, IT, Manufacturing, Rental, Fleet Management

*   **Organizations** requiring flexible terminology and unlimited hierarchy depth

*   **Businesses** needing formal transfer workflows and compliance audit trails


## What You'll Learn

This documentation covers:

1.  **Setup** - Initial configuration, number series, transfer order setup, and holder change control

2.  **Classification Configuration** - Building your organizational taxonomy

3.  **Asset Management** - Creating and managing asset records

4.  **Parent-Child Relationships** - Building physical assembly structures with relationship history

5.  **Holder Management** - Tracking asset location and custody with multiple transfer methods

6.  **Asset Journal** - Batch-based asset transfers with validation

7.  **Asset Transfer Orders** - Document-based transfers with workflow

8.  **Attributes** - Adding custom fields per industry

9.  **Component BOM** - Linking standard parts to assets

10. **Reporting** - Finding and analyzing your assets


## Getting Started

**Quick Start Path:**

1.  **Setup** → Configure number series, enable features
2.  **Create Industries** → Define your industry structure
3.  **Create Assets** → Add your first assets
4.  **Try Transfers** → Use Asset Journal or Transfer Orders to move assets
5.  **Build Hierarchies** → Attach components to parent assets
6.  **View History** → Explore holder entries and relationship entries

**For Administrators:**

*   Review Setup to configure number series and control options
*   Decide whether to enable **Block Manual Holder Change** for strict audit control
*   Configure Transfer Order Nos. and Posted Transfer Nos.
*   Set up Reason Codes for transfer categorization

**For End Users:**

*   Learn when to use Asset Journal vs Transfer Orders vs Manual changes
*   Understand automatic child propagation during transfers
*   Use Relationship History to track component installations
*   Review Holder History for asset movement audit trail

---
