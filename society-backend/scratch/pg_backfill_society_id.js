const knex = require("knex")(require("../knexfile").development);
const fs = require("fs");
const path = require("path");

async function backfillSocietyId() {
  console.log("🚀 Starting PG Backfill: metadata -> society_id");
  
  const auditLogPath = path.join(__dirname, "backfill_audit_log.json");
  const auditLogs = [];

  try {
    const rows = await knex("document_chunks").select("id", "metadata");
    console.log(`Found ${rows.length} rows to process.`);

    for (const row of rows) {
      const metadata = typeof row.metadata === 'string' ? JSON.parse(row.metadata) : row.metadata;
      let targetSocietyId = metadata.society_id || metadata.societyId;
      
      if (!targetSocietyId) {
          console.warn(`⚠️ No societyId found for row ${row.id}, assigning 'legacy_society'`);
          targetSocietyId = "legacy_society";
      }

      await knex("document_chunks")
        .where("id", row.id)
        .update({ society_id: targetSocietyId });

      auditLogs.push({
        id: row.id,
        original_metadata: metadata,
        assigned_society_id: targetSocietyId,
        timestamp: new Date().toISOString()
      });
    }

    fs.writeFileSync(auditLogPath, JSON.stringify(auditLogs, null, 2));
    console.log(`✅ Backfill complete. Audit log saved to ${auditLogPath}`);

  } catch (err) {
    console.error("❌ Backfill failed:", err.message);
  } finally {
    await knex.destroy();
  }
}

backfillSocietyId();
