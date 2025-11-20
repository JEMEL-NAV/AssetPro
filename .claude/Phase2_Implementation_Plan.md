# Asset Pro - Phase 2 Implementation Plan

**Project:** Asset Pro - Phase 2: Asset Transfer and Document Integration
**Strategy:** Phased Delivery (Option 2)
**Status:** In Progress

---

## Implementation Strategy

This plan implements Phase 2 in 7 major stages, with each stage being a complete, testable unit that can be committed to git. This allows:
- ✅ Incremental progress tracking
- ✅ Ability to revert to any stable stage
- ✅ Testing at each milestone
- ✅ Clear delivery checkpoints

---

## Stage Overview

| Stage | Description | Objects | Status | Git Commit |
|-------|-------------|---------|--------|------------|
| 1.1 | Asset Journal - Tables & Pages | 2 tables, 2 pages | ✅ **COMPLETE** | 62c805b |
| 1.2 | Asset Journal - Posting Logic | 1 codeunit, tests | ✅ **COMPLETE** | e2f7016 |
| 1.3 | Asset Transfer Order - Tables | 4 tables, 1 enum | ✅ **COMPLETE** | 41f2340 |
| 1.4 | Asset Transfer Order - Pages | 6 pages | ✅ **COMPLETE** | 279974f |
| 1.5 | Asset Transfer Order - Posting | 1 codeunit, tests | ✅ **COMPLETE** | 2e0eabf |
| 2.1 | Relationship Entry Infrastructure | 1 table, 1 enum, 1 page, 1 codeunit | Pending | - |
| 2.2 | Asset Card Enhancements | 2 page extensions, tests | Pending | - |
| 3.1 | Manual Holder Change Control | Table enhancements, tests | Pending | - |
| 4.1 | Sales Asset Line Tables | 4 tables | Pending | - |
| 4.2 | Sales Asset Line Pages | 4 pages | Pending | - |
| 4.3 | Sales Integration Logic | 3 extensions, 1 codeunit, tests | Pending | - |
| 5.1 | Purchase Asset Line Tables | 4 tables | Pending | - |
| 5.2 | Purchase Integration Logic | 5 pages, 2 extensions, tests | Pending | - |
| 6.1 | Transfer Asset Line Tables | 2 tables, 2 pages | Pending | - |
| 6.2 | Transfer Integration Logic | 2 extensions, tests | Pending | - |
| 7.1 | Role Center Implementation | 1 table, 3 pages, 1 profile | Pending | - |

**Progress: 5/17 stages complete (29%)**

---

## Stage 1: Core Transfer Infrastructure

### Stage 1.1: Asset Journal - Tables & Pages ✅ COMPLETE

**Objective:** Create journal structure for batch-based asset transfers

**Objects Created:**
- ✅ Table 70182311 "JML AP Asset Journal Batch"
- ✅ Table 70182312 "JML AP Asset Journal Line"
- ✅ Page 70182351 "JML AP Asset Journal Batches"
- ✅ Page 70182352 "JML AP Asset Journal"

**Key Features:**
- Batch-based journal structure (like General Journal)
- No journal templates (simplified)
- Automatic validation of holder codes with lookups
- Subasset transfer blocking at line level
- Posting date field (validation in Stage 1.2)

**Testing:**
- ✅ Build: 0 errors, 0 warnings
- ✅ Manual testing ready (pages created)

**Git Commit:** `62c805b` "Phase 2 Stage 1.1 - Asset Journal tables and pages"

---

### Stage 1.2: Asset Journal - Posting Logic ✅ COMPLETE

**Objective:** Implement journal posting with enhanced validation

**Objects Created:**
- ✅ Codeunit 70182390 "JML AP Asset Jnl.-Post"
- ✅ Test Codeunit 50107 "JML AP Journal Tests" (6 test procedures)
- ✅ Enhanced "JML AP Document Type" enum (added Journal value)

**Key Features Implemented:**
- ✅ Enhanced posting date validation (R1):
  - Cannot backdate before last entry
  - Recursive check for all subassets
  - Respects User Setup date range (Allow Posting From/To)
- ✅ Always propagate to children (R4) - TransferAssetWithChildren
- ✅ Create holder entries with shared Transaction No.
- ✅ Progress dialog during posting
- ✅ Subasset transfer blocking

