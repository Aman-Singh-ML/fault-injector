'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/store/authStore';
import { adminAPI } from '@/lib/api';
import Navbar from '@/components/Navbar';
import toast from 'react-hot-toast';
import { FaUsers, FaHotel, FaCalendarAlt, FaDollarSign, FaChartLine, FaSpinner } from 'react-icons/fa';
import Link from 'next/link';

export default function AdminDashboardPage() {
  const router = useRouter();
  const { isAuthenticated, user } = useAuthStore();
  const [stats, setStats] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!isAuthenticated) {
      router.push('/login');
      return;
    }
    
    if (user?.role !== 'ADMIN') {
      toast.error('Access denied. Admin only.');
      router.push('/dashboard');
      return;
    }

    fetchAnalytics();
  }, [isAuthenticated, user, router]);

  const fetchAnalytics = async () => {
    setLoading(true);
    try {
      const response = await adminAPI.getAnalytics();
      console.log('Analytics data:', response.data);
      setStats(response.data);
    } catch (error: any) {
      console.error('Failed to fetch analytics:', error);
      toast.error('Failed to fetch analytics data');
      // Set empty stats on error
      setStats({
        totalUsers: 0,
        totalHotels: 0,
        totalBookings: 0,
        totalRevenue: 0,
        recentBookings: 0,
        activeUsers: 0,
      });
    } finally {
      setLoading(false);
    }
  };

  if (!isAuthenticated || user?.role !== 'ADMIN') {
    return null;
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <Navbar />
      
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900">Admin Dashboard</h1>
          <p className="mt-2 text-gray-600">Manage your hotel reservation system</p>
        </div>

        {loading ? (
          <div className="flex justify-center items-center py-20">
            <FaSpinner className="animate-spin text-4xl text-primary-600" />
          </div>
        ) : (
          <>
            {/* Stats Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
              <div className="bg-white rounded-lg shadow-md p-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm text-gray-600 mb-1">Total Users</p>
                    <p className="text-3xl font-bold text-gray-900">{stats?.totalUsers || 0}</p>
                  </div>
                  <FaUsers className="text-4xl text-blue-500" />
                </div>
              </div>

              <div className="bg-white rounded-lg shadow-md p-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm text-gray-600 mb-1">Total Hotels</p>
                    <p className="text-3xl font-bold text-gray-900">{stats?.totalHotels || 0}</p>
                  </div>
                  <FaHotel className="text-4xl text-green-500" />
                </div>
              </div>

              <div className="bg-white rounded-lg shadow-md p-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm text-gray-600 mb-1">Total Bookings</p>
                    <p className="text-3xl font-bold text-gray-900">{stats?.totalBookings || 0}</p>
                  </div>
                  <FaCalendarAlt className="text-4xl text-purple-500" />
                </div>
              </div>

              <div className="bg-white rounded-lg shadow-md p-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm text-gray-600 mb-1">Total Revenue</p>
                    <p className="text-3xl font-bold text-gray-900">
                      ${(stats?.totalRevenue || 0).toLocaleString()}
                    </p>
                  </div>
                  <FaDollarSign className="text-4xl text-yellow-500" />
                </div>
              </div>
            </div>

            {/* Quick Actions */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
              <Link
                href="/admin/users"
                className="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow duration-200"
              >
                <div className="flex items-center space-x-4">
                  <FaUsers className="text-3xl text-blue-500" />
                  <div>
                    <h3 className="text-lg font-bold text-gray-900">Manage Users</h3>
                    <p className="text-sm text-gray-600">View and manage user accounts</p>
                  </div>
                </div>
              </Link>

              <Link
                href="/admin/hotels"
                className="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow duration-200"
              >
                <div className="flex items-center space-x-4">
                  <FaHotel className="text-3xl text-green-500" />
                  <div>
                    <h3 className="text-lg font-bold text-gray-900">Manage Hotels</h3>
                    <p className="text-sm text-gray-600">Add, edit, or remove hotels</p>
                  </div>
                </div>
              </Link>

              <Link
                href="/admin/bookings"
                className="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow duration-200"
              >
                <div className="flex items-center space-x-4">
                  <FaCalendarAlt className="text-3xl text-purple-500" />
                  <div>
                    <h3 className="text-lg font-bold text-gray-900">Manage Bookings</h3>
                    <p className="text-sm text-gray-600">View and manage all bookings</p>
                  </div>
                </div>
              </Link>
            </div>

            {/* Recent Activity & Statistics */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
              {/* Recent Activity */}
              <div className="bg-white rounded-lg shadow-md p-6">
                <h2 className="text-xl font-bold text-gray-900 mb-4 flex items-center">
                  <FaChartLine className="mr-2" />
                  Recent Activity
                </h2>
                <div className="space-y-4">
                  <div className="flex items-center justify-between py-3 border-b border-gray-200">
                    <div>
                      <p className="font-medium text-gray-900">New bookings this week</p>
                      <p className="text-sm text-gray-600">Last 7 days</p>
                    </div>
                    <span className="text-2xl font-bold text-primary-600">
                      {stats?.recentBookings || 0}
                    </span>
                  </div>

                  <div className="flex items-center justify-between py-3 border-b border-gray-200">
                    <div>
                      <p className="font-medium text-gray-900">New users this month</p>
                      <p className="text-sm text-gray-600">Last 30 days</p>
                    </div>
                    <span className="text-2xl font-bold text-green-600">
                      {stats?.activeUsers || 0}
                    </span>
                  </div>

                  <div className="flex items-center justify-between py-3">
                    <div>
                      <p className="font-medium text-gray-900">New users this week</p>
                      <p className="text-sm text-gray-600">Last 7 days</p>
                    </div>
                    <span className="text-2xl font-bold text-blue-600">
                      {stats?.recentUsers || 0}
                    </span>
                  </div>
                </div>
              </div>

              {/* Booking Status Breakdown */}
              <div className="bg-white rounded-lg shadow-md p-6">
                <h2 className="text-xl font-bold text-gray-900 mb-4">Booking Status</h2>
                <div className="space-y-4">
                  <div className="flex items-center justify-between py-3 border-b border-gray-200">
                    <div className="flex items-center">
                      <div className="w-3 h-3 bg-yellow-500 rounded-full mr-3"></div>
                      <span className="font-medium text-gray-900">Pending</span>
                    </div>
                    <span className="text-xl font-bold text-gray-900">
                      {stats?.bookingsByStatus?.PENDING || 0}
                    </span>
                  </div>

                  <div className="flex items-center justify-between py-3 border-b border-gray-200">
                    <div className="flex items-center">
                      <div className="w-3 h-3 bg-green-500 rounded-full mr-3"></div>
                      <span className="font-medium text-gray-900">Confirmed</span>
                    </div>
                    <span className="text-xl font-bold text-gray-900">
                      {stats?.bookingsByStatus?.CONFIRMED || 0}
                    </span>
                  </div>

                  <div className="flex items-center justify-between py-3 border-b border-gray-200">
                    <div className="flex items-center">
                      <div className="w-3 h-3 bg-blue-500 rounded-full mr-3"></div>
                      <span className="font-medium text-gray-900">Completed</span>
                    </div>
                    <span className="text-xl font-bold text-gray-900">
                      {stats?.bookingsByStatus?.COMPLETED || 0}
                    </span>
                  </div>

                  <div className="flex items-center justify-between py-3">
                    <div className="flex items-center">
                      <div className="w-3 h-3 bg-red-500 rounded-full mr-3"></div>
                      <span className="font-medium text-gray-900">Cancelled</span>
                    </div>
                    <span className="text-xl font-bold text-gray-900">
                      {stats?.bookingsByStatus?.CANCELLED || 0}
                    </span>
                  </div>
                </div>
              </div>
            </div>

            {/* User Role Breakdown */}
            <div className="bg-white rounded-lg shadow-md p-6">
              <h2 className="text-xl font-bold text-gray-900 mb-4">User Roles</h2>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div className="text-center p-4 bg-purple-50 rounded-lg">
                  <p className="text-sm text-gray-600 mb-2">Administrators</p>
                  <p className="text-3xl font-bold text-purple-600">
                    {stats?.usersByRole?.ADMIN || 0}
                  </p>
                </div>
                <div className="text-center p-4 bg-blue-50 rounded-lg">
                  <p className="text-sm text-gray-600 mb-2">Regular Users</p>
                  <p className="text-3xl font-bold text-blue-600">
                    {stats?.usersByRole?.USER || 0}
                  </p>
                </div>
                <div className="text-center p-4 bg-green-50 rounded-lg">
                  <p className="text-sm text-gray-600 mb-2">Total Users</p>
                  <p className="text-3xl font-bold text-green-600">
                    {stats?.totalUsers || 0}
                  </p>
                </div>
              </div>
            </div>
          </>
        )}
      </div>
    </div>
  );
}

