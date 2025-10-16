'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/store/authStore';
import { adminAPI } from '@/lib/api';
import { Hotel } from '@/types';
import Navbar from '@/components/Navbar';
import toast from 'react-hot-toast';
import { FaSpinner, FaEdit, FaTrash, FaPlus, FaStar, FaMapMarkerAlt } from 'react-icons/fa';

export default function AdminHotelsPage() {
  const router = useRouter();
  const { isAuthenticated, user } = useAuthStore();
  const [hotels, setHotels] = useState<Hotel[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!isAuthenticated) {
      router.push('/login');
      return;
    }
    
    if (user?.role !== 'ADMIN') {
      toast.error('Access denied. Admin only.');
      router.push('/dashboard');
      return;
    }

    fetchHotels();
  }, [isAuthenticated, user, router]);

  const fetchHotels = async () => {
    setLoading(true);
    try {
      const response = await adminAPI.getAllHotels();
      setHotels(response.data.hotels || response.data);
    } catch (error: any) {
      toast.error('Failed to fetch hotels');
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteHotel = async (hotelId: string) => {
    if (!confirm('Are you sure you want to delete this hotel?')) {
      return;
    }

    try {
      await adminAPI.deleteHotel(hotelId);
      toast.success('Hotel deleted successfully');
      fetchHotels();
    } catch (error: any) {
      toast.error('Failed to delete hotel');
    }
  };

  if (!isAuthenticated || user?.role !== 'ADMIN') {
    return null;
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <Navbar />
      
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="mb-8 flex justify-between items-center">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">Hotel Management</h1>
            <p className="mt-2 text-gray-600">Manage all hotels in the system</p>
          </div>
          <button
            onClick={() => router.push('/admin/hotels/new')}
            className="flex items-center space-x-2 px-4 py-2 bg-primary-600 text-white rounded-md hover:bg-primary-700"
          >
            <FaPlus />
            <span>Add Hotel</span>
          </button>
        </div>

        {/* Hotels Grid */}
        {loading ? (
          <div className="flex justify-center items-center py-20">
            <FaSpinner className="animate-spin text-4xl text-primary-600" />
          </div>
        ) : hotels.length === 0 ? (
          <div className="text-center py-20 bg-white rounded-lg shadow-md">
            <p className="text-gray-500 text-lg">No hotels found</p>
            <button
              onClick={() => router.push('/admin/hotels/new')}
              className="mt-4 px-4 py-2 bg-primary-600 text-white rounded-md hover:bg-primary-700"
            >
              Add Your First Hotel
            </button>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {hotels.map((hotel) => (
              <div
                key={hotel._id}
                className="bg-white rounded-lg shadow-md overflow-hidden hover:shadow-xl transition-shadow duration-300"
              >
                {/* Hotel Image */}
                <div className="relative h-48 bg-gray-200">
                  {hotel.images && hotel.images.length > 0 ? (
                    <img
                      src={hotel.images[0]}
                      alt={hotel.name}
                      className="w-full h-full object-cover"
                    />
                  ) : (
                    <div className="w-full h-full flex items-center justify-center bg-gradient-to-br from-primary-100 to-primary-200">
                      <span className="text-primary-600 text-4xl font-bold">
                        {hotel.name.charAt(0)}
                      </span>
                    </div>
                  )}
                  
                  {/* Rating Badge */}
                  <div className="absolute top-2 right-2 bg-white px-2 py-1 rounded-md shadow-md flex items-center space-x-1">
                    <FaStar className="text-yellow-400" />
                    <span className="font-semibold text-sm">{hotel.rating.toFixed(1)}</span>
                  </div>
                </div>

                {/* Hotel Info */}
                <div className="p-4">
                  <h3 className="text-lg font-bold text-gray-900 mb-2 truncate">
                    {hotel.name}
                  </h3>
                  
                  <div className="flex items-center text-gray-600 text-sm mb-2">
                    <FaMapMarkerAlt className="mr-1" />
                    <span className="truncate">{hotel.city}, {hotel.address}</span>
                  </div>

                  <p className="text-gray-600 text-sm mb-4 line-clamp-2">
                    {hotel.description}
                  </p>

                  {/* Price and Rooms */}
                  <div className="flex items-center justify-between mb-4 pb-4 border-b border-gray-200">
                    <div>
                      <p className="text-primary-600 font-bold text-xl">
                        ${hotel.price_per_night}
                      </p>
                      <p className="text-gray-500 text-xs">per night</p>
                    </div>
                    <div className="text-right">
                      <p className="text-gray-900 font-semibold">
                        {hotel.available_rooms}
                      </p>
                      <p className="text-gray-500 text-xs">rooms available</p>
                    </div>
                  </div>

                  {/* Actions */}
                  <div className="flex space-x-2">
                    <button
                      onClick={() => router.push(`/admin/hotels/${hotel._id}`)}
                      className="flex-1 px-3 py-2 bg-primary-600 text-white rounded-md hover:bg-primary-700 transition-colors duration-200 text-sm font-medium flex items-center justify-center space-x-1"
                    >
                      <FaEdit />
                      <span>Edit</span>
                    </button>
                    <button
                      onClick={() => handleDeleteHotel(hotel._id)}
                      className="flex-1 px-3 py-2 bg-red-600 text-white rounded-md hover:bg-red-700 transition-colors duration-200 text-sm font-medium flex items-center justify-center space-x-1"
                    >
                      <FaTrash />
                      <span>Delete</span>
                    </button>
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

