# ONEWAY Firebase schema and authorization

This is the authoritative implementation schema for the current Flutter app. Collection names and field names use the existing export's naming; do not rename fields without a data migration.

## Roles

| Role | Assignment path | Capability |
| --- | --- | --- |
| `user` | Default Firebase-auth registration | Discovery, favorites, reports, profile, emergency contacts. |
| `businessOwner` | Super-admin Cloud Function | Own business profile fields only. |
| `moderator` | Super-admin Cloud Function | Place/report/review moderation. |
| `admin` | Super-admin Cloud Function | Administrative access and audit-log reads. |
| `superAdmin` | Initial configured owner only | Custom Auth claim plus Firestore role; can use trusted role-assignment function. |

Roles are never assigned by client-side Firestore writes.

## Collections

| Collection | Primary fields | Client access |
| --- | --- | --- |
| `users` | `uid`, `email`, `display_name`, `photo_url`, `phone_number`, `role`, `created_time`, `updated_time` | Owner reads/edits their permitted profile fields. |
| `places` | name/category/address/location/contact fields, `accessibility_features`, `verification_status`, `last_verified_at` | Public read; moderator write. |
| `placeSubmissions` | `place_name`, `category`, `description`, `address`, `submittedBy`, `status`, `created_at` | User creates and reads own; moderator reviews. |
| `accessibilityReports` | `place_id`, `place_name`, `createdBy`, `problemCategory`, `description`, `photo_urls`, `location`, `status`, `created_at` | User creates/reads own; moderator reviews. |
| `reviews` | `place_id`, `createdBy`, `user_name`, `rating`, `comment`, `status`, `created_at` | Public read; authenticated 1–5 rating create; moderation supported. |
| `favorites` | `userId`, `placeId`, display snapshot fields, `created_at` | Private owner access. |
| `notifications` | `userId`, `title`, `body`, `type`, `is_read`, `created_at` | Private read; client may only change `is_read`. |
| `businesses` | `ownerId`, `business_name`, `category`, contact fields, `status`, `subscription_tier`, `branch_place_ids` | Public read; pending registration; owner can edit limited profile fields. |
| `emergencyContacts` | `userId`, `name`, `relationship`, `phone_number`, `is_primary`, `created_at` | Private owner access. |
| `routeReports` | `createdBy`, route/barrier evidence, `status` | Owner submits/reads; moderator reviews. |
| `conversations/{id}/messages` | `createdBy`, `participantIds`; `senderId`, message payload | Participants only. |
| `subscriptions` | `ownerId`, provider reference, plan/status dates | Owner/admin read; backend-only writes. |
| `auditLogs` | `actor_uid`, `action`, `target_uid`, `metadata`, `created_at` | Backend writes only; admins read. |

## Accessibility fields

`places.accessibility_features` currently supports `wheelchairEntrance`, `ramp`, `suitableElevator`, `accessibleRestroom`, `accessibleParking`, `corridorWidth`, and `entranceObstacles`.

An absent Boolean is **unknown**. The client must never convert absence to an accessibility claim. Only the `verified` status is displayed as `تم التحقق`; all other values carry a warning or incomplete-state label.

## Required indexes

The checked-in `firebase/firestore.indexes.json` includes the current compound indexes. Firestore will produce an index-creation link if a new compound query is introduced. Add that index to source control before deploying it.

## Initial super-admin setup

The configured initial owner is `bdalrhmnmady93@gmail.com`. This is not a Firestore rule exception and does not expose an API secret.

1. Install Firebase CLI and authenticate to the existing project.
2. Set the Functions runtime value:

```powershell
firebase functions:config:set oneway.initial_admin_email="bdalrhmnmady93@gmail.com" --project oneway-f665d
```

3. Deploy backend and security configuration:

```powershell
firebase deploy --only functions,firestore:rules,firestore:indexes,storage --project oneway-f665d
```

4. Sign in as that account and invoke `bootstrapInitialSuperAdmin` once from a trusted admin setup screen or Firebase Functions shell, then refresh the Firebase ID token (sign out/in).

The source code is prepared for this flow but no production role, claim, or Firebase data was changed from this workspace because the Firebase CLI and project credentials are unavailable here.
