// src/modules/auth/auth.controller.js
const authService = require('./auth.service');

class AuthController {
  async register(req, res) {
    try {
      const { email, password, full_name } = req.body;
      
      const result = await authService.register({ email, password, full_name });
      
      res.status(201).json({
        status: 'success',
        data: result
      });
    } catch (error) {
      res.status(error.statusCode || 500).json({
        status: 'error',
        message: error.message || 'Internal Server Error'
      });
    }
  }

  async login(req, res) {
    try {
      const { email, password } = req.body;

      const result = await authService.login({ email, password });

      res.status(200).json({
        status: 'success',
        data: result
      });
    } catch (error) {
      res.status(error.statusCode || 500).json({
        status: 'error',
        message: error.message || 'Internal Server Error'
      });
    }
  }

  // Example of a protected controller method
  async getMe(req, res) {
    // req.user is populated by the protect middleware
    res.status(200).json({
      status: 'success',
      data: {
        user: req.user
      }
    });
  }
}

module.exports = new AuthController();
