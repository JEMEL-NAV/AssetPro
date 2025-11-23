# Asset Pro - Phase 2 Stage 3.2: User Experience Corrections

**Project:** Asset Pro - Phase 2
**Stage:** 3.2 - UX Corrections and Enhanced Validation
**Status:** Planning
**Created:** 2025-11-23

---

## Overview

This stage implements corrections and enhancements based on user testing feedback. The changes improve usability and add missing validation rules for holder changes and parent-child relationships.

---

## Requirements Summary

### R1: Asset Journal - Current Holder Address Display
**Requirement:** Display current holder's address on journal line for reference
**Rationale:** Users need to see where the asset currently is (address) when planning transfers

### R2: Asset Journal - Allow Same Holder, Different Address
**Requirement:** Allow transferring asset to same holder but different address
**Current Issue:** SameHolderErr blocks transfers like Customer A, Address 1 → Customer A, Address 2
**Rationale:** Common scenario: Moving equipment between customer locations

### R3: Asset Journal - Confirm Before Posting
**Requirement:** Show confirmation dialog before posting journal
**Rationale:** Prevent accidental posting of large batches

### R4: Parent Assignment - Same Holder Validation
**Requirement:** Parent and child must have same current holder when assigning parent
**Current Issue:** Can assign parent even if assets are at different locations
**Rationale:** Physical assembly only possible when both assets are in same location

### R5: Parent Assignment - Level Validation
**Requirement:** Only allow parent assignment to assets at parent level (Classification Level 1)
**Current Issue:** Can assign same-level asset as parent (e.g., Level 3 → Level 3)
**Rationale:** Prevent incorrect hierarchies

### R6: Transfer Order - Allow Same Holder, Different Address
**Requirement:** Same as R2, but for Transfer Orders
**Current Issue:** CheckTransferOrder() blocks same holder transfers

### R7: Transfer Order - Confirm Before Posting
**Requirement:** Show confirmation dialog before posting transfer order
**Rationale:** Prevent accidental posting

---

## Technical Design

### Change 1: Asset Journal Line - Add Current Holder Address

**Object:** Table 70182312 "JML AP Asset Journal Line"

**Changes:**
- Add field 14 "Current Holder Addr Code" (Code[10])
- Populate in OnValidate of "Asset No." field (line 27-48)
- Set to Editable = false (display only)

**Code Location:** Line 27-48 (Asset No. OnValidate trigger)

```al
// After line 43:
"Current Holder Addr Code" := Asset."Current Holder Addr Code";
```

**Object:** Page 70182352 "JML AP Asset Journal"

**Changes:**
- Add "Current Holder Addr Code" column after "Current Holder Code"
- Read-only, for display only

---

### Change 2: Asset Journal Line - Remove Same Holder Validation

**Object:** Table 70182312 "JML AP Asset Journal Line"

**Changes:**
- Remove or modify lines 121-124 in "New Holder Code" OnValidate
- Allow same holder if address codes differ
- Only error if both holder AND address are identical

**Current Code (lines 121-124):**
```al
// Validate different from current
if ("New Holder Type" = "Current Holder Type") and
   ("New Holder Code" = "Current Holder Code")
then
    Error(SameHolderErr, "Asset No.");
```

**New Code:**
```al
// Allow same holder if address changes
// Only block if holder AND address are identical
if ("New Holder Type" = "Current Holder Type") and
   ("New Holder Code" = "Current Holder Code") and
   ("New Holder Addr Code" = "Current Holder Addr Code")
then
    Error(SameHolderAddressErr, "Asset No.");
```

**New Error Message:**
```al
SameHolderAddressErr: Label 'New holder and address must be different from current holder and address for asset %1.';
```

---

### Change 3: Asset Journal Posting - Add Confirmation Dialog

**Object:** Codeunit 70182390 "JML AP Asset Jnl.-Post"

**Changes:**
- Add ConfirmPost boolean parameter (or internal variable)
- Add confirmation dialog before posting in Code() procedure
- Allow suppression for API/automated posting

**Code Location:** Line 26-59 (Code() procedure)

**Implementation:**
```al
local procedure Code()
var
    AssetJnlBatch: Record "JML AP Asset Journal Batch";
    ConfirmQst: Label 'Do you want to post %1 journal line(s)?';
begin
    if AssetJnlLine."Journal Batch Name" = '' then
        exit;

    AssetJnlBatch.Get(AssetJnlLine."Journal Batch Name");

    AssetJnlLine.SetRange("Journal Batch Name", AssetJnlLine."Journal Batch Name");
    if not AssetJnlLine.FindSet() then
        exit;

    NoOfRecords := AssetJnlLine.Count;

    // Add confirmation dialog (unless suppressed)
    if not SuppressConfirmation then
        if not Confirm(ConfirmQst, true, NoOfRecords) then
            exit;

    LineCount := 0;
    Window.Open(PostingMsg);
    // ... rest of posting logic
end;
```

**Additional Changes:**
- Add global variable: `SuppressConfirmation: Boolean`
- Add procedure: `SetSuppressConfirmation(Suppress: Boolean)` for API use

