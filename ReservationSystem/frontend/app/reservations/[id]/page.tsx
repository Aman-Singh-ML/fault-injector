'use client';

import { useEffect, useState } from 'react';
import { useRouter, useParams } from 'next/navigation';
import { useAuthStore } from '@/store/authStore';
import { bookingsAPI } from '@/lib/api';
import { Booking } from '@/types';
import Navbar from '@/components/Navbar';
import toast from 'react-hot-toast';
import { 
  FaSpinner, 
  FaCalendarAlt, 
  FaMapMarkerAlt, 
  FaUsers, 
  FaDollarSign, 
  FaCheckCircle, 
  FaClock, 
  FaTimesCircle,
  FaArrowLeft,
  FaReceipt,
  FaBed,
  FaChild
} from 'react-icons/fa';
import { format } from 'date-fns';

export default function ReservationDetailsPage() {
  const router = useRouter();
  const params = useParams();
  const { isAuthenticated } = useAuthStore();
  const [booking, setBooking] = useState<Booking | null>(null);
  const [loading, setLoading] = useState(true);
  const [cancelling, setCancelling] = useState(false);

  useEffect(() => {
    if (!isAuthenticated) {
      router.push('/login');
      return;
    }
    if (params.id) {
      fetchBookingDetails();
    }
  }, [isAuthenticated, params.id, router]);

  const fetchBookingDetails = async () => {
    setLoading(true);
    try {
      const response = await bookingsAPI.getById(params.id as string);
      setBooking(response.data);
    } catch (error: any) {
      console.error('Failed to fetch booking details:', error);
      toast.error('Failed to fetch booking details');
      router.push('/reservations');
    } finally {
      setLoading(false);
    }
  };

  const handleCancelBooking = async () => {
    if (!booking) return;
    
    if (!confirm('Are you sure you want to cancel this booking?')) {
      return;
    }

    setCancelling(true);
    try {
      await bookingsAPI.cancel(booking.id);
      toast.success('Booking cancelled successfully');
      fetchBookingDetails();
    } catch (error: any) {
      console.error('Failed to cancel booking:', error);
      toast.error('Failed to cancel booking');
    } finally {
      setCancelling(false);
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'CONFIRMED':
        return <FaCheckCircle className="text-green-500 text-3xl" />;
      case 'PENDING':
        return <FaClock className="text-yellow-500 text-3xl" />;
      case 'CANCELLED':
        return <FaTimesCircle className="text-red-500 text-3xl" />;
      case 'COMPLETED':
        return <FaCheckCircle className="text-blue-500 text-3xl" />;
      default:
        return null;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'CONFIRMED':
        return 'bg-green-100 text-green-800 border-green-300';
      case 'PENDING':
        return 'bg-yellow-100 text-yellow-800 border-yellow-300';
      case 'CANCELLED':
        return 'bg-red-100 text-red-800 border-red-300';
      case 'COMPLETED':
        return 'bg-blue-100 text-blue-800 border-blue-300';
      default:
        return 'bg-gray-100 text-gray-800 border-gray-300';
    }
  };

  if (!isAuthenticated) {
    return null;
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50">
        <Navbar />
        <div className="flex justify-center items-center py-20">
          <FaSpinner className="animate-spin text-4xl text-primary-600" />
        </div>
      </div>
    );
  }

  if (!booking) {
    return (
      <div className="min-h-screen bg-gray-50">
        <Navbar />
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <div className="text-center py-20 bg-white rounded-lg shadow-md">
            <p className="text-gray-500 text-lg">Booking not found</p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <Navbar />
      
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Back Button */}
        <button
          onClick={() => router.push('/reservations')}
          className="mb-6 flex items-center text-primary-600 hover:text-primary-700 font-medium"
        >
          <FaArrowLeft className="mr-2" />
          Back to Reservations
        </button>

        {/* Booking Details Card */}
        <div className="bg-white rounded-lg shadow-lg overflow-hidden">
          {/* Header */}
          <div className="bg-gradient-to-r from-primary-600 to-primary-700 p-6 text-white">
            <div className="flex items-center justify-between">
              <div>
                <h1 className="text-2xl font-bold">{booking.hotelName || 'Hotel Booking'}</h1>
                <p className="text-primary-100 mt-1">Booking ID: #{booking.id}</p>
              </div>
              <div className="flex items-center space-x-3">
                {getStatusIcon(booking.status)}
              </div>
            </div>
          </div>

          {/* Status Badge */}
          <div className="px-6 py-4 border-b border-gray-200">
            <div className={`inline-flex items-center px-4 py-2 rounded-full border-2 ${getStatusColor(booking.status)}`}>
              <span className="font-semibold text-lg">{booking.status}</span>
            </div>
          </div>

          {/* Booking Information */}
          <div className="p-6 space-y-6">
            {/* Dates */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="flex items-start space-x-4">
                <div className="flex-shrink-0 w-12 h-12 bg-primary-100 rounded-lg flex items-center justify-center">
                  <FaCalendarAlt className="text-primary-600 text-xl" />
                </div>
                <div>
                  <p className="text-sm text-gray-500 font-medium">Check-in</p>
                  <p className="text-lg font-bold text-gray-900">
                    {format(new Date(booking.checkInDate), 'EEEE, MMM dd, yyyy')}
                  </p>
                  <p className="text-sm text-gray-600">After 2:00 PM</p>
                </div>
              </div>

              <div className="flex items-start space-x-4">
                <div className="flex-shrink-0 w-12 h-12 bg-primary-100 rounded-lg flex items-center justify-center">
                  <FaCalendarAlt className="text-primary-600 text-xl" />
                </div>
                <div>
                  <p className="text-sm text-gray-500 font-medium">Check-out</p>
                  <p className="text-lg font-bold text-gray-900">
                    {format(new Date(booking.checkOutDate), 'EEEE, MMM dd, yyyy')}
                  </p>
                  <p className="text-sm text-gray-600">Before 11:00 AM</p>
                </div>
              </div>
            </div>

            {/* Guests */}
            <div className="border-t border-gray-200 pt-6">
              <h3 className="text-lg font-semibold text-gray-900 mb-4">Guest Information</h3>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div className="flex items-center space-x-3">
                  <div className="flex-shrink-0 w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
                    <FaBed className="text-blue-600" />
                  </div>
                  <div>
                    <p className="text-sm text-gray-500">Rooms</p>
                    <p className="text-lg font-bold text-gray-900">{booking.rooms}</p>
                  </div>
                </div>

                <div className="flex items-center space-x-3">
                  <div className="flex-shrink-0 w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center">
                    <FaUsers className="text-green-600" />
                  </div>
                  <div>
                    <p className="text-sm text-gray-500">Adults</p>
                    <p className="text-lg font-bold text-gray-900">{booking.adults}</p>
                  </div>
                </div>

                <div className="flex items-center space-x-3">
                  <div className="flex-shrink-0 w-10 h-10 bg-purple-100 rounded-lg flex items-center justify-center">
                    <FaChild className="text-purple-600" />
                  </div>
                  <div>
                    <p className="text-sm text-gray-500">Children</p>
                    <p className="text-lg font-bold text-gray-900">{booking.children}</p>
                  </div>
                </div>
              </div>
            </div>

            {/* Price */}
            <div className="border-t border-gray-200 pt-6">
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-3">
                  <div className="flex-shrink-0 w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
                    <FaDollarSign className="text-green-600 text-xl" />
                  </div>
                  <div>
                    <p className="text-sm text-gray-500">Total Amount</p>
                    <p className="text-3xl font-bold text-primary-600">${booking.totalPrice}</p>
                  </div>
                </div>
              </div>
            </div>

            {/* Booking Dates */}
            <div className="border-t border-gray-200 pt-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
                <div>
                  <p className="text-gray-500">Booked on</p>
                  <p className="font-medium text-gray-900">
                    {format(new Date(booking.createdAt), 'MMM dd, yyyy HH:mm')}
                  </p>
                </div>
                <div>
                  <p className="text-gray-500">Last updated</p>
                  <p className="font-medium text-gray-900">
                    {format(new Date(booking.updatedAt), 'MMM dd, yyyy HH:mm')}
                  </p>
                </div>
              </div>
            </div>
          </div>

          {/* Actions */}
          {(booking.status === 'PENDING' || booking.status === 'CONFIRMED') && (
            <div className="px-6 py-4 bg-gray-50 border-t border-gray-200">
              <button
                onClick={handleCancelBooking}
                disabled={cancelling}
                className="w-full md:w-auto px-6 py-3 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors duration-200 font-medium disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center space-x-2"
              >
                {cancelling ? (
                  <>
                    <FaSpinner className="animate-spin" />
                    <span>Cancelling...</span>
                  </>
                ) : (
                  <>
                    <FaTimesCircle />
                    <span>Cancel Booking</span>
                  </>
                )}
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

