'use client';

import Navbar from '@/components/Navbar';
import { FaHotel, FaUsers, FaGlobe, FaAward, FaShieldAlt, FaHeadset } from 'react-icons/fa';

export default function AboutPage() {
  return (
    <div className="min-h-screen bg-gray-50">
      <Navbar />
      
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        {/* Hero Section */}
        <div className="text-center mb-16">
          <FaHotel className="mx-auto text-6xl text-primary-600 mb-6" />
          <h1 className="text-4xl font-bold text-gray-900 mb-4">
            About HotelBook
          </h1>
          <p className="text-xl text-gray-600 max-w-3xl mx-auto">
            Your trusted partner in finding and booking the perfect hotel stay worldwide
          </p>
        </div>

        {/* Mission Section */}
        <div className="bg-white rounded-lg shadow-md p-8 mb-12">
          <h2 className="text-2xl font-bold text-gray-900 mb-4">Our Mission</h2>
          <p className="text-gray-600 leading-relaxed">
            At HotelBook, we're committed to making hotel booking simple, transparent, and enjoyable. 
            We believe that finding the perfect place to stay shouldn't be complicated or stressful. 
            Our platform connects travelers with thousands of quality hotels worldwide, offering 
            competitive prices and exceptional service.
          </p>
        </div>

        {/* Features Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8 mb-12">
          <div className="bg-white rounded-lg shadow-md p-6 text-center">
            <FaGlobe className="mx-auto text-4xl text-primary-600 mb-4" />
            <h3 className="text-xl font-bold text-gray-900 mb-2">Global Reach</h3>
            <p className="text-gray-600">
              Access to thousands of hotels in hundreds of cities worldwide
            </p>
          </div>

          <div className="bg-white rounded-lg shadow-md p-6 text-center">
            <FaAward className="mx-auto text-4xl text-primary-600 mb-4" />
            <h3 className="text-xl font-bold text-gray-900 mb-2">Best Prices</h3>
            <p className="text-gray-600">
              Competitive rates and exclusive deals for our members
            </p>
          </div>

          <div className="bg-white rounded-lg shadow-md p-6 text-center">
            <FaShieldAlt className="mx-auto text-4xl text-primary-600 mb-4" />
            <h3 className="text-xl font-bold text-gray-900 mb-2">Secure Booking</h3>
            <p className="text-gray-600">
              Safe and secure payment processing with data protection
            </p>
          </div>

          <div className="bg-white rounded-lg shadow-md p-6 text-center">
            <FaHeadset className="mx-auto text-4xl text-primary-600 mb-4" />
            <h3 className="text-xl font-bold text-gray-900 mb-2">24/7 Support</h3>
            <p className="text-gray-600">
              Round-the-clock customer service to assist you anytime
            </p>
          </div>

          <div className="bg-white rounded-lg shadow-md p-6 text-center">
            <FaUsers className="mx-auto text-4xl text-primary-600 mb-4" />
            <h3 className="text-xl font-bold text-gray-900 mb-2">Trusted Community</h3>
            <p className="text-gray-600">
              Join millions of satisfied travelers worldwide
            </p>
          </div>

          <div className="bg-white rounded-lg shadow-md p-6 text-center">
            <FaHotel className="mx-auto text-4xl text-primary-600 mb-4" />
            <h3 className="text-xl font-bold text-gray-900 mb-2">Quality Hotels</h3>
            <p className="text-gray-600">
              Carefully selected hotels meeting our quality standards
            </p>
          </div>
        </div>

        {/* Stats Section */}
        <div className="bg-gradient-to-r from-primary-600 to-primary-700 rounded-lg shadow-xl p-8 mb-12">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-8 text-center text-white">
            <div>
              <div className="text-4xl font-bold mb-2">10K+</div>
              <div className="text-primary-100">Hotels</div>
            </div>
            <div>
              <div className="text-4xl font-bold mb-2">500+</div>
              <div className="text-primary-100">Cities</div>
            </div>
            <div>
              <div className="text-4xl font-bold mb-2">1M+</div>
              <div className="text-primary-100">Bookings</div>
            </div>
            <div>
              <div className="text-4xl font-bold mb-2">4.8/5</div>
              <div className="text-primary-100">Rating</div>
            </div>
          </div>
        </div>

        {/* Technology Section */}
        <div className="bg-white rounded-lg shadow-md p-8 mb-12">
          <h2 className="text-2xl font-bold text-gray-900 mb-4">Our Technology</h2>
          <p className="text-gray-600 leading-relaxed mb-4">
            Built with cutting-edge microservices architecture, our platform ensures:
          </p>
          <ul className="space-y-2 text-gray-600">
            <li className="flex items-start">
              <span className="text-primary-600 mr-2">✓</span>
              <span>High availability and reliability</span>
            </li>
            <li className="flex items-start">
              <span className="text-primary-600 mr-2">✓</span>
              <span>Fast and responsive user experience</span>
            </li>
            <li className="flex items-start">
              <span className="text-primary-600 mr-2">✓</span>
              <span>Real-time booking updates and notifications</span>
            </li>
            <li className="flex items-start">
              <span className="text-primary-600 mr-2">✓</span>
              <span>Secure payment processing</span>
            </li>
            <li className="flex items-start">
              <span className="text-primary-600 mr-2">✓</span>
              <span>Advanced search and filtering capabilities</span>
            </li>
          </ul>
        </div>

        {/* Contact Section */}
        <div className="bg-white rounded-lg shadow-md p-8 text-center">
          <h2 className="text-2xl font-bold text-gray-900 mb-4">Get in Touch</h2>
          <p className="text-gray-600 mb-6">
            Have questions? We'd love to hear from you.
          </p>
          <div className="flex flex-col md:flex-row justify-center gap-4">
            <a
              href="mailto:support@hotelbook.com"
              className="px-6 py-3 bg-primary-600 text-white rounded-md hover:bg-primary-700 transition-colors duration-200"
            >
              Email Us
            </a>
            <a
              href="tel:+1234567890"
              className="px-6 py-3 bg-gray-200 text-gray-800 rounded-md hover:bg-gray-300 transition-colors duration-200"
            >
              Call Us
            </a>
          </div>
        </div>
      </div>
    </div>
  );
}

