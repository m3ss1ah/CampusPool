// src/modules/requests/requests.routes.js
const express = require('express');
const { body } = require('express-validator');
const requestsController = require('./requests.controller');
const { protect } = require('../../middleware/auth.middleware');
const { validate } = require('../../middleware/validation.middleware');

const router = express.Router();

// All routes are protected
router.use(protect);

// POST /api/requests
const createValidation = [
  body('commute_id').isUUID().withMessage('Valid commute_id is required'),
  body('message').optional().isString().trim()
];
router.post('/', createValidation, validate, requestsController.createRequest);

// GET /api/requests/me (Get requests I've sent)
router.get('/me', requestsController.getMyRequests);

// GET /api/requests/commute/:commuteId (Get requests for my commute)
router.get('/commute/:commuteId', requestsController.getRequestsForCommute);

// PATCH /api/requests/:id/status (Accept/Reject)
const statusValidation = [
  body('status').isIn(['accepted', 'rejected']).withMessage('Status must be accepted or rejected')
];
router.patch('/:id/status', statusValidation, validate, requestsController.updateRequestStatus);

module.exports = router;
