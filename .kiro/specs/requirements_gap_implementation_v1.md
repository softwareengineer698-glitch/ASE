---
title: Requirements Gap Implementation
version: 1.0.0
status: in_progress
created: 2026-07-03
description: Implementation design for 4 pending requirements from 18-point requirements document

## Implementation Status

| Task | Status | Files Modified |
|------|--------|----------------|
| Remove NGO Verification | ✅ Complete | admin_service.dart, admin_provider.dart, admin_dashboard.dart, ngo_profile_screen.dart |
| Expand Notification System | ✅ Complete | notification_model.dart, notification_service.dart |
| Add Request Feature | ✅ Complete | food_request_model.dart, food_request_service.dart, request_list_screen.dart, create_request_screen.dart, my_requests_screen.dart, ngo_dashboard_new.dart, main.dart |
| Verify Registration | ✅ Complete | sign_up_screen.dart (already simplified) |

---

## Overview

This spec outlines the design and implementation approach for 4 critical gaps identified in the requirements assessment:

1. **Remove NGO Verification** - Simplify by removing manual verification layer
2. **Expand Notification System** - Complete notification coverage for all events
3. **Add Request Feature** - Allow users to submit food requests
4. **Verify Registration Simplification** - Confirm and refine single registration flow

## 1. Remove NGO Verification

### Current State
- `admin_dashboard.dart`: Has "Verifications" tab with manual NGO approval workflow
- `ngo_profile_screen.dart`: Shows "Verified" / "Pending Verification" badges
- `user_model.dart`: Has `isVerified` boolean field (default false)
- `admin_service.dart`: Has `verifyNGO()` and `streamPendingNGOs()` methods

### Required Changes

#### 1.1 Remove Verification Tab from Admin Dashboard
- File: `lib/screens/admin/admin_dashboard.dart`
- Change: Remove "Verifications" tab (tab index 2)
- Keep: Overview and Users tabs
- Rationale: Admin can still view/delete users through Users tab

#### 1.2 Remove Verification Badge from NGO Profile
- File: `lib/screens/profile/ngo_profile_screen.dart`
- Change: Remove `isVerified` badge display
- Keep: Profile editing, settings, etc.
- Rationale: All NGOs are automatically verified

#### 1.3 Remove isVerified Field References
- Files: Multiple (user_model.dart, admin_service.dart, ngo_profile_screen.dart)
- Change: Remove `isVerified` field from UserModel
- Note: Keep field in Firestore for backward compatibility (ignore on read)

#### 1.4 Remove Admin Verification Methods
- File: `lib/services/admin_service.dart`
- Change: Remove `verifyNGO()`, `streamPendingNGOs()` methods
- Keep: User management (delete user, stream users)

#### 1.5 Update Admin Dashboard Stats
- File: `lib/providers/admin_provider.dart`
- Change: Remove "pendingNGOs" from stats calculation
- Rationale: No pending verifications exist

### Implementation Order
1. Remove verification methods from AdminService
2. Update AdminProvider to remove pending NGOs
3. Remove Verifications tab from AdminDashboard
4. Remove verification badge from NGO profile
5. Remove isVerified field (soft removal for compatibility)

---

## 2. Expand Notification System

### Current State
- `notification_service.dart`: Basic in-memory notifications
- `notification_model.dart`: Has NotificationType enum (surplusReported, surplusAccepted, surplusCollected, general)
- Missing: Claim notifications, pickup reminders, expiry reminders, new food nearby

### Required Changes

#### 2.1 Expand NotificationType Enum
```dart
enum NotificationType {
  surplusReported,      // New food available
  surplusAccepted,      // NGO accepted donation
  surplusCollected,     // Donation collected
  claimReceived,        // Claim request received (for donors)
  claimAccepted,        // Claim approved (for NGOs)
  claimRejected,        // Claim denied
  pickupReminder,       // Pickup deadline approaching
  expiryReminder,       // Food expiring soon
  requestFulfilled,     // Request was fulfilled
  general,
}
```

#### 2.2 Add Notification Methods to NotificationService
- `notifyNewFoodNearby()` - Alert NGOs of new surplus in their area
- `notifyClaimReceived()` - Alert donors of claim requests on their donations
- `notifyClaimAccepted()` - Confirm claim was approved
- `notifyClaimRejected()` - Inform claim was denied
- `notifyPickupReminder()` - Remind NGOs to pick up before expiry
- `notifyExpiryReminder()` - Warn about expiring food
- `notifyRequestFulfilled()` - Confirm request was met

#### 2.3 Update NotificationsScreen
- File: `lib/screens/notifications/notifications_screen.dart`
- Add: Filter by notification type
- Add: Group by date (Today, Yesterday, This Week)
- Add: Mark all as read functionality

#### 2.4 Integrate Notifications into App Flow
- Donor Dashboard: Show notifications badge
- NGO Dashboard: Show notifications badge
- Bottom Navigation: Add notifications icon with badge

