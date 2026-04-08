const jwt = require("jsonwebtoken");

const JWT_SECRET = "7a2ed9afb59dff850b4b12ecd222e131b82488f46c029a148b157541ab1c203404990645ab9139363e93a92f34eabdd26118eb172fcd2366d4dc8566dcbbcacc";
const baseUrl = "http://localhost:3000";
const token = jwt.sign({ uid: "test_user_v38", society_id: "test_society_v38" }, JWT_SECRET);

async function testHardening() {
  console.log("\n🛡️  --- TESTING AI V3.8 HARDENING (PRODUCTION-SAFE) --- 🛡️\n");

  // 1. TEST: Large Image Rejection (>2MB)
  console.log("1️⃣  Testing Large Image Rejection...");
  const largeBase64 = "data:image/png;base64," + "A".repeat(3 * 1024 * 1024); // ~3MB
  try {
    const res = await fetch(`${baseUrl}/ai/chat`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
      body: JSON.stringify({ message: "What is this?", base64Image: largeBase64 })
    });
    console.log("   Status:", res.status, res.status === 413 ? "✅ Correct (413 Payload Too Large)" : "❌ Incorrect");
  } catch (e) { console.error("   ❌ Error:", e.message); }

  // 2. TEST: Invalid Image Format
  console.log("\n2️⃣  Testing Invalid Image Format...");
  try {
    const res = await fetch(`${baseUrl}/ai/chat`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
      body: JSON.stringify({ message: "What is this?", base64Image: "not_a_base64_image" })
    });
    console.log("   Status:", res.status, res.status === 400 ? "✅ Correct (400 Bad Request)" : "❌ Incorrect");
  } catch (e) { console.error("   ❌ Error:", e.message); }

  // 3. TEST: Missing Input
  console.log("\n3️⃣  Testing Missing Input...");
  try {
    const res = await fetch(`${baseUrl}/ai/chat`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
      body: JSON.stringify({ message: "" })
    });
    console.log("   Status:", res.status, res.status === 400 ? "✅ Correct (400 Bad Request)" : "❌ Incorrect");
  } catch (e) { console.error("   ❌ Error:", e.message); }

  // 4. TEST: Receipt Extraction Fallback (Simulated failure)
  console.log("\n4️⃣  Testing Receipt Extraction Partial Fallback...");
  try {
    const res = await fetch(`${baseUrl}/ai/extract-receipt`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
      body: JSON.stringify({ base64Image: "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==" })
    });
    const data = await res.json();
    console.log("   Status:", res.status);
    if (!data.success && data.partialData) {
      console.log("   ✅ SUCCESS: Returned success:false with partialData instead of crashing.");
    } else if (data.parsed?.vendor) {
      console.log("   ✅ SUCCESS: Extraction worked perfectly.");
    } else {
      console.log("   ❌ FAILED: Unexpected response format:", JSON.stringify(data, null, 2));
    }
  } catch (e) { console.error("   ❌ Error:", e.message); }

  console.log("\n🏁 --- HARDENING VERIFICATION COMPLETE --- 🏁\n");
}

testHardening();
