// src/modules/commutes/commutes.controller.js
const commutesService = require('./commutes.service');
const { success, error, paginated } = require('../../utils/response');

const createCommute = async (req, res, next) => {
  try {
    const commute = await commutesService.createCommute(req.user.id, req.body);
    return res.status(201).json({ success: true, data: commute, message: 'Commute listed successfully' });
  } catch (err) {
    next(err);
  }
};

const getNearby = async (req, res, next) => {
  try {
    const { lat, lng, radius, page, limit } = req.query;
    if (!lat || !lng) {
      return error(res, 'lat and lng are required', 'VALIDATION_ERROR', 400);
    }

    const result = await commutesService.getNearbyCommutes(
      parseFloat(lat),
      parseFloat(lng),
      radius ? parseFloat(radius) * 1000 : 5000, // convert km to meters
      page ? parseInt(page, 10) : 1,
      limit ? parseInt(limit, 10) : 20
    );

    return paginated(res, result.commutes, result.pagination, 'Nearby commutes fetched');
  } catch (err) {
    next(err);
  }
};

const getDetail = async (req, res, next) => {
  try {
    const commute = await commutesService.getCommuteById(req.params.id, req.user.id);
    if (!commute) {
      return error(res, 'Commute not found', 'NOT_FOUND', 404);
    }
    return success(res, commute, 'Commute fetched');
  } catch (err) {
    next(err);
  }
};

const getMyCommutes = async (req, res, next) => {
  try {
    const { status } = req.query;
    const commutes = await commutesService.getMyCommutes(req.user.id, status || 'all');
    return success(res, commutes, 'My commutes fetched');
  } catch (err) {
    next(err);
  }
};

const updateStatus = async (req, res, next) => {
  try {
    const result = await commutesService.updateCommuteStatus(
      req.params.id, req.user.id, req.body.status
    );
    if (result.error) {
      return error(res, result.error, 'BAD_REQUEST', result.statusCode);
    }
    return success(res, result.commute, 'Commute status updated');
  } catch (err) {
    next(err);
  }
};

module.exports = { createCommute, getNearby, getDetail, getMyCommutes, updateStatus };
