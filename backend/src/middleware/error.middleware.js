const { error } = require('../utils/response');

const errorHandler = (err, req, res, next) => {
  console.error('[Error]:', err.message);

  let statusCode = 500;
  let errorCode = 'SERVER_ERROR';
  let message = 'An unexpected error occurred';

  if (err.name === 'ValidationError') {
    statusCode = 400;
    errorCode = 'VALIDATION_ERROR';
    message = err.message;
  } else if (err.name === 'UnauthorizedError') {
    statusCode = 401;
    errorCode = 'UNAUTHORIZED';
    message = 'Invalid token';
  } else if (err.code === '23505') { // Postgres Unique Violation
    statusCode = 409;
    errorCode = 'CONFLICT';
    message = 'Record already exists';
  }

  // Fallback to error message in dev mode
  if (process.env.NODE_ENV === 'development') {
    message = err.message;
  }

  error(res, message, errorCode, statusCode);
};

module.exports = errorHandler;
