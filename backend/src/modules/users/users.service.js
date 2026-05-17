// src/modules/users/users.service.js
const { pool } = require('../../config/db');

class UsersService {
  /**
   * Get user profile by ID
   */
  async getProfile(userId) {
    const result = await pool.query(
      `SELECT id, full_name, email, phone, college, profile_pic_url, has_vehicle, vehicle_type, total_rides_offered, total_rides_joined, created_at
       FROM users 
       WHERE id = $1`,
      [userId]
    );

    if (result.rows.length === 0) {
      const error = new Error('User not found');
      error.statusCode = 404;
      throw error;
    }

    return result.rows[0];
  }

  /**
   * Update user profile
   */
  async updateProfile(userId, updateData) {
    const fields = [];
    const values = [];
    let idx = 1;

    // Allowed update fields
    const allowedFields = ['full_name', 'phone', 'college', 'has_vehicle', 'vehicle_type', 'fcm_token'];

    for (const field of allowedFields) {
      if (updateData[field] !== undefined) {
        fields.push(`${field} = $${idx}`);
        values.push(updateData[field]);
        idx++;
      }
    }

    if (fields.length === 0) {
      const error = new Error('No valid fields to update');
      error.statusCode = 400;
      throw error;
    }

    values.push(userId);
    const result = await pool.query(
      `UPDATE users 
       SET ${fields.join(', ')}, updated_at = NOW() 
       WHERE id = $${idx}
       RETURNING id, full_name, email, phone, college, profile_pic_url, has_vehicle, vehicle_type, updated_at`,
      values
    );

    return result.rows[0];
  }
}

module.exports = new UsersService();
