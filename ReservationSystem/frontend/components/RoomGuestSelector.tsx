'use client';

import { useState, useRef, useEffect } from 'react';
import { FaUsers, FaMinus, FaPlus, FaBed, FaChild } from 'react-icons/fa';

interface RoomGuestSelectorProps {
  rooms: number;
  adults: number;
  children: number;
  onUpdate: (rooms: number, adults: number, children: number) => void;
  variant?: 'default' | 'gradient'; // default for white bg, gradient for colored bg
}

export default function RoomGuestSelector({ rooms, adults, children, onUpdate, variant = 'default' }: RoomGuestSelectorProps) {
  const [isOpen, setIsOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);

  const isGradient = variant === 'gradient';

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const updateRooms = (delta: number) => {
    const newRooms = Math.max(1, Math.min(10, rooms + delta));
    onUpdate(newRooms, adults, children);
  };

  const updateAdults = (delta: number) => {
    const newAdults = Math.max(1, Math.min(30, adults + delta));
    onUpdate(rooms, newAdults, children);
  };

  const updateChildren = (delta: number) => {
    const newChildren = Math.max(0, Math.min(10, children + delta));
    onUpdate(rooms, adults, newChildren);
  };

  const totalGuests = adults + children;

  return (
    <div className="relative" ref={dropdownRef}>
      <label className={`block text-sm font-medium mb-2 ${isGradient ? 'text-white' : 'text-gray-700'}`}>
        <FaUsers className="inline mr-2" />
        Rooms & Guests
      </label>

      <button
        type="button"
        onClick={() => setIsOpen(!isOpen)}
        className={`w-full px-4 py-3 rounded-lg text-gray-900 bg-white text-left flex items-center justify-between transition-colors ${
          isGradient
            ? 'border-0 focus:ring-2 focus:ring-white hover:bg-gray-50'
            : 'border border-gray-300 focus:ring-2 focus:ring-primary-500 hover:border-gray-400'
        }`}
      >
        <span>
          {rooms} Room{rooms > 1 ? 's' : ''}, {totalGuests} Guest{totalGuests > 1 ? 's' : ''}
        </span>
        <svg
          className={`w-5 h-5 transition-transform ${isOpen ? 'rotate-180' : ''}`}
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
        </svg>
      </button>

      {isOpen && (
        <div className="absolute z-[100] mt-2 w-full min-w-[320px] bg-white rounded-lg shadow-xl border border-gray-200 p-4">
          {/* Rooms */}
          <div className="flex items-center justify-between py-3 border-b border-gray-200 gap-4">
            <div className="flex items-center flex-1 min-w-0">
              <FaBed className="text-primary-600 mr-3 text-lg flex-shrink-0" />
              <div className="flex-1 min-w-0">
                <div className="font-semibold text-gray-900 text-sm">Rooms</div>
                <div className="text-xs text-gray-500">Number of rooms</div>
              </div>
            </div>
            <div className="flex items-center space-x-2 flex-shrink-0">
              <button
                type="button"
                onClick={() => updateRooms(-1)}
                disabled={rooms <= 1}
                className="w-8 h-8 flex-shrink-0 rounded-full border-2 border-primary-600 text-primary-600 flex items-center justify-center hover:bg-primary-50 disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
              >
                <FaMinus className="text-xs" />
              </button>
              <span className="w-8 text-center font-semibold text-gray-900 flex-shrink-0">{rooms}</span>
              <button
                type="button"
                onClick={() => updateRooms(1)}
                disabled={rooms >= 10}
                className="w-8 h-8 flex-shrink-0 rounded-full border-2 border-primary-600 text-primary-600 flex items-center justify-center hover:bg-primary-50 disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
              >
                <FaPlus className="text-xs" />
              </button>
            </div>
          </div>

          {/* Adults */}
          <div className="flex items-center justify-between py-3 border-b border-gray-200 gap-4">
            <div className="flex items-center flex-1 min-w-0">
              <FaUsers className="text-primary-600 mr-3 text-lg flex-shrink-0" />
              <div className="flex-1 min-w-0">
                <div className="font-semibold text-gray-900 text-sm">Adults</div>
                <div className="text-xs text-gray-500">Ages 13 or above</div>
              </div>
            </div>
            <div className="flex items-center space-x-2 flex-shrink-0">
              <button
                type="button"
                onClick={() => updateAdults(-1)}
                disabled={adults <= 1}
                className="w-8 h-8 flex-shrink-0 rounded-full border-2 border-primary-600 text-primary-600 flex items-center justify-center hover:bg-primary-50 disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
              >
                <FaMinus className="text-xs" />
              </button>
              <span className="w-8 text-center font-semibold text-gray-900 flex-shrink-0">{adults}</span>
              <button
                type="button"
                onClick={() => updateAdults(1)}
                disabled={adults >= 30}
                className="w-8 h-8 flex-shrink-0 rounded-full border-2 border-primary-600 text-primary-600 flex items-center justify-center hover:bg-primary-50 disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
              >
                <FaPlus className="text-xs" />
              </button>
            </div>
          </div>

          {/* Children */}
          <div className="flex items-center justify-between py-3 gap-4">
            <div className="flex items-center flex-1 min-w-0">
              <FaChild className="text-primary-600 mr-3 text-lg flex-shrink-0" />
              <div className="flex-1 min-w-0">
                <div className="font-semibold text-gray-900 text-sm">Children</div>
                <div className="text-xs text-gray-500">Ages 0-12</div>
              </div>
            </div>
            <div className="flex items-center space-x-2 flex-shrink-0">
              <button
                type="button"
                onClick={() => updateChildren(-1)}
                disabled={children <= 0}
                className="w-8 h-8 flex-shrink-0 rounded-full border-2 border-primary-600 text-primary-600 flex items-center justify-center hover:bg-primary-50 disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
              >
                <FaMinus className="text-xs" />
              </button>
              <span className="w-8 text-center font-semibold text-gray-900 flex-shrink-0">{children}</span>
              <button
                type="button"
                onClick={() => updateChildren(1)}
                disabled={children >= 10}
                className="w-8 h-8 flex-shrink-0 rounded-full border-2 border-primary-600 text-primary-600 flex items-center justify-center hover:bg-primary-50 disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
              >
                <FaPlus className="text-xs" />
              </button>
            </div>
          </div>

          {/* Done Button */}
          <button
            type="button"
            onClick={() => setIsOpen(false)}
            className="w-full mt-3 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition-colors font-medium"
          >
            Done
          </button>
        </div>
      )}
    </div>
  );
}

