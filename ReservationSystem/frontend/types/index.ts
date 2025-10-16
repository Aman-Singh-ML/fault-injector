export interface User {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  role: 'ADMIN' | 'CUSTOMER';
  phoneNumber?: string;
  enabled: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface Hotel {
  _id: string;
  name: string;
  description: string;
  city: string;
  address: string;
  location?: {
    type: string;
    coordinates: [number, number];
  };
  rating: number;
  price_per_night: number;
  amenities: string[];
  images: string[];
  total_rooms: number;
  available_rooms: number;
  contact?: {
    phone: string;
    email: string;
  };
}

export interface Booking {
  id: string;
  userId: string;
  hotelId: string;
  hotelName?: string;
  checkInDate: string;
  checkOutDate: string;
  rooms: number;
  adults: number;
  children: number;
  totalPrice: number;
  status: 'PENDING' | 'CONFIRMED' | 'CANCELLED' | 'COMPLETED';
  createdAt: string;
  updatedAt: string;
}

export interface Payment {
  id: string;
  bookingId: string;
  amount: number;
  paymentMethod: string;
  status: 'PENDING' | 'COMPLETED' | 'FAILED' | 'REFUNDED';
  transactionId?: string;
  createdAt: string;
  updatedAt: string;
}

export interface Notification {
  id: string;
  userId: string;
  message: string;
  type: 'INFO' | 'SUCCESS' | 'WARNING' | 'ERROR';
  read: boolean;
  createdAt: string;
}

export interface SearchFilters {
  city?: string;
  checkIn?: string;
  checkOut?: string;
  rooms?: number;
  adults?: number;
  children?: number;
  minPrice?: number;
  maxPrice?: number;
  minRating?: number;
}

export interface RoomOccupancy {
  adults: number;
  children: number;
}

