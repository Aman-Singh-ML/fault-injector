import { useState, useEffect, useCallback, useRef } from 'react';
import { useAuthStore } from '@/store/authStore';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:9000';

interface NotificationEvent {
  type: 'connected' | 'new_notification' | 'notification_read' | 'all_notifications_read';
  notification?: any;
  notificationId?: string;
  count?: number;
  message?: string;
}

export function useNotifications() {
  const { user, isAuthenticated } = useAuthStore();
  const [unreadCount, setUnreadCount] = useState(0);
  const [notifications, setNotifications] = useState<any[]>([]);
  const eventSourceRef = useRef<EventSource | null>(null);
  const reconnectTimeoutRef = useRef<NodeJS.Timeout | null>(null);

  // Fetch initial notifications
  const fetchNotifications = useCallback(async () => {
    if (!user?.id) return;

    try {
      const response = await fetch(`${API_URL}/notifications/${user.id}`);
      const data = await response.json();
      
      setNotifications(data.notifications || []);
      setUnreadCount(data.unreadCount || 0);
    } catch (error) {
      console.error('Failed to fetch notifications:', error);
    }
  }, [user?.id]);

  // Connect to SSE stream
  const connectSSE = useCallback(() => {
    if (!user?.id || !isAuthenticated) return;

    // Close existing connection
    if (eventSourceRef.current) {
      eventSourceRef.current.close();
    }

    try {
      // Note: SSE through API gateway might have issues, so we connect directly to notification service
      const eventSource = new EventSource(`http://localhost:8083/notifications/${user.id}/stream`);
      
      eventSource.onopen = () => {
        console.log('✅ SSE connection established');
      };

      eventSource.onmessage = (event) => {
        try {
          const data: NotificationEvent = JSON.parse(event.data);
          
          switch (data.type) {
            case 'connected':
              console.log('📡 Connected to notification stream');
              break;
              
            case 'new_notification':
              console.log('🔔 New notification received:', data.notification);
              // Add new notification to the list
              setNotifications(prev => [data.notification, ...prev]);
              setUnreadCount(prev => prev + 1);
              
              // Show browser notification if permitted
              if (Notification.permission === 'granted' && data.notification) {
                new Notification(data.notification.title || 'New Notification', {
                  body: data.notification.message,
                  icon: '/favicon.ico',
                  badge: '/favicon.ico'
                });
              }
              break;
              
            case 'notification_read':
              console.log('✅ Notification marked as read:', data.notificationId);
              setUnreadCount(prev => Math.max(0, prev - 1));
              break;
              
            case 'all_notifications_read':
              console.log('✅ All notifications marked as read');
              setUnreadCount(0);
              break;
          }
        } catch (error) {
          console.error('Error parsing SSE message:', error);
        }
      };

      eventSource.onerror = (error) => {
        console.error('❌ SSE connection error:', error);
        eventSource.close();
        
        // Attempt to reconnect after 5 seconds
        reconnectTimeoutRef.current = setTimeout(() => {
          console.log('🔄 Attempting to reconnect SSE...');
          connectSSE();
        }, 5000);
      };

      eventSourceRef.current = eventSource;
    } catch (error) {
      console.error('Failed to establish SSE connection:', error);
    }
  }, [user?.id, isAuthenticated]);

  // Request notification permission
  const requestNotificationPermission = useCallback(async () => {
    if ('Notification' in window && Notification.permission === 'default') {
      const permission = await Notification.requestPermission();
      console.log('Notification permission:', permission);
    }
  }, []);

  // Initialize
  useEffect(() => {
    if (isAuthenticated && user?.id) {
      fetchNotifications();
      connectSSE();
      requestNotificationPermission();
    }

    return () => {
      if (eventSourceRef.current) {
        eventSourceRef.current.close();
      }
      if (reconnectTimeoutRef.current) {
        clearTimeout(reconnectTimeoutRef.current);
      }
    };
  }, [isAuthenticated, user?.id, fetchNotifications, connectSSE, requestNotificationPermission]);

  return {
    unreadCount,
    notifications,
    fetchNotifications,
    reconnect: connectSSE
  };
}