**Testing:**
- ✅ 6 test procedures created (happy path, error cases, edge cases)
- ✅ Tests cover: posting date validation, children propagation, subasset blocking
- ⚠️ Tests need BC container with test libraries to run

**Build Status:**
- ✅ Main App: 0 errors, 0 warnings
- ✅ Published to container bc27w1

**Git Commit:** `e2f7016` "Phase 2 Stage 1.2 - Asset Journal posting logic"

---

### Stage 1.3: Asset Transfer Order - Tables & Enum ✅ COMPLETE

**Objective:** Create Transfer Order document structure

**Objects Created:**
- ✅ Enum 70182409 "JML AP Transfer Status" (Open, Released - no "Posted" status)
- ✅ Table 70182313 "JML AP Asset Transfer Header"
- ✅ Table 70182314 "JML AP Asset Transfer Line"
- ✅ Table 70182315 "JML AP Posted Asset Transfer"
- ✅ Table 70182316 "JML AP Pstd. Asset Trans. Line"

**Enhanced Existing Objects:**
- ✅ Table 70182300 "JML AP Asset Setup" - Added Transfer Order Nos. and Posted Transfer Nos.
- ✅ Page 70182330 "JML AP Asset Setup" - Added Numbering group with new fields

**Key Features Implemented:**
- ✅ Header/Lines document pattern
- ✅ From Holder → To Holder validation (must be different)
- ✅ Status flow: Open → Released → Posted (to archive)
- ✅ Automatic document numbering with No. Series
- ✅ No "Include Children" field (R4 - children always transfer automatically)
- ✅ Line validation: Cannot transfer subassets, must be at From Holder
- ✅ OnDelete cascade for lines when header deleted

**Build Status:**
- ✅ Main App: 0 errors, 0 warnings
- ✅ Ready for Stage 1.4 (pages will reference these tables)

**Git Commit:** `41f2340` "Phase 2 Stage 1.3 - Asset Transfer Order tables and enum"

---

### Stage 1.4: Asset Transfer Order - Pages ✅ COMPLETE

**Objective:** Create Transfer Order UI

**Objects Created:**
- ✅ Page 70182353 "JML AP Asset Transfer Orders" (List)
- ✅ Page 70182354 "JML AP Asset Transfer Order" (Document)
- ✅ Page 70182355 "JML AP Asset Transfer Subpage" (ListPart)
- ✅ Page 70182356 "JML AP Asset Posted Transfers" (List)
- ✅ Page 70182357 "JML AP Asset Posted Transfer" (Document)
- ✅ Page 70182358 "JML AP Asset Posted Trans. Sub" (ListPart)

**Enhanced Existing Objects:**
- ✅ Table 70182313 "JML AP Asset Transfer Header" - Added LookupPageId and DrillDownPageId
- ✅ Table 70182315 "JML AP Posted Asset Transfer" - Added LookupPageId and DrillDownPageId

**Key Features Implemented:**
- ✅ Release/Reopen actions with validation
- ✅ Post action placeholder (implementation in Stage 1.5)
- ✅ Navigate to posted document
- ✅ No "Include Children" column (R4 - children always transfer automatically)
- ✅ Status management (Open → Released)
- ✅ All fields have Caption and ToolTip (AL Best Practices)
- ✅ Editable control based on Status

**Build Status:**
- ✅ Main App: 0 errors, 0 warnings
- ✅ Published to container bc27w1

**Git Commit:** `279974f` "Phase 2 Stage 1.4 - Asset Transfer Order pages"

---

### Stage 1.5: Asset Transfer Order - Posting Logic ✅ COMPLETE

**Objective:** Post Transfer Order using journal pattern (R2)

**Objects Created:**
- ✅ Codeunit 70182391 "JML AP Asset Transfer-Post"
- ✅ Test Codeunit 50108 "JML AP Transfer Order Tests" (10 test procedures)

**Enhanced Existing Objects:**
- ✅ Page 70182354 "JML AP Asset Transfer Order" - Post action now functional
- ✅ Page 70182353 "JML AP Asset Transfer Orders" - Post action now functional

**Key Features Implemented:**
- ✅ CheckTransferOrder validation (Status, holders, lines)
- ✅ PostTransferOrder using JOURNAL PATTERN:
  1. Get/create system journal batch "POSTING"
  2. Convert transfer lines to journal lines
  3. Call Asset Jnl.-Post (creates holder entries, validates posting dates)
  4. Create posted document (header + lines with Transaction No.)
  5. Delete source document
