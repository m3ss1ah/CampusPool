const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');

let io;
const connectedUsers = new Map(); // userId -> socketId

const initSocket = (server) => {
  io = new Server(server, {
    cors: {
      origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
      methods: ['GET', 'POST']
    }
  });

  io.engine.pingTimeout = 60000;
  io.engine.pingInterval = 25000;

  // Authentication middleware
  io.use((socket, next) => {
    const token = socket.handshake.auth?.token?.split(' ')[1];
    if (!token) {
      return next(new Error('Authentication error: Token missing'));
    }

    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      socket.user = decoded; // Attach user to socket
      next();
    } catch (err) {
      next(new Error('Authentication error: Invalid token'));
    }
  });

  io.on('connection', (socket) => {
    const userId = socket.user.id;
    console.log(`Socket connected: ${socket.id} (User: ${userId})`);
    
    // Join personal room for notifications
    socket.join(`user:${userId}`);
    connectedUsers.set(userId, socket.id);

    // Chat Events
    socket.on('join_conversation', ({ conversation_id }) => {
      socket.join(`conversation:${conversation_id}`);
    });

    socket.on('leave_conversation', ({ conversation_id }) => {
      socket.leave(`conversation:${conversation_id}`);
    });

    socket.on('typing', ({ conversation_id, is_typing }) => {
      socket.to(`conversation:${conversation_id}`).emit('typing', {
        conversation_id,
        user_id: userId,
        is_typing
      });
    });

    socket.on('disconnect', () => {
      connectedUsers.delete(userId);
      console.log(`Socket disconnected: ${socket.id} (User: ${userId})`);
    });
  });

  return io;
};

const getIO = () => {
  if (!io) {
    throw new Error('Socket.io not initialized!');
  }
  return io;
};

module.exports = { initSocket, getIO, connectedUsers };
