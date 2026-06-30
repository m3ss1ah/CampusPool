// src/modules/chat/chat.controller.js
const chatService = require('./chat.service');
const { success, error } = require('../../utils/response');
const { getIO } = require('../../socket');

const getOrCreateConversation = async (req, res, next) => {
  try {
    const { target_user_id, commute_id } = req.body;
    const conversation = await chatService.getOrCreateConversation(req.user.id, target_user_id, commute_id);
    return success(res, conversation);
  } catch (err) {
    next(err);
  }
};

const getConversations = async (req, res, next) => {
  try {
    const conversations = await chatService.getConversations(req.user.id);
    return success(res, conversations);
  } catch (err) {
    next(err);
  }
};

const getMessages = async (req, res, next) => {
  try {
    const { cursor, limit } = req.query;
    const result = await chatService.getMessages(req.user.id, req.params.conversationId, cursor, limit);
    return res.status(200).json({
      success: true,
      data: result.data,
      cursor: result.cursor
    });
  } catch (err) {
    next(err);
  }
};

const sendMessage = async (req, res, next) => {
  try {
    const message = await chatService.sendMessage(req.user.id, req.params.conversationId, req.body.content);
    
    // Emit event via socket.io
    const io = getIO();
    io.to(`conversation:${req.params.conversationId}`).emit('new_message', {
      id: message.id,
      conversation_id: req.params.conversationId,
      sender_id: message.sender_id,
      content: message.content,
      created_at: message.created_at
    });

    // Send Push Notification
    try {
      const { pool } = require('../../config/db');
      const { sendPushNotification } = require('../../utils/firebase');
      
      const convoRes = await pool.query(
        `SELECT u.fcm_token, sender.full_name as sender_name 
         FROM conversations c
         JOIN users u ON u.id = CASE WHEN c.participant_a = $1 THEN c.participant_b ELSE c.participant_a END
         JOIN users sender ON sender.id = $1
         WHERE c.id = $2`,
        [req.user.id, req.params.conversationId]
      );

      if (convoRes.rows.length > 0 && convoRes.rows[0].fcm_token) {
        await sendPushNotification(
          convoRes.rows[0].fcm_token,
          `New message from ${convoRes.rows[0].sender_name}`,
          message.content,
          { conversationId: req.params.conversationId, type: 'chat' }
        );
      }
    } catch (pushErr) {
      console.error('Failed to send push notification:', pushErr);
    }

    return res.status(201).json({
      success: true,
      data: message
    });
  } catch (err) {
    next(err);
  }
};

const deleteMessage = async (req, res, next) => {
  try {
    const deleted = await chatService.deleteMessage(req.user.id, req.params.id);

    const io = getIO();
    io.to(`conversation:${deleted.conversation_id}`).emit('message_deleted', {
      message_id: deleted.id,
      conversation_id: deleted.conversation_id,
      deleted_at: deleted.deleted_at
    });

    return success(res, null, 'Message deleted');
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getOrCreateConversation,
  getConversations,
  getMessages,
  sendMessage,
  deleteMessage
};
