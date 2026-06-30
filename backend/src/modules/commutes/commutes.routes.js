// src/modules/commutes/commutes.routes.js
const router = require('express').Router();
const { authenticate } = require('../../middleware/auth.middleware');
const commutesController = require('./commutes.controller');

router.use(authenticate);

router.post('/',       commutesController.createCommute);
router.get('/nearby',  commutesController.getNearby);
router.get('/my',      commutesController.getMyCommutes);
router.get('/:id',     commutesController.getDetail);
router.patch('/:id/status', commutesController.updateStatus);

module.exports = router;