'use client';

import Link from 'next/link';

export function HeroSection() {
  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20">
      <div className="text-center">
        <h1 className="text-5xl md:text-6xl font-extrabold text-gray-900 mb-6">
          Find Your Perfect Stay
        </h1>
        <p className="text-xl md:text-2xl text-gray-600 mb-8 max-w-3xl mx-auto">
          Book hotels worldwide with the best prices and exceptional service. 
          Your dream vacation starts here.
        </p>
        <div className="flex flex-col sm:flex-row justify-center gap-4">
          <Link
            href="/register"
            className="px-8 py-4 text-lg font-medium text-white bg-primary-600 rounded-lg hover:bg-primary-700 transition-colors duration-200 shadow-lg"
          >
            Get Started
          </Link>
          <Link
            href="/about"
            className="px-8 py-4 text-lg font-medium text-gray-700 bg-white rounded-lg hover:bg-gray-50 transition-colors duration-200 shadow-lg"
          >
            Learn More
          </Link>
        </div>
      </div>
    </div>
  );
}

