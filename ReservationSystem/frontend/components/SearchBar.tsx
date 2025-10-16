'use client';

import { useState } from 'react';
import { FaSearch, FaMapMarkerAlt, FaCalendarAlt, FaDollarSign, FaStar, FaFilter, FaTimes } from 'react-icons/fa';
import RoomGuestSelector from './RoomGuestSelector';

interface SearchBarProps {
  onSearch: (filters: any) => void;
}

export default function SearchBar({ onSearch }: SearchBarProps) {
  const [city, setCity] = useState('');
  const [checkIn, setCheckIn] = useState('');
  const [checkOut, setCheckOut] = useState('');
  const [rooms, setRooms] = useState(1);
  const [adults, setAdults] = useState(2);
  const [children, setChildren] = useState(0);
  const [minPrice, setMinPrice] = useState('');
  const [maxPrice, setMaxPrice] = useState('');
  const [minRating, setMinRating] = useState('');
  const [showAdvanced, setShowAdvanced] = useState(false);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    const filters: any = {};

    if (city) filters.city = city;
    if (checkIn) filters.checkIn = checkIn;
    if (checkOut) filters.checkOut = checkOut;
    if (rooms) filters.rooms = rooms;
    if (adults) filters.adults = adults;
    if (children) filters.children = children;
    if (minPrice) filters.minPrice = parseFloat(minPrice);
    if (maxPrice) filters.maxPrice = parseFloat(maxPrice);
    if (minRating) filters.minRating = parseFloat(minRating);

    onSearch(filters);
  };

  const handleClearFilters = () => {
    setCity('');
    setCheckIn('');
    setCheckOut('');
    setRooms(1);
    setAdults(2);
    setChildren(0);
    setMinPrice('');
    setMaxPrice('');
    setMinRating('');
    onSearch({});
  };

  const handleRoomGuestUpdate = (newRooms: number, newAdults: number, newChildren: number) => {
    setRooms(newRooms);
    setAdults(newAdults);
    setChildren(newChildren);
  };

  const today = new Date().toISOString().split('T')[0];

  return (
    <div className="bg-white rounded-xl shadow-lg mb-8 overflow-visible relative z-20">
      {/* Main Search Bar */}
      <div className="bg-gradient-to-r from-primary-600 to-primary-700 p-6 rounded-t-xl">
        <form onSubmit={handleSearch}>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
            {/* City */}
            <div className="lg:col-span-2">
              <label className="block text-sm font-medium text-white mb-2">
                <FaMapMarkerAlt className="inline mr-2" />
                Destination
              </label>
              <input
                type="text"
                value={city}
                onChange={(e) => setCity(e.target.value)}
                placeholder="Where are you going?"
                className="w-full px-4 py-3 border-0 rounded-lg focus:ring-2 focus:ring-white text-gray-900 bg-white placeholder-gray-500"
              />
            </div>

            {/* Check-in */}
            <div>
              <label className="block text-sm font-medium text-white mb-2">
                <FaCalendarAlt className="inline mr-2" />
                Check-in
              </label>
              <input
                type="date"
                value={checkIn}
                onChange={(e) => setCheckIn(e.target.value)}
                min={today}
                className="w-full px-4 py-3 border-0 rounded-lg focus:ring-2 focus:ring-white text-gray-900 bg-white"
              />
            </div>

            {/* Check-out */}
            <div>
              <label className="block text-sm font-medium text-white mb-2">
                <FaCalendarAlt className="inline mr-2" />
                Check-out
              </label>
              <input
                type="date"
                value={checkOut}
                onChange={(e) => setCheckOut(e.target.value)}
                min={checkIn || today}
                className="w-full px-4 py-3 border-0 rounded-lg focus:ring-2 focus:ring-white text-gray-900 bg-white"
              />
            </div>

            {/* Rooms & Guests */}
            <RoomGuestSelector
              rooms={rooms}
              adults={adults}
              children={children}
              onUpdate={handleRoomGuestUpdate}
              variant="gradient"
            />
          </div>

          {/* Search and Filter Buttons */}
          <div className="mt-4 flex flex-col sm:flex-row gap-3">
            <button
              type="submit"
              className="flex-1 bg-white text-primary-600 py-3 px-6 rounded-lg hover:bg-gray-50 transition-all duration-200 flex items-center justify-center space-x-2 font-semibold shadow-md hover:shadow-lg"
            >
              <FaSearch />
              <span>Search Hotels</span>
            </button>
            
            <button
              type="button"
              onClick={() => setShowAdvanced(!showAdvanced)}
              className="bg-primary-800 text-white py-3 px-6 rounded-lg hover:bg-primary-900 transition-all duration-200 flex items-center justify-center space-x-2 font-medium"
            >
              <FaFilter />
              <span>{showAdvanced ? 'Hide Filters' : 'More Filters'}</span>
            </button>

            {(city || checkIn || checkOut || minPrice || maxPrice || minRating) && (
              <button
                type="button"
                onClick={handleClearFilters}
                className="bg-red-500 text-white py-3 px-6 rounded-lg hover:bg-red-600 transition-all duration-200 flex items-center justify-center space-x-2 font-medium"
              >
                <FaTimes />
                <span>Clear</span>
              </button>
            )}
          </div>
        </form>
      </div>

      {/* Advanced Filters */}
      {showAdvanced && (
        <div className="p-6 bg-gray-50 border-t border-gray-200 rounded-b-xl">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Advanced Filters</h3>
          
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {/* Price Range */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-3">
                <FaDollarSign className="inline mr-2 text-primary-600" />
                Price Range (per night)
              </label>
              <div className="flex items-center space-x-3">
                <input
                  type="number"
                  value={minPrice}
                  onChange={(e) => setMinPrice(e.target.value)}
                  placeholder="Min"
                  className="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent text-gray-900 bg-white"
                />
                <span className="text-gray-500">-</span>
                <input
                  type="number"
                  value={maxPrice}
                  onChange={(e) => setMaxPrice(e.target.value)}
                  placeholder="Max"
                  className="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent text-gray-900 bg-white"
                />
              </div>
            </div>

            {/* Rating */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-3">
                <FaStar className="inline mr-2 text-primary-600" />
                Minimum Rating
              </label>
              <select
                value={minRating}
                onChange={(e) => setMinRating(e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent text-gray-900 bg-white"
              >
                <option value="">Any rating</option>
                <option value="3">3+ Stars</option>
                <option value="3.5">3.5+ Stars</option>
                <option value="4">4+ Stars</option>
                <option value="4.5">4.5+ Stars</option>
                <option value="5">5 Stars</option>
              </select>
            </div>

            {/* Quick Price Filters */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-3">
                Quick Price Filters
              </label>
              <div className="flex flex-wrap gap-2">
                <button
                  type="button"
                  onClick={() => { setMinPrice(''); setMaxPrice('200'); handleSearch(new Event('submit') as any); }}
                  className="px-4 py-2 bg-white border border-gray-300 rounded-lg hover:bg-primary-50 hover:border-primary-500 transition-colors text-sm font-medium text-gray-700"
                >
                  Under $200
                </button>
                <button
                  type="button"
                  onClick={() => { setMinPrice('200'); setMaxPrice('400'); handleSearch(new Event('submit') as any); }}
                  className="px-4 py-2 bg-white border border-gray-300 rounded-lg hover:bg-primary-50 hover:border-primary-500 transition-colors text-sm font-medium text-gray-700"
                >
                  $200 - $400
                </button>
                <button
                  type="button"
                  onClick={() => { setMinPrice('400'); setMaxPrice(''); handleSearch(new Event('submit') as any); }}
                  className="px-4 py-2 bg-white border border-gray-300 rounded-lg hover:bg-primary-50 hover:border-primary-500 transition-colors text-sm font-medium text-gray-700"
                >
                  $400+
                </button>
              </div>
            </div>
          </div>

          {/* Active Filters Display */}
          {(minPrice || maxPrice || minRating) && (
            <div className="mt-4 pt-4 border-t border-gray-200">
              <div className="flex flex-wrap gap-2">
                <span className="text-sm font-medium text-gray-700">Active filters:</span>
                {minPrice && (
                  <span className="px-3 py-1 bg-primary-100 text-primary-700 rounded-full text-sm font-medium">
                    Min: ${minPrice}
                  </span>
                )}
                {maxPrice && (
                  <span className="px-3 py-1 bg-primary-100 text-primary-700 rounded-full text-sm font-medium">
                    Max: ${maxPrice}
                  </span>
                )}
                {minRating && (
                  <span className="px-3 py-1 bg-primary-100 text-primary-700 rounded-full text-sm font-medium">
                    {minRating}+ Stars
                  </span>
                )}
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
