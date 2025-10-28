'use client';

import { useEffect, useState, Suspense } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { useAuthStore } from '@/store/authStore';
import { hotelsAPI } from '@/lib/api';
import { Hotel } from '@/types';
import Navbar from '@/components/Navbar';
import Footer from '@/components/Footer';
import HotelCard from '@/components/HotelCard';
import RoomGuestSelector from '@/components/RoomGuestSelector';
import toast from 'react-hot-toast';
import { FaSpinner, FaFilter, FaSlidersH } from 'react-icons/fa';

function SearchPageContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { isAuthenticated } = useAuthStore();
  const [hotels, setHotels] = useState<Hotel[]>([]);
  const [loading, setLoading] = useState(true);
  const [showFilters, setShowFilters] = useState(true);
  const [isHydrated, setIsHydrated] = useState(false);

  const [filters, setFilters] = useState({
    city: searchParams.get('city') || '',
    checkIn: searchParams.get('checkIn') || '',
    checkOut: searchParams.get('checkOut') || '',
    rooms: parseInt(searchParams.get('rooms') || '1'),
    adults: parseInt(searchParams.get('adults') || '2'),
    children: parseInt(searchParams.get('children') || '0'),
    minPrice: '',
    maxPrice: '',
    minRating: '',
  });

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

  const fetchHotels = async () => {
    setLoading(true);
    try {
      const searchFilters: any = {};
      if (filters.city) searchFilters.city = filters.city;
      if (filters.checkIn) searchFilters.checkIn = filters.checkIn;
      if (filters.checkOut) searchFilters.checkOut = filters.checkOut;
      if (filters.rooms) searchFilters.rooms = filters.rooms;
      if (filters.adults) searchFilters.adults = filters.adults;
      if (filters.children) searchFilters.children = filters.children;
      if (filters.minPrice) searchFilters.minPrice = parseFloat(filters.minPrice);
      if (filters.maxPrice) searchFilters.maxPrice = parseFloat(filters.maxPrice);
      if (filters.minRating) searchFilters.minRating = parseFloat(filters.minRating);

      const response = await hotelsAPI.search(searchFilters);
      // Ensure we always have an array
      setHotels(Array.isArray(response.data) ? response.data : []);
    } catch (error: any) {
      console.error('Search error:', error);
      toast.error('Failed to fetch hotels');
      setHotels([]); // Set empty array on error
    } finally {
      setLoading(false);
    }
  };

  const handleSearch = () => {
    fetchHotels();
  };

  const handleReset = () => {
    setFilters({
      city: '',
      checkIn: '',
      checkOut: '',
      rooms: 1,
      adults: 2,
      children: 0,
      minPrice: '',
      maxPrice: '',
      minRating: '',
    });
  };

  if (!isAuthenticated) {
    return null;
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <Navbar />
      
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="flex flex-col lg:flex-row gap-6">
          {/* Filters Sidebar */}
          <div className={`lg:w-1/4 ${showFilters ? 'block' : 'hidden lg:block'}`}>
            <div className="bg-white rounded-lg shadow-md p-6 sticky top-4">
              <div className="flex items-center justify-between mb-6">
                <h2 className="text-xl font-bold text-gray-900 flex items-center">
                  <FaSlidersH className="mr-2" />
                  Filters
                </h2>
                <button
                  onClick={handleReset}
                  className="text-sm text-primary-600 hover:text-primary-700"
                >
                  Reset
                </button>
              </div>

              <div className="space-y-6">
                {/* City */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    City
                  </label>
                  <input
                    type="text"
                    value={filters.city}
                    onChange={(e) => setFilters({ ...filters, city: e.target.value })}
                    placeholder="Enter city"
                    className="w-full px-3 py-2 border border-gray-300 rounded-md text-gray-900 bg-white focus:outline-none focus:ring-2 focus:ring-primary-500"
                  />
                </div>

                {/* Check-in Date */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Check-in Date
                  </label>
                  <input
                    type="date"
                    value={filters.checkIn}
                    onChange={(e) => setFilters({ ...filters, checkIn: e.target.value })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md text-gray-900 bg-white focus:outline-none focus:ring-2 focus:ring-primary-500"
                  />
                </div>

                {/* Check-out Date */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Check-out Date
                  </label>
                  <input
                    type="date"
                    value={filters.checkOut}
                    onChange={(e) => setFilters({ ...filters, checkOut: e.target.value })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md text-gray-900 bg-white focus:outline-none focus:ring-2 focus:ring-primary-500"
                  />
                </div>

                {/* Rooms & Guests */}
                <div>
                  <RoomGuestSelector
                    rooms={filters.rooms}
                    adults={filters.adults}
                    children={filters.children}
                    onUpdate={(rooms, adults, children) => {
                      setFilters({ ...filters, rooms, adults, children });
                    }}
                  />
                </div>

                {/* Price Range */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Price Range (per night)
                  </label>
                  <div className="grid grid-cols-2 gap-2">
                    <input
                      type="number"
                      value={filters.minPrice}
                      onChange={(e) => setFilters({ ...filters, minPrice: e.target.value })}
                      placeholder="Min"
                      className="px-3 py-2 border border-gray-300 rounded-md text-gray-900 bg-white focus:outline-none focus:ring-2 focus:ring-primary-500"
                    />
                    <input
                      type="number"
                      value={filters.maxPrice}
                      onChange={(e) => setFilters({ ...filters, maxPrice: e.target.value })}
                      placeholder="Max"
                      className="px-3 py-2 border border-gray-300 rounded-md text-gray-900 bg-white focus:outline-none focus:ring-2 focus:ring-primary-500"
                    />
                  </div>
                </div>

                {/* Minimum Rating */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Minimum Rating
                  </label>
                  <select
                    value={filters.minRating}
                    onChange={(e) => setFilters({ ...filters, minRating: e.target.value })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md text-gray-900 bg-white focus:outline-none focus:ring-2 focus:ring-primary-500"
                  >
                    <option value="">Any</option>
                    <option value="3">3+ Stars</option>
                    <option value="3.5">3.5+ Stars</option>
                    <option value="4">4+ Stars</option>
                    <option value="4.5">4.5+ Stars</option>
                  </select>
                </div>

                {/* Search Button */}
                <button
                  onClick={handleSearch}
                  className="w-full px-4 py-2 bg-primary-600 text-white rounded-md hover:bg-primary-700 transition-colors duration-200"
                >
                  Apply Filters
                </button>
              </div>
            </div>
          </div>

          {/* Hotels List */}
          <div className="lg:w-3/4">
            {/* Mobile Filter Toggle */}
            <button
              onClick={() => setShowFilters(!showFilters)}
              className="lg:hidden mb-4 flex items-center space-x-2 px-4 py-2 bg-white rounded-md shadow-md"
            >
              <FaFilter />
              <span>Filters</span>
            </button>

            {/* Results Header */}
            <div className="flex justify-between items-center mb-6">
              <h1 className="text-2xl font-bold text-gray-900">
                Search Results
              </h1>
              <p className="text-gray-600">
                {hotels.length} {hotels.length === 1 ? 'hotel' : 'hotels'} found
              </p>
            </div>

            {/* Hotels Grid */}
            {loading ? (
              <div className="flex justify-center items-center py-20">
                <FaSpinner className="animate-spin text-4xl text-primary-600" />
              </div>
            ) : hotels.length === 0 ? (
              <div className="text-center py-20 bg-white rounded-lg shadow-md">
                <p className="text-gray-500 text-lg">No hotels found</p>
                <p className="text-gray-400 mt-2">Try adjusting your search filters</p>
              </div>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {hotels.map((hotel) => (
                  <HotelCard key={hotel._id} hotel={hotel} />
                ))}
              </div>
            )}
          </div>
        </div>
      </div>
      <Footer />
    </div>
  );
}

export default function SearchPage() {
  return (
    <Suspense fallback={
      <div className="min-h-screen bg-gray-50">
        <Navbar />
        <div className="flex items-center justify-center h-64">
          <FaSpinner className="animate-spin text-4xl text-primary-600" />
        </div>
      </div>
    }>
      <SearchPageContent />
    </Suspense>
  );
}

