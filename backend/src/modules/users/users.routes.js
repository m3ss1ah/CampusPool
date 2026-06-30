const router = require('express').Router();
const { body } = require('express-validator');
const usersController = require('./users.controller');
const { validate } = require('../../middleware/validate.middleware');
const { authenticate } = require('../../middleware/auth.middleware');

const updateProfileValidation = [
  body('full_name').optional().notEmpty().withMessage('Full name cannot be empty'),
  body('phone').optional().isString(),
  body('college').optional().isString(),
  body('has_vehicle').optional().isBoolean(),
  body('vehicle_type').optional().isString(),
  body('profile_pic_url').optional().isURL().withMessage('Must be a valid URL'),
  validate
];

router.use(authenticate);

router.get('/profile', usersController.getProfile);
router.patch('/profile', updateProfileValidation, usersController.updateProfile);

module.exports = router;