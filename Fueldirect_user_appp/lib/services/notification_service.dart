import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_common.dart';
import 'dart:async';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Decoupling: Store listens to this stream instead of direct calls
  final _onLocalNotification = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onLocalNotification => _onLocalNotification.stream;

  Future<void> init() async {
    debugPrint('NOTIFICATION_INIT: [1] Starting timezone init');
    try {
      tz.initializeTimeZones();
      debugPrint('NOTIFICATION_INIT: [2] Timezones initialized');
    } catch (e) {
      debugPrint('NOTIFICATION_INIT: [ERROR] Timezone init failed: $e');
    }

    debugPrint('NOTIFICATION_INIT: [3] Configuring Android settings');
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Guard against multiple initializations
    if (_notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>() == null) {
       debugPrint('NOTIFICATION_INIT: [SKIPPED] Native implementation not found');
       // return; // Don't return, might be iOS
    }

    try {
      debugPrint('NOTIFICATION_INIT: [4] Calling _notificationsPlugin.initialize');
      final bool? success = await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('NOTIFICATION_INIT: Notification tapped');
        },
      ).timeout(const Duration(seconds: 5), onTimeout: () {
        debugPrint('NOTIFICATION_INIT: [TIMEOUT] Plugin initialize timed out');
        return false;
      });
      
      if (success != true) {
        debugPrint('NOTIFICATION_INIT: [WARN] Plugin initialize returned false');
      } else {
        debugPrint('NOTIFICATION_INIT: [5] Plugin initialized successfully');
      }
    } catch (e) {
      debugPrint('NOTIFICATION_INIT: [CRITICAL_ERROR] Plugin initialize threw: $e');
      // Do NOT rethrow. Native crashes here are fatal if not handled carefully.
      return; 
    }

    try {
      debugPrint('NOTIFICATION_INIT: [6] Creating notification channel');
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
        playSound: true,
      );

      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(channel);
        debugPrint('NOTIFICATION_INIT: [7] Channel created successfully');
      }
    } catch (e) {
      debugPrint('NOTIFICATION_INIT: [ERROR] Channel creation failed: $e');
    }
  }

  Future<void> showNotification({
    int id = 0,
    required String title,
    required String body,
    NotificationType type = NotificationType.order,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );

    // Notify listeners (like NotificationStore)
    _onLocalNotification.add({'title': title, 'body': body, 'type': type});
  }

  // --- DB Notifications ---
  
  static Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
  }) async {
    try {
      await Supabase.instance.client.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
      });
    } catch (e) {
      debugPrint('Error sending DB notification: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    try {
      final data = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return [];
    }
  }

  static Stream<List<Map<String, dynamic>>> getNotificationStream(String userId) {
    return Supabase.instance.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  static Future<void> markNotificationRead(String notificationId) async {
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Call this function right after the user assigns or updates an order in Supabase
  static Future<void> notifyAssignedDriver(String assignedDriverId, String orderId) async {
    try {
      // This targets the already existing Edge Function
      await Supabase.instance.client.functions.invoke(
        'send-notification',
        body: {
          'target_type': 'driver',       // DO NOT CHANGE: Tells backend to fetch token from drivers table
          'target_id': assignedDriverId, // The ID of the driver (from the drivers table) receiving the order
          'title': 'New Order Assigned 🔥',
          'body': 'You have been assigned a new fuel delivery order!',
          'data': {
            'type': 'order_update', 
            'order_id': orderId
          },
        },
      );
      debugPrint('✅ Push notification triggered successfully to the driver.');
    } catch (e) {
      debugPrint('❌ Failed to trigger driver notification: $e');
    }
  }
}

