// src/middleware/auth.middleware.js
const { verifyToken } = require('../utils/jwt');
const { pool } = require('../config/db');

/**
 * Middleware to protect routes.
 * Ensures the request has a valid Bearer token and the user exists.
 */
const protect = async (req, res, next) => {
  let token;

  // Extract token from Authorization header
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    token = req.headers.authorization.split(' ')[1];
  }

  if (!token) {
    return res.status(401).json({ status: 'fail', message: 'Not authorized, no token provided' });
  }

  try {
    // 1. Verify token
    const decoded = verifyToken(token);

    // 2. Check if user still exists
    const result = await pool.query('SELECT id, email, full_name FROM users WHERE id = $1', [decoded.id]);
    const user = result.rows[0];

    if (!user) {
      return res.status(401).json({ status: 'fail', message: 'The user belonging to this token no longer exists.' });
    }

    // 3. Attach user to request object
    req.user = user;
    next();
  } catch (error) {
    console.error('Auth middleware error:', error.message);
    res.status(401).json({ status: 'fail', message: 'Not authorized, token failed or expired' });
  }
};

module.exports = {
  protect
};