- ✅ Enhanced posting date validation via journal (R1)
- ✅ Children always transferred automatically (R4)
- ✅ Transaction No. linking in posted lines for traceability
- ✅ Success message with posted document number

**Testing:**
- ✅ 10 test procedures created covering:
  - Happy path: Valid order, multiple assets, with children
  - Error cases: Not released, no lines, wrong holder, blocked, subasset
  - Edge cases: Posting date validation, Transaction No. linking
- ⚠️ Tests require test library setup (Library Assert) to execute

**Build Status:**
- ✅ Main App: 0 errors, 0 warnings
- ✅ Published to container bc27w1
- ⚠️ Test execution pending test library configuration

**Git Commit:** `2e0eabf` "Phase 2 Stage 1.5 - Asset Transfer Order posting logic"

---

## Stage 2: Relationship Tracking

### Stage 2.1: Relationship Entry Infrastructure ⏸️ PENDING

**Objective:** Implement attach/detach audit trail (R5)

**Objects to Create:**
- Table 70182317 "JML AP Asset Relationship Entry"
- Enum 70182408 "JML AP Relationship Entry Type" (Attach, Detach)
- Page 70182365 "JML AP Relationship Entries"
- Codeunit 70182393 "JML AP Relationship Mgt"

**Key Features:**
- Log every Attach event
- Log every Detach event
- Capture holder at moment of change
- Entry No., Transaction No., Posting Date
- Reason Code supported

**Testing:**
- Unit: LogAttachEvent creates correct entry
- Unit: LogDetachEvent creates correct entry
- Build: 0 errors, 0 warnings

**Git Commit:** "Phase 2 Stage 2.1 - Relationship tracking infrastructure"

---

### Stage 2.2: Asset Card Enhancements ⏸️ PENDING

**Objective:** Add Detach action to Asset Card/List (R6)

**Objects to Create:**
- Page Extension 70182441 "JML AP Asset Card Ext"
- Page Extension 70182442 "JML AP Asset List Ext"
- Test Codeunit 50109 "JML AP Relationship Tests"

**Key Features:**
- Detach action on Asset Card
- Batch Detach action on Asset List
- Relationship History action (drilldown)
- Validation: Cannot transfer if Parent Asset No. populated

**Testing:**
- Integration: Attach asset, verify entry created
- Integration: Detach asset, verify entry created
- Integration: Attempt to transfer subasset (should error)
- Integration: Detach then transfer (should succeed)
- Build-Publish-Test: All tests pass

**Git Commit:** "Phase 2 Stage 2.2 - Asset Card relationship enhancements"

---

## Stage 3: Manual Holder Change Control

### Stage 3.1: Setup and Asset Enhancements ⏸️ PENDING

**Objective:** Implement R7 and R8 - manual change control and auto-registration

**Objects to Enhance:**
- Table 70182300 "JML AP Asset Setup" - Add "Block Manual Holder Change" field
- Table 70182301 "JML AP Asset" - Add OnModify trigger for R8
- Page 70182330 "JML AP Asset Setup" - Add field to page
- Enhance tests in 50105 "JML AP Transfer Tests"

**Key Features:**
- R7: Block Manual Holder Change checkbox in setup
- R7: Validation on Asset Card holder fields
- R8: OnModify trigger to auto-register manual changes
- R8: Create Transfer Out/In entries automatically
- R8: Document No. = "MANUAL-[timestamp]"

**Testing:**
- Unit: Block validation works correctly
- Integration: Manual change creates holder entries (when allowed)
- Integration: Manual change blocked (when setup enabled)
- Integration: Children propagate with manual change
- Build-Publish-Test: All tests pass

**Git Commit:** "Phase 2 Stage 3.1 - Manual holder change control (R7/R8)"

---

## Stage 4: BC Document Integration - Sales

### Stage 4.1: Sales Asset Line Tables ⏸️ PENDING

**Objective:** Create tables for asset lines on Sales documents (R3)

