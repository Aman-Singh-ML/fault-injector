import axios from 'axios';

const API_URL = process.env.NEXT_PUBLIC_API_URL || '/api';

const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor to add auth token
api.interceptors.request.use(
  (config) => {
    if (typeof window !== 'undefined') {
      const authStorage = localStorage.getItem('auth-storage');
      if (authStorage) {
        try {
          const { state } = JSON.parse(authStorage);
          if (state?.token) {
            config.headers.Authorization = `Bearer ${state.token}`;
          }
        } catch (error) {
          console.error('Error parsing auth storage:', error);
        }
      }
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor for error handling
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // Clear auth and redirect to login
      if (typeof window !== 'undefined') {
        localStorage.removeItem('auth-storage');
        window.location.href = '/login';
      }
    }
    return Promise.reject(error);
  }
);

export default api;

// Auth API
export const authAPI = {
  login: (email: string, password: string) =>
    api.post('/auth/login', { email, password }),

  register: (data: {
    email: string;
    password: string;
    firstName: string;
    lastName: string;
    phoneNumber: string;
  }) => api.post('/auth/register', data),

  getProfile: () => {
    console.log('📡 Fetching profile from server...');
    return api.get('/auth/profile', {
      headers: {
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0'
      }
    });
  },

  updateProfile: (data: {
    firstName?: string;
    lastName?: string;
    email?: string;
    phoneNumber?: string;
  }) => {
    console.log('📡 Updating profile...', data);
    return api.put('/auth/profile', data, {
      headers: {
        'Cache-Control': 'no-cache, no-store, must-revalidate'
      }
    });
  },

  verifyToken: () => api.post('/auth/verify'),

  clearCache: () => {
    if (typeof window !== 'undefined') {
      console.log('🧹 Clearing profile cache...');
      localStorage.removeItem('profile-cache');
    }
  }
};

// Hotels API (Search Service)
export const hotelsAPI = {
  search: (params: {
    city?: string;
    checkIn?: string;
    checkOut?: string;
    guests?: number;
    minPrice?: number;
    maxPrice?: number;
    minRating?: number;
  }) => api.get('/search/hotels', { params }),

  getById: (id: string) => api.get(`/search/hotels/${id}`),
};

// Bookings API (Search Service publishes to Kafka, Booking Service consumes)
export const bookingsAPI = {
  create: (data: {
    userId: string;
    hotelId: string;
    hotelName: string;
    checkInDate: string;
    checkOutDate: string;
    rooms: number;
    adults: number;
    children: number;
    totalPrice: number;
  }) => api.post('/search/book', data),

  checkAvailability: (data: {
    hotelId: string;
    checkIn: string;
    checkOut: string;
    rooms: number;
  }) => api.post('/booking/check-availability', data),

  getAll: () => api.get('/booking/bookings'),

  getById: (id: string) => api.get(`/booking/bookings/${id}`),

  confirm: (id: string, data: { paymentId: string; transactionId: string }) =>
    api.put(`/booking/bookings/${id}/confirm`, data),

  cancel: (id: string) => api.put(`/booking/bookings/${id}/cancel`),

  getInventory: (hotelId: string, checkIn?: string, checkOut?: string) => {
    const params = checkIn && checkOut ? `?checkIn=${checkIn}&checkOut=${checkOut}` : '';
    return api.get(`/booking/inventory/${hotelId}${params}`);
  },
};

export const paymentAPI = {
  initiate: (data: {
    bookingId: string;
    userId: string;
    amount: number;
  }) => api.post('/payment/initiate', data),

  verifyOTP: (data: {
    paymentId: string;
    otp: string;
  }) => api.post('/payment/verify-otp', data),

  getByBookingId: (bookingId: string) => api.get(`/payment/bookings/${bookingId}`),

  getById: (id: string) => api.get(`/payment/payments/${id}`),
};

export const notificationAPI = {
  getAll: () => api.get('/notify/notifications'),

  getUnreadCount: () => api.get('/notify/notifications/unread-count'),

  markAsRead: (id: string) => api.put(`/notify/notifications/${id}/read`),

  markAllAsRead: () => api.put('/notify/notifications/read-all'),

  delete: (id: string) => api.delete(`/notify/notifications/${id}`),
};

// Payments API (Payment Service)
export const paymentsAPI = {
  process: (data: {
    bookingId: string;
    amount: number;
    paymentMethod: string;
  }) => api.post('/payment/payments', data),

  getAll: () => api.get('/payment/payments'),

  getById: (id: string) => api.get(`/payment/payments/${id}`),
};

// Notifications API (Notification Service)
export const notificationsAPI = {
  getAll: (userId: string) => api.post(`/notifications`, { userId }),

  markAsRead: (id: string) => api.put(`/notifications/${id}/read`),

  markAllAsRead: (userId: string) => api.post(`/notifications/read-all`, { userId }),

  delete: (id: string) => api.post(`/notifications/delete`, { id }),
};

// Admin API
export const adminAPI = {
  // Users management (Auth Service)
  getAllUsers: () => api.get('/admin/users'),
  getUserById: (id: string) => api.get(`/admin/users/${id}`),
  updateUser: (id: string, data: any) => api.put(`/admin/users/${id}`, data),
  deleteUser: (id: string) => api.delete(`/admin/users/${id}`),

  // Hotels management (Search Service)
  getAllHotels: () => api.get('/admin/hotels'),
  createHotel: (data: any) => api.post('/admin/hotels', data),
  updateHotel: (id: string, data: any) => api.put(`/admin/hotels/${id}`, data),
  deleteHotel: (id: string) => api.delete(`/admin/hotels/${id}`),

  // Bookings management (Booking Service)
  getAllBookings: () => api.get('/admin/bookings'),
  updateBookingStatus: (id: string, status: string) =>
    api.put(`/admin/bookings/${id}/status`, { status }),

  // Analytics (aggregated from multiple services)
  getAnalytics: () => api.get('/auth/admin/analytics'),
};
