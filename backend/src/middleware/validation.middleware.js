// src/middleware/validation.middleware.js
const { validationResult } = require('express-validator');

/**
 * Middleware to check for validation errors from express-validator.
 * Returns 400 Bad Request with array of errors if validation fails.
 */
const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      status: 'fail',
      errors: errors.array().map(err => ({ field: err.path, message: err.msg }))
    });
  }
  next();
};

module.exports = {
  validate
};
