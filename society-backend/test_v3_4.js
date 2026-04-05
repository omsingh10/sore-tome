const jwt = require("jsonwebtoken");

const JWT_SECRET = "7a2ed9afb59dff850b4b12ecd222e131b82488f46c029a148b157541ab1c203404990645ab9139363e93a92f34eabdd26118eb172fcd2366d4dc8566dcbbcacc";

async function testV3_4() {
  const token = jwt.sign({ uid: "test_user_v34", society_id: "test_society_v34" }, JWT_SECRET);
  const baseUrl = "http://localhost:3000";

  console.log("\n🚀 --- TESTING RESILIENT SEARCH & DYNAMIC DRAFTS (V3.4) --- 🚀");
  try {
    const response = await fetch(`${baseUrl}/ai/chat`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify({ message: "Draft a notice about the playground cleaning tomorrow." })
    });

    const data = await response.json();
    console.log("Status:", response.status);
    console.log("Full Output:", JSON.stringify(data, null, 2));

    if (data.type === "draft") {
      console.log("\n✅ SUCCESS! AI generated a structured draft without 429 errors.");
    } else if (data.type === "text") {
      console.log("\n✅ SEMI-SUCCESS: AI returned text. Check if 429 occurred in logs.");
    } else {
      console.log("\n❌ FAILED: Unexpected format or error.");
    }
  } catch (err) {
    console.error("❌ ERROR:", err.message);
  }
}

testV3_4();