### Implementation Order
1. Update NotificationType enum
2. Add new notification methods to NotificationService
3. Update NotificationsScreen UI
4. Add notification badges to dashboards
5. Trigger notifications from donation/claim flows

---

## 3. Add Request Feature

### Requirement
Allow users to submit food requests specifying what they need. Donors can fulfill these requests.

### Design

#### 3.1 Request Model (new file)
```dart
class FoodRequest {
  final String id;
  final String userId;
  final String userName;
  final String foodType;
  final String description;
  final int quantity;
  final String unit; // kg, pieces, boxes, etc.
  final DateTime neededBy;
  final RequestStatus status;
  final DateTime createdAt;
  final String? fulfilledByDonorId;
  final String? fulfilledByDonorName;
}
```

#### 3.2 Request Status Enum
```dart
enum RequestStatus {
  pending,      // Waiting for fulfillment
  fulfilled,    // Donors provided the food
  expired,      // Deadline passed without fulfillment
  cancelled,    // User cancelled request
}
```

#### 3.3 Request Service (new file)
- `createRequest()` - User submits new request
- `getRequests()` - Get all active requests
- `getMyRequests()` - Get user's own requests
- `fulfillRequest()` - Donor marks request as fulfilled
- `cancelRequest()` - User cancels request
- `expireRequests()` - Auto-expire past deadline requests

#### 3.4 Request Screens (new files)
- `request_list_screen.dart` - Browse all requests (NGO/Individual view)
- `create_request_screen.dart` - Submit new request
- `my_requests_screen.dart` - View own requests

#### 3.5 Integration Points
- Add "Requests" button to NGO Dashboard
- Show matching donations for each request
- Donors can see requests when creating donations

### Implementation Order
1. Create Request model
2. Create Request service
3. Create Request screens
4. Add to navigation flow
5. Connect to donation flow

---

## 4. Verify & Refine Registration Flow

### Current State
- `sign_up_screen.dart`: Already simplified - no role selection during registration
- Defaults to `UserRole.donor`
- Role picker shown after first login

### Required Changes

#### 4.1 Verify Current Implementation
The current sign_up_screen.dart appears to already match the requirement:
- No role selection during sign up
- Default role is donor
- Role picker shown after login

#### 4.2 Potential Enhancements
- Add OTP verification during registration (as per requirements)
- Make role picker more prominent
- Add skip option (default to Donor)

### Implementation Order (if enhancements needed)
1. Add OTP verification to sign up
2. Update role picker UI
3. Test registration flow

---

## Files to Modify

### High Priority
1. `lib/screens/admin/admin_dashboard.dart` - Remove verification tab
2. `lib/screens/profile/ngo_profile_screen.dart` - Remove verification badge
3. `lib/services/admin_service.dart` - Remove verification methods
4. `lib/models/notification_model.dart` - Expand notification types
5. `lib/services/notification_service.dart` - Add notification methods
6. `lib/models/food_request_model.dart` - NEW FILE
7. `lib/services/food_request_service.dart` - NEW FILE

### Medium Priority
8. `lib/screens/notifications/notifications_screen.dart` - Enhance UI
9. `lib/screens/request/create_request_screen.dart` - NEW FILE
10. `lib/screens/request/request_list_screen.dart` - NEW FILE
11. `lib/providers/admin_provider.dart` - Remove pending NGOs stat

### Low Priority
12. `lib/models/user_model.dart` - Soft remove isVerified field
13. `lib/main.dart` - Add notification badge to navigation

---

## Testing Checklist

### NGO Verification Removal
- [ ] Admin dashboard has only 2 tabs (Overview, Users)
- [ ] No "Verifications" tab visible
- [ ] NGO profile shows no verification badge
- [ ] NGOs can access all features immediately after registration

### Notification System
- [ ] New food nearby notifications work
- [ ] Claim received/accepted/rejected notifications work
- [ ] Pickup reminders appear
- [ ] Expiry warnings are shown
- [ ] Notification badges show correct count on dashboards

### Request Feature
- [ ] Users can create food requests
- [ ] NGOs can see available requests
- [ ] Donors can fulfill requests
- [ ] Request status updates correctly

### Registration
- [ ] No role selection during sign up
- [ ] Role picker appears after first login
- [ ] Users can change roles anytime
- [ ] OTP verification works (if implemented)

---

## Dependencies & Risks

### Dependencies
- Firebase Firestore for request storage
- NotificationService for all notification types
- Existing donation flow for request matching

### Risks
- Breaking change for existing verified NGOs (should be auto-verified)
- Notification overload (need to limit frequency)
- Request spam (may need moderation)

---

## Estimated Effort

| Task | Complexity |
|------|------------|
| Remove NGO Verification | Low |
| Expand Notifications | Medium |
| Add Request Feature | Medium-High |
| Verify Registration | Low (already done) |

---

## Notes

- All changes should maintain backward compatibility where possible
- Remove verification features but keep user data
- Notifications should be dismissible and groupable
- Requests should have expiration dates to auto-expire