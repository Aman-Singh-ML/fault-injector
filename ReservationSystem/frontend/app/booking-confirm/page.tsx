'use client';

import { useEffect, useState, Suspense } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { useAuthStore } from '@/store/authStore';
import api, { bookingsAPI, paymentAPI } from '@/lib/api';
import Navbar from '@/components/Navbar';
import toast from 'react-hot-toast';
import {
  FaSpinner,
  FaCheckCircle,
  FaTimesCircle,
  FaHotel,
  FaCalendarAlt,
  FaBed,
  FaUsers,
  FaChild,
  FaDollarSign,
  FaCreditCard
} from 'react-icons/fa';

function BookingConfirmPageContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { user, isAuthenticated } = useAuthStore();

  const [loading, setLoading] = useState(false);
  const [processing, setProcessing] = useState(false);
  const [bookingCreated, setBookingCreated] = useState(false);
  const [showOTPInput, setShowOTPInput] = useState(false);
  const [bookingId, setBookingId] = useState<string | null>(null);
  const [paymentId, setPaymentId] = useState<string | null>(null);
  const [generatedOTP, setGeneratedOTP] = useState<string>('');
  const [enteredOTP, setEnteredOTP] = useState<string>('');
  const [otpError, setOTPError] = useState<string>('');

  // Get booking details from URL params
  const hotelId = searchParams.get('hotelId');
  const hotelName = searchParams.get('hotelName');
  const checkIn = searchParams.get('checkIn');
  const checkOut = searchParams.get('checkOut');
  const rooms = parseInt(searchParams.get('rooms') || '1');
  const adults = parseInt(searchParams.get('adults') || '2');
  const children = parseInt(searchParams.get('children') || '0');
  const totalPrice = parseFloat(searchParams.get('totalPrice') || '0');

  useEffect(() => {
    if (!isAuthenticated) {
      router.push('/login');
      return;
    }

    if (!hotelId || !checkIn || !checkOut) {
      toast.error('Invalid booking details');
      router.push('/dashboard');
    }
  }, [isAuthenticated, hotelId, checkIn, checkOut, router]);

  const handleConfirmBooking = async () => {
    if (!user) return;

    setLoading(true);
    setProcessing(true);

    try {
      // Create booking via Kafka (via search service)
      toast.loading('Creating booking...', { id: 'booking' });

      const bookingResponse = await api.post('/bookings/create', {
        hotelId: hotelId!,
        hotelName: hotelName || '',
        checkInDate: checkIn!,
        checkOutDate: checkOut!,
        rooms,
        adults,
        children,
        totalPrice
      });

      // Expect 202 Accepted when queued
      if (bookingResponse?.status === 202) {
        toast.success('Booking request queued for processing!', { id: 'booking' });
      } else {
        toast.success(bookingResponse?.data?.message || 'Booking request queued for processing!', { id: 'booking' });
      }

      // Redirect to reservations after 2 seconds (shows Pending until processed)
      setTimeout(() => {
        router.push('/reservations');
      }, 2000);

    } catch (error: any) {
      console.error('Booking error:', error);
      const res = error?.response;
      const code = res?.data?.code;
      const errMsg = res?.data?.error || res?.data?.message;

      if (res?.status === 503) {
        // Kafka producer in search-service reported service issues
        switch (code) {
          case 'KAFKA_NOT_CONNECTED':
            toast.error('Booking service is temporarily unavailable. Please try again in a moment.', { id: 'booking' });
            break;
          case 'KAFKA_TIMEOUT':
            toast.error('Booking request timed out. Please try again.', { id: 'booking' });
            break;
          case 'KAFKA_LEADER_NOT_AVAILABLE':
            toast.error('Booking service is temporarily unavailable. Please try again.', { id: 'booking' });
            break;
          case 'KAFKA_TOPIC_NOT_FOUND':
            toast.error('Booking service configuration error. Please contact support.', { id: 'booking' });
            break;
          case 'KAFKA_PUBLISH_FAILED':
            toast.error('Failed to process booking request. Please try again.', { id: 'booking' });
            break;
          default:
            toast.error(errMsg || 'Booking service unavailable', { id: 'booking' });
        }
      } else if (code === 'INSUFFICIENT_INVENTORY') {
        toast.error('Sorry, not enough rooms available for selected dates', { id: 'booking' });
      } else {
        toast.error(errMsg || 'Failed to create booking', { id: 'booking' });
      }

      setProcessing(false);
      setLoading(false);
    }
  };

  const handleVerifyOTP = async () => {
    if (!enteredOTP || enteredOTP.length !== 6) {
      setOTPError('Please enter a valid 6-digit OTP');
      return;
    }

    setProcessing(true);
    setOTPError('');

    try {
      toast.loading('Verifying OTP...', { id: 'otp' });

      // Verify OTP
      const verifyResponse = await paymentAPI.verifyOTP({
        paymentId: paymentId!,
        otp: enteredOTP
      });

      const payment = verifyResponse.data;

      toast.success('Payment successful!', { id: 'otp' });

      // Confirm booking
      await bookingsAPI.confirm(bookingId!, {
        paymentId: payment.id.toString(),
        transactionId: payment.transactionId
      });

      toast.success('Booking confirmed!');

      // Redirect to reservations after 2 seconds
      setTimeout(() => {
        router.push('/reservations');
      }, 2000);

    } catch (error: any) {
      console.error('OTP verification error:', error);

      if (error.response?.data?.error === 'Invalid OTP') {
        setOTPError('Invalid OTP. Please try again.');
        toast.error('Invalid OTP. Please check and try again.', { id: 'otp' });
      } else {
        toast.error('Payment verification failed. Please try again.', { id: 'otp' });
      }

      setProcessing(false);
    }
  };

  if (!isAuthenticated) {
    return null;
  }

  const nights = checkIn && checkOut 
    ? Math.ceil((new Date(checkOut).getTime() - new Date(checkIn).getTime()) / (1000 * 60 * 60 * 24))
    : 0;

  return (
    <div className="min-h-screen bg-gray-50">
      <Navbar />
      
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="bg-white rounded-lg shadow-lg p-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-6">Confirm Your Booking</h1>

          {/* Booking Summary */}
          <div className="mb-8 p-6 bg-gray-50 rounded-lg">
            <h2 className="text-xl font-semibold text-gray-900 mb-4 flex items-center">
              <FaHotel className="mr-2 text-primary-600" />
              Booking Summary
            </h2>

            <div className="space-y-4">
              <div>
                <p className="text-sm text-gray-500">Hotel</p>
                <p className="text-lg font-semibold text-gray-900">{hotelName}</p>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <p className="text-sm text-gray-500 flex items-center">
                    <FaCalendarAlt className="mr-2" />
                    Check-in
                  </p>
                  <p className="font-medium text-gray-900">{checkIn}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-500 flex items-center">
                    <FaCalendarAlt className="mr-2" />
                    Check-out
                  </p>
                  <p className="font-medium text-gray-900">{checkOut}</p>
                </div>
              </div>

              <div className="grid grid-cols-3 gap-4">
                <div>
                  <p className="text-sm text-gray-500 flex items-center">
                    <FaBed className="mr-2" />
                    Rooms
                  </p>
                  <p className="font-medium text-gray-900">{rooms}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-500 flex items-center">
                    <FaUsers className="mr-2" />
                    Adults
                  </p>
                  <p className="font-medium text-gray-900">{adults}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-500 flex items-center">
                    <FaChild className="mr-2" />
                    Children
                  </p>
                  <p className="font-medium text-gray-900">{children}</p>
                </div>
              </div>

              <div className="pt-4 border-t border-gray-200">
                <div className="flex justify-between items-center mb-2">
                  <span className="text-gray-600">{rooms} room{rooms > 1 ? 's' : ''} × {nights} night{nights > 1 ? 's' : ''}</span>
                  <span className="font-medium text-gray-900">${totalPrice / rooms / nights} per night</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-xl font-bold text-gray-900 flex items-center">
                    <FaDollarSign />
                    Total
                  </span>
                  <span className="text-2xl font-bold text-primary-600">${totalPrice}</span>
                </div>
              </div>
            </div>
          </div>

          {/* Payment Method */}
          <div className="mb-8">
            <h2 className="text-xl font-semibold text-gray-900 mb-4 flex items-center">
              <FaCreditCard className="mr-2 text-primary-600" />
              Payment Method
            </h2>
            <div className="p-4 border-2 border-primary-600 rounded-lg bg-primary-50">
              <p className="font-medium text-gray-900">OTP-Based Payment Verification</p>
              <p className="text-sm text-gray-600 mt-1">You will receive a 6-digit OTP to verify payment</p>
            </div>
          </div>



          {/* Status Messages */}
          {processing && (
            <div className="mb-6 p-4 bg-blue-50 border border-blue-200 rounded-lg">
              <div className="flex items-center space-x-3">
                <FaSpinner className="animate-spin text-blue-600 text-xl" />
                <div>
                  <p className="font-medium text-blue-900">Creating your booking...</p>
                  <p className="text-sm text-blue-700">Please wait, this may take a few moments</p>
                </div>
              </div>
            </div>
          )}

          {/* Action Buttons */}
          <div className="flex space-x-4">
            <button
              onClick={handleConfirmBooking}
              disabled={processing}
              className={`flex-1 py-4 rounded-lg font-semibold text-white transition-all flex items-center justify-center space-x-2 ${
                processing
                  ? 'bg-gray-400 cursor-not-allowed'
                  : 'bg-primary-600 hover:bg-primary-700 shadow-lg hover:shadow-xl'
              }`}
            >
              {processing ? (
                <>
                  <FaSpinner className="animate-spin" />
                  <span>Creating Booking...</span>
                </>
              ) : (
                <>
                  <FaCheckCircle />
                  <span>Confirm Booking</span>
                </>
              )}
            </button>

            <button
              onClick={() => router.back()}
              disabled={processing}
              className="px-6 py-4 border-2 border-gray-300 rounded-lg font-semibold text-gray-700 hover:bg-gray-50 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Cancel
            </button>
          </div>

          {/* Info */}
          <div className="mt-6 p-4 bg-green-50 border border-green-200 rounded-lg">
            <p className="text-sm text-green-800">
              <strong>✅ Booking Flow:</strong> Your booking will be created and sent to our system via Kafka.
              You will be redirected to your reservations page to view your booking.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}

export default function BookingConfirmPage() {
  return (
    <Suspense fallback={
      <div className="min-h-screen bg-gray-50">
        <Navbar />
        <div className="flex items-center justify-center h-64">
          <FaSpinner className="animate-spin text-4xl text-primary-600" />
        </div>
      </div>
    }>
      <BookingConfirmPageContent />
    </Suspense>
  );
}

