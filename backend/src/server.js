// src/server.js
require('dotenv').config();
const express = require('express');
const { pool, initDB, closeDB } = require('./config/db');

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(express.json());

// Routes
const authRoutes = require('./modules/auth/auth.routes');
const usersRoutes = require('./modules/users/users.routes');
const commutesRoutes = require('./modules/commutes/commutes.routes');
const requestsRoutes = require('./modules/requests/requests.routes');
const chatRoutes = require('./modules/chat/chat.routes');

app.use('/api/auth', authRoutes);
app.use('/api/users', usersRoutes);
app.use('/api/commutes', commutesRoutes);
app.use('/api/requests', requestsRoutes);
app.use('/api/chat', chatRoutes);

/**
 * Health Check Route
 * Verifies server health and actual database connectivity
 */
app.get('/health', async (req, res) => {
  try {
    const dbStatus = await pool.query('SELECT 1');
    res.status(200).json({
      status: 'UP',
      timestamp: new Date().toISOString(),
      env: process.env.NODE_ENV,
      database: dbStatus ? 'CONNECTED' : 'DISCONNECTED'
    });
  } catch (error) {
    res.status(503).json({
      status: 'DOWN',
      timestamp: new Date().toISOString(),
      env: process.env.NODE_ENV,
      database: 'ERROR',
      error: error.message
    });
  }
});

/**
 * Main Server Startup
 */
const startServer = async () => {
  try {
    // 1. Initialize Database Connection (includes PostGIS check)
    await initDB();

    // 2. Start Express Listener
    app.listen(PORT, () => {
      console.log(`🚀 CampusPool API running on port ${PORT} [${process.env.NODE_ENV}]`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
};

/**
 * Handle Graceful Shutdown
 */
process.on('SIGINT', async () => {
  console.log('\nGracefully shutting down...');
  await closeDB();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  console.log('\nGracefully shutting down...');
  await closeDB();
  process.exit(0);
});

startServer();
