import { useState, useEffect, useCallback } from 'react';
import { useAuthStore } from '@/store/authStore';

const API_URL = process.env.NEXT_PUBLIC_API_URL || '/api';

export function useNotifications() {
  const { user, isAuthenticated } = useAuthStore();
  const [unreadCount, setUnreadCount] = useState(0);
  const [notifications, setNotifications] = useState<any[]>([]);

  // Fetch notifications on demand (no SSE)
  const fetchNotifications = useCallback(async () => {
    if (!user?.id) return;

    try {
      const response = await fetch(`${API_URL}/notifications/${user.id}`);
      if (!response.ok) {
        throw new Error(`Failed to fetch notifications: ${response.status}`);
      }
      const data = await response.json();

      // Handle different response formats
      let notificationsList = [];
      let unread = 0;

      if (data.notifications && Array.isArray(data.notifications)) {
        notificationsList = data.notifications;
        unread = data.unreadCount || 0;
      } else if (Array.isArray(data)) {
        notificationsList = data;
        unread = data.filter((n: any) => !n.read).length;
      }

      setNotifications(notificationsList);
      setUnreadCount(unread);
      console.log('✅ Notifications fetched on demand:', notificationsList.length);
    } catch (error) {
      console.error('Failed to fetch notifications:', error);
      setNotifications([]);
      setUnreadCount(0);
    }
  }, [user?.id]);

  // Initialize - only fetch when user clicks on notifications
  useEffect(() => {
    if (isAuthenticated && user?.id) {
      // Don't auto-fetch, wait for user to click on notifications
      console.log('📌 Notifications ready for on-demand loading');
    }
  }, [isAuthenticated, user?.id]);

  return {
    unreadCount,
    notifications,
    fetchNotifications
  };
}

