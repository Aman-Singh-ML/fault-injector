'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/store/authStore';
import { FaHotel, FaBell, FaUser, FaSignOutAlt, FaHome, FaSearch, FaCalendarAlt, FaInfoCircle, FaCog } from 'react-icons/fa';
import { useState, useCallback } from 'react';
import { useNotifications } from '@/hooks/useNotifications';

export default function Navbar() {
  const router = useRouter();
  const { user, isAuthenticated, logout } = useAuthStore();
  const [showUserMenu, setShowUserMenu] = useState(false);
  const [showNotifications, setShowNotifications] = useState(false);

  // Use lazy-loaded notifications hook - only fetch when user clicks
  const { unreadCount, notifications, fetchNotifications } = useNotifications();

  // Handle notification icon click - fetch on demand
  const handleNotificationClick = useCallback(async () => {
    setShowNotifications(!showNotifications);
    if (!showNotifications) {
      // Only fetch when opening notifications
      await fetchNotifications();
    }
  }, [showNotifications, fetchNotifications]);

  const handleLogout = () => {
    logout();
    router.push('/login');
  };

  const isAdmin = user?.role === 'ADMIN';

  return (
    <nav className="bg-white shadow-lg">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between h-16">
          {/* Logo */}
          <div className="flex items-center">
            <Link href={isAuthenticated ? '/dashboard' : '/'} className="flex items-center space-x-2">
              <FaHotel className="text-primary-600 text-3xl" />
              <span className="text-xl font-bold text-gray-800">HotelBook</span>
            </Link>
          </div>

          {/* Navigation Links */}
          {isAuthenticated && (
            <div className="hidden md:flex items-center space-x-4">
              <Link
                href="/dashboard"
                className="flex items-center space-x-1 px-3 py-2 rounded-md text-sm font-medium text-gray-700 hover:text-primary-600 hover:bg-gray-100"
              >
                <FaHome />
                <span>Dashboard</span>
              </Link>
              
              <Link
                href="/search"
                className="flex items-center space-x-1 px-3 py-2 rounded-md text-sm font-medium text-gray-700 hover:text-primary-600 hover:bg-gray-100"
              >
                <FaSearch />
                <span>Search</span>
              </Link>
              
              <Link
                href="/reservations"
                className="flex items-center space-x-1 px-3 py-2 rounded-md text-sm font-medium text-gray-700 hover:text-primary-600 hover:bg-gray-100"
              >
                <FaCalendarAlt />
                <span>Reservations</span>
              </Link>

              {isAdmin && (
                <Link
                  href="/admin"
                  className="flex items-center space-x-1 px-3 py-2 rounded-md text-sm font-medium text-gray-700 hover:text-primary-600 hover:bg-gray-100"
                >
                  <FaCog />
                  <span>Admin</span>
                </Link>
              )}
              
              <Link
                href="/about"
                className="flex items-center space-x-1 px-3 py-2 rounded-md text-sm font-medium text-gray-700 hover:text-primary-600 hover:bg-gray-100"
              >
                <FaInfoCircle />
                <span>About</span>
              </Link>
            </div>
          )}

          {/* Right side - User menu */}
          <div className="flex items-center space-x-4">
            {isAuthenticated ? (
              <>
                <div className="relative">
                  <button
                    onClick={handleNotificationClick}
                    className="relative p-2 text-gray-600 hover:text-primary-600 transition-colors"
                    title={unreadCount > 0 ? `${unreadCount} unread notification${unreadCount > 1 ? 's' : ''}` : 'Notifications'}
                  >
                    <FaBell className="text-xl" />
                    {unreadCount > 0 && (
                      <>
                        {/* Unread count badge */}
                        <span className="absolute -top-1 -right-1 flex items-center justify-center min-w-[18px] h-[18px] text-xs font-bold text-white bg-red-500 rounded-full px-1 animate-pulse shadow-lg">
                          {unreadCount > 99 ? '99+' : unreadCount}
                        </span>
                      </>
                    )}
                  </button>

                  {/* Notification Panel */}
                  {showNotifications && (
                    <div className="absolute right-0 mt-2 w-80 bg-white rounded-md shadow-xl py-2 z-50 max-h-96 overflow-y-auto">
                      {notifications && notifications.length > 0 ? (
                        <>
                          <div className="px-4 py-2 border-b border-gray-200">
                            <p className="text-sm font-semibold text-gray-900">
                              Notifications ({notifications.length})
                            </p>
                          </div>
                          <div className="divide-y divide-gray-100">
                            {notifications.map((notification: any) => (
                              <div
                                key={notification._id || notification.id}
                                className="px-4 py-3 hover:bg-gray-50 transition-colors"
                              >
                                <p className="text-sm text-gray-900 font-medium">
                                  {notification.title || notification.message}
                                </p>
                                {notification.title && (
                                  <p className="text-xs text-gray-600 mt-1">
                                    {notification.message}
                                  </p>
                                )}
                                <p className="text-xs text-gray-400 mt-1">
                                  {new Date(notification.createdAt).toLocaleString()}
                                </p>
                              </div>
                            ))}
                          </div>
                          <div className="px-4 py-2 border-t border-gray-200 text-center">
                            <Link
                              href="/notifications"
                              className="text-xs text-primary-600 hover:text-primary-700 font-medium"
                              onClick={() => setShowNotifications(false)}
                            >
                              View all notifications
                            </Link>
                          </div>
                        </>
                      ) : (
                        <div className="px-4 py-8 text-center">
                          <p className="text-sm text-gray-500">No notifications</p>
                        </div>
                      )}
                    </div>
                  )}
                </div>

                <div className="relative">
                  <button
                    onClick={() => setShowUserMenu(!showUserMenu)}
                    className="flex items-center space-x-2 p-2 rounded-md hover:bg-gray-100"
                  >
                    <div className="w-8 h-8 bg-primary-600 rounded-full flex items-center justify-center text-white font-semibold">
                      {user?.firstName?.[0]}{user?.lastName?.[0]}
                    </div>
                    <span className="hidden md:block text-sm font-medium text-gray-700">
                      {user?.firstName} {user?.lastName}
                    </span>
                  </button>

                  {showUserMenu && (
                    <div className="absolute right-0 mt-2 w-48 bg-white rounded-md shadow-lg py-1 z-50">
                      <Link
                        href="/profile"
                        className="flex items-center space-x-2 px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                        onClick={() => setShowUserMenu(false)}
                      >
                        <FaUser />
                        <span>Profile</span>
                      </Link>
                      <button
                        onClick={handleLogout}
                        className="flex items-center space-x-2 w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                      >
                        <FaSignOutAlt />
                        <span>Logout</span>
                      </button>
                    </div>
                  )}
                </div>
              </>
            ) : (
              <div className="flex items-center space-x-2">
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
            )}
          </div>
        </div>
      </div>
    </nav>
  );
}

