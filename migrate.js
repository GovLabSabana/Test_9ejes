require('dotenv').config();
const fs = require('fs');
const path = require('path');
const { Pool } = require('pg');

function getConnectionString() {
    return process.env.DATABASE_URL || 
           process.env.DATABASE_PUBLIC_URL ||
           (process.env.PGHOST && `postgresql://${process.env.PGUSER}:${process.env.PGPASSWORD}@${process.env.PGHOST}:${process.env.PGPORT || 5432}/${process.env.PGDATABASE}`);
}

async function runMigration(providedPool = null) {
    const connectionString = getConnectionString();
    if (!connectionString && !providedPool) {
        console.error('[Migration] Error: No se encontró DATABASE_URL ni variables de conexión a PostgreSQL.');
        console.error('[Migration] Asegúrate de definir DATABASE_URL en Railway o en un archivo .env local.');
        process.exit(1);
    }

    const pool = providedPool || new Pool({
        connectionString,
        ssl: connectionString && !connectionString.includes('localhost') && !connectionString.includes('127.0.0.1')
            ? { rejectUnauthorized: false }
            : false
    });

    console.log('[Migration] Conectando a PostgreSQL para ejecutar railway_schema.sql...');
    const schemaPath = path.join(__dirname, 'railway_schema.sql');
    const sql = fs.readFileSync(schemaPath, 'utf8');

    try {
        await pool.query(sql);
        console.log('[Migration] ✅ Tablas, datos y funciones creados exitosamente en PostgreSQL.');
    } catch (err) {
        console.error('[Migration] ❌ Error ejecutando migración:', err);
        throw err;
    } finally {
        if (!providedPool) {
            await pool.end();
        }
    }
}

if (require.main === module) {
    runMigration()
        .then(() => process.exit(0))
        .catch(() => process.exit(1));
}

module.exports = { runMigration, getConnectionString };
