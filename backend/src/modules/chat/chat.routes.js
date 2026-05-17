// src/modules/chat/chat.routes.js
const express = require('express');
const { body } = require('express-validator');
const chatController = require('./chat.controller');
const { protect } = require('../../middleware/auth.middleware');
const { validate } = require('../../middleware/validation.middleware');

const router = express.Router();

router.use(protect);

// POST /api/chat/conversations (Start or get a conversation)
const createValidation = [
  body('target_user_id').isUUID().withMessage('Valid target_user_id is required'),
  body('commute_id').isUUID().withMessage('Valid commute_id is required')
];
router.post('/conversations', createValidation, validate, chatController.getOrCreateConversation);

// GET /api/chat/conversations (List all my conversations)
router.get('/conversations', chatController.getConversations);

// GET /api/chat/conversations/:conversationId/messages
router.get('/conversations/:conversationId/messages', chatController.getMessages);

// POST /api/chat/conversations/:conversationId/messages
const messageValidation = [
  body('content').notEmpty().withMessage('Message content cannot be empty')
];
router.post('/conversations/:conversationId/messages', messageValidation, validate, chatController.sendMessage);

module.exports = router;
