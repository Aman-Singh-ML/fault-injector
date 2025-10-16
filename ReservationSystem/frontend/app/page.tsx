'use client';

import Link from 'next/link';
import { useAuthStore } from '@/store/authStore';
import { useRouter } from 'next/navigation';
import { useEffect } from 'react';
import { FaHotel, FaSearch, FaShieldAlt, FaHeadset, FaStar } from 'react-icons/fa';

export default function HomePage() {
  const router = useRouter();
  const { isAuthenticated } = useAuthStore();

  useEffect(() => {
    if (isAuthenticated) {
      router.push('/dashboard');
    }
  }, [isAuthenticated, router]);

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary-50 to-white">
      {/* Navigation */}
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

      {/* Hero Section */}
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

        {/* Features */}
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

        {/* Stats */}
        <div className="mt-20 bg-white rounded-lg shadow-xl p-8">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-8 text-center">
            <div>
              <div className="text-4xl font-bold text-primary-600 mb-2">10K+</div>
              <div className="text-gray-600">Hotels</div>
            </div>
            <div>
              <div className="text-4xl font-bold text-primary-600 mb-2">500+</div>
              <div className="text-gray-600">Cities</div>
            </div>
            <div>
              <div className="text-4xl font-bold text-primary-600 mb-2">1M+</div>
              <div className="text-gray-600">Happy Customers</div>
            </div>
            <div>
              <div className="text-4xl font-bold text-primary-600 mb-2">4.8/5</div>
              <div className="text-gray-600">Average Rating</div>
            </div>
          </div>
        </div>

        {/* CTA Section */}
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
      </div>

      {/* Footer */}
      <footer className="bg-gray-900 text-white mt-20">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
            <div>
              <div className="flex items-center space-x-2 mb-4">
                <FaHotel className="text-primary-400 text-2xl" />
                <span className="text-xl font-bold">HotelBook</span>
              </div>
              <p className="text-gray-400 text-sm">
                Your trusted partner in finding and booking the perfect hotel stay worldwide.
              </p>
            </div>
            <div>
              <h3 className="font-bold mb-4">Company</h3>
              <ul className="space-y-2 text-sm text-gray-400">
                <li><Link href="/about" className="hover:text-white">About Us</Link></li>
                <li><a href="#" className="hover:text-white">Careers</a></li>
                <li><a href="#" className="hover:text-white">Press</a></li>
              </ul>
            </div>
            <div>
              <h3 className="font-bold mb-4">Support</h3>
              <ul className="space-y-2 text-sm text-gray-400">
                <li><a href="#" className="hover:text-white">Help Center</a></li>
                <li><a href="#" className="hover:text-white">Contact Us</a></li>
                <li><a href="#" className="hover:text-white">Privacy Policy</a></li>
              </ul>
            </div>
            <div>
              <h3 className="font-bold mb-4">Connect</h3>
              <ul className="space-y-2 text-sm text-gray-400">
                <li><a href="#" className="hover:text-white">Facebook</a></li>
                <li><a href="#" className="hover:text-white">Twitter</a></li>
                <li><a href="#" className="hover:text-white">Instagram</a></li>
              </ul>
            </div>
          </div>
          <div className="border-t border-gray-800 mt-8 pt-8 text-center text-sm text-gray-400">
            <p>&copy; 2025 HotelBook. All rights reserved.</p>
          </div>
        </div>
      </footer>
    </div>
  );
}

