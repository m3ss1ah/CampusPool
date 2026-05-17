// src/modules/auth/auth.service.js
const { pool } = require('../../config/db');
const { hashPassword, comparePassword } = require('../../utils/hash');
const { generateToken } = require('../../utils/jwt');

class AuthService {
  /**
   * Register a new user
   */
  async register({ email, password, full_name }) {
    // 1. Check if user already exists
    const existingUser = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
    if (existingUser.rows.length > 0) {
      const error = new Error('Email is already registered');
      error.statusCode = 400;
      throw error;
    }

    // 2. Hash password
    const hashed = await hashPassword(password);

    // 3. Insert into DB
    const result = await pool.query(
      `INSERT INTO users (email, password_hash, full_name)
       VALUES ($1, $2, $3)
       RETURNING id, email, full_name, created_at`,
      [email, hashed, full_name]
    );

    const user = result.rows[0];

    // 4. Generate JWT
    const token = generateToken(user.id);

    return { user, token };
  }

  /**
   * Login a user
   */
  async login({ email, password }) {
    // 1. Find user by email
    const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
    const user = result.rows[0];

    // 2. Verify user exists and password matches
    if (!user || !(await comparePassword(password, user.password_hash))) {
      const error = new Error('Invalid email or password');
      error.statusCode = 401;
      throw error;
    }

    // 3. Generate JWT
    const token = generateToken(user.id);

    // 4. Return user info (excluding password hash)
    const { password_hash, ...userWithoutPassword } = user;

    return { user: userWithoutPassword, token };
  }
}

module.exports = new AuthService();
