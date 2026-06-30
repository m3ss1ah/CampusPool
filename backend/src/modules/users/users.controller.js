const usersService = require('./users.service');
const { success, error } = require('../../utils/response');

const getProfile = async (req, res, next) => {
  try {
    const user = await usersService.getProfile(req.user.id);
    if (!user) {
      return error(res, 'User not found', 'NOT_FOUND', 404);
    }
    return success(res, user, 'Profile fetched successfully');
  } catch (err) {
    next(err);
  }
};

const updateProfile = async (req, res, next) => {
  try {
    const user = await usersService.updateProfile(req.user.id, req.body);
    return success(res, user, 'Profile updated successfully');
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getProfile,
  updateProfile,
};
