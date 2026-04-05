const { Client } = require('pg');
require('dotenv').config({ path: 'e:/Work/sore-tome/society-backend/.env' });

async function verify() {
  const client = new Client({ 
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false }
  });
  await client.connect();
  try {
    console.log("--- Verifying PostgreSQL Extensions ---");
    await client.query('CREATE EXTENSION IF NOT EXISTS vector;');
    await client.query('CREATE EXTENSION IF NOT EXISTS pg_trgm;');
    const res = await client.query('SELECT extname FROM pg_extension;');
    console.log("Enabled extensions:", res.rows.map(r => r.extname).join(', '));
    console.log("---------------------------------------");
  } catch (err) {
    console.error("❌ Error verifying extensions:", err.message);
  } finally {
    await client.end();
  }
}
verify();
