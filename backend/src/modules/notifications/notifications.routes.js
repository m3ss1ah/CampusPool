const router = require('express').Router();
const { authenticate } = require('../../middleware/auth.middleware');
const notificationController = require('./notifications.controller');

router.use(authenticate);

router.get('/', notificationController.getNotifications);
router.patch('/read-all', notificationController.markAllAsRead);
router.patch('/:id/read', notificationController.markAsRead);

module.exports = router;