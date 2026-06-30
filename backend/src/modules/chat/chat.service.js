// src/modules/chat/chat.service.js
const { pool } = require('../../config/db');

const getOrCreateConversation = async (userId, targetUserId, commuteId) => {
  const participantA = userId < targetUserId ? userId : targetUserId;
  const participantB = userId < targetUserId ? targetUserId : userId;

  const checkResult = await pool.query(
    `SELECT id FROM conversations 
     WHERE participant_a = $1 AND participant_b = $2 AND commute_id = $3`,
    [participantA, participantB, commuteId]
  );

  if (checkResult.rows.length > 0) {
    return checkResult.rows[0];
  }

  const createResult = await pool.query(
    `INSERT INTO conversations (commute_id, participant_a, participant_b)
     VALUES ($1, $2, $3)
     RETURNING id`,
    [commuteId, participantA, participantB]
  );

  return createResult.rows[0];
};

const getConversations = async (userId) => {
  const result = await pool.query(
    `SELECT c.id, c.commute_id, c.last_message, c.last_message_at,
            u.id as other_user_id, u.full_name, u.profile_pic_url,
            com.source_label, com.dest_label,
            (
              SELECT count(*) FROM messages m
              WHERE m.conversation_id = c.id
                AND m.sender_id != $1
                AND m.is_read = false
                AND m.deleted_at IS NULL
            ) as unread_count
     FROM conversations c
     JOIN users u ON (u.id = CASE WHEN c.participant_a = $1 THEN c.participant_b ELSE c.participant_a END)
     LEFT JOIN commutes com ON c.commute_id = com.id
     WHERE c.participant_a = $1 OR c.participant_b = $1
     ORDER BY c.last_message_at DESC NULLS LAST`,
    [userId]
  );
  return result.rows;
};

const getMessages = async (userId, conversationId, cursor, limit = 20) => {
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

  let cursorCondition = '';
  const params = [conversationId];

  if (cursor) {
    const [dateStr, idStr] = cursor.split('__');
    params.push(dateStr, idStr);
    cursorCondition = `AND (created_at, id) < ($2::timestamptz, $3::uuid)`;
  }

  const queryText = `
    SELECT id, sender_id, content, is_read, deleted_at, created_at
    FROM messages
    WHERE conversation_id = $1 ${cursorCondition}
    ORDER BY created_at DESC, id DESC
    LIMIT $${params.length + 1}
  `;
  params.push(limit + 1);

  const result = await pool.query(queryText, params);

  let hasMore = false;
  let nextCursor = null;

  if (result.rows.length > limit) {
    hasMore = true;
    result.rows.pop();
    const lastItem = result.rows[result.rows.length - 1];
    nextCursor = `${lastItem.created_at.toISOString()}__${lastItem.id}`;
  } else if (result.rows.length > 0) {
    const lastItem = result.rows[result.rows.length - 1];
    nextCursor = `${lastItem.created_at.toISOString()}__${lastItem.id}`;
  }

  const processedRows = result.rows.map(row => {
    if (row.deleted_at) {
      row.content = "Message deleted";
    }
    return row;
  });

  return {
    data: processedRows,
    cursor: {
      next_cursor: nextCursor,
      has_more: hasMore
    }
  };
};

const sendMessage = async (userId, conversationId, content) => {
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

    const msgResult = await client.query(
      `INSERT INTO messages (conversation_id, sender_id, content)
       VALUES ($1, $2, $3)
       RETURNING id, sender_id, content, is_read, deleted_at, created_at`,
      [conversationId, userId, content]
    );

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
};

const deleteMessage = async (userId, messageId) => {
  const result = await pool.query(
    `UPDATE messages SET deleted_at = NOW() 
     WHERE id = $1 AND sender_id = $2 AND deleted_at IS NULL
     RETURNING id, conversation_id, deleted_at`,
    [messageId, userId]
  );
  if (result.rows.length === 0) {
    const err = new Error('Message not found or unauthorized');
    err.statusCode = 404;
    throw err;
  }
  return result.rows[0];
};

module.exports = {
  getOrCreateConversation,
  getConversations,
  getMessages,
  sendMessage,
  deleteMessage
};
