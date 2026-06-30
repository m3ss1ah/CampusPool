const { pool } = require('../../config/db');
const { getIO } = require('../../socket');
const notificationService = require('../notifications/notifications.service');

/**
 * Request a seat on a commute
 */
const createRequest = async (userId, commuteId, message) => {
  // 1. Check if commute exists and has available seats
  const commuteCheck = await pool.query(
    'SELECT creator_id, available_seats, status FROM commutes WHERE id = $1',
    [commuteId]
  );
  if (commuteCheck.rows.length === 0) {
    const err = new Error('Commute not found'); err.statusCode = 404; throw err;
  }
  const commute = commuteCheck.rows[0];

  if (commute.creator_id === userId) {
    const err = new Error('You cannot request your own commute'); err.statusCode = 400; throw err;
  }
  if (commute.status !== 'open' || commute.available_seats < 1) {
    const err = new Error('Commute is no longer available'); err.statusCode = 400; throw err;
  }

  // 2. Insert request (handles unique constraint via DB)
  try {
    const result = await pool.query(
      `INSERT INTO ride_requests (commute_id, requester_id, message)
       VALUES ($1, $2, $3)
       RETURNING id, commute_id, requester_id, status, message, created_at`,
      [commuteId, userId, message]
    );
    return result.rows[0];
  } catch (error) {
    if (error.code === '23505') {
      const err = new Error('You have already requested this commute'); err.statusCode = 400; throw err;
    }
    throw error;
  }
};

/**
 * Get all requests made BY the user (outgoing)
 */
const getMyRequests = async (userId) => {
  const result = await pool.query(
    `SELECT r.id, r.commute_id, r.status, r.message, r.created_at,
            c.source_label, c.dest_label, c.departure_time,
            u.full_name as creator_name, u.profile_pic_url as creator_pic
     FROM ride_requests r
     JOIN commutes c ON r.commute_id = c.id
     JOIN users u ON c.creator_id = u.id
     WHERE r.requester_id = $1
     ORDER BY r.created_at DESC`,
    [userId]
  );
  return result.rows;
};

/**
 * Get all incoming requests on commutes the user created
 */
const getIncomingRequests = async (userId) => {
  const result = await pool.query(
    `SELECT r.id, r.commute_id, r.status, r.message, r.created_at,
            c.source_label, c.dest_label, c.departure_time,
            u.id as requester_id, u.full_name, u.phone, u.profile_pic_url
     FROM ride_requests r
     JOIN commutes c ON r.commute_id = c.id
     JOIN users u ON r.requester_id = u.id
     WHERE c.creator_id = $1
     ORDER BY r.created_at DESC`,
    [userId]
  );
  return result.rows;
};

/**
 * Update request status (Accept/Reject) — commute creator only
 */
const updateRequestStatus = async (userId, requestId, status) => {
  if (!['accepted', 'rejected'].includes(status)) {
    const err = new Error('Invalid status'); err.statusCode = 400; throw err;
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const reqQuery = await client.query(
      `SELECT r.commute_id, r.requester_id, r.status as current_status,
              c.creator_id, c.available_seats
       FROM ride_requests r
       JOIN commutes c ON r.commute_id = c.id
       WHERE r.id = $1 FOR UPDATE`,
      [requestId]
    );

    if (reqQuery.rows.length === 0) {
      const err = new Error('Request not found'); err.statusCode = 404; throw err;
    }

    const { commute_id, current_status, creator_id, available_seats } = reqQuery.rows[0];

    if (creator_id !== userId) {
      const err = new Error('Unauthorized'); err.statusCode = 403; throw err;
    }
    if (current_status !== 'pending') {
      const err = new Error('Request is already processed'); err.statusCode = 400; throw err;
    }

    // If accepting, decrement seats
    if (status === 'accepted') {
      if (available_seats < 1) {
        const err = new Error('No seats available'); err.statusCode = 400; throw err;
      }
      await client.query(
        `UPDATE commutes
         SET available_seats = available_seats - 1,
             status = CASE WHEN available_seats - 1 = 0 THEN 'full' ELSE status END
         WHERE id = $1`,
        [commute_id]
      );
    }

    const result = await client.query(
      `UPDATE ride_requests SET status = $1, updated_at = NOW()
       WHERE id = $2 RETURNING id, commute_id, requester_id, status`,
      [status, requestId]
    );

    // Create Notification for the requester
    const notification = await notificationService.createNotification(client, {
      userId: requester_id,
      type: `request_${status}`,
      title: `Seat Request ${status === 'accepted' ? 'Accepted' : 'Rejected'}`,
      body: `Your seat request has been ${status}`,
      metadata: { commute_id, request_id: requestId }
    });

    await client.query('COMMIT');

    // Emit event via socket.io
    try {
      const io = getIO();
      io.to(`user:${requester_id}`).emit('notification', notification);
    } catch (err) {
      console.error('Socket.io emit error:', err);
    }

    return result.rows[0];
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

/**
 * Cancel a request (requester only, pending only)
 */
const cancelRequest = async (userId, requestId) => {
  const reqCheck = await pool.query(
    `SELECT requester_id, status FROM ride_requests WHERE id = $1`,
    [requestId]
  );

  if (reqCheck.rows.length === 0) {
    const err = new Error('Request not found'); err.statusCode = 404; throw err;
  }
  if (reqCheck.rows[0].requester_id !== userId) {
    const err = new Error('Unauthorized'); err.statusCode = 403; throw err;
  }
  if (reqCheck.rows[0].status !== 'pending') {
    const err = new Error('Only pending requests can be cancelled'); err.statusCode = 400; throw err;
  }

  const result = await pool.query(
    `UPDATE ride_requests SET status = 'cancelled', updated_at = NOW()
     WHERE id = $1 RETURNING id, status`,
    [requestId]
  );

  return result.rows[0];
};

module.exports = {
  createRequest,
  getMyRequests,
  getIncomingRequests,
  updateRequestStatus,
  cancelRequest,
};
