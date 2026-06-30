require('dotenv').config();
const http = require('http');
const app = require('./app');
const { initDB, closeDB } = require('./config/db');
const { initSocket } = require('./socket');

const PORT = process.env.PORT || 5000;
const server = http.createServer(app);

initSocket(server);

const startServer = async () => {
  try {
    // 1. Initialize Database Connection (includes PostGIS check)
    await initDB();

    // 2. Start Server
    server.listen(PORT, () => {
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
const shutdown = async () => {
  console.log('\nGracefully shutting down...');
  await closeDB();
  process.exit(0);
};

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);

startServer();
