'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/store/authStore';
import { notificationsAPI } from '@/lib/api';
import { Notification } from '@/types';
import Navbar from '@/components/Navbar';
import toast from 'react-hot-toast';
import { FaSpinner, FaCheckCircle, FaExclamationCircle, FaInfoCircle, FaTimesCircle } from 'react-icons/fa';
import { format } from 'date-fns';

export default function NotificationsPage() {
  const router = useRouter();
  const { isAuthenticated, user } = useAuthStore();
  const [notifications, setNotifications] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!isAuthenticated) {
      router.push('/login');
      return;
    }
    fetchNotifications();
  }, [isAuthenticated, router]);

  const fetchNotifications = async () => {
    if (!user?.id) return;

    setLoading(true);
    try {
      const response = await notificationsAPI.getAll(user.id);
      // Map the response to match frontend types
      const mappedNotifications = response.data.notifications.map((n: any) => ({
        id: n._id,
        userId: n.userId.toString(),
        message: n.message,
        type: n.type === 'BOOKING' ? 'INFO' : n.type === 'PAYMENT' ? 'SUCCESS' : 'INFO',
        read: n.read,
        createdAt: n.createdAt,
        title: n.title,
        data: n.data
      }));
      setNotifications(mappedNotifications);
    } catch (error: any) {
      console.error('Failed to fetch notifications:', error);
      toast.error('Failed to fetch notifications');
    } finally {
      setLoading(false);
    }
  };

  const handleMarkAsRead = async (id: string) => {
    try {
      await notificationsAPI.markAsRead(id);
      fetchNotifications();
    } catch (error: any) {
      toast.error('Failed to mark as read');
    }
  };

  const handleMarkAllAsRead = async () => {
    if (!user?.id) return;

    try {
      await notificationsAPI.markAllAsRead(user.id);
      toast.success('All notifications marked as read');
      fetchNotifications();
    } catch (error: any) {
      toast.error('Failed to mark all as read');
    }
  };

  const getNotificationIcon = (type: string) => {
    switch (type) {
      case 'SUCCESS':
        return <FaCheckCircle className="text-green-500 text-2xl" />;
      case 'ERROR':
        return <FaTimesCircle className="text-red-500 text-2xl" />;
      case 'WARNING':
        return <FaExclamationCircle className="text-yellow-500 text-2xl" />;
      default:
        return <FaInfoCircle className="text-blue-500 text-2xl" />;
    }
  };

  const getNotificationColor = (type: string) => {
    switch (type) {
      case 'SUCCESS':
        return 'bg-green-50 border-green-200';
      case 'ERROR':
        return 'bg-red-50 border-red-200';
      case 'WARNING':
        return 'bg-yellow-50 border-yellow-200';
      default:
        return 'bg-blue-50 border-blue-200';
    }
  };

  if (!isAuthenticated) {
    return null;
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <Navbar />
      
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="mb-8 flex justify-between items-center">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">Notifications</h1>
            <p className="mt-2 text-gray-600">
              {notifications.filter(n => !n.read).length} unread notifications
            </p>
          </div>
          
          {notifications.some(n => !n.read) && (
            <button
              onClick={handleMarkAllAsRead}
              className="px-4 py-2 text-sm font-medium text-primary-600 hover:text-primary-700"
            >
              Mark all as read
            </button>
          )}
        </div>

        {/* Notifications List */}
        {loading ? (
          <div className="flex justify-center items-center py-20">
            <FaSpinner className="animate-spin text-4xl text-primary-600" />
          </div>
        ) : notifications.length === 0 ? (
          <div className="text-center py-20 bg-white rounded-lg shadow-md">
            <FaInfoCircle className="mx-auto text-6xl text-gray-300 mb-4" />
            <p className="text-gray-500 text-lg">No notifications yet</p>
            <p className="text-gray-400 mt-2">We'll notify you when something important happens</p>
          </div>
        ) : (
          <div className="space-y-4">
            {notifications.map((notification) => (
              <div
                key={notification.id}
                className={`border rounded-lg p-4 ${
                  notification.read ? 'bg-white border-gray-200' : getNotificationColor(notification.type)
                } hover:shadow-md transition-shadow duration-200`}
              >
                <div className="flex items-start space-x-4">
                  <div className="flex-shrink-0">
                    {getNotificationIcon(notification.type)}
                  </div>
                  
                  <div className="flex-1 min-w-0">
                    {(notification as any).title && (
                      <p className={`text-sm font-semibold ${notification.read ? 'text-gray-700' : 'text-gray-900'}`}>
                        {(notification as any).title}
                      </p>
                    )}
                    <p className={`text-sm ${notification.read ? 'text-gray-600' : 'text-gray-800'} ${(notification as any).title ? 'mt-1' : ''}`}>
                      {notification.message}
                    </p>
                    <p className="text-xs text-gray-500 mt-1">
                      {format(new Date(notification.createdAt), 'MMM dd, yyyy HH:mm')}
                    </p>
                  </div>

                  {!notification.read && (
                    <button
                      onClick={() => handleMarkAsRead(notification.id)}
                      className="flex-shrink-0 text-sm text-primary-600 hover:text-primary-700"
                    >
                      Mark as read
                    </button>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

