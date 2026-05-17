// src/modules/auth/auth.routes.js
const express = require('express');
const { body } = require('express-validator');
const authController = require('./auth.controller');
const { validate } = require('../../middleware/validation.middleware');
const { protect } = require('../../middleware/auth.middleware');

const router = express.Router();

// Validation Rules
const registerValidation = [
  body('email').isEmail().withMessage('Please provide a valid email'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters long'),
  body('full_name').notEmpty().withMessage('Full name is required')
];

const loginValidation = [
  body('email').isEmail().withMessage('Please provide a valid email'),
  body('password').notEmpty().withMessage('Password is required')
];

// Public Routes
router.post('/register', registerValidation, validate, authController.register);
router.post('/login', loginValidation, validate, authController.login);

// Protected Routes
// Example: Get current logged-in user profile
router.get('/me', protect, authController.getMe);

module.exports = router;
