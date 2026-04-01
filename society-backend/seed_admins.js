const admin = require("firebase-admin");
const bcrypt = require("bcryptjs");

// Assuming config/firebase handles admin initialization, or we can just initialize it here using our service account key.
// Wait, society-backend/config/firebase.js exports { getDb, getAdmin }
require("dotenv").config();
const { initFirebase, getDb, getAdmin } = require("./config/firebase");

async function seedAdmins() {
  try {
    initFirebase();
    const db = getDb();
    const adminObj = getAdmin();

    const admins = [
      { phone: "admin", password: "123123", role: "main_admin", name: "Society Main Admin", uid: "admin-001", status: "approved" },
      { phone: "treasurer", password: "123", role: "treasurer", name: "Society Treasurer", uid: "admin-002", status: "approved" },
      { phone: "secretary", password: "123", role: "secretary", name: "Society Secretary", uid: "admin-003", status: "approved" }
    ];

    for (const a of admins) {
      const existing = await db.collection("users").where("phone", "==", a.phone).get();
      if (!existing.empty) {
        console.log(`Admin ${a.phone} already exists in Firestore. Updating password and role just in case...`);
        const docId = existing.docs[0].id;
        const hashedPassword = await bcrypt.hash(a.password, 10);
        await db.collection("users").doc(docId).update({
            password: hashedPassword,
            role: a.role,
            status: a.status
        });
      } else {
        const hashedPassword = await bcrypt.hash(a.password, 10);
        await db.collection("users").doc(a.uid).set({
          uid: a.uid,
          name: a.name,
          phone: a.phone,
          password: hashedPassword,
          flatNumber: "Admin-Office",
          role: a.role,
          status: a.status,
          createdAt: adminObj.firestore.FieldValue.serverTimestamp(),
          residentType: "owner",
          maintenanceExempt: true
        });
        console.log(`Created admin ${a.phone} in Firestore.`);
      }
    }
    console.log("Seeding complete.");
    process.exit(0);
  } catch (error) {
    console.error("Error seeding admins:", error);
    process.exit(1);
  }
}

seedAdmins();
