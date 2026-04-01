const admin = require("firebase-admin");
const path = require("path");
const fs = require("fs");

let db;

function initFirebase() {
  if (admin.apps.length > 0) return; // already initialized

  const serviceAccountPath = path.resolve(
    process.env.FIREBASE_SERVICE_ACCOUNT_PATH || "./config/serviceAccountKey.json"
  );

  // Check if file exists to prevent hard crash
  if (!fs.existsSync(serviceAccountPath)) {
    console.error("\n❌ ERROR: Firebase service account key missing!");
    console.error(`📍 Expected at: ${serviceAccountPath}`);
    console.error("\nTo fix this:");
    console.error("1. Go to Firebase Console -> Project Settings -> Service Accounts");
    console.error("2. Click 'Generate new private key' and download the JSON.");
    console.error(`3. Rename it to 'serviceAccountKey.json' and place it in the 'config' folder.`);
    console.error("\nThe backend will not work until this file is provided.\n");
    return;
  }

  try {
    admin.initializeApp({
      credential: admin.credential.cert(require(serviceAccountPath)),
      projectId: process.env.FIREBASE_PROJECT_ID,
    });

    db = admin.firestore();
    console.log("✅ Firebase connected");
  } catch (err) {
    console.error("❌ Firebase initialization failed:", err.message);
  }
}

function getDb() {
  if (!db) throw new Error("Firebase not initialized. Call initFirebase() first.");
  return db;
}

function getAdmin() {
  return admin;
}

module.exports = { initFirebase, getDb, getAdmin };
