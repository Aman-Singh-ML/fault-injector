'use client';

import { FaSearch, FaStar, FaShieldAlt, FaHeadset } from 'react-icons/fa';

export function FeaturesSection() {
  return (
    <div className="mt-20 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
      <div className="bg-white rounded-lg shadow-md p-6 text-center hover:shadow-xl transition-shadow duration-200">
        <FaSearch className="mx-auto text-4xl text-primary-600 mb-4" />
        <h3 className="text-lg font-bold text-gray-900 mb-2">Easy Search</h3>
        <p className="text-gray-600 text-sm">
          Find hotels quickly with our advanced search and filters
        </p>
      </div>

      <div className="bg-white rounded-lg shadow-md p-6 text-center hover:shadow-xl transition-shadow duration-200">
        <FaStar className="mx-auto text-4xl text-primary-600 mb-4" />
        <h3 className="text-lg font-bold text-gray-900 mb-2">Best Prices</h3>
        <p className="text-gray-600 text-sm">
          Competitive rates and exclusive deals for our members
        </p>
      </div>

      <div className="bg-white rounded-lg shadow-md p-6 text-center hover:shadow-xl transition-shadow duration-200">
        <FaShieldAlt className="mx-auto text-4xl text-primary-600 mb-4" />
        <h3 className="text-lg font-bold text-gray-900 mb-2">Secure Booking</h3>
        <p className="text-gray-600 text-sm">
          Safe and secure payment processing with data protection
        </p>
      </div>

      <div className="bg-white rounded-lg shadow-md p-6 text-center hover:shadow-xl transition-shadow duration-200">
        <FaHeadset className="mx-auto text-4xl text-primary-600 mb-4" />
        <h3 className="text-lg font-bold text-gray-900 mb-2">24/7 Support</h3>
        <p className="text-gray-600 text-sm">
          Round-the-clock customer service to assist you anytime
        </p>
      </div>
    </div>
  );
}

