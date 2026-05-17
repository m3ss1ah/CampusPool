// src/modules/requests/requests.service.js
const { pool } = require('../../config/db');

class RequestsService {
  /**
   * Request a seat on a commute
   */
  async createRequest(userId, commuteId, message) {
    // 1. Check if commute exists and has available seats
    const commuteCheck = await pool.query('SELECT creator_id, available_seats, status FROM commutes WHERE id = $1', [commuteId]);
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
         RETURNING id, commute_id, status, created_at`,
        [commuteId, userId, message]
      );
      return result.rows[0];
    } catch (error) {
      if (error.code === '23505') { // Unique violation
        const err = new Error('You have already requested this commute'); err.statusCode = 400; throw err;
      }
      throw error;
    }
  }

  /**
   * Get all requests made BY the user
   */
  async getMyRequests(userId) {
    const result = await pool.query(
      `SELECT r.id, r.status, r.created_at, 
              c.source_label, c.dest_label, c.departure_time,
              u.full_name as creator_name, u.phone as creator_phone
       FROM ride_requests r
       JOIN commutes c ON r.commute_id = c.id
       JOIN users u ON c.creator_id = u.id
       WHERE r.requester_id = $1
       ORDER BY r.created_at DESC`,
      [userId]
    );
    return result.rows;
  }

  /**
   * Get all requests FOR a specific commute (Creator only)
   */
  async getRequestsForCommute(userId, commuteId) {
    // Check ownership
    const commuteCheck = await pool.query('SELECT creator_id FROM commutes WHERE id = $1', [commuteId]);
    if (commuteCheck.rows.length === 0) {
      const err = new Error('Commute not found'); err.statusCode = 404; throw err;
    }
    if (commuteCheck.rows[0].creator_id !== userId) {
      const err = new Error('Unauthorized'); err.statusCode = 403; throw err;
    }

    const result = await pool.query(
      `SELECT r.id, r.status, r.message, r.created_at,
              u.id as requester_id, u.full_name, u.phone, u.profile_pic_url
       FROM ride_requests r
       JOIN users u ON r.requester_id = u.id
       WHERE r.commute_id = $1
       ORDER BY r.created_at ASC`,
      [commuteId]
    );
    return result.rows;
  }

  /**
   * Update request status (Accept/Reject)
   */
  async updateRequestStatus(userId, requestId, status) {
    if (!['accepted', 'rejected'].includes(status)) {
      const err = new Error('Invalid status'); err.statusCode = 400; throw err;
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // 1. Get request and commute info
      const reqQuery = await client.query(
        `SELECT r.commute_id, r.status as current_status, c.creator_id, c.available_seats
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

      // 2. If accepting, decrement seats
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

      // 3. Update request status
      const result = await client.query(
        `UPDATE ride_requests SET status = $1, updated_at = NOW() WHERE id = $2 RETURNING id, status`,
        [status, requestId]
      );

      await client.query('COMMIT');
      return result.rows[0];
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }
}

module.exports = new RequestsService();