---

### Change 4: Asset Table - Parent Assignment Same Holder Validation

**Object:** Table 70182301 "JML AP Asset"

**Changes:**
- Enhance ValidateParentAsset() procedure (line 541-563)
- Add validation that parent and child have same current holder
- Allow blank holders (unconfigured assets)

**Code Location:** Line 541-563 (ValidateParentAsset() procedure)

**Implementation:**
```al
local procedure ValidateParentAsset()
var
    ParentAsset: Record "JML AP Asset";
    AssetValidator: Codeunit "JML AP Asset Validation";
    RelationshipMgt: Codeunit "JML AP Relationship Mgt";
begin
    // ... existing relationship logging code (lines 546-552)

    if "Parent Asset No." = '' then begin
        "Hierarchy Level" := 1;
        UpdateRootAssetNo();
        exit;
    end;

    // NEW: Validate same holder if both assets have holders
    if ParentAsset.Get("Parent Asset No.") then begin
        if ("Current Holder Type" <> "Current Holder Type"::" ") and
           (ParentAsset."Current Holder Type" <> "Current Holder Type"::" ")
        then begin
            if ("Current Holder Type" <> ParentAsset."Current Holder Type") or
               ("Current Holder Code" <> ParentAsset."Current Holder Code")
            then
                Error(DifferentHolderErr, "No.", "Parent Asset No.",
                      ParentAsset."Current Holder Type", ParentAsset."Current Holder Code");
        end;
    end;

    AssetValidator.ValidateParentAssignment(Rec);
    CalculateHierarchyLevel();
    UpdateRootAssetNo();
end;
```

**New Error Message:**
```al
DifferentHolderErr: Label 'Cannot assign asset %1 to parent %2. Parent is at %3 %4, but child is at different holder. Both must be at same location.';
```

---

### Change 5: Asset Table - Parent Level Validation

**Object:** Codeunit 70182380 "JML AP Asset Validation"

**Changes:**
- Enhance ValidateParentAssignment() procedure
- Add check that parent asset is at Classification Level 1 (parent level)
- Prevent same-level or child-level assets from being parents

**Implementation:**
```al
procedure ValidateParentAssignment(var ChildAsset: Record "JML AP Asset")
var
    ParentAsset: Record "JML AP Asset";
    ClassValue: Record "JML AP Classification Val";
    ParentLevelNo: Integer;
begin
    // ... existing circular reference checks ...

    // NEW: Validate parent is at parent level (Level 1)
    if ParentAsset.Get(ChildAsset."Parent Asset No.") then begin
        if ParentAsset."Classification Code" <> '' then begin
            ParentAsset.CalcFields("Classification Level No.");
            ParentLevelNo := ParentAsset."Classification Level No.";

            // Only Level 1 assets can be parents
            if ParentLevelNo <> 1 then
                Error(InvalidParentLevelErr,
                      ParentAsset."No.",
                      ParentLevelNo,
                      ParentAsset."Classification Code");
        end;
    end;

    // ... rest of existing validation ...
end;
```

**New Error Message:**
```al
InvalidParentLevelErr: Label 'Cannot use asset %1 as parent. It is at classification level %2 (%3). Only parent-level assets (Level 1) can have children.';
```

---

### Change 6: Transfer Order - Allow Same Holder, Different Address

**Object:** Codeunit 70182391 "JML AP Asset Transfer-Post"

**Changes:**
- Modify CheckTransferOrder() procedure (line 35-59)
- Change validation to allow same holder with different address
- Only error if both holder AND address are identical

**Current Code (lines 49-53):**
```al
// Validate different holders
if (TransferHdr."From Holder Type" = TransferHdr."To Holder Type") and
   (TransferHdr."From Holder Code" = TransferHdr."To Holder Code")
then
    Error('From Holder and To Holder must be different.');
```

**New Code:**
```al
// Allow same holder if address changes
if (TransferHdr."From Holder Type" = TransferHdr."To Holder Type") and
   (TransferHdr."From Holder Code" = TransferHdr."To Holder Code") and
   (TransferHdr."From Holder Addr Code" = TransferHdr."To Holder Addr Code")
then
    Error(SameHolderAddressErr);

var
    SameHolderAddressErr: Label 'From Holder and To Holder cannot be identical (same type, code, and address). Use different address for same holder transfers.';
```

---

### Change 7: Transfer Order - Add Confirmation Dialog

**Object:** Codeunit 70182391 "JML AP Asset Transfer-Post"

**Changes:**
- Add confirmation dialog in Code() procedure (line 21-33)
- Confirm before starting posting process

**Code Location:** Line 21-33 (Code() procedure)

**Implementation:**
```al
local procedure Code()
var
    PostedTransferNo: Code[20];
    ConfirmQst: Label 'Do you want to post Transfer Order %1?';
begin
    CheckTransferOrder(TransferHeader);

    // Add confirmation dialog
    if not Confirm(ConfirmQst, true, TransferHeader."No.") then
        exit;

    Window.Open(PostingMsg);
    Window.Update(1, TransferHeader."No.");

    PostedTransferNo := PostTransferOrder(TransferHeader);

    Window.Close();
    Message(PostedMsg, TransferHeader."No.", PostedTransferNo);
end;
```

