// src/modules/users/users.routes.js
const express = require('express');
const { body } = require('express-validator');
const usersController = require('./users.controller');
const { protect } = require('../../middleware/auth.middleware');
const { validate } = require('../../middleware/validation.middleware');

const router = express.Router();

// All user routes are protected
router.use(protect);

// GET /api/users/profile
router.get('/profile', usersController.getProfile);

// PATCH /api/users/profile
const updateValidation = [
  body('full_name').optional().notEmpty().withMessage('Full name cannot be empty'),
  body('phone').optional().isMobilePhone().withMessage('Invalid phone number'),
  body('college').optional().notEmpty().withMessage('College name cannot be empty'),
  body('has_vehicle').optional().isBoolean().withMessage('has_vehicle must be a boolean'),
  body('vehicle_type').optional().isIn(['bike', 'car', 'auto']).withMessage('Invalid vehicle type')
];

router.patch('/profile', updateValidation, validate, usersController.updateProfile);

module.exports = router;
