// src/modules/chat/chat.service.js
const { pool } = require('../../config/db');

class ChatService {
  /**
   * Get or create a conversation between two users for a commute
   */
  async getOrCreateConversation(userId, targetUserId, commuteId) {
    // 1. Order participants to prevent duplicates (UUIDs are comparable)
    const participantA = userId < targetUserId ? userId : targetUserId;
    const participantB = userId < targetUserId ? targetUserId : userId;

    // 2. Check if exists
    const checkResult = await pool.query(
      `SELECT id FROM conversations 
       WHERE participant_a = $1 AND participant_b = $2 AND commute_id = $3`,
      [participantA, participantB, commuteId]
    );

    if (checkResult.rows.length > 0) {
      return checkResult.rows[0];
    }

    // 3. Create new if not exists
    const createResult = await pool.query(
      `INSERT INTO conversations (commute_id, participant_a, participant_b)
       VALUES ($1, $2, $3)
       RETURNING id`,
      [commuteId, participantA, participantB]
    );

    return createResult.rows[0];
  }

  /**
   * Get all conversations for a user
   */
  async getConversations(userId) {
    const result = await pool.query(
      `SELECT c.id, c.commute_id, c.last_message, c.last_message_at,
              u.id as other_user_id, u.full_name, u.profile_pic_url,
              com.source_label, com.dest_label
       FROM conversations c
       JOIN users u ON (u.id = CASE WHEN c.participant_a = $1 THEN c.participant_b ELSE c.participant_a END)
       LEFT JOIN commutes com ON c.commute_id = com.id
       WHERE c.participant_a = $1 OR c.participant_b = $1
       ORDER BY c.last_message_at DESC NULLS LAST`,
      [userId]
    );
    return result.rows;
  }

  /**
   * Get messages for a specific conversation
   */
  async getMessages(userId, conversationId) {
    // 1. Verify user is part of the conversation
    const convoCheck = await pool.query(
      `SELECT id FROM conversations 
       WHERE id = $1 AND (participant_a = $2 OR participant_b = $2)`,
      [conversationId, userId]
    );

    if (convoCheck.rows.length === 0) {
      const err = new Error('Conversation not found or access denied');
      err.statusCode = 404;
      throw err;
    }

    // 2. Fetch messages
    const result = await pool.query(
      `SELECT id, sender_id, content, is_read, created_at
       FROM messages
       WHERE conversation_id = $1 AND deleted_at IS NULL
       ORDER BY created_at ASC`,
      [conversationId]
    );
    return result.rows;
  }

  /**
   * Send a message in a conversation
   */
  async sendMessage(userId, conversationId, content) {
    // Verify participation
    const convoCheck = await pool.query(
      `SELECT id FROM conversations 
       WHERE id = $1 AND (participant_a = $2 OR participant_b = $2)`,
      [conversationId, userId]
    );

    if (convoCheck.rows.length === 0) {
      const err = new Error('Conversation not found or access denied');
      err.statusCode = 404;
      throw err;
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // 1. Insert message
      const msgResult = await client.query(
        `INSERT INTO messages (conversation_id, sender_id, content)
         VALUES ($1, $2, $3)
         RETURNING id, sender_id, content, created_at`,
        [conversationId, userId, content]
      );

      // 2. Update conversation's last_message fields
      await client.query(
        `UPDATE conversations 
         SET last_message = $1, last_message_at = NOW()
         WHERE id = $2`,
        [content, conversationId]
      );

      await client.query('COMMIT');
      return msgResult.rows[0];
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }
}

module.exports = new ChatService();