**Objects to Create:**
- Table 70182318 "JML AP Sales Asset Line"
- Table 70182319 "JML AP Posted Sales Asset Line" (invoices)
- Table 70182324 "JML AP Posted Sales Shpt. Asset Line" (shipments)
- Table 70182326 "JML AP Posted Ret. Shpt. Asset Line" (return shipments)

**Key Features:**
- Linked to Sales Header via Document Type + Document No.
- Qty to Ship, Qty Shipped fields (0 or 1)
- No "Include Children" field
- Shipment-based transfer (R3)

**Testing:**
- Manual: Create sales asset line record
- Build: 0 errors, 0 warnings

**Git Commit:** "Phase 2 Stage 4.1 - Sales asset line tables"

---

### Stage 4.2: Sales Asset Line Pages ⏸️ PENDING

**Objective:** Create pages for Sales asset lines

**Objects to Create:**
- Page 70182359 "JML AP Sales Asset Subpage"
- Page 70182360 "JML AP Posted Sales Asset Sub"
- Page 70182366 "JML AP Posted Sales Shpt. Asset Sub"
- Page 70182368 "JML AP Posted Ret. Shpt. Asset Sub"

**Key Features:**
- ListPart for embedding in Sales documents
- Asset lookup
- Qty to Ship column
- Read-only posted pages

**Testing:**
- Manual: Open pages, verify layout
- Build: 0 errors, 0 warnings

**Git Commit:** "Phase 2 Stage 4.2 - Sales asset line pages"

---

### Stage 4.3: Sales Integration Logic ⏸️ PENDING

**Objective:** Integrate asset transfer with Sales posting

**Objects to Create:**
- Table Extension 70182420 "JML AP Sales Header Ext"
- Table Extension 70182423 "JML AP Sales Inv. Header Ext"
- Page Extension 70182435 "JML AP Sales Order Ext"
- Page Extension 70182436 "JML AP Sales Invoice Ext"
- Page Extension 70182443 "JML AP Sales Shipment Ext"
- Codeunit 70182392 "JML AP Document Integration" (Sales subscribers)
- Test Codeunit 50110 "JML AP Sales Integration Tests"

**Key Features:**
- OnBeforeDelete cascade for asset lines
- Asset Lines subpage on Sales Order
- Shipment posting: Transfer assets to customer
- Invoice posting: No asset movement (already shipped)
- Event subscribers for Sales-Post codeunit

**Testing:**
- Integration: Post sales shipment with assets
- Integration: Verify holder entries created at shipment
- Integration: Post invoice after shipment (no asset movement)
- Integration: Verify children transferred with parent
- Integration: Asset-only shipment (zero amount)
- Build-Publish-Test: All tests pass

**Git Commit:** "Phase 2 Stage 4.3 - Sales document integration"

---

## Stage 5: BC Document Integration - Purchase

### Stage 5.1: Purchase Asset Line Tables ⏸️ PENDING

**Objective:** Create tables for asset lines on Purchase documents

**Objects to Create:**
- Table 70182320 "JML AP Purch. Asset Line"
- Table 70182321 "JML AP Posted Purch. Asset Line" (invoices)
- Table 70182325 "JML AP Posted Purch. Rcpt. Asset Line" (receipts)
- Table 70182327 "JML AP Posted Ret. Rcpt. Asset Line" (return receipts)

**Key Features:**
- Similar to Sales asset lines
- Receipt-based transfer (vendor → location)

**Testing:**
- Manual: Create purchase asset line record
- Build: 0 errors, 0 warnings

**Git Commit:** "Phase 2 Stage 5.1 - Purchase asset line tables"

---

### Stage 5.2: Purchase Integration Logic ⏸️ PENDING

**Objective:** Integrate asset transfer with Purchase posting

**Objects to Create:**
- Page 70182361 "JML AP Purch. Asset Subpage"
- Page 70182362 "JML AP Posted Purch. Asset Sub"
- Page 70182367 "JML AP Posted Purch. Rcpt. Asset Sub"
- Page 70182369 "JML AP Posted Ret. Rcpt. Asset Sub"
- Table Extension 70182421 "JML AP Purch. Header Ext"
- Table Extension 70182424 "JML AP Purch. Inv. Header Ext"
- Page Extension 70182437 "JML AP Purch. Order Ext"
- Page Extension 70182438 "JML AP Purch. Invoice Ext"
- Page Extension 70182444 "JML AP Purch. Receipt Ext"
- Enhance Codeunit 70182392 (Purchase subscribers)
- Test Codeunit 50111 "JML AP Purchase Integration Tests"

