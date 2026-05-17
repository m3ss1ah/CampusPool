// src/config/db.js
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20, // Maximum number of clients in the pool
  idleTimeoutMillis: 30000, // Close idle clients after 30 seconds
  connectionTimeoutMillis: 2000, // Return an error if a connection takes > 2 seconds
});

// Production-grade logging and error handling for the pool
pool.on('error', (err) => {
  console.error('Unexpected error on idle PostgreSQL client', err);
  process.exit(-1);
});

/**
 * Initialize Database Connection
 * Verifies connectivity and PostGIS functionality
 */
const initDB = async () => {
  try {
    const dbUrl = new URL(process.env.DATABASE_URL);
    console.log(`Connecting to database at: ${dbUrl.host}`);
    const client = await pool.connect();
    console.log('✅ Successfully connected to PostgreSQL/Supabase');

    // Verify PostGIS is enabled
    const res = await client.query('SELECT PostGIS_Version();');
    console.log(`🌍 PostGIS Active: ${res.rows[0].postgis_version}`);
    
    client.release();
  } catch (err) {
    console.error('❌ Database initialization failed:', err.message);
    console.log('Retrying in 5 seconds...');
    // Recursive retry with delay
    setTimeout(initDB, 5000);
  }
};

/**
 * Graceful Shutdown Handling
 */
const closeDB = async () => {
  console.log('Closing PostgreSQL pool...');
  await pool.end();
  console.log('PostgreSQL pool closed.');
};

module.exports = {
  query: (text, params) => pool.query(text, params),
  pool,
  initDB,
  closeDB,
};
