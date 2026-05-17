// src/modules/commutes/commutes.service.js
const { pool } = require('../../config/db');
const { formatPoint } = require('../../utils/geometry');

class CommutesService {
  /**
   * Create a new commute listing
   */
  async createCommute(userId, commuteData) {
    const {
      source_label,
      source_lat,
      source_lng,
      dest_label,
      dest_lat,
      dest_lng,
      departure_time,
      total_seats,
      vehicle_type,
      notes
    } = commuteData;

    const result = await pool.query(
      `INSERT INTO commutes (
        creator_id, 
        source_label, source_location, 
        dest_label, dest_location, 
        departure_time, total_seats, available_seats, 
        vehicle_type, notes
      ) VALUES ($1, $2, ST_GeogFromText($3), $4, ST_GeogFromText($5), $6, $7, $8, $9, $10)
      RETURNING id, source_label, source_lat, source_lng, dest_label, dest_lat, dest_lng, departure_time, total_seats, available_seats, status`,
      [
        userId,
        source_label,
        formatPoint(source_lat, source_lng),
        dest_label,
        formatPoint(dest_lat, dest_lng),
        departure_time,
        total_seats,
        total_seats, // initially available = total
        vehicle_type,
        notes
      ]
    );

    return result.rows[0];
  }

  /**
   * Get commutes near a specific location
   * radius is in meters
   */
  async getNearbyCommutes(lat, lng, radius = 5000) {
    const result = await pool.query(
      `SELECT 
        c.*,
        u.full_name as creator_name,
        u.profile_pic_url as creator_pic,
        ST_Distance(c.source_location, ST_GeogFromText($1)) as distance_from_source
      FROM commutes c
      JOIN users u ON c.creator_id = u.id
      WHERE c.status = 'open' 
        AND ST_DWithin(c.source_location, ST_GeogFromText($1), $2)
        AND c.departure_time > NOW()
      ORDER BY distance_from_source ASC
      LIMIT 50`,
      [formatPoint(lat, lng), radius]
    );

    return result.rows;
  }

  /**
   * Get single commute detail
   */
  async getCommuteById(commuteId) {
    const result = await pool.query(
      `SELECT 
        c.*, 
        u.full_name as creator_name, 
        u.phone as creator_phone,
        u.college as creator_college
      FROM commutes c
      JOIN users u ON c.creator_id = u.id
      WHERE c.id = $1`,
      [commuteId]
    );

    if (result.rows.length === 0) {
      const error = new Error('Commute not found');
      error.statusCode = 404;
      throw error;
    }

    return result.rows[0];
  }
}

module.exports = new CommutesService();
