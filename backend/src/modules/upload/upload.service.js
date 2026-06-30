const cloudinary = require('../../config/cloudinary');
const fs = require('fs');

const uploadImage = async (filePath) => {
  try {
    const result = await cloudinary.uploader.upload(filePath, {
      folder: 'campuspool/profiles',
      allowed_formats: ['jpg', 'png', 'jpeg', 'webp'],
      transformation: [{ width: 500, height: 500, crop: 'limit' }]
    });
    // Remove temporary file
    fs.unlinkSync(filePath);
    return result.secure_url;
  } catch (error) {
    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
    }
    throw new Error('Image upload failed: ' + error.message);
  }
};

module.exports = {
  uploadImage,
};
