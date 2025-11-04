import express from 'express';
import serviceProxy from '../utils/serviceProxy.js';

const router = express.Router();
const BOOKING_SERVICE_URL = process.env.BOOKING_SERVICE_URL || 'http://localhost:8000';

// Get all bookings for user
router.get('/', async (req, res, next) => {
  try {
    const response = await serviceProxy.get(`${BOOKING_SERVICE_URL}/bookings`, {
      headers: {
        'X-User-Id': req.user.id.toString(),
        'X-User-Role': req.user.role || 'USER'
      }
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
      headers: {
        'X-User-Id': req.user.id.toString(),
        'X-User-Role': req.user.role || 'USER'
      }
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
      headers: {
        'X-User-Id': req.user.id.toString(),
        'X-User-Role': req.user.role || 'USER'
      }
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
      headers: {
        'X-User-Id': req.user.id.toString(),
        'X-User-Role': req.user.role || 'USER'
      }
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
      headers: {
        'X-User-Id': req.user.id.toString(),
        'X-User-Role': req.user.role || 'USER'
      }
    });
    res.json(response.data);
  } catch (error) {
    next(error);
  }
});

export default router;

