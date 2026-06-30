const authService = require('./auth.service');
const { signToken } = require('../../utils/jwt');
const { success, error } = require('../../utils/response');
const bcrypt = require('bcryptjs');

const register = async (req, res, next) => {
  try {
    const user = await authService.registerUser(req.body);
    const token = signToken({ id: user.id });
    return res.status(201).json({
      success: true,
      data: { user, token },
      message: 'Account created successfully',
    });
  } catch (err) {
    next(err);
  }
};

const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;
    const user = await authService.getUserByEmail(email);
    
    if (!user || !(await bcrypt.compare(password, user.password_hash))) {
      return error(res, 'Invalid credentials', 'UNAUTHORIZED', 401);
    }
    
    const token = signToken({ id: user.id });
    
    // Remove password_hash before returning
    delete user.password_hash;
    
    return success(res, { user, token }, 'Login successful');
  } catch (err) {
    next(err);
  }
};

const updateFcmToken = async (req, res, next) => {
  try {
    const { fcm_token } = req.body;
    await authService.updateFcmToken(req.user.id, fcm_token);
    return success(res, null, 'FCM token updated');
  } catch (err) {
    next(err);
  }
};

module.exports = {
  register,
  login,
  updateFcmToken,
};
