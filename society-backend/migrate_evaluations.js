const { Client } = require('pg');
require('dotenv').config({ path: 'e:/Work/sore-tome/society-backend/.env' });

async function migrate() {
  const client = new Client({ 
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false }
  });
  await client.connect();
  try {
    console.log("--- Creating AI Evaluations table ---");
    await client.query(`
      CREATE TABLE IF NOT EXISTS ai_evaluations (
        id SERIAL PRIMARY KEY,
        request_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        society_id TEXT NOT NULL,
        hallucination_score FLOAT,
        accuracy_score FLOAT,
        relevance_score FLOAT,
        user_feedback TEXT,
        metadata JSONB,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
      CREATE INDEX IF NOT EXISTS idx_eval_society_id ON ai_evaluations(society_id);
      CREATE INDEX IF NOT EXISTS idx_eval_request_id ON ai_evaluations(request_id);
    `);
    console.log("✅ AI Evaluations table created successfully.");
  } catch (err) {
    console.error("❌ Error creating table:", err.message);
  } finally {
    await client.end();
  }
}
migrate();
