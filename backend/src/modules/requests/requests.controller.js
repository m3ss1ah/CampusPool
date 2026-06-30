// src/modules/requests/requests.controller.js
const requestsService = require('./requests.service');
const { success, error } = require('../../utils/response');

const createRequest = async (req, res, next) => {
  try {
    const { commute_id, message } = req.body;
    if (!commute_id) {
      return error(res, 'commute_id is required', 'VALIDATION_ERROR', 400);
    }
    const request = await requestsService.createRequest(req.user.id, commute_id, message);
    return res.status(201).json({ success: true, data: request, message: 'Seat request sent' });
  } catch (err) {
    if (err.statusCode) {
      return error(res, err.message, 'BAD_REQUEST', err.statusCode);
    }
    next(err);
  }
};

const respondToRequest = async (req, res, next) => {
  try {
    const result = await requestsService.updateRequestStatus(
      req.user.id, req.params.id, req.body.status
    );
    return success(res, result, `Request ${req.body.status}`);
  } catch (err) {
    if (err.statusCode) {
      return error(res, err.message, 'BAD_REQUEST', err.statusCode);
    }
    next(err);
  }
};

const cancelRequest = async (req, res, next) => {
  try {
    const result = await requestsService.cancelRequest(req.user.id, req.params.id);
    return success(res, result, 'Request cancelled');
  } catch (err) {
    if (err.statusCode) {
      return error(res, err.message, 'BAD_REQUEST', err.statusCode);
    }
    next(err);
  }
};

const getIncoming = async (req, res, next) => {
  try {
    const requests = await requestsService.getIncomingRequests(req.user.id);
    return success(res, requests, 'Incoming requests fetched');
  } catch (err) {
    next(err);
  }
};

const getOutgoing = async (req, res, next) => {
  try {
    const requests = await requestsService.getMyRequests(req.user.id);
    return success(res, requests, 'Outgoing requests fetched');
  } catch (err) {
    next(err);
  }
};

module.exports = { createRequest, respondToRequest, cancelRequest, getIncoming, getOutgoing };
