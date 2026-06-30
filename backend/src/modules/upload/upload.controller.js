const uploadService = require('./upload.service');
const { success, error } = require('../../utils/response');

const uploadProfilePicture = async (req, res, next) => {
  try {
    if (!req.file) {
      return error(res, 'No image file provided', 'VALIDATION_ERROR', 400);
    }
    
    const url = await uploadService.uploadImage(req.file.path);
    return success(res, { url }, 'Profile picture uploaded');
  } catch (err) {
    next(err);
  }
};

module.exports = {
  uploadProfilePicture,
};
