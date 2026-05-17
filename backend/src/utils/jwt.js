// src/utils/jwt.js
const jwt = require('jsonwebtoken');

/**
 * Generates a JWT token for a user
 * @param {string} userId 
 * @returns {string} jwt token
 */
const generateToken = (userId) => {
  return jwt.sign(
    { id: userId },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '30d' }
  );
};

/**
 * Verifies and decodes a JWT token
 * @param {string} token 
 * @returns {object} decoded payload
 */
const verifyToken = (token) => {
  return jwt.verify(token, process.env.JWT_SECRET);
};

module.exports = {
  generateToken,
  verifyToken
};
