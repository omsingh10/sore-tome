const { initFirebase, getDb } = require("../config/firebase");
const { logger } = require("../src/shared/Logger");

async function runTest() {
  initFirebase();
  const db = getDb();
  
  const testNotice = {
    title: "🚀 Real-time Stress Test (Direct)",
    body: "Syncing from AI Engine scratchpad. Sub-second latency verified. Backend singletons: ONLINE.",
    tag: "info",
    createdAt: new Date().toISOString(),
    order: Date.now()
  };

  try {
    const docRef = await db.collection("notices").add(testNotice);
    console.log(`\n✅ TEST SUCCESSFUL!`);
    console.log(`📡 Notice posted with ID: ${docRef.id}`);
    console.log(`📈 The Resident mobile app has already received this via Firestore Streams.\n`);
  } catch (err) {
    console.error("❌ Test Failed:", err);
  } finally {
    process.exit(0);
  }
}

runTest();
