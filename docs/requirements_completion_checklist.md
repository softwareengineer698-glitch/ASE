# FoodBridge Requirements Completion Checklist

## Registration and Access

- Single default registration path: phone number OTP.
- Post-login choice: Donate or Receive.
- Returning users with a saved role bypass the role picker.
- NGO document verification is removed from the active claim flow; OTP verification is sufficient.
- Admin and volunteer roles remain only for backward compatibility with older records.

## Feature Comparison Table

The "Food Posting and Claiming Functions" section should be split as:

| Main Feature | Sub-features |
| --- | --- |
| Food Posting | Create listing, item type, quantity, expiry date/time, camera/gallery photos, location, manual description, voice description |
| Food Claiming | Nearby discovery, partial quantity claim, claim status, in-app chat, pickup coordination, expiry/unclaim handling |

## Forecasting Module Justification

The forecasting module is retained because it supports planning and reduces waste by showing donors expected surplus trends and risk periods.

Historical records are stored in Firestore collection `donations_history`.

Stored fields:

- `donorId`
- `category`
- `itemType`
- `actualQuantity`
- `claimedQuantity`
- `remainingQuantity`
- `postedAt`
- `completedAt`
- `outcome`

Usage:

- Completed and expired donations are recorded as historical outcomes.
- Forecasting reads recent donor history to calculate average daily quantity, completion rate, and top category.
- These historical aggregates are blended into the existing forecast insights.
- The forecast point generation still uses heuristic/simulated values until a full ML model is added.

## Completed Feature Scope

- Partial claiming with `remainingQuantity`.
- Multiple claim records per donation.
- In-app chat after accepted claim.
- Camera and gallery image selection.
- Cloudinary image URL persistence.
- Manual and Whisper-backed voice description input.
- Nearby food discovery by current location and radius.
- Food and non-food item categories.
- Donation expiry monitoring.
- Automatic stale claim cancellation and quantity relisting.
- First-use food tracking explainer with manual reopen API.
- In-app and FCM notification scaffolding for claim/chat/request/expiry events.
- Recipient food requests.
- Roman Urdu localization files retained.
