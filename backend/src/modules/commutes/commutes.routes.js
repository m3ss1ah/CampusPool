// src/modules/commutes/commutes.routes.js
const express = require('express');
const { body, query } = require('express-validator');
const commutesController = require('./commutes.controller');
const { protect } = require('../../middleware/auth.middleware');
const { validate } = require('../../middleware/validation.middleware');

const router = express.Router();

// All commute routes are protected
router.use(protect);

// POST /api/commutes
const createValidation = [
  body('source_label').notEmpty().withMessage('Source label is required'),
  body('source_lat').isFloat({ min: -90, max: 90 }).withMessage('Valid source latitude is required'),
  body('source_lng').isFloat({ min: -180, max: 180 }).withMessage('Valid source longitude is required'),
  body('dest_label').notEmpty().withMessage('Destination label is required'),
  body('dest_lat').isFloat({ min: -90, max: 90 }).withMessage('Valid destination latitude is required'),
  body('dest_lng').isFloat({ min: -180, max: 180 }).withMessage('Valid destination longitude is required'),
  body('departure_time').isISO8601().withMessage('Valid departure time is required'),
  body('total_seats').isInt({ min: 1, max: 8 }).withMessage('Seats must be between 1 and 8')
];

router.post('/', createValidation, validate, commutesController.createCommute);

// GET /api/commutes/nearby
const nearbyValidation = [
  query('lat').isFloat().withMessage('lat is required'),
  query('lng').isFloat().withMessage('lng is required'),
  query('radius').optional().isInt().withMessage('radius must be an integer')
];

router.get('/nearby', nearbyValidation, validate, commutesController.getNearby);

// GET /api/commutes/:id
router.get('/:id', commutesController.getDetail);

module.exports = router;
