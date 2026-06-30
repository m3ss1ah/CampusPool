// src/utils/destinations.js
const { pool } = require('../config/db');

/**
 * Normalize a destination label using alias table.
 * Falls back to cleaned lowercase string if no alias found.
 */
const normalizeDestination = async (rawLabel) => {
  const cleaned = rawLabel
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9\s]/g, '')
    .replace(/\s+/g, ' ');

  try {
    const result = await pool.query(
      `SELECT canonical FROM destination_aliases WHERE alias = $1 LIMIT 1`,
      [cleaned]
    );
    if (result.rows.length > 0) {
      return result.rows[0].canonical;
    }
  } catch (_) {
    // alias lookup failure is non-critical — fall through
  }

  return cleaned;
};

module.exports = { normalizeDestination };
