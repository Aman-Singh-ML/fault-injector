'use client';

import { useEffect, useState } from 'react';
import { useRouter, useParams } from 'next/navigation';
import { useAuthStore } from '@/store/authStore';
import { hotelsAPI } from '@/lib/api';
import { Hotel } from '@/types';
import Navbar from '@/components/Navbar';
import RoomGuestSelector from '@/components/RoomGuestSelector';
import toast from 'react-hot-toast';
import { 
  FaStar, 
  FaMapMarkerAlt, 
  FaPhone, 
  FaEnvelope, 
  FaWifi, 
  FaSwimmingPool, 
  FaDumbbell, 
  FaUtensils,
  FaSpa,
  FaParking,
  FaConciergeBell,
  FaChevronLeft,
  FaChevronRight,
  FaCheck
} from 'react-icons/fa';

export default function HotelDetailsPage() {
  const router = useRouter();
  const params = useParams();
  const { isAuthenticated } = useAuthStore();
  const [hotel, setHotel] = useState<Hotel | null>(null);
  const [loading, setLoading] = useState(true);
  const [currentImageIndex, setCurrentImageIndex] = useState(0);
  const [checkInDate, setCheckInDate] = useState('');
  const [checkOutDate, setCheckOutDate] = useState('');
  const [rooms, setRooms] = useState(1);
  const [adults, setAdults] = useState(2);
  const [children, setChildren] = useState(0);

  useEffect(() => {
    if (!isAuthenticated) {
      router.push('/login');
      return;
    }
    fetchHotelDetails();
  }, [isAuthenticated, params.id]);

  const fetchHotelDetails = async () => {
    setLoading(true);
    try {
      const response = await hotelsAPI.getById(params.id as string);
      setHotel(response.data);
    } catch (error: any) {
      toast.error('Failed to fetch hotel details');
      router.push('/dashboard');
    } finally {
      setLoading(false);
    }
  };

  const handleBookNow = () => {
    if (!checkInDate || !checkOutDate) {
      toast.error('Please select check-in and check-out dates');
      return;
    }

    const checkIn = new Date(checkInDate);
    const checkOut = new Date(checkOutDate);
    const nights = Math.ceil((checkOut.getTime() - checkIn.getTime()) / (1000 * 60 * 60 * 24));

    if (nights <= 0) {
      toast.error('Check-out date must be after check-in date');
      return;
    }

    const totalPrice = nights * rooms * (hotel?.price_per_night || 0);

    // Navigate to booking confirmation page
    router.push(`/booking-confirm?hotelId=${hotel?._id}&hotelName=${encodeURIComponent(hotel?.name || '')}&checkIn=${checkInDate}&checkOut=${checkOutDate}&rooms=${rooms}&adults=${adults}&children=${children}&totalPrice=${totalPrice}`);
  };

  const nextImage = () => {
    if (hotel && hotel.images.length > 0) {
      setCurrentImageIndex((prev) => (prev + 1) % hotel.images.length);
    }
  };

  const prevImage = () => {
    if (hotel && hotel.images.length > 0) {
      setCurrentImageIndex((prev) => (prev - 1 + hotel.images.length) % hotel.images.length);
    }
  };

  const getAmenityIcon = (amenity: string) => {
    const amenityLower = amenity.toLowerCase();
    if (amenityLower.includes('wifi')) return <FaWifi />;
    if (amenityLower.includes('pool')) return <FaSwimmingPool />;
    if (amenityLower.includes('gym')) return <FaDumbbell />;
    if (amenityLower.includes('restaurant')) return <FaUtensils />;
    if (amenityLower.includes('spa')) return <FaSpa />;
    if (amenityLower.includes('parking')) return <FaParking />;
    return <FaConciergeBell />;
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50">
        <Navbar />
        <div className="flex items-center justify-center h-screen">
          <div className="animate-spin rounded-full h-16 w-16 border-t-2 border-b-2 border-primary-600"></div>
        </div>
      </div>
    );
  }

  if (!hotel) {
    return null;
  }

  // Get today's date for min date
  const today = new Date().toISOString().split('T')[0];

  return (
    <div className="min-h-screen bg-gray-50">
      <Navbar />
      
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Back Button */}
        <button
          onClick={() => router.back()}
          className="mb-6 flex items-center text-gray-600 hover:text-gray-900 transition-colors"
        >
          <FaChevronLeft className="mr-2" />
          Back to search
        </button>

        {/* Hotel Images Gallery */}
        <div className="bg-white rounded-lg shadow-lg overflow-hidden mb-8">
          <div className="relative h-96 md:h-[500px] bg-gray-200">
            {hotel.images && hotel.images.length > 0 ? (
              <>
                <img
                  src={hotel.images[currentImageIndex]}
                  alt={hotel.name}
                  className="w-full h-full object-cover"
                />
                {hotel.images.length > 1 && (
                  <>
                    <button
                      onClick={prevImage}
                      className="absolute left-4 top-1/2 transform -translate-y-1/2 bg-white/90 hover:bg-white p-3 rounded-full shadow-lg transition-all"
                    >
                      <FaChevronLeft className="text-gray-800" />
                    </button>
                    <button
                      onClick={nextImage}
                      className="absolute right-4 top-1/2 transform -translate-y-1/2 bg-white/90 hover:bg-white p-3 rounded-full shadow-lg transition-all"
                    >
                      <FaChevronRight className="text-gray-800" />
                    </button>
                    <div className="absolute bottom-4 left-1/2 transform -translate-x-1/2 flex space-x-2">
                      {hotel.images.map((_, index) => (
                        <button
                          key={index}
                          onClick={() => setCurrentImageIndex(index)}
                          className={`w-2 h-2 rounded-full transition-all ${
                            index === currentImageIndex ? 'bg-white w-8' : 'bg-white/60'
                          }`}
                        />
                      ))}
                    </div>
                  </>
                )}
              </>
            ) : (
              <div className="w-full h-full flex items-center justify-center bg-gradient-to-br from-primary-100 to-primary-200">
                <span className="text-primary-600 text-6xl font-bold">
                  {hotel.name.charAt(0)}
                </span>
              </div>
            )}
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Left Column - Hotel Details */}
          <div className="lg:col-span-2 space-y-6">
            {/* Hotel Header */}
            <div className="bg-white rounded-lg shadow-md p-6">
              <div className="flex items-start justify-between mb-4">
                <div>
                  <h1 className="text-3xl font-bold text-gray-900 mb-2">{hotel.name}</h1>
                  <div className="flex items-center text-gray-600 mb-2">
                    <FaMapMarkerAlt className="mr-2 text-primary-600" />
                    <span>{hotel.address}, {hotel.city}</span>
                  </div>
                </div>
                <div className="flex items-center bg-primary-600 text-white px-4 py-2 rounded-lg">
                  <FaStar className="mr-2" />
                  <span className="text-2xl font-bold">{hotel.rating.toFixed(1)}</span>
                </div>
              </div>

              <div className="flex items-center space-x-6 text-sm text-gray-600">
                {hotel.contact && (
                  <>
                    <div className="flex items-center">
                      <FaPhone className="mr-2 text-primary-600" />
                      <span>{hotel.contact.phone}</span>
                    </div>
                    <div className="flex items-center">
                      <FaEnvelope className="mr-2 text-primary-600" />
                      <span>{hotel.contact.email}</span>
                    </div>
                  </>
                )}
              </div>
            </div>

            {/* Description */}
            <div className="bg-white rounded-lg shadow-md p-6">
              <h2 className="text-2xl font-bold text-gray-900 mb-4">About this property</h2>
              <p className="text-gray-700 leading-relaxed">{hotel.description}</p>
            </div>

            {/* Amenities */}
            <div className="bg-white rounded-lg shadow-md p-6">
              <h2 className="text-2xl font-bold text-gray-900 mb-4">Amenities</h2>
              <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
                {hotel.amenities.map((amenity, index) => (
                  <div key={index} className="flex items-center space-x-3 text-gray-700">
                    <div className="text-primary-600 text-xl">
                      {getAmenityIcon(amenity)}
                    </div>
                    <span>{amenity}</span>
                  </div>
                ))}
              </div>
            </div>

            {/* Room Availability */}
            <div className="bg-white rounded-lg shadow-md p-6">
              <h2 className="text-2xl font-bold text-gray-900 mb-4">Availability</h2>
              <div className="flex items-center space-x-4">
                <div className="flex-1">
                  <div className="text-sm text-gray-600 mb-1">Total Rooms</div>
                  <div className="text-2xl font-bold text-gray-900">{hotel.total_rooms}</div>
                </div>
                <div className="flex-1">
                  <div className="text-sm text-gray-600 mb-1">Available Rooms</div>
                  <div className={`text-2xl font-bold ${hotel.available_rooms > 0 ? 'text-green-600' : 'text-red-600'}`}>
                    {hotel.available_rooms}
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Right Column - Booking Card */}
          <div className="lg:col-span-1">
            <div className="bg-white rounded-lg shadow-lg p-6 sticky top-24">
              <div className="mb-6">
                <div className="text-sm text-gray-600 mb-1">Price per night</div>
                <div className="text-4xl font-bold text-primary-600">
                  ${hotel.price_per_night}
                </div>
              </div>

              <div className="space-y-4 mb-6">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Check-in Date
                  </label>
                  <input
                    type="date"
                    value={checkInDate}
                    onChange={(e) => setCheckInDate(e.target.value)}
                    min={today}
                    className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent text-gray-900 bg-white"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Check-out Date
                  </label>
                  <input
                    type="date"
                    value={checkOutDate}
                    onChange={(e) => setCheckOutDate(e.target.value)}
                    min={checkInDate || today}
                    className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent text-gray-900 bg-white"
                  />
                </div>

                <div>
                  <RoomGuestSelector
                    rooms={rooms}
                    adults={adults}
                    children={children}
                    onUpdate={(newRooms, newAdults, newChildren) => {
                      setRooms(newRooms);
                      setAdults(newAdults);
                      setChildren(newChildren);
                    }}
                  />
                </div>
              </div>

              {checkInDate && checkOutDate && (
                <div className="mb-6 p-4 bg-gray-50 rounded-lg">
                  <div className="flex justify-between text-sm mb-2">
                    <span className="text-gray-600">
                      ${hotel.price_per_night} × {Math.ceil((new Date(checkOutDate).getTime() - new Date(checkInDate).getTime()) / (1000 * 60 * 60 * 24))} nights × {rooms} room{rooms > 1 ? 's' : ''}
                    </span>
                    <span className="font-semibold text-gray-900">
                      ${hotel.price_per_night * Math.ceil((new Date(checkOutDate).getTime() - new Date(checkInDate).getTime()) / (1000 * 60 * 60 * 24)) * rooms}
                    </span>
                  </div>
                  <div className="text-xs text-gray-500 mb-2">
                    {rooms} room{rooms > 1 ? 's' : ''} • {adults} adult{adults > 1 ? 's' : ''} {children > 0 && `• ${children} child${children > 1 ? 'ren' : ''}`}
                  </div>
                  <div className="border-t border-gray-200 pt-2 mt-2">
                    <div className="flex justify-between">
                      <span className="font-bold text-gray-900">Total</span>
                      <span className="font-bold text-primary-600 text-xl">
                        ${hotel.price_per_night * Math.ceil((new Date(checkOutDate).getTime() - new Date(checkInDate).getTime()) / (1000 * 60 * 60 * 24)) * rooms}
                      </span>
                    </div>
                  </div>
                </div>
              )}

              <button
                onClick={handleBookNow}
                disabled={hotel.available_rooms === 0}
                className={`w-full py-4 rounded-lg font-semibold text-white transition-all ${
                  hotel.available_rooms === 0
                    ? 'bg-gray-400 cursor-not-allowed'
                    : 'bg-primary-600 hover:bg-primary-700 shadow-lg hover:shadow-xl'
                }`}
              >
                {hotel.available_rooms === 0 ? 'Sold Out' : 'Reserve Now'}
              </button>

              <div className="mt-4 space-y-2">
                <div className="flex items-center text-sm text-gray-600">
                  <FaCheck className="text-green-600 mr-2" />
                  <span>Free cancellation</span>
                </div>
                <div className="flex items-center text-sm text-gray-600">
                  <FaCheck className="text-green-600 mr-2" />
                  <span>No prepayment needed</span>
                </div>
                <div className="flex items-center text-sm text-gray-600">
                  <FaCheck className="text-green-600 mr-2" />
                  <span>Instant confirmation</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

