'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/store/authStore';
import { hotelsAPI } from '@/lib/api';
import { Hotel } from '@/types';
import Navbar from '@/components/Navbar';
import HotelCard from '@/components/HotelCard';
import SearchBar from '@/components/SearchBar';
import toast from 'react-hot-toast';
import { FaSpinner } from 'react-icons/fa';

export default function DashboardPage() {
  const router = useRouter();
  const { isAuthenticated, user } = useAuthStore();
  const [hotels, setHotels] = useState<Hotel[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchFilters, setSearchFilters] = useState({});
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
    fetchHotels();
  }, [isAuthenticated, isHydrated, router]);

  const fetchHotels = async (filters = {}) => {
    setLoading(true);
    try {
      const response = await hotelsAPI.search(filters);
      setHotels(response.data);
    } catch (error: any) {
      toast.error('Failed to fetch hotels');
    } finally {
      setLoading(false);
    }
  };

  const handleSearch = (filters: any) => {
    setSearchFilters(filters);
    fetchHotels(filters);
  };

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
        {/* Welcome Section */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900">
            Welcome back, {user?.firstName}!
          </h1>
          <p className="mt-2 text-gray-600">
            Find and book your perfect hotel stay
          </p>
        </div>

        {/* Search Bar */}
        <div className="mb-8 relative z-10">
          <SearchBar onSearch={handleSearch} />
        </div>

        {/* Hotels Grid */}
        <div>
          <div className="flex justify-between items-center mb-6">
            <h2 className="text-2xl font-bold text-gray-900">
              Available Hotels
            </h2>
            <p className="text-gray-600">
              {hotels.length} {hotels.length === 1 ? 'hotel' : 'hotels'} found
            </p>
          </div>

          {loading ? (
            <div className="flex justify-center items-center py-20">
              <FaSpinner className="animate-spin text-4xl text-primary-600" />
            </div>
          ) : hotels.length === 0 ? (
            <div className="text-center py-20">
              <p className="text-gray-500 text-lg">No hotels found</p>
              <p className="text-gray-400 mt-2">Try adjusting your search filters</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {hotels.map((hotel) => (
                <HotelCard key={hotel._id} hotel={hotel} />
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

