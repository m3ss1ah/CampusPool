// src/modules/users/users.controller.js
const usersService = require('./users.service');

class UsersController {
  async getProfile(req, res) {
    try {
      const user = await usersService.getProfile(req.user.id);
      res.status(200).json({
        status: 'success',
        data: { user }
      });
    } catch (error) {
      res.status(error.statusCode || 500).json({
        status: 'error',
        message: error.message || 'Internal Server Error'
      });
    }
  }

  async updateProfile(req, res) {
    try {
      const updatedUser = await usersService.updateProfile(req.user.id, req.body);
      res.status(200).json({
        status: 'success',
        message: 'Profile updated successfully',
        data: { user: updatedUser }
      });
    } catch (error) {
      res.status(error.statusCode || 500).json({
        status: 'error',
        message: error.message || 'Internal Server Error'
      });
    }
  }
}

module.exports = new UsersController();
