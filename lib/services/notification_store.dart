import 'package:flutter/foundation.dart';

/// Holds a single notification entry in the inbox.
class AppNotification {
  final int id;
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

enum NotificationType { order, promo, system }

/// Singleton store that holds all in-app notification history.
/// Updated every time [NotificationService.showNotification] fires.
class NotificationStore extends ChangeNotifier {
  NotificationStore._internal() {
    // Add default welcome notifications for demo
    _items.add(AppNotification(
      id: 1,
      title: 'Welcome to FuelDirect!',
      body: 'Your premium fuel delivery service is now ready. Explore our latest fuel prices on the dashboard.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      type: NotificationType.system,
      isRead: true,
    ));
    _items.add(AppNotification(
      id: 2,
      title: 'Save 10% on your first order',
      body: 'Use code WELCOME10 at checkout to get an instant discount on your first fuel top-up.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      type: NotificationType.promo,
    ));
  }
  static final NotificationStore instance = NotificationStore._internal();

  final List<AppNotification> _items = [];

  List<AppNotification> get items => List.unmodifiable(_items.reversed.toList());

  int get unreadCount => _items.where((n) => !n.isRead).length;

  void add({
    required String title,
    required String body,
    NotificationType type = NotificationType.order,
  }) {
    _items.add(AppNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title,
      body: body,
      timestamp: DateTime.now(),
      type: type,
    ));
    notifyListeners();
  }

  void markAllRead() {
    for (final n in _items) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void markRead(int id) {
    final n = _items.firstWhere((n) => n.id == id, orElse: () => _items.first);
    n.isRead = true;
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
