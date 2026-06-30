const router = require('express').Router();
const { authenticate } = require('../../middleware/auth.middleware');
const chatController = require('./chat.controller');

router.use(authenticate);

router.get('/conversations', chatController.getConversations);
router.post('/conversations', chatController.getOrCreateConversation);
router.get('/conversations/:conversationId/messages', chatController.getMessages);
router.post('/conversations/:conversationId/messages', chatController.sendMessage);
router.delete('/messages/:id', chatController.deleteMessage);

module.exports = router;