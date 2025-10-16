'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/store/authStore';
import { bookingsAPI } from '@/lib/api';
import { Booking } from '@/types';
import Navbar from '@/components/Navbar';
import toast from 'react-hot-toast';
import { FaSpinner, FaCalendarAlt, FaMapMarkerAlt, FaUsers, FaDollarSign, FaCheckCircle, FaClock, FaTimesCircle } from 'react-icons/fa';
import { format } from 'date-fns';

export default function ReservationsPage() {
  const router = useRouter();
  const { isAuthenticated, token } = useAuthStore();
  const [bookings, setBookings] = useState<Booking[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<string>('all');
  const [isHydrated, setIsHydrated] = useState(false);

  // Wait for Zustand to hydrate from localStorage
  useEffect(() => {
    setIsHydrated(true);
  }, []);

  useEffect(() => {
    // Don't check auth until hydrated
    if (!isHydrated) return;

    if (!isAuthenticated) {
      router.push('/login');
      return;
    }

    fetchBookings();
  }, [isAuthenticated, isHydrated, router]);

  const fetchBookings = async () => {
    setLoading(true);
    try {
      const response = await bookingsAPI.getAll();
      setBookings(response.data);
    } catch (error: any) {
      toast.error('Failed to fetch bookings');
    } finally {
      setLoading(false);
    }
  };

  const handleCancelBooking = async (id: string) => {
    if (!confirm('Are you sure you want to cancel this booking?')) {
      return;
    }

    try {
      await bookingsAPI.cancel(id);
      toast.success('Booking cancelled successfully');
      fetchBookings();
    } catch (error: any) {
      toast.error('Failed to cancel booking');
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'CONFIRMED':
        return <FaCheckCircle className="text-green-500" />;
      case 'PENDING':
        return <FaClock className="text-yellow-500" />;
      case 'CANCELLED':
        return <FaTimesCircle className="text-red-500" />;
      case 'COMPLETED':
        return <FaCheckCircle className="text-blue-500" />;
      default:
        return null;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'CONFIRMED':
        return 'bg-green-100 text-green-800';
      case 'PENDING':
        return 'bg-yellow-100 text-yellow-800';
      case 'CANCELLED':
        return 'bg-red-100 text-red-800';
      case 'COMPLETED':
        return 'bg-blue-100 text-blue-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const filteredBookings = bookings.filter((booking) => {
    if (filter === 'all') return true;
    return booking.status === filter.toUpperCase();
  });

  // Show loading while hydrating
  if (!isHydrated) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <FaSpinner className="animate-spin text-4xl text-blue-600" />
      </div>
    );
  }

  if (!isAuthenticated) {
    return null;
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <Navbar />
      
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900">My Reservations</h1>
          <p className="mt-2 text-gray-600">View and manage your hotel bookings</p>
        </div>

        {/* Filter Tabs */}
        <div className="mb-6 flex space-x-2 overflow-x-auto">
          {['all', 'pending', 'confirmed', 'completed', 'cancelled'].map((tab) => (
            <button
              key={tab}
              onClick={() => setFilter(tab)}
              className={`px-4 py-2 rounded-md text-sm font-medium whitespace-nowrap ${
                filter === tab
                  ? 'bg-primary-600 text-white'
                  : 'bg-white text-gray-700 hover:bg-gray-100'
              }`}
            >
              {tab.charAt(0).toUpperCase() + tab.slice(1)}
            </button>
          ))}
        </div>

        {/* Bookings List */}
        {loading ? (
          <div className="flex justify-center items-center py-20">
            <FaSpinner className="animate-spin text-4xl text-primary-600" />
          </div>
        ) : filteredBookings.length === 0 ? (
          <div className="text-center py-20 bg-white rounded-lg shadow-md">
            <p className="text-gray-500 text-lg">No reservations found</p>
            <p className="text-gray-400 mt-2">Start booking your perfect stay!</p>
          </div>
        ) : (
          <div className="space-y-4">
            {filteredBookings.map((booking) => (
              <div
                key={booking.id}
                className="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow duration-200"
              >
                <div className="flex flex-col md:flex-row md:items-center md:justify-between">
                  {/* Booking Info */}
                  <div className="flex-1">
                    <div className="flex items-center space-x-2 mb-2">
                      <h3 className="text-lg font-bold text-gray-900">
                        {booking.hotelName || 'Hotel Booking'}
                      </h3>
                      <span className={`px-2 py-1 rounded-full text-xs font-medium flex items-center space-x-1 ${getStatusColor(booking.status)}`}>
                        {getStatusIcon(booking.status)}
                        <span>{booking.status}</span>
                      </span>
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mt-4">
                      <div className="flex items-center text-gray-600">
                        <FaCalendarAlt className="mr-2" />
                        <div>
                          <p className="text-xs text-gray-500">Check-in</p>
                          <p className="font-medium">
                            {format(new Date(booking.checkInDate), 'MMM dd, yyyy')}
                          </p>
                        </div>
                      </div>

                      <div className="flex items-center text-gray-600">
                        <FaCalendarAlt className="mr-2" />
                        <div>
                          <p className="text-xs text-gray-500">Check-out</p>
                          <p className="font-medium">
                            {format(new Date(booking.checkOutDate), 'MMM dd, yyyy')}
                          </p>
                        </div>
                      </div>

                      <div className="flex items-center text-gray-600">
                        <FaUsers className="mr-2" />
                        <div>
                          <p className="text-xs text-gray-500">Guests</p>
                          <p className="font-medium">
                            {booking.rooms} room{booking.rooms > 1 ? 's' : ''} • {booking.adults} adult{booking.adults > 1 ? 's' : ''} {booking.children > 0 && `• ${booking.children} child${booking.children > 1 ? 'ren' : ''}`}
                          </p>
                        </div>
                      </div>
                    </div>

                    <div className="mt-4 flex items-center text-primary-600 font-bold text-xl">
                      <FaDollarSign />
                      <span>{booking.totalPrice}</span>
                      <span className="text-sm text-gray-500 ml-2 font-normal">total</span>
                    </div>
                  </div>

                  {/* Actions */}
                  <div className="mt-4 md:mt-0 md:ml-6 flex flex-col space-y-2">
                    <button
                      onClick={() => router.push(`/reservations/${booking.id}`)}
                      className="px-4 py-2 bg-primary-600 text-white rounded-md hover:bg-primary-700 transition-colors duration-200 text-sm font-medium"
                    >
                      View Details
                    </button>
                    
                    {booking.status === 'PENDING' || booking.status === 'CONFIRMED' ? (
                      <button
                        onClick={() => handleCancelBooking(booking.id)}
                        className="px-4 py-2 bg-red-600 text-white rounded-md hover:bg-red-700 transition-colors duration-200 text-sm font-medium"
                      >
                        Cancel Booking
                      </button>
                    ) : null}
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

