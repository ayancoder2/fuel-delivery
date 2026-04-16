import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import 'notification_common.dart';
import 'notification_service.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Holds a single notification entry in the inbox.
class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final NotificationType type;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });
}

/// Singleton store that holds all in-app notification history.
class NotificationStore extends ChangeNotifier {
  StreamSubscription? _subscription;
  StreamSubscription? _localSub;
  
  NotificationStore._internal() {
    // Listen for local notifications from the service
    _localSub = NotificationService().onLocalNotification.listen((data) {
      _addLocal(
        title: data['title'],
        body: data['body'],
        type: data['type'],
      );
    });
  }
  
  static final NotificationStore instance = NotificationStore._internal();

  final List<AppNotification> _items = [];

  void syncWithSupabase(String userId) {
    _subscription?.cancel();
    _subscription = NotificationService.getNotificationStream(userId).listen((data) {
      _items.clear();
      for (final doc in data) {
        _items.add(AppNotification(
          id: doc['id'].toString(),
          title: doc['title'] ?? '',
          body: doc['body'] ?? '',
          timestamp: DateTime.parse(doc['created_at']),
          type: NotificationType.order, 
          isRead: doc['is_read'] ?? false,
        ));
      }
      notifyListeners();
    });
  }

  List<AppNotification> get items => List.unmodifiable(_items.reversed.toList());

  int get unreadCount => _items.where((n) => !n.isRead).length;

  /// Internal method to handle local notification additions
  void _addLocal({
    required String title,
    required String body,
    NotificationType type = NotificationType.order,
  }) {
    _items.add(AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
      type: type,
    ));
    notifyListeners();
  }

  void add({
    required String title,
    required String body,
    NotificationType type = NotificationType.order,
  }) {
    final userId = AuthService.currentUser?.id;
    if (userId != null) {
      NotificationService.sendNotification(
        userId: userId,
        title: title,
        body: body,
      );
    }
  }

  void markAllRead() {
    final userId = AuthService.currentUser?.id;
    if (userId != null) {
      Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .then((_) => notifyListeners());
    }
  }

  void markRead(String id) {
    NotificationService.markNotificationRead(id);
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _localSub?.cancel();
    super.dispose();
  }
}
