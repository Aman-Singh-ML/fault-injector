const axios = require('axios');

const AUTH_SERVICE_URL = process.env.AUTH_SERVICE_URL || 'http://localhost:8081';

const authMiddleware = async (req, res, next) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];
    
    if (!token) {
      return res.status(401).json({ error: 'No token provided' });
    }

    // Verify token with auth service
    const response = await axios.post(`${AUTH_SERVICE_URL}/auth/verify`, {}, {
      headers: { Authorization: `Bearer ${token}` }
    });

    if (response.data && response.data.user) {
      req.user = response.data.user;
      next();
    } else {
      return res.status(401).json({ error: 'Invalid token' });
    }
  } catch (error) {
    console.error('Auth middleware error:', error.message);
    return res.status(401).json({ error: 'Authentication failed' });
  }
};

module.exports = authMiddleware;

