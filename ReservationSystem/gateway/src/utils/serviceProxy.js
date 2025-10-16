const axios = require('axios');

const serviceProxy = axios.create({
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json'
  }
});

// Request interceptor
serviceProxy.interceptors.request.use(
  (config) => {
    console.log(`[${new Date().toISOString()}] ${config.method.toUpperCase()} ${config.url}`);
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor
serviceProxy.interceptors.response.use(
  (response) => {
    return response;
  },
  (error) => {
    if (error.response) {
      // Server responded with error status
      const err = new Error(error.response.data.message || 'Service error');
      err.status = error.response.status;
      err.data = error.response.data;
      return Promise.reject(err);
    } else if (error.request) {
      // Request made but no response
      const err = new Error('Service unavailable');
      err.status = 503;
      return Promise.reject(err);
    } else {
      // Something else happened
      return Promise.reject(error);
    }
  }
);

module.exports = serviceProxy;

