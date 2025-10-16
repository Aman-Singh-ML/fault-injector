const express = require('express');
const router = express.Router();
const serviceProxy = require('../utils/serviceProxy');

const PAYMENT_SERVICE_URL = process.env.PAYMENT_SERVICE_URL || 'http://localhost:8084';

// Process payment
router.post('/', async (req, res, next) => {
  try {
    const response = await serviceProxy.post(`${PAYMENT_SERVICE_URL}/payments`, req.body, {
      headers: { 'user-id': req.user.id }
    });
    res.status(201).json(response.data);
  } catch (error) {
    next(error);
  }
});

// Get payment status
router.get('/:id', async (req, res, next) => {
  try {
    const response = await serviceProxy.get(`${PAYMENT_SERVICE_URL}/payments/${req.params.id}`, {
      headers: { 'user-id': req.user.id }
    });
    res.json(response.data);
  } catch (error) {
    next(error);
  }
});

// Refund payment
router.post('/:id/refund', async (req, res, next) => {
  try {
    const response = await serviceProxy.post(`${PAYMENT_SERVICE_URL}/payments/${req.params.id}/refund`, req.body, {
      headers: { 'user-id': req.user.id }
    });
    res.json(response.data);
  } catch (error) {
    next(error);
  }
});

module.exports = router;

