const { Client } = require('pg');
require('dotenv').config({ path: 'e:/Work/sore-tome/society-backend/.env' });

async function migrate() {
  const client = new Client({ 
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false }
  });
  await client.connect();
  try {
    console.log("--- Creating AI Prompts table ---");
    await client.query(`
      CREATE TABLE IF NOT EXISTS ai_prompts (
        id SERIAL PRIMARY KEY,
        name TEXT NOT NULL,
        version INTEGER NOT NULL DEFAULT 1,
        content TEXT NOT NULL,
        is_active BOOLEAN DEFAULT false,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(name, version)
      );
      CREATE INDEX IF NOT EXISTS idx_prompt_name ON ai_prompts(name);
    `);
    console.log("✅ AI Prompts table created successfully.");
  } catch (err) {
    console.error("❌ Error creating table:", err.message);
  } finally {
    await client.end();
  }
}
migrate();
