const matchingService = require('./matching.service');
const { success, error, paginated } = require('../../utils/response');

const suggestMatches = async (req, res, next) => {
  try {
    const { lat, lng, dest_label, page = 1, limit = 10 } = req.query;

    if (!lat || !lng) {
      return error(res, 'Missing location coordinates', 400);
    }

    const matches = await matchingService.suggestMatches({
      lat: parseFloat(lat),
      lng: parseFloat(lng),
      destLabel: dest_label,
      page: parseInt(page, 10),
      limit: parseInt(limit, 10),
    });

    // In a real scenario we'd query COUNT(*), but for this MVP we'll just check if length == limit
    return paginated(res, matches, {
      page: parseInt(page, 10),
      limit: parseInt(limit, 10),
      hasMore: matches.length === parseInt(limit, 10),
    });
  } catch (err) {
    next(err);
  }
};

module.exports = { suggestMatches };
