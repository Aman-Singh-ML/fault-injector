const express = require('express');
const router = express.Router();
const serviceProxy = require('../utils/serviceProxy');

const BOOKING_SERVICE_URL = process.env.BOOKING_SERVICE_URL || 'http://localhost:8083';

// Get all bookings for user
router.get('/', async (req, res, next) => {
  try {
    const response = await serviceProxy.get(`${BOOKING_SERVICE_URL}/bookings`, {
      headers: { 'user-id': req.user.id }
    });
    res.json(response.data);
  } catch (error) {
    next(error);
  }
});

// Get booking by ID
router.get('/:id', async (req, res, next) => {
  try {
    const response = await serviceProxy.get(`${BOOKING_SERVICE_URL}/bookings/${req.params.id}`, {
      headers: { 'user-id': req.user.id }
    });
    res.json(response.data);
  } catch (error) {
    next(error);
  }
});

// Create new booking
router.post('/', async (req, res, next) => {
  try {
    const response = await serviceProxy.post(`${BOOKING_SERVICE_URL}/bookings`, req.body, {
      headers: { 'user-id': req.user.id }
    });
    res.status(201).json(response.data);
  } catch (error) {
    next(error);
  }
});

// Update booking
router.put('/:id', async (req, res, next) => {
  try {
    const response = await serviceProxy.put(`${BOOKING_SERVICE_URL}/bookings/${req.params.id}`, req.body, {
      headers: { 'user-id': req.user.id }
    });
    res.json(response.data);
  } catch (error) {
    next(error);
  }
});

// Cancel booking
router.delete('/:id', async (req, res, next) => {
  try {
    const response = await serviceProxy.delete(`${BOOKING_SERVICE_URL}/bookings/${req.params.id}`, {
      headers: { 'user-id': req.user.id }
    });
    res.json(response.data);
  } catch (error) {
    next(error);
  }
});

module.exports = router;

