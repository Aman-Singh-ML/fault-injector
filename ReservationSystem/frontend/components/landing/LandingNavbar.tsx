'use client';

import Link from 'next/link';
import { FaHotel } from 'react-icons/fa';

export function LandingNavbar() {
  return (
    <nav className="bg-white shadow-sm">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between h-16 items-center">
          <div className="flex items-center space-x-2">
            <FaHotel className="text-primary-600 text-3xl" />
            <span className="text-xl font-bold text-gray-800">HotelBook</span>
          </div>
          <div className="flex items-center space-x-4">
            <Link
              href="/login"
              className="px-4 py-2 text-sm font-medium text-gray-700 hover:text-primary-600"
            >
              Login
            </Link>
            <Link
              href="/register"
              className="px-4 py-2 text-sm font-medium text-white bg-primary-600 rounded-md hover:bg-primary-700"
            >
              Sign Up
            </Link>
          </div>
        </div>
      </div>
    </nav>
  );
}

