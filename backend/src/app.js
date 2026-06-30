const express    = require('express');
const helmet     = require('helmet');
const hpp        = require('hpp');
const xssClean   = require('xss-clean');
const cors       = require('cors');
const rateLimit  = require('express-rate-limit');
const morgan     = require('morgan');

const app = express();

// 1. Security headers (helmet first)
app.use(helmet());

// 2. CORS
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
  methods: ['GET', 'POST', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// 3. Body parsers
app.use(express.json({ limit: '10kb' }));        // reject large payloads
app.use(express.urlencoded({ extended: true, limit: '10kb' }));

// 4. HTTP Parameter Pollution prevention
app.use(hpp());

// 5. XSS sanitization (clean all req.body, req.query, req.params)
app.use(xssClean());

// 6. Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,  // 15 minutes
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, error: 'RATE_LIMIT_EXCEEDED', message: 'Too many requests' }
});
app.use('/api/', limiter);

// Stricter limiter for auth routes
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 1000, // Increased for development
  message: { success: false, error: 'AUTH_RATE_LIMIT', message: 'Too many auth attempts' }
});
app.use('/api/auth/', authLimiter);

// 7. Logging (development only)
if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
}

// 8. Routes (after all middleware)
app.use('/api/auth',          require('./modules/auth/auth.routes'));
app.use('/api/users',         require('./modules/users/users.routes'));
app.use('/api/commutes',      require('./modules/commutes/commutes.routes'));
app.use('/api/requests',      require('./modules/requests/requests.routes'));
app.use('/api/matching',      require('./modules/matching/matching.routes'));
app.use('/api/chat',          require('./modules/chat/chat.routes'));
app.use('/api/notifications', require('./modules/notifications/notifications.routes'));
app.use('/api/upload',        require('./modules/upload/upload.routes'));

// 9. 404 handler
app.use((req, res) => {
  res.status(404).json({ success: false, error: 'NOT_FOUND', message: 'Route not found' });
});

// 10. Global error handler (must be last)
app.use(require('./middleware/error.middleware'));

module.exports = app;
