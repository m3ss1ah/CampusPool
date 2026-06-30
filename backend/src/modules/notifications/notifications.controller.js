const notificationService = require('./notifications.service');
const { success } = require('../../utils/response');

const getNotifications = async (req, res, next) => {
  try {
    const { page = 1, limit = 30 } = req.query;
    const result = await notificationService.getNotifications(req.user.id, page, limit);
    
    return res.status(200).json({
      success: true,
      data: result.data,
      unread_count: result.unread_count,
      pagination: result.pagination
    });
  } catch (err) {
    next(err);
  }
};

const markAsRead = async (req, res, next) => {
  try {
    const notification = await notificationService.markAsRead(req.user.id, req.params.id);
    return success(res, notification);
  } catch (err) {
    next(err);
  }
};

const markAllAsRead = async (req, res, next) => {
  try {
    await notificationService.markAllAsRead(req.user.id);
    return success(res, null, 'All notifications marked as read');
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getNotifications,
  markAsRead,
  markAllAsRead
};
