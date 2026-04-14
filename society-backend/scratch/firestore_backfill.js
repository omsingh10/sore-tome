const { initFirebase, getDb } = require("../config/firebase");
const fs = require("fs");
const path = require("path");
require("dotenv").config();

async function backfillFirestore() {
  console.log("🚀 Starting Firestore Backfill: Multi-Tenancy Hardening");
  
  initFirebase();
  const db = getDb();
  const auditLogPath = path.join(__dirname, "firestore_backfill_audit.json");
  const auditLogs = [];

  const collections = ["issues", "transactions", "notifications", "channels", "funds"];
  
  try {
    // 1. Pre-fetch a user map for faster lookups
    console.log("Fetching user mapping...");
    const userSnap = await db.collection("users").get();
    const userSocietyMap = {};
    userSnap.forEach(doc => {
      userSocietyMap[doc.id] = doc.data().societyId || doc.data().society_id || "legacy_society";
    });

    for (const colName of collections) {
      console.log(`Processing collection: ${colName}`);
      const snap = await db.collection(colName).get();
      
      const batch = db.batch();
      let operations = 0;

      for (const doc of snap.docs) {
        const data = doc.data();
        if (data.societyId) continue; // Already backfilled

        // Identification Logic
        const userId = data.postedBy || data.addedBy || data.userId || data.senderId || data.createdBy;
        let targetSocietyId = "legacy_society";

        if (userId && userSocietyMap[userId]) {
           targetSocietyId = userSocietyMap[userId];
        }

        batch.update(doc.ref, { societyId: targetSocietyId });
        operations++;

        auditLogs.push({
          collection: colName,
          docId: doc.id,
          original_data: data,
          assigned_societyId: targetSocietyId,
          timestamp: new Date().toISOString()
        });

        if (operations >= 400) { // Firestore batch limit is 500
          await batch.commit();
          console.log(`Committed batch for ${colName}`);
          operations = 0;
        }
      }

      if (operations > 0) {
        await batch.commit();
        console.log(`Committed final batch for ${colName}`);
      }
    }

    fs.writeFileSync(auditLogPath, JSON.stringify(auditLogs, null, 2));
    console.log(`✅ Backfill complete. Audit log saved to ${auditLogPath}`);

  } catch (err) {
    console.error("❌ Backfill failed:", err.message);
  }
}

backfillFirestore();
