# Assigning the Asset Manager Profile

**Module:** Asset Pro
**Feature:** Role Center Profile Assignment
**Version:** 26.0.2.0

---

## Quick Start

Follow these steps to assign the Asset Manager role to a user:

### Step 1: Open User Settings
1. Search for **"User Settings List"** or **"User Personalization"**
2. Press Enter to open the page

### Step 2: Select the User
1. Find the user who needs Asset Manager access
2. Click on their record to open the details

### Step 3: Assign the Profile
1. In the **Profile** field, click the lookup (three dots)
2. Search for **"Asset Manager"**
3. Select **"Asset Manager"** from the list
4. The system will populate:
   - Profile ID: `JML AP ASSET MANAGER`
   - Role Center: `JML AP Asset Mgmt. Role Center`

### Step 4: Save and Apply
1. Click **OK** to save the changes
2. Inform the user to **sign out and sign back in**
3. The new Role Center will appear on next login

---

## Verification

After the user signs back in:
1. They should see the **Asset Manager Role Center** as their home page
2. The headline banner will display a personalized greeting
3. Activity tiles will show real-time KPIs
4. Navigation sections will be organized for Asset Pro

---

## Permissions

**Important:** The user must also have the **"JMLAssetPro"** permission set assigned to access Asset Pro functionality.

To assign permissions:
1. Search for **"Permission Set by User"**
2. Select the user
3. Add **"JMLAssetPro"** to their permission sets
4. Save the changes

---

## Multiple Users

To assign the Asset Manager profile to multiple users:
1. Follow Steps 1-4 above for each user
2. Alternatively, use **Permission Set by Security Group** to manage permissions for groups of users

---

## Removing the Profile

To remove the Asset Manager profile from a user:
1. Open **User Settings List**
2. Select the user
3. Clear the **Profile** field or select a different profile
4. Save the changes
5. User must sign out and sign back in

---

## Troubleshooting

### User Doesn't See the Role Center
- **Solution:** Ensure the user signed out and back in after profile assignment
- **Solution:** Clear browser cache and retry

### Permission Errors
- **Solution:** Verify the user has the "JMLAssetPro" permission set assigned
- **Solution:** Contact system administrator if issues persist

### Role Center Appears Empty
- **Cause:** No data exists yet in Asset Pro
- **Solution:** This is normal for new installations. KPIs will populate as data is created.

---

**Last Updated:** 2025-11-27
**Updated By:** Claude Code (AI Implementation)