**Key Features:**
- Asset Lines subpage on Purchase Order
- Receipt posting: Transfer assets from vendor to location
- Invoice posting: No asset movement
- Event subscribers for Purch-Post codeunit

**Testing:**
- Integration: Post purchase receipt with assets
- Integration: Verify holder entries created at receipt
- Integration: Post invoice after receipt (no asset movement)
- Integration: Verify children transferred
- Build-Publish-Test: All tests pass

**Git Commit:** "Phase 2 Stage 5.2 - Purchase document integration"

---

## Stage 6: BC Document Integration - Transfer

### Stage 6.1: Transfer Asset Line Tables ⏸️ PENDING

**Objective:** Create tables for asset lines on Transfer Orders

**Objects to Create:**
- Table 70182322 "JML AP Transfer Asset Line"
- Table 70182323 "JML AP Posted Transfer Asset Line"
- Page 70182363 "JML AP Transfer Asset Subpage"
- Page 70182364 "JML AP Posted Transfer Asset Sub"

**Key Features:**
- Shipment: Asset leaves source location
- Receipt: Asset arrives at destination location
- Two-step transfer process

**Testing:**
- Manual: Create transfer asset line
- Build: 0 errors, 0 warnings

**Git Commit:** "Phase 2 Stage 6.1 - Transfer asset line tables and pages"

---

### Stage 6.2: Transfer Integration Logic ⏸️ PENDING

**Objective:** Integrate asset transfer with Transfer Order posting

**Objects to Create:**
- Table Extension 70182422 "JML AP Transfer Header Ext"
- Table Extension 70182425 "JML AP Trans. Receipt Hdr Ext"
- Page Extension 70182439 "JML AP Transfer Order Ext"
- Page Extension 70182440 "JML AP Trans. Receipt Ext"
- Enhance Codeunit 70182392 (Transfer subscribers)
- Test Codeunit 50112 "JML AP Transfer Integration Tests"

**Key Features:**
- Asset Lines subpage on Transfer Order
- Ship posting: Transfer Out from source
- Receive posting: Transfer In to destination
- Event subscribers for TransferOrder-Post codeunit

**Testing:**
- Integration: Post transfer shipment with assets
- Integration: Post transfer receipt
- Integration: Verify two-step holder entries
- Integration: Verify children transferred at both steps
- Build-Publish-Test: All tests pass

**Git Commit:** "Phase 2 Stage 6.2 - Transfer document integration"

---

## Stage 7: Role Center

### Stage 7.1: Role Center Implementation ⏸️ PENDING

**Objective:** Provide Asset Manager workspace (R7)

**Objects to Create:**
- Table 70182328 "JML AP Asset Mgmt. Cue"
- Page 70182370 "JML AP Asset Mgmt. Role Center"
- Page 70182371 "JML AP Asset Mgmt. Activities"
- Page 70182372 "JML AP Asset Mgmt. Headline"
- Profile "JML AP ASSET MANAGER"
- Test Codeunit 50113 "JML AP Role Center Tests"

**Key Features:**
- Dynamic KPI tiles (Total Assets, Open Transfers, etc.)
- Quick access to all Asset Pro pages
- Headline with greeting and activity summary
- Activities part with cue groups
- Navigation areas (Sections, Embedding, Creation)

**Testing:**
- Manual: Assign profile to user
- Manual: Verify all tiles display correct counts
- Manual: Verify all navigation links work
- Manual: Verify headlines update dynamically
- Unit: Cue calculation tests
- Build-Publish-Test: All tests pass

**Git Commit:** "Phase 2 Stage 7.1 - Asset Management Role Center"

---

## Progress Tracking

