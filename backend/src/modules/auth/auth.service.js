const bcrypt = require('bcryptjs');
const db = require('../../config/db');

const registerUser = async ({ full_name, email, password, phone, college }) => {
  const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.edu$/i;
  if (!emailRegex.test(email)) {
    throw new Error('Registration is restricted to .edu email addresses only.');
  }

  const password_hash = await bcrypt.hash(password, 10);
  const query = `
    INSERT INTO users (full_name, email, password_hash, phone, college)
    VALUES ($1, $2, $3, $4, $5)
    RETURNING id, full_name, email, phone, college, has_vehicle, vehicle_type, created_at;
  `;
  const values = [full_name, email.toLowerCase(), password_hash, phone, college];
  const { rows } = await db.query(query, values);
  return rows[0];
};

const getUserByEmail = async (email) => {
  const query = `SELECT * FROM users WHERE email = $1`;
  const { rows } = await db.query(query, [email.toLowerCase()]);
  return rows[0];
};

const updateFcmToken = async (userId, fcmToken) => {
  const query = `UPDATE users SET fcm_token = $1 WHERE id = $2`;
  await db.query(query, [fcmToken, userId]);
};

module.exports = {
  registerUser,
  getUserByEmail,
  updateFcmToken,
};
