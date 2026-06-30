const router = require('express').Router();
const multer = require('multer');
const uploadController = require('./upload.controller');
const { authenticate } = require('../../middleware/auth.middleware');

const upload = multer({ 
  dest: 'uploads/',
  limits: { fileSize: 5 * 1024 * 1024 } // 5MB max
});

router.post('/profile-picture', authenticate, upload.single('image'), uploadController.uploadProfilePicture);

module.exports = router;