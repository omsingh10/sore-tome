const { Client } = require('pg');
require('dotenv').config({ path: 'e:/Work/sore-tome/society-backend/.env' });

async function migrate() {
  const client = new Client({ 
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false }
  });
  await client.connect();
  try {
    console.log("--- Creating AI Costs table ---");
    await client.query(`
      CREATE TABLE IF NOT EXISTS ai_costs (
        id SERIAL PRIMARY KEY,
        user_id TEXT NOT NULL,
        society_id TEXT NOT NULL,
        request_id TEXT NOT NULL,
        tokens INTEGER NOT NULL,
        cost_usd DECIMAL(12, 6) NOT NULL,
        metadata JSONB,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
      CREATE INDEX IF NOT EXISTS idx_cost_society_id ON ai_costs(society_id);
      CREATE INDEX IF NOT EXISTS idx_cost_user_id ON ai_costs(user_id);
    `);
    console.log("✅ AI Costs table created successfully.");
  } catch (err) {
    console.error("❌ Error creating table:", err.message);
  } finally {
    await client.end();
  }
}
migrate();
