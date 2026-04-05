const { Client } = require('pg');
require('dotenv').config({ path: 'e:/Work/sore-tome/society-backend/.env' });

async function migrate() {
  const client = new Client({ 
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false }
  });
  await client.connect();
  try {
    console.log("--- Creating Semantic Cache table ---");
    await client.query(`
      CREATE TABLE IF NOT EXISTS semantic_cache (
        id SERIAL PRIMARY KEY,
        society_id TEXT NOT NULL,
        query TEXT NOT NULL,
        response TEXT NOT NULL,
        embedding vector(1536),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
      CREATE INDEX IF NOT EXISTS idx_semantic_cache_embedding ON semantic_cache USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
      CREATE UNIQUE INDEX IF NOT EXISTS idx_query_society ON semantic_cache(society_id, query);
    `);
    console.log("✅ Semantic Cache table created successfully.");
  } catch (err) {
    console.error("❌ Error creating table:", err.message);
  } finally {
    await client.end();
  }
}
migrate();