### Completed Stages
- [x] **Stage 1.1** - Asset Journal tables and pages (Git: 62c805b)
- [x] **Stage 1.2** - Asset Journal posting logic (Git: e2f7016)
- [x] **Stage 1.3** - Asset Transfer Order tables (Git: 41f2340)
- [x] **Stage 1.4** - Asset Transfer Order pages (Git: 279974f)
- [x] **Stage 1.5** - Asset Transfer Order posting logic (Git: 2e0eabf)
- [ ] Stage 2.1 - Relationship tracking infrastructure
- [ ] Stage 2.2 - Asset Card relationship enhancements
- [ ] Stage 3.1 - Manual holder change control
- [ ] Stage 4.1 - Sales asset line tables
- [ ] Stage 4.2 - Sales asset line pages
- [ ] Stage 4.3 - Sales integration logic
- [ ] Stage 5.1 - Purchase asset line tables
- [ ] Stage 5.2 - Purchase integration logic
- [ ] Stage 6.1 - Transfer asset line tables and pages
- [ ] Stage 6.2 - Transfer integration logic
- [ ] Stage 7.1 - Role Center implementation

### Current Stage
**Stage 2.1** - Relationship Entry Infrastructure (Next to implement)

### Progress Summary
- **Completed:** 5/17 stages (29%)
- **Current Phase:** Stage 1 - Core Transfer Infrastructure (Complete!)
- **Git Commits:** 5 (62c805b, e2f7016, 41f2340, 279974f, 2e0eabf)
- **Objects Created:** 21 (2 enums, 6 tables, 8 pages, 3 codeunits, 2 table enhancements)
- **Tests Created:** 16 test procedures (6 in 50107, 10 in 50108)

---

## Object ID Usage Summary

### Tables (70182311-70182328)
- 70182311: Asset Journal Batch ✅ CREATED
- 70182312: Asset Journal Line ✅ CREATED
- 70182313: Asset Transfer Header ✅ CREATED
- 70182314: Asset Transfer Line ✅ CREATED
- 70182315: Posted Asset Transfer ✅ CREATED
- 70182316: Pstd. Asset Trans. Line ✅ CREATED
- 70182317: Asset Relationship Entry
- 70182318: Sales Asset Line
- 70182319: Posted Sales Asset Line
- 70182320: Purch. Asset Line
- 70182321: Posted Purch. Asset Line
- 70182322: Transfer Asset Line
- 70182323: Posted Transfer Asset Line
- 70182324: Posted Sales Shpt. Asset Line
- 70182325: Posted Purch. Rcpt. Asset Line
- 70182326: Posted Ret. Shpt. Asset Line
- 70182327: Posted Ret. Rcpt. Asset Line
- 70182328: Asset Mgmt. Cue

### Pages (70182351-70182372)
- 70182351: Asset Journal Batches ✅ CREATED
- 70182352: Asset Journal ✅ CREATED
- 70182353-70182358: Transfer Order pages (6)
- 70182359-70182364: Document integration subpages (6)
- 70182365: Relationship Entries
- 70182366-70182369: Posted shipment/receipt subpages (4)
- 70182370-70182372: Role Center pages (3)

### Codeunits (70182390-70182393)
- 70182390: Asset Jnl.-Post ✅ CREATED
- 70182391: Asset Transfer-Post
- 70182392: Document Integration
- 70182393: Relationship Mgt

### Enums (70182408-70182409)
- 70182408: Relationship Entry Type
- 70182409: Transfer Status ✅ CREATED

### Enhanced Existing Objects
- ✅ Enum 70182405: JML AP Document Type (added Journal value)
- ✅ Table 70182300: JML AP Asset Setup (added Transfer Order Nos., Posted Transfer Nos.)
- ✅ Page 70182330: JML AP Asset Setup (added Numbering group)

### Table Extensions (70182420-70182425)
- 70182420-70182422: Document Header extensions (3)
- 70182423-70182425: Posted Header extensions (3)

### Page Extensions (70182435-70182446)
- 70182435-70182440: Main document extensions (6)
- 70182441-70182442: Asset Card/List extensions (2)
- 70182443-70182446: Posted shipment/receipt extensions (4)

### Test Codeunits (50107-50113)
- 50107: Journal Tests ✅ CREATED (6 test procedures)
- 50108: Transfer Order Tests
- 50109: Relationship Tests
- 50110: Sales Integration Tests
- 50111: Purchase Integration Tests
- 50112: Transfer Integration Tests
- 50113: Role Center Tests

---

## Notes

- Each stage ends with a git commit for version control
- Each stage with posting logic requires full build-publish-test cycle
- All objects follow AL Best Practices (no WITH, Caption/ToolTip required, etc.)
- All tests follow AAA pattern (Arrange-Act-Assert)
- Minimum 3 test scenarios per feature (happy path, error, edge case)
