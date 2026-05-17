// src/modules/chat/chat.controller.js
const chatService = require('./chat.service');

class ChatController {
  async getOrCreateConversation(req, res) {
    try {
      const { target_user_id, commute_id } = req.body;
      const conversation = await chatService.getOrCreateConversation(req.user.id, target_user_id, commute_id);
      
      res.status(200).json({
        status: 'success',
        data: { conversation }
      });
    } catch (error) {
      res.status(error.statusCode || 500).json({ status: 'error', message: error.message });
    }
  }

  async getConversations(req, res) {
    try {
      const conversations = await chatService.getConversations(req.user.id);
      res.status(200).json({
        status: 'success',
        results: conversations.length,
        data: { conversations }
      });
    } catch (error) {
      res.status(error.statusCode || 500).json({ status: 'error', message: error.message });
    }
  }

  async getMessages(req, res) {
    try {
      const messages = await chatService.getMessages(req.user.id, req.params.conversationId);
      res.status(200).json({
        status: 'success',
        results: messages.length,
        data: { messages }
      });
    } catch (error) {
      res.status(error.statusCode || 500).json({ status: 'error', message: error.message });
    }
  }

  async sendMessage(req, res) {
    try {
      const message = await chatService.sendMessage(req.user.id, req.params.conversationId, req.body.content);
      res.status(201).json({
        status: 'success',
        data: { message }
      });
    } catch (error) {
      res.status(error.statusCode || 500).json({ status: 'error', message: error.message });
    }
  }
}

module.exports = new ChatController();
