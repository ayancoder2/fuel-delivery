import 'package:flutter/material.dart';
import '../../services/notification_store.dart';
import '../../services/notification_common.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Mark all as read when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationStore.instance.markAllRead();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF333333), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              NotificationStore.instance.clear();
              setState(() {});
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: Color(0xFFFF6600), fontWeight: FontWeight.bold),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFFF6600),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFFF6600),
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Orders'),
            Tab(text: 'Promos'),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: NotificationStore.instance,
        builder: (context, _) {
          final all = NotificationStore.instance.items;
          final orders = all.where((n) => n.type == NotificationType.order).toList();
          final promos = all.where((n) => n.type == NotificationType.promo).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(all),
              _buildList(orders),
              _buildList(promos),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<AppNotification> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 72, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'No notifications yet',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'You\'ll see updates about your orders here',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final notif = items[index];
        return _NotificationCard(notification: notif);
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;

  const _NotificationCard({required this.notification});

  IconData _iconForType(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return Icons.local_shipping_outlined;
      case NotificationType.promo:
        return Icons.local_offer_outlined;
      case NotificationType.system:
        return Icons.info_outline;
    }
  }

  Color _colorForType(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return const Color(0xFFFF6600);
      case NotificationType.promo:
        return const Color(0xFF6B4EE6);
      case NotificationType.system:
        return const Color(0xFF10B981);
    }
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForType(notification.type);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : color.withAlpha(12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.isRead ? const Color(0xFFEEEEEE) : color.withAlpha(60),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(_iconForType(notification.type), color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.bold,
                          color: const Color(0xFF333333),
                        ),
                      ),
                    ),
                    if (!notification.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.body,
                  style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatTimestamp(notification.timestamp),
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
