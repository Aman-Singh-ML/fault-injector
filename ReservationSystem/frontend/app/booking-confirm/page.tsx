'use client';

import { useEffect, useState, Suspense } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { useAuthStore } from '@/store/authStore';
import { bookingsAPI, paymentAPI } from '@/lib/api';
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
      // Step 1: Create booking
      toast.loading('Creating booking...', { id: 'booking' });

      const bookingResponse = await bookingsAPI.create({
        userId: user.id,
        hotelId: hotelId!,
        hotelName: hotelName || '',
        checkInDate: checkIn!,
        checkOutDate: checkOut!,
        rooms,
        adults,
        children,
        totalPrice
      });

      const newBooking = bookingResponse.data;
      setBookingId(newBooking.id);
      setBookingCreated(true);

      toast.success('Booking created!', { id: 'booking' });

      // Step 2: Initiate payment and get OTP
      toast.loading('Generating payment OTP...', { id: 'payment' });

      const paymentResponse = await paymentAPI.initiate({
        bookingId: newBooking.id,
        userId: user.id,
        amount: totalPrice
      });

      const payment = paymentResponse.data;
      setPaymentId(payment.paymentId.toString());
      setGeneratedOTP(payment.otp);

      toast.success('OTP generated! Please verify to complete payment.', { id: 'payment' });

      // Show OTP input
      setShowOTPInput(true);
      setProcessing(false);
      setLoading(false);

    } catch (error: any) {
      console.error('Booking error:', error);

      if (error.response?.data?.code === 'INSUFFICIENT_INVENTORY') {
        toast.error('Sorry, not enough rooms available for selected dates', { id: 'booking' });
      } else {
        toast.error(error.response?.data?.error || 'Failed to create booking', { id: 'booking' });
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

          {/* OTP Display and Input */}
          {showOTPInput && (
            <div className="mb-8 p-6 bg-gradient-to-r from-green-50 to-blue-50 border-2 border-green-300 rounded-lg">
              <h3 className="text-lg font-semibold text-gray-900 mb-4">🔐 Payment OTP Verification</h3>

              {/* Display Generated OTP */}
              <div className="mb-6 p-4 bg-white rounded-lg border-2 border-green-500">
                <p className="text-sm text-gray-600 mb-2">Your Payment OTP:</p>
                <p className="text-4xl font-bold text-green-600 tracking-widest text-center">{generatedOTP}</p>
                <p className="text-xs text-gray-500 mt-2 text-center">
                  (In production, this would be sent via SMS/Email)
                </p>
              </div>

              {/* OTP Input */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Enter OTP to Complete Payment:
                </label>
                <input
                  type="text"
                  maxLength={6}
                  value={enteredOTP}
                  onChange={(e) => {
                    setEnteredOTP(e.target.value.replace(/\D/g, ''));
                    setOTPError('');
                  }}
                  placeholder="Enter 6-digit OTP"
                  className="w-full px-4 py-3 text-2xl tracking-widest text-center text-gray-900 bg-white border-2 border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent placeholder-gray-400"
                  disabled={processing}
                />
                {otpError && (
                  <p className="mt-2 text-sm text-red-600">{otpError}</p>
                )}
              </div>

              {/* Verify Button */}
              <button
                onClick={handleVerifyOTP}
                disabled={processing || enteredOTP.length !== 6}
                className={`w-full mt-4 py-3 rounded-lg font-semibold text-white transition-all flex items-center justify-center space-x-2 ${
                  processing || enteredOTP.length !== 6
                    ? 'bg-gray-400 cursor-not-allowed'
                    : 'bg-green-600 hover:bg-green-700 shadow-lg hover:shadow-xl'
                }`}
              >
                {processing ? (
                  <>
                    <FaSpinner className="animate-spin" />
                    <span>Verifying...</span>
                  </>
                ) : (
                  <>
                    <FaCheckCircle />
                    <span>Verify OTP & Complete Payment</span>
                  </>
                )}
              </button>
            </div>
          )}

          {/* Status Messages */}
          {processing && !showOTPInput && (
            <div className="mb-6 p-4 bg-blue-50 border border-blue-200 rounded-lg">
              <div className="flex items-center space-x-3">
                <FaSpinner className="animate-spin text-blue-600 text-xl" />
                <div>
                  <p className="font-medium text-blue-900">
                    {!bookingCreated && 'Creating your booking...'}
                    {bookingCreated && 'Generating payment OTP...'}
                  </p>
                  <p className="text-sm text-blue-700">Please wait, this may take a few moments</p>
                </div>
              </div>
            </div>
          )}

          {/* Action Buttons */}
          {!showOTPInput && (
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
                    <span>Processing...</span>
                  </>
                ) : (
                  <>
                    <FaCheckCircle />
                    <span>Confirm & Generate OTP</span>
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
          )}

          {/* Info */}
          <div className="mt-6 p-4 bg-blue-50 border border-blue-200 rounded-lg">
            <p className="text-sm text-blue-800">
              <strong>Note:</strong> This is an OTP-based payment verification system.
              You will receive a 6-digit OTP that you need to enter to complete the payment.
              No actual payment gateway is integrated.
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

