const express = require('express');
const router = express.Router();
const serviceProxy = require('../utils/serviceProxy');

const SEARCH_SERVICE_URL = process.env.SEARCH_SERVICE_URL || 'http://localhost:8081';

// Search hotels
router.get('/hotels', async (req, res, next) => {
  try {
    const { city, checkIn, checkOut, guests, rooms, minPrice, maxPrice, minRating } = req.query;
    const response = await serviceProxy.get(`${SEARCH_SERVICE_URL}/search/hotels`, {
      params: { city, checkIn, checkOut, guests, rooms, minPrice, maxPrice, minRating }
    });
    res.json(response.data);
  } catch (error) {
    next(error);
  }
});

// Get hotel details
router.get('/hotels/:id', async (req, res, next) => {
  try {
    const response = await serviceProxy.get(`${SEARCH_SERVICE_URL}/hotels/${req.params.id}`);
    res.json(response.data);
  } catch (error) {
    next(error);
  }
});

// Get available rooms
router.get('/hotels/:id/rooms', async (req, res, next) => {
  try {
    const { checkIn, checkOut } = req.query;
    const response = await serviceProxy.get(`${SEARCH_SERVICE_URL}/hotels/${req.params.id}/rooms`, {
      params: { checkIn, checkOut }
    });
    res.json(response.data);
  } catch (error) {
    next(error);
  }
});

module.exports = router;

