/**
 * ONEWAY / Accessible Egypt - Firestore Places Seeder
 *
 * This script seeds curated accessible Egyptian places into Firestore.
 * Supports:
 *  1. Local Emulator: set FIRESTORE_EMULATOR_HOST=localhost:8080
 *  2. Cloud Firestore: uses GOOGLE_APPLICATION_CREDENTIALS or default credentials
 */

const fs = require('fs');
const path = require('path');
const { initializeApp, getApps } = require('firebase-admin/app');
const { getFirestore, GeoPoint, FieldValue } = require('firebase-admin/firestore');

const seedFilePath = path.join(__dirname, 'seeds', 'places_seed.json');

if (!fs.existsSync(seedFilePath)) {
  console.error(`Seed file not found at: ${seedFilePath}`);
  process.exit(1);
}

const placesData = JSON.parse(fs.readFileSync(seedFilePath, 'utf8'));

// Initialize Firebase Admin
const projectId = process.env.GCLOUD_PROJECT || 'oneway-f665d';

if (getApps().length === 0) {
  initializeApp({
    projectId: projectId,
  });
}

const db = getFirestore();

async function seedPlaces() {
  console.log(`Starting to seed ${placesData.length} places into Firestore project: ${projectId}...`);

  let count = 0;
  for (const place of placesData) {
    const docId = place.id;
    const docRef = db.collection('places').doc(docId);

    const data = {
      name: place.name,
      category: place.category,
      description: place.description || '',
      photo_url: place.photo_url || '',
      photos: place.photos || [],
      address: place.address || '',
      governorate: place.governorate || '',
      city: place.city || '',
      location: new GeoPoint(place.location.latitude, place.location.longitude),
      phone_number: place.phone_number || '',
      website: place.website || '',
      opening_hours: place.opening_hours || '',
      accessibility_features: place.accessibility_features || {},
      verification_status: place.verification_status || 'verified',
      verified_by: place.verified_by || 'فريق ONEWAY الميداني',
      last_verified_at: FieldValue.serverTimestamp(),
      rating: place.rating || 4.5,
    };

    await docRef.set(data, { merge: true });
    count++;
    console.log(`[${count}/${placesData.length}] Seeded: ${place.name} (${docId})`);
  }

  console.log(`\n Successfully seeded ${count} places into Firestore collection 'places'!`);
}

seedPlaces().catch((error) => {
  console.error('\nSeeding failed:');
  if (error.code === 7 || error.message?.includes('Could not load the default credentials')) {
    console.error('>> Google Application Default Credentials not found.');
    console.error('>> To authenticate:');
    console.error('   1. Download a Service Account key from Firebase Console -> Project Settings -> Service Accounts');
    console.error('   2. Set: $env:GOOGLE_APPLICATION_CREDENTIALS = "C:\\path\\to\\serviceAccountKey.json"');
    console.error('   3. Run: node seed_places.js');
    console.error('\n>> Alternatively: Seed places directly inside the Flutter app with 1 click!');
  } else {
    console.error(error);
  }
  process.exit(1);
});
