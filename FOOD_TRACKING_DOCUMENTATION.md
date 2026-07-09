# Food Tracking System Documentation

## Overview

The Food Tracking System provides end-to-end visibility of food donations from creation to completion, enabling transparency, accountability, and insights for all stakeholders.

## What is Tracked

### 1. Donation Lifecycle
- **Creation** - When, where, what, and how much
- **Listing** - Availability status changes
- **Claims** - Who claimed, when, how much
- **Coordination** - Chat messages, arrangements
- **Collection** - Pickup confirmation with photos
- **Completion** - Final status and feedback

### 2. Status Transitions
```
Available → Claimed → Accepted → Collected → Completed
         ↓          ↓          ↓
      Expired   Rejected   Cancelled
```

### 3. Key Metrics
- **Time to Claim** - How long until first claim
- **Time to Collect** - Duration from acceptance to pickup
- **Completion Rate** - % of donations successfully completed
- **Waste Rate** - % of donations that expired
- **Response Time** - Donor response time to claims

### 4. User Actions
- Donation posts, edits, cancellations
- Claims submitted, accepted, rejected
- Chat interactions
- Ratings and feedback
- Photos uploaded (before/after)

## Why Tracking is Useful

### For Donors
✅ **Transparency** - See exactly where their donation went  
✅ **Impact Visibility** - Track cumulative contributions  
✅ **Reputation Building** - Positive ratings increase trust  
✅ **Pattern Learning** - Understand what donations work best  
✅ **Tax Records** - Export donation history for tax purposes  

### For NGOs/Recipients
✅ **Reliability Tracking** - Identify dependable donors  
✅ **Planning** - Historical data helps forecast needs  
✅ **Accountability** - Proof of food collection and distribution  
✅ **Performance** - Track response times and efficiency  
✅ **Compliance** - Meet regulatory reporting requirements  

### For Administrators
✅ **Platform Analytics** - Monitor system usage and health  
✅ **Fraud Detection** - Identify suspicious patterns  
✅ **Quality Control** - Track user ratings and complaints  
✅ **Resource Allocation** - Understand regional demand  
✅ **Impact Reports** - Generate reports for stakeholders  

### For Researchers
✅ **Food Waste Studies** - Quantify waste patterns  
✅ **Behavioral Analysis** - Study donation behaviors  
✅ **Urban Food Systems** - Map food flows in cities  
✅ **Social Impact** - Measure community benefits  

## How Tracking Works

### Data Collection Points

#### 1. Donation Creation
```dart
{
  "donationId": "DON123",
  "donorId": "USER456",
  "timestamp": "2026-07-03T10:30:00Z",
  "foodType": "Rice",
  "quantity": 10,
  "unit": "kg",
  "location": {"lat": 24.8607, "lon": 67.0011},
  "expiryTime": "2026-07-05T18:00:00Z"
}
```

#### 2. Claim Tracking
```dart
{
  "claimId": "CLM789",
  "donationId": "DON123",
  "claimantId": "NGO101",
  "quantity": 10,
  "timestamp": "2026-07-03T11:15:00Z",
  "status": "pending",
  "responseTime": null
}
```

#### 3. Status Changes
```dart
{
  "trackingId": "TRK456",
  "donationId": "DON123",
  "previousStatus": "available",
  "newStatus": "claimed",
  "timestamp": "2026-07-03T11:15:00Z",
  "triggeredBy": "NGO101"
}
```

#### 4. Completion
```dart
{
  "completionId": "CMP789",
  "donationId": "DON123",
  "collectedBy": "NGO101",
  "timestamp": "2026-07-03T14:30:00Z",
  "photoUrl": "...",
  "rating": 5,
  "feedback": "Excellent quality"
}
```

### Real-Time Updates

The tracking system uses Firebase real-time listeners to provide instant updates:

```dart
// Stream donation status
_donationService.streamDonation(donationId).listen((donation) {
  // UI updates automatically
});

// Stream tracking history
_trackingService.streamTrackingEvents(donationId).listen((events) {
  // Timeline updates in real-time
});
```

## User Interface Components

### 1. History Screen (`history_screen.dart`)
- Lists all past donations/claims
- Filterable by status, date, food type
- Shows completion statistics
- Export functionality

### 2. Donation Detail View
- Complete timeline of events
- Status badges and progress indicators
- Chat history integration
- Photo gallery (before/after)

### 3. Analytics Dashboard (`analytics_dashboard.dart`)
- Personal impact metrics
- Charts and graphs
- Comparative statistics
- Trend analysis

### 4. Tracking Timeline Widget
```
✅ Donation Created - 10:30 AM
✅ Claimed by ABC NGO - 11:15 AM  
✅ Accepted by Donor - 11:30 AM
🚚 In Transit - 2:00 PM
✅ Collected - 2:30 PM
⭐ Rated 5 stars - 3:00 PM
```

## Privacy Considerations

### What is NOT Tracked
- ❌ Exact user locations (only approximate)
- ❌ Personal phone numbers (masked in chat)
- ❌ Financial information
- ❌ Religious/political preferences

### Data Retention
- **Active donations**: Permanent
- **Completed donations**: 2 years
- **Chat messages**: 6 months after completion
- **Analytics aggregates**: Indefinite (anonymized)

## Benefits Summary

| Stakeholder | Key Benefit | Metric |
|------------|-------------|--------|
| Donors | See impact | Total kg donated |
| NGOs | Plan better | Average response time |
| Admins | Monitor health | Platform completion rate |
| Community | Reduce waste | % food saved from waste |

## Implementation Files

### Core Services
- `lib/services/donation_service.dart` - Donation tracking
- `lib/services/analytics_service.dart` - Analytics aggregation
- `lib/models/donation_model.dart` - Tracking data models

### UI Screens
- `lib/screens/history/history_screen.dart` - History view
- `lib/screens/analytics/analytics_dashboard.dart` - Analytics
- `lib/widgets/tracking_timeline.dart` - Timeline widget

## API Examples

```dart
// Get user's donation history
final history = await trackingService.getDonationHistory(
  userId: currentUser.uid,
  startDate: DateTime.now().subtract(Duration(days: 30)),
  endDate: DateTime.now(),
);

// Get analytics
final analytics = await analyticsService.getUserAnalytics(currentUser.uid);
print('Total donated: ${analytics.totalQuantity} kg');
print('Completion rate: ${analytics.completionRate}%');

// Export history for tax purposes
final pdf = await trackingService.exportHistory(
  userId: currentUser.uid,
  year: 2026,
);
```

## Future Enhancements

1. **Blockchain Integration** - Immutable tracking records
2. **QR Code Scanning** - Quick pickup verification
3. **GPS Tracking** - Real-time delivery tracking
4. **Carbon Footprint** - Calculate environmental impact
5. **Gamification** - Badges and achievements for milestones