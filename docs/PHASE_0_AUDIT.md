# ONEWAY Phase 0 audit

Audit date: 6 November 2026 (Africa/Cairo)

## What was inspected

- Flutter application, navigation, page and component exports
- Firebase Auth integration, generated Firestore schemas, Firebase configuration, Cloud Functions and rules
- Android/iOS Firebase configuration and package manifest
- Firestore indexes and the automated widget test

## Current implementation status

| Area | Status | Evidence / finding |
| --- | --- | --- |
| App shell, Arabic-first copy, Cairo font, RTL-ready Material localization | Partially implemented | Arabic screens and `Locale('ar')` are present; locale selection and runtime English switching are not implemented. |
| Email/password authentication, Google Sign-In, reset password | Partially implemented | Client flows exist. Provider configuration must be confirmed in Firebase Console. |
| User profile, settings, help, notifications | Partially implemented | Profile edit and in-app notification read state are Firestore-backed; push delivery and full preference persistence are incomplete. |
| Place schema and accessibility profile | Partially implemented | `places` and `accessibility_features` schemas exist, but several required accessibility states and provenance fields are absent. |
| Discovery, search and filters | Partially implemented | A Firestore-backed explorer now filters loaded records with Arabic normalization; server search, distance sort, and pagination remain. |
| Favorites | Partially implemented | Persistent create/remove flow is wired to existing favorites records; device/emulator verification remains. |
| Reporting | Partially implemented | Text reports are submitted as `new` and clearly await moderation; secure photo upload and moderation workflow remain. |
| Maps and location | Blocked by external configuration | Google Maps widget exists; no verified Maps key, location permission flow, or live place data was found. |
| Voice assistant / text-to-speech | Blocked by external configuration | Screen deliberately says microphone is not enabled. No speech package or configured provider is present. |
| AI assistant | Missing | No secure backend AI endpoint or provider configuration exists. |
| Business/admin dashboard | Partially implemented | A static dashboard exists. It does not query live metrics or provide moderation actions. It is now route-gated for authorized roles. |
| Emergency/SOS | Partially implemented | Emergency contacts are Firestore-backed. There is no verified delivery backend, so the app does not claim alerts were sent. |
| Firebase Functions | Missing / scaffold only | `onUserDeleted` initializes references but performs no cleanup or audit action. |
| Firestore and Storage security | Partially implemented | Rules existed and were hardened for client-created core documents; deploy and emulator validation remain required. |
| Tests | Partially implemented | `flutter test` passes (1 basic setup test). No integration/device/Firebase emulator tests exist. |

## Safe improvements applied in this phase

1. Authenticated users now land on the dashboard rather than the filter screen.
2. User-facing routes require authentication.
3. The business/admin portal has a client-side role guard for `businessOwner`, `moderator`, `admin`, and `superAdmin`. Firestore rules remain the data-security authority.
4. Firestore rules now constrain supported client-created fields for users, reports, submissions, reviews, and favorites; reviews also constrain ratings to 1–5. Profile changes cannot alter a role.
5. Firestore composite-index field names were aligned with the existing schema's `snake_case` timestamp and verification fields.
6. The signed-in home and search routes now use a Firestore-backed place explorer. It has Arabic-normalized local search, category and accessibility filters, explicit unknown states, place details, persistent favorites, and moderated report submission.
7. Users can view their reports, mark their own in-app notifications read, update their basic profile, and manage emergency contacts. Moderators can review and change report statuses through a role-protected route.
8. Firebase Functions now contain a configuration-backed initial-super-admin bootstrap and server-audited operational role assignment. See `FIREBASE_SCHEMA.md`; deployment is still required before these server functions exist in Firebase.

## Important limitations

- This workspace is not a Git repository, so no source-control backup or baseline diff could be created here.
- No production Firebase project, Firestore data, Firebase Console settings, Maps credentials, billing account, or deployment access was available for inspection. Nothing was deployed.
- Existing static screen content is presentation-only until replaced with data-backed queries. It must not be used as evidence of verification, revenue, users, businesses, or emergency delivery.

## Recommended next phase

Add server-backed Arabic search/pagination and complete the moderation, upload, Maps, voice, AI, and notification vertical slices. Validate every rules change in Firebase Emulator Suite before deployment.
