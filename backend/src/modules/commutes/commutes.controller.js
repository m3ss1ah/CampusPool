// src/modules/commutes/commutes.controller.js
const commutesService = require('./commutes.service');

class CommutesController {
  async createCommute(req, res) {
    try {
      const commute = await commutesService.createCommute(req.user.id, req.body);
      res.status(201).json({
        status: 'success',
        message: 'Commute listed successfully',
        data: { commute }
      });
    } catch (error) {
      res.status(error.statusCode || 500).json({
        status: 'error',
        message: error.message || 'Internal Server Error'
      });
    }
  }

  async getNearby(req, res) {
    try {
      const { lat, lng, radius } = req.query;
      if (!lat || !lng) {
        return res.status(400).json({ status: 'error', message: 'lat and lng are required' });
      }

      const commutes = await commutesService.getNearbyCommutes(lat, lng, radius);
      res.status(200).json({
        status: 'success',
        results: commutes.length,
        data: { commutes }
      });
    } catch (error) {
      res.status(error.statusCode || 500).json({
        status: 'error',
        message: error.message || 'Internal Server Error'
      });
    }
  }

  async getDetail(req, res) {
    try {
      const commute = await commutesService.getCommuteById(req.params.id);
      res.status(200).json({
        status: 'success',
        data: { commute }
      });
    } catch (error) {
      res.status(error.statusCode || 500).json({
        status: 'error',
        message: error.message || 'Internal Server Error'
      });
    }
  }
}

module.exports = new CommutesController();
