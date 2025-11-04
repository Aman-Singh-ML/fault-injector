import express from 'express';
import serviceProxy from '../utils/serviceProxy.js';

const router = express.Router();
const NOTIFICATION_SERVICE_URL = process.env.NOTIFICATION_SERVICE_URL || 'http://localhost:8083';

// Get all notifications for user (POST with body)
router.post('/', async (req, res, next) => {
  try {
    // Use userId from request body or from authenticated user
    const userId = req.body.userId || req.user?.id;
    
    if (!userId) {
      return res.status(401).json({ error: 'User ID required' });
    }

    const response = await serviceProxy.post(`${NOTIFICATION_SERVICE_URL}/notifications`, {
      userId: userId.toString()
    });
    res.json(response.data);
  } catch (error) {
    next(error);
  }
});

// Mark all as read (POST with body)
router.post('/read-all', async (req, res, next) => {
  try {
    const userId = req.body.userId || req.user?.id;
    
    if (!userId) {
      return res.status(401).json({ error: 'User ID required' });
    }

    const response = await serviceProxy.post(`${NOTIFICATION_SERVICE_URL}/notifications/read-all`, {
      userId: userId.toString()
    });
    res.json(response.data);
  } catch (error) {
    next(error);
  }
});

// Delete notification (POST with body)
router.post('/delete', async (req, res, next) => {
  try {
    const { id } = req.body;
    
    if (!id) {
      return res.status(400).json({ error: 'Notification ID required' });
    }

    const response = await serviceProxy.post(`${NOTIFICATION_SERVICE_URL}/notifications/delete`, {
      id
    });
    res.json(response.data);
  } catch (error) {
    next(error);
  }
});

// Mark notification as read (PUT - keeping for backward compatibility)
router.put('/:id/read', async (req, res, next) => {
  try {
    const response = await serviceProxy.put(`${NOTIFICATION_SERVICE_URL}/notifications/${req.params.id}/read`);
    res.json(response.data);
  } catch (error) {
    next(error);
  }
});

export default router;

