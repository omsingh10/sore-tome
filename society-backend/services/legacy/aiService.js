const Anthropic = require("@anthropic-ai/sdk");
const { getDb } = require("../config/firebase");

const client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

// Builds a dynamic system prompt using live data from Firestore
async function buildSystemPrompt() {
  const db = getDb();
  const societyName = process.env.SOCIETY_NAME || "Our Society";
  const city = process.env.SOCIETY_CITY || "";

  // Fetch rules and timings from Firestore to keep AI answers up to date
  let rulesText = "";
  try {
    const rulesSnap = await db.collection("rules").get();
    rulesSnap.forEach((doc) => {
      const d = doc.data();
      rulesText += `\n- ${d.title}: ${d.content}`;
    });
  } catch (_) {
    // Fallback if rules collection is empty
    rulesText = `
- Gym timings: Monday–Saturday 6:00 AM–10:00 AM and 5:00 PM–9:00 PM. Sunday closed.
- Swimming pool: Daily 7:00 AM–8:00 PM. Maintenance every Tuesday 10 AM–12 PM.
- Parking: 1 reserved spot per flat. Visitors use visitor parking near Gate 2.
- Noise policy: No loud music after 10 PM or before 7 AM.
- Pet policy: Pets allowed on leash in common areas. Register with admin.`;
  }

  // Fetch upcoming events
  let eventsText = "";
  try {
    const now = new Date();
    const eventsSnap = await db
      .collection("events")
      .where("date", ">=", now)
      .orderBy("date")
      .limit(5)
      .get();

    eventsSnap.forEach((doc) => {
      const d = doc.data();
      const dateStr = d.date?.toDate?.().toDateString() || d.date;
      eventsText += `\n- ${d.title} on ${dateStr}: ${d.description}`;
    });
  } catch (_) {}

  return `You are a helpful assistant for ${societyName}${city ? ", " + city : ""}.
You help residents with questions about society rules, timings, events, facilities, and general information.

SOCIETY RULES & TIMINGS:${rulesText}

UPCOMING EVENTS:${eventsText || "\n- No upcoming events at the moment."}

INSTRUCTIONS:
- Answer only questions related to this society.
- Be concise and friendly. Keep replies under 5 sentences.
- You can respond in Hindi, Hinglish, or English based on how the user writes.
- If you don't know something specific, say "Please contact the admin for this information."
- Do not make up rules or timings that aren't listed above.
- Do not answer questions unrelated to the society (weather, news, coding, etc.).`;
}

// Main chat function — called from the /ai/chat route
async function chatWithAI(userMessage, conversationHistory = []) {
  const systemPrompt = await buildSystemPrompt();

  // conversationHistory format: [{ role: "user"|"assistant", content: "..." }]
  const messages = [
    ...conversationHistory.slice(-10), // keep last 10 messages for context
    { role: "user", content: userMessage },
  ];

  const response = await client.messages.create({
    model: "claude-sonnet-4-20250514",
    max_tokens: 500,
    system: systemPrompt,
    messages,
  });

  return response.content[0].text;
}

module.exports = { chatWithAI };
