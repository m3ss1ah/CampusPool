// src/utils/response.js
const success = (res, data, message = 'Success', statusCode = 200) =>
  res.status(statusCode).json({ success: true, data, message });

const error = (res, message, errorCode = 'SERVER_ERROR', statusCode = 500) =>
  res.status(statusCode).json({ success: false, error: errorCode, message });

const paginated = (res, data, pagination, message = 'Success') =>
  res.status(200).json({ success: true, data, pagination, message });

const cursored = (res, data, cursor, message = 'Success') =>
  res.status(200).json({ success: true, data, cursor, message });

module.exports = { success, error, paginated, cursored };
