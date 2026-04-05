const jwt = require("jsonwebtoken");

// Use the secret found in .env
const JWT_SECRET = "7a2ed9afb59dff850b4b12ecd222e131b82488f46c029a148b157541ab1c203404990645ab9139363e93a92f34eabdd26118eb172fcd2366d4dc8566dcbbcacc";

async function test() {
  const token = jwt.sign({ uid: "test_user_123", society_id: "test_society" }, JWT_SECRET);
  const baseUrl = "http://localhost:3000";

  console.log("\n🚀 --- TESTING AI CONNECTION (JSON MODE) --- 🚀");
  try {
    const response = await fetch(`${baseUrl}/ai/chat`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify({ message: "Hello AI, are you connected?" })
    });

    const data = await response.json();
    if (response.ok) {
      console.log("✅ SUCCESS! AI Reply:", data.reply);
    } else {
      console.log("❌ FAILED! Status:", response.status, "Error:", data);
    }
  } catch (err) {
    console.error("❌ CONNECTION ERROR:", err.message);
  }

  console.log("\n🚀 --- TESTING AI CONNECTION (STREAMING MODE) --- 🚀");
  try {
    const response = await fetch(`${baseUrl}/ai/chat`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
        'Accept': 'text/event-stream' // Force SSE
      },
      body: JSON.stringify({ message: "Hello AI, stream a long greeting!" })
    });

    if (response.ok) {
      console.log("✅ SSE STREAM STARTED...");
      const reader = response.body.getReader();
      const decoder = new TextDecoder();
      
      while (true) {
        const { value, done } = await reader.read();
        if (done) break;
        const chunk = decoder.decode(value);
        console.log("Chunk:", chunk);
      }
      console.log("✅ SSE STREAM FINISHED.");
    } else {
      const data = await response.json();
      console.log("❌ FAILED! Status:", response.status, "Error:", data);
    }
  } catch (err) {
    console.error("❌ CONNECTION ERROR:", err.message);
  }
}

test();
