# Asset Pro - Backlog and Enhancement Ideas

**Purpose:** Track polish items, feature ideas, and future enhancements that are outside the current Phase 2 scope.

---

## Polish Items (UI/UX Improvements)

### 1. Asset Card - Picture FactBox
**Priority:** Medium
**Description:** Add a FactBox to Asset Card page to display asset picture
**Benefits:**
- Visual identification of assets
- Improved user experience
- Quick asset recognition

**Technical Notes:**
- Use Picture field type in Asset table
- Create FactBox page part
- Add to Asset Card page FactBox area

**Estimated Effort:** 1-2 hours

---

### 2. AI Integration for Asset Management
**Priority:** Low (Experimental)
**Description:** Explore AI capabilities for asset management solution
**Potential Use Cases:**
- Asset description auto-generation from pictures
- Predictive maintenance suggestions based on holder history
- Smart asset categorization/tagging
- Natural language queries for asset search
- Automated anomaly detection in transfer patterns

**Technical Notes:**
- Could leverage Azure OpenAI Service
- Integration via AL HttpClient
- Might need custom API wrapper
- Consider privacy/security implications

**Estimated Effort:** Research phase: 4-8 hours

---

## Future Feature Ideas

### 3. Asset Maintenance Tracking
**Description:** Track maintenance schedules, service history, costs
**Status:** Idea
**Related to:** Holder history tracking

---

### 4. Asset Depreciation Module
**Description:** Financial depreciation tracking tied to holder changes
**Status:** Idea
**Dependencies:** Would need FA integration

---

### 5. Mobile App for Asset Scanning
**Description:** QR/barcode scanning for quick asset transfers
**Status:** Idea
**Technology:** BC Mobile App or custom Power App

---

## Technical Debt

### 6. Performance Optimization
**Description:** Review recursive child asset lookups for large hierarchies
**Status:** Monitor
**Action:** Profile with >100 assets in 3+ levels

---

## Documentation Improvements

### 7. User Guide - Asset Transfer Workflows
**Description:** Step-by-step guides for common scenarios
**Status:** Pending
**Scope:** After Phase 2 complete

---

### 8. Admin Guide - Setup and Configuration
**Description:** Complete setup walkthrough with screenshots
**Status:** Pending
**Scope:** After Phase 2 complete

---

### 9. Customer/Vendor/Ship-to address cards factboxes with linked assets count
**Description:** To show in customer/vendor etc card data with assets linked to that entity.
**Status:** Pending
**Scope:** After Phase 2 complete

---

## Notes

- Items here are NOT part of Phase 2 implementation plan
- Review this backlog after Phase 2 completion
- Prioritize based on user feedback
- Some ideas may become Phase 3 features

**Last Updated:** 2025-11-22
