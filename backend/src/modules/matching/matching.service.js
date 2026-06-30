const { pool } = require('../../config/db');
const { applyPublicPrivacy } = require('../../utils/privacy');
const { normalizeDestination } = require('../../utils/destinations');

const suggestMatches = async ({ lat, lng, destLabel, page = 1, limit = 10 }) => {
  const offset = (page - 1) * limit;

  let queryText = `
    SELECT c.*,
      u.full_name as creator_name,
      u.profile_pic_url as creator_pic,
      ST_Distance(
        c.source_location,
        ST_SetSRID(ST_MakePoint($2, $1), 4326)::geography
      ) AS distance_meters
    FROM commutes c
    JOIN users u ON c.creator_id = u.id
    WHERE c.status = 'open'
      AND c.departure_time > NOW()
      AND ST_DWithin(
        c.source_location,
        ST_SetSRID(ST_MakePoint($2, $1), 4326)::geography,
        15000 -- 15km radius
      )
  `;

  const queryParams = [lat, lng];

  if (destLabel) {
    const normalized = await normalizeDestination(destLabel);
    queryParams.push(normalized);
    // Use pg_trgm similarity logic against the normalized destination label
    queryText += ` AND similarity(c.dest_label_normalized, $${queryParams.length}) > 0.3`;
    queryText += ` ORDER BY similarity(c.dest_label_normalized, $${queryParams.length}) DESC, distance_meters ASC`;
  } else {
    queryText += ` ORDER BY distance_meters ASC`;
  }

  queryText += ` LIMIT $${queryParams.length + 1} OFFSET $${queryParams.length + 2}`;
  queryParams.push(limit, offset);

  const result = await pool.query(queryText, queryParams);

  // Apply public privacy masking (round coordinates)
  return result.rows.map(applyPublicPrivacy);
};

module.exports = { suggestMatches };
