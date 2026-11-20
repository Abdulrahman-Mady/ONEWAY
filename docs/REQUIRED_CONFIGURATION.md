# ONEWAY required service configuration

No credential is included in this repository. Configure and test each service before enabling its corresponding UI.

## Firebase

1. Confirm the existing Firebase project is the intended production or staging project in `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist`.
2. In Firebase Authentication, enable Email/Password and Google. Register Android SHA-1/SHA-256 and iOS bundle identifiers for Google Sign-In.
3. Deploy the reviewed rules and indexes only after Firebase Emulator Suite tests pass:

```powershell
cd firebase
firebase deploy --only firestore:rules,firestore:indexes,storage
```

4. Do not deploy the placeholder function as a user-data deletion solution. Implement and test retention/deletion policy first.

## Google Maps and device location

1. Create restricted Android/iOS Maps SDK keys in Google Cloud. Restrict by package/bundle ID and signing certificate where applicable.
2. Enable Maps SDK for Android and iOS only; add Places/Routes APIs only if the implemented feature needs them.
3. Add platform location permissions with an in-context explanation and test deny, approximate, and permanently-denied flows.
4. Label directions as standard navigation unless separate, evidence-backed accessibility route data is available.

## Speech, AI, notifications, and SOS

- Speech: select a provider that supports Arabic/Egyptian Arabic, obtain consent before microphone use, and add a manual text fallback. Never enable background listening.
- AI: call the model only from a trusted backend function. Store the provider secret in server-side configuration, ground answers in queried Firestore records, and return explicit unknown-data warnings.
- Push: configure Firebase Cloud Messaging for Android and APNs for iOS, persist notification preferences, and send only after backend confirmation.
- SOS: choose and integrate an actual delivery provider. Show delivery status only from its confirmed backend response and require explicit location-sharing consent.

## Release checks

- Run Firestore and Storage rules tests in the emulator.
- Run registration, Google Sign-In, reset-password, report upload, unauthorized-role, map permission, notification, and accessibility smoke tests on physical Android devices.
- Add production crash reporting and a privacy/data-retention policy before launch.