---

## Testing Strategy

### Test 1: Current Holder Address Display
**Scenario:** Create asset with Customer + Address, add to journal
**Expected:** Journal line shows current address code
**Verify:** Field populated and read-only

### Test 2: Same Holder, Different Address (Journal)
**Scenario:** Move asset from Customer A, Address 1 → Customer A, Address 2
**Expected:** Validation passes, posting succeeds
**Verify:** Holder entries created with correct addresses

### Test 3: Same Holder, Same Address (Journal)
**Scenario:** Try to "transfer" asset to same holder and address
**Expected:** Error message displayed
**Verify:** Cannot post invalid transfer

### Test 4: Journal Posting Confirmation
**Scenario:** Post journal with 5 lines
**Expected:** Confirmation dialog "Post 5 lines?"
**Verify:** Cancel = no posting, OK = posting proceeds

### Test 5: Parent Assignment - Same Holder
**Scenario:** Asset A at Location X, Asset B at Location Y, assign B to A as parent
**Expected:** Error - different holders
**Verify:** Error message shows holder details

### Test 6: Parent Assignment - Same Holder Success
**Scenario:** Asset A at Location X, Asset B at Location X, assign B to A as parent
**Expected:** Assignment succeeds
**Verify:** Parent relationship created

### Test 7: Parent Assignment - Level Validation
**Scenario:** Asset A (Level 3), Asset B (Level 3), assign B to A as parent
**Expected:** Error - parent must be Level 1
**Verify:** Error message shows level requirement

### Test 8: Transfer Order - Same Holder, Different Address
**Scenario:** Transfer order from Vendor A, Addr 1 → Vendor A, Addr 2
**Expected:** Posting succeeds
**Verify:** Holder entries have correct addresses

### Test 9: Transfer Order Confirmation
**Scenario:** Post transfer order with 3 assets
**Expected:** Confirmation dialog shown
**Verify:** Cancel = no posting, OK = posting proceeds

---

## Implementation Order

1. **Asset Journal Line - Current Holder Address** (Low Risk)
   - Add field and populate from asset
   - Add to page

2. **Asset Journal - Remove Same Holder Block** (Medium Risk)
   - Modify validation logic
   - Update error message

3. **Journal Posting Confirmation** (Low Risk)
   - Add Confirm() call
   - Add suppression flag

4. **Parent Assignment - Same Holder Check** (Medium Risk)
   - Add validation in ValidateParentAsset()
   - Add error message

5. **Parent Assignment - Level Check** (High Risk - New Rule)
   - Enhance AssetValidator codeunit
   - Add classification level check

6. **Transfer Order - Same Holder Support** (Medium Risk)
   - Modify CheckTransferOrder()
   - Update error message

7. **Transfer Order - Confirmation** (Low Risk)
   - Add Confirm() call

8. **Build, Test, Commit** (After each group)
   - Run full test suite
   - Verify no regressions

---

## Objects Modified

### Tables
- 70182312 "JML AP Asset Journal Line" - Add field, modify validation
- 70182301 "JML AP Asset" - Enhance parent validation

### Pages
- 70182352 "JML AP Asset Journal" - Add address column

### Codeunits
- 70182390 "JML AP Asset Jnl.-Post" - Add confirmation
- 70182391 "JML AP Asset Transfer-Post" - Modify validation, add confirmation
- 70182380 "JML AP Asset Validation" - Add level validation

### Tests
- 50107 "JML AP Journal Tests" - Add test for address field, same holder scenarios
- 50108 "JML AP Transfer Order Tests" - Add test for same holder, confirmation
- 50110 "JML AP Manual Holder Tests" - Add parent assignment validation tests

---

## Risks and Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Breaking existing journals | HIGH | Backward compatibility: blank address = different |
| Level 1 rule too strict | MEDIUM | Discuss with user before implementation |
| Confirmation dialogs annoying | LOW | Add suppression flag for automation |
| Same holder creates duplicate entries | MEDIUM | Verify journal posting handles address-only changes |

---

## Success Criteria

- ✅ All 9 test scenarios pass
- ✅ Build: 0 errors, 0 warnings
- ✅ No regressions in existing tests
- ✅ User approval of Level 1 parent rule
- ✅ Documentation updated

---

## Git Commit Strategy

**Option A: Single Commit**
- All changes in one commit
- Easier to revert if issues found
- Harder to review

**Option B: Two Commits**
- Commit 1: Asset Journal corrections (Changes 1-3)
- Commit 2: Parent/Transfer corrections (Changes 4-7)

**Recommended: Option B** - Logical separation of concerns

---

## Notes

- Change 5 (Level validation) is NEW BUSINESS RULE - requires user confirmation
- All other changes are UX improvements or bug fixes
- Maintain backward compatibility where possible
- Document breaking changes in commit message

---

**Status:** Ready for implementation
**Next Step:** User approval for Level 1 parent rule (Change 5)
