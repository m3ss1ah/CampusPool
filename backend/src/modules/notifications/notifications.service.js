const { pool } = require('../../config/db');

const getNotifications = async (userId, page = 1, limit = 30) => {
  const offset = (page - 1) * limit;

  // Get paginated notifications
  const result = await pool.query(
    `SELECT * FROM notifications
     WHERE user_id = $1
     ORDER BY created_at DESC
     LIMIT $2 OFFSET $3`,
    [userId, limit, offset]
  );

  // Get total unread count
  const unreadResult = await pool.query(
    `SELECT count(*) FROM notifications WHERE user_id = $1 AND is_read = false`,
    [userId]
  );
  
  // Get total count for pagination
  const totalResult = await pool.query(
    `SELECT count(*) FROM notifications WHERE user_id = $1`,
    [userId]
  );

  const total = parseInt(totalResult.rows[0].count, 10);
  const unreadCount = parseInt(unreadResult.rows[0].count, 10);

  return {
    data: result.rows,
    unread_count: unreadCount,
    pagination: {
      page: parseInt(page, 10),
      limit: parseInt(limit, 10),
      total,
      has_more: offset + result.rows.length < total
    }
  };
};

const markAsRead = async (userId, notificationId) => {
  const result = await pool.query(
    `UPDATE notifications SET is_read = true 
     WHERE id = $1 AND user_id = $2 RETURNING *`,
    [notificationId, userId]
  );
  if (result.rows.length === 0) {
    throw new Error('Notification not found');
  }
  return result.rows[0];
};

const markAllAsRead = async (userId) => {
  await pool.query(
    `UPDATE notifications SET is_read = true WHERE user_id = $1 AND is_read = false`,
    [userId]
  );
};

const createNotification = async (clientOrPool, { userId, type, title, body, metadata }) => {
  const result = await clientOrPool.query(
    `INSERT INTO notifications (user_id, type, title, body, metadata)
     VALUES ($1, $2, $3, $4, $5) RETURNING *`,
    [userId, type, title, body, metadata]
  );
  return result.rows[0];
};

module.exports = {
  getNotifications,
  markAsRead,
  markAllAsRead,
  createNotification
};
