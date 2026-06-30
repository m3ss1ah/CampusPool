const jwt = require('jsonwebtoken');
const { error } = require('../utils/response');

const authenticate = (req, res, next) => {
  const auth = req.headers.authorization;
  if (!auth?.startsWith('Bearer ')) {
    return error(res, 'Authorization token required', 'UNAUTHORIZED', 401);
  }
  try {
    req.user = jwt.verify(auth.split(' ')[1], process.env.JWT_SECRET);
    next();
  } catch (err) {
    return error(res, 'Invalid or expired token', 'INVALID_TOKEN', 401);
  }
};

module.exports = { authenticate };
