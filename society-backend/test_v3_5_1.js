const jwt = require("jsonwebtoken");

const JWT_SECRET = "7a2ed9afb59dff850b4b12ecd222e131b82488f46c029a148b157541ab1c203404990645ab9139363e93a92f34eabdd26118eb172fcd2366d4dc8566dcbbcacc";

async function testV3_5_1() {
  const token = jwt.sign({ uid: "test_user_v351", society_id: "test_society_v351" }, JWT_SECRET);
  const baseUrl = "http://localhost:3000";

  console.log("\n🚀 --- TESTING CLEAN & FREE AI (V3.5.1) --- 🚀");
  console.log("Providers: Groq, Cerebras, Cloudflare (REST Embeddings)");
  
  try {
    const response = await fetch(`${baseUrl}/ai/chat`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify({ message: "Draft a notice for a society meeting on Sunday." })
    });

    const data = await response.json();
    console.log("Status:", response.status);
    console.log("Full Output:", JSON.stringify(data, null, 2));

    if (data.type === "draft") {
      console.log("\n✅ SUCCESS! AI generated a structured draft using the FREE stack.");
    } else if (data.type === "text") {
      console.log("\n✅ SEMI-SUCCESS: AI returned text. Check logs to ensure no 429/402 occurred.");
    } else {
      console.log("\n❌ FAILED: Unexpected format or error.");
    }
  } catch (err) {
    console.error("❌ ERROR:", err.message);
  }
}

testV3_5_1();
