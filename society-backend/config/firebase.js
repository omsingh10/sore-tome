const admin = require("firebase-admin");

let db;

function initFirebase() {
  if (admin.apps.length > 0) return;

  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const privateKey = process.env.FIREBASE_PRIVATE_KEY;

  if (!projectId || !clientEmail || !privateKey) {
    console.error("\n❌ CRITICAL ERROR: Missing Firebase Environment Variables!");
    console.error("Required: FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY\n");
    throw new Error("Targeted Failure: Firebase Configuration Incomplete");
  }

  try {
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId,
        clientEmail,
        // Support both literal newlines and escaped versions for flexible deployment
        privateKey: privateKey.includes("\\n") 
          ? privateKey.replace(/\\n/g, "\n") 
          : privateKey,
      }),
      storageBucket: process.env.FIREBASE_STORAGE_BUCKET || `${projectId}.appspot.com`,
    });

    db = admin.firestore();
    console.log("✅ Firebase connected (Initialized via Environment)");
  } catch (err) {
    console.error("❌ Firebase initialization failed:", err.message);
    throw err; // Fail-fast: prevents the server from running in a crippled state
  }
}

function getDb() {
  if (!db) throw new Error("Firebase not initialized. Call initFirebase() first.");
  return db;
}

function getStorage() {
  return admin.storage();
}

function getAdmin() {
  return admin;
}

module.exports = { initFirebase, getDb, getStorage, getAdmin };

