'use client';

import Link from 'next/link';

export function CTASection() {
  return (
    <div className="mt-20 bg-gradient-to-r from-primary-600 to-primary-700 rounded-lg shadow-xl p-12 text-center">
      <h2 className="text-3xl md:text-4xl font-bold text-white mb-4">
        Ready to Start Your Journey?
      </h2>
      <p className="text-xl text-primary-100 mb-8">
        Join thousands of travelers who trust HotelBook for their stays
      </p>
      <Link
        href="/register"
        className="inline-block px-8 py-4 text-lg font-medium text-primary-600 bg-white rounded-lg hover:bg-gray-100 transition-colors duration-200 shadow-lg"
      >
        Create Free Account
      </Link>
    </div>
  );
}

