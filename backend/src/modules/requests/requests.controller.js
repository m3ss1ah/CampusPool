// src/modules/requests/requests.controller.js
const requestsService = require('./requests.service');

class RequestsController {
  async createRequest(req, res) {
    try {
      const request = await requestsService.createRequest(req.user.id, req.body.commute_id, req.body.message);
      res.status(201).json({
        status: 'success',
        message: 'Ride request sent',
        data: { request }
      });
    } catch (error) {
      res.status(error.statusCode || 500).json({ status: 'error', message: error.message || 'Server Error' });
    }
  }

  async getMyRequests(req, res) {
    try {
      const requests = await requestsService.getMyRequests(req.user.id);
      res.status(200).json({
        status: 'success',
        results: requests.length,
        data: { requests }
      });
    } catch (error) {
      res.status(error.statusCode || 500).json({ status: 'error', message: error.message || 'Server Error' });
    }
  }

  async getRequestsForCommute(req, res) {
    try {
      const requests = await requestsService.getRequestsForCommute(req.user.id, req.params.commuteId);
      res.status(200).json({
        status: 'success',
        results: requests.length,
        data: { requests }
      });
    } catch (error) {
      res.status(error.statusCode || 500).json({ status: 'error', message: error.message || 'Server Error' });
    }
  }

  async updateRequestStatus(req, res) {
    try {
      const request = await requestsService.updateRequestStatus(req.user.id, req.params.id, req.body.status);
      res.status(200).json({
        status: 'success',
        message: `Request ${req.body.status}`,
        data: { request }
      });
    } catch (error) {
      res.status(error.statusCode || 500).json({ status: 'error', message: error.message || 'Server Error' });
    }
  }
}

module.exports = new RequestsController();
