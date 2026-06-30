// src/modules/commutes/commutes.service.js
const { pool } = require('../../config/db');
const { formatPoint } = require('../../utils/geometry');
const { normalizeDestination } = require('../../utils/destinations');
const { applyPublicPrivacy, applyCoordinatePrivacy } = require('../../utils/privacy');

/**
 * Create a new commute listing
 */
const createCommute = async (userId, commuteData) => {
  const {
    source_label, source_lat, source_lng,
    dest_label, dest_lat, dest_lng,
    departure_time, total_seats, vehicle_type, notes
  } = commuteData;

  const destNormalized = await normalizeDestination(dest_label);

  const result = await pool.query(
    `INSERT INTO commutes (
      creator_id,
      source_label, source_location,
      dest_label, dest_label_normalized, dest_location,
      departure_time, total_seats, available_seats,
      vehicle_type, notes
    ) VALUES ($1, $2, ST_GeogFromText($3), $4, $5, ST_GeogFromText($6), $7, $8, $8, $9, $10)
    RETURNING id, creator_id, source_label, source_lat, source_lng,
              dest_label, dest_lat, dest_lng,
              departure_time, total_seats, available_seats,
              vehicle_type, notes, status, created_at`,
    [
      userId,
      source_label,
      formatPoint(source_lat, source_lng),
      dest_label,
      destNormalized,
      formatPoint(dest_lat, dest_lng),
      departure_time,
      total_seats,
      vehicle_type,
      notes
    ]
  );

  return applyPublicPrivacy(result.rows[0]);
};

/**
 * Get commutes near a specific location with pagination
 */
const getNearbyCommutes = async (lat, lng, radius = 5000, page = 1, limit = 20) => {
  const offset = (page - 1) * limit;

  // Count total
  const countResult = await pool.query(
    `SELECT COUNT(*) FROM commutes c
     WHERE c.status = 'open'
       AND c.departure_time > NOW()
       AND ST_DWithin(c.source_location, ST_GeogFromText($1), $2)`,
    [formatPoint(lat, lng), radius]
  );
  const total = parseInt(countResult.rows[0].count, 10);

  // Fetch page
  const result = await pool.query(
    `SELECT
      c.id, c.creator_id,
      u.full_name as creator_name,
      u.profile_pic_url as creator_pic,
      c.source_label, c.source_lat, c.source_lng,
      c.dest_label, c.dest_lat, c.dest_lng,
      c.departure_time, c.total_seats, c.available_seats,
      c.vehicle_type, c.notes, c.status, c.created_at,
      ST_Distance(c.source_location, ST_GeogFromText($1)) as distance_meters
    FROM commutes c
    JOIN users u ON c.creator_id = u.id
    WHERE c.status = 'open'
      AND c.departure_time > NOW()
      AND ST_DWithin(c.source_location, ST_GeogFromText($1), $2)
    ORDER BY distance_meters ASC
    LIMIT $3 OFFSET $4`,
    [formatPoint(lat, lng), radius, limit, offset]
  );

  const commutes = result.rows.map(applyPublicPrivacy);
  return {
    commutes,
    pagination: { page, limit, total, has_more: offset + limit < total }
  };
};

/**
 * Get single commute detail with coordinate privacy
 */
const getCommuteById = async (commuteId, userId) => {
  const result = await pool.query(
    `SELECT
      c.id, c.creator_id,
      c.source_label, c.source_lat, c.source_lng,
      c.dest_label, c.dest_lat, c.dest_lng,
      c.departure_time, c.total_seats, c.available_seats,
      c.vehicle_type, c.notes, c.status, c.created_at
    FROM commutes c
    WHERE c.id = $1`,
    [commuteId]
  );

  if (result.rows.length === 0) return null;

  const commute = result.rows[0];

  // Get creator info
  const creatorResult = await pool.query(
    `SELECT id, full_name, profile_pic_url, phone, college FROM users WHERE id = $1`,
    [commute.creator_id]
  );
  commute.creator = creatorResult.rows[0] || null;

  // Get participants (accepted requests)
  const participantsResult = await pool.query(
    `SELECT u.id, u.full_name, u.profile_pic_url, r.status
     FROM ride_requests r
     JOIN users u ON r.requester_id = u.id
     WHERE r.commute_id = $1 AND r.status = 'accepted'`,
    [commuteId]
  );
  commute.participants = participantsResult.rows;

  const acceptedIds = participantsResult.rows.map(p => p.id);

  // Check if current user has a request
  const myRequest = await pool.query(
    `SELECT status FROM ride_requests WHERE commute_id = $1 AND requester_id = $2`,
    [commuteId, userId]
  );
  commute.my_request_status = myRequest.rows.length > 0 ? myRequest.rows[0].status : null;

  // Apply coordinate privacy
  return applyCoordinatePrivacy(commute, userId, acceptedIds);
};

/**
 * Get my commutes (created by me)
 */
const getMyCommutes = async (userId, status = 'all') => {
  let statusFilter = '';
  const params = [userId];

  if (status !== 'all') {
    statusFilter = ' AND c.status = $2';
    params.push(status);
  }

  const result = await pool.query(
    `SELECT
      c.id, c.creator_id, c.source_label, c.source_lat, c.source_lng,
      c.dest_label, c.dest_lat, c.dest_lng,
      c.departure_time, c.total_seats, c.available_seats,
      c.vehicle_type, c.notes, c.status, c.created_at,
      (SELECT COUNT(*) FROM ride_requests r WHERE r.commute_id = c.id AND r.status = 'pending') as pending_requests
    FROM commutes c
    WHERE c.creator_id = $1${statusFilter}
    ORDER BY c.departure_time DESC`,
    params
  );

  return result.rows; // Creator gets exact coords
};

/**
 * Update commute status (creator only)
 */
const updateCommuteStatus = async (commuteId, userId, newStatus) => {
  if (!['ongoing', 'completed', 'cancelled'].includes(newStatus)) {
    return { error: 'Invalid status', statusCode: 400 };
  }

  const check = await pool.query(
    `SELECT creator_id, status FROM commutes WHERE id = $1`,
    [commuteId]
  );

  if (check.rows.length === 0) return { error: 'Commute not found', statusCode: 404 };
  if (check.rows[0].creator_id !== userId) return { error: 'Unauthorized', statusCode: 403 };

  const result = await pool.query(
    `UPDATE commutes SET status = $1, updated_at = NOW() WHERE id = $2
     RETURNING id, status`,
    [newStatus, commuteId]
  );

  return { commute: result.rows[0] };
};

module.exports = {
  createCommute,
  getNearbyCommutes,
  getCommuteById,
  getMyCommutes,
  updateCommuteStatus,
};
