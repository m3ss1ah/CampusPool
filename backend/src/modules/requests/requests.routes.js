// src/modules/requests/requests.routes.js
const router = require('express').Router();
const { authenticate } = require('../../middleware/auth.middleware');
const requestsController = require('./requests.controller');

router.use(authenticate);

router.post('/',               requestsController.createRequest);
router.patch('/:id/respond',   requestsController.respondToRequest);
router.patch('/:id/cancel',    requestsController.cancelRequest);
router.get('/incoming',        requestsController.getIncoming);
router.get('/outgoing',        requestsController.getOutgoing);

module.exports = router;