const router = require('express').Router();
const { authenticate } = require('../../middleware/auth.middleware');
const matchingController = require('./matching.controller');

router.use(authenticate);

router.get('/suggest', matchingController.suggestMatches);

module.exports = router;