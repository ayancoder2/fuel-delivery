import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'inventory_service.dart';
import 'notification_service.dart';

class OrderService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<Map<String, dynamic>?> createOrder({
    required String userId,
    String? vehicleId,
    String? fuelType,
    double? quantity,
    double? totalPrice,
    String? address,
    double? lat,
    double? lng,
    DateTime? scheduledTime,
    String? discountId,
  }) async {
    final double qtyNeeded = quantity ?? 0.0;
    
    final hasInventory = await InventoryService.checkFuelInventory(fuelType ?? 'Petrol', qtyNeeded);
    if (!hasInventory) {
      throw Exception('Insufficient inventory for $fuelType.');
    }

    final String orderNumber = 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final response = await client.from('orders').insert({
      'user_id': userId,
      'order_number': orderNumber,
      'vehicle_id': vehicleId,
      'fuel_type': fuelType,
      'quantity': quantity,
      'total_price': totalPrice,
      'delivery_address': address,
      'latitude': lat,
      'longitude': lng,
      'scheduled_time': scheduledTime?.toIso8601String(),
      'discount_id': discountId,
    }).select().single();

    await InventoryService.decrementFuelInventory(fuelType ?? 'Petrol', qtyNeeded);

    return response;
  }

  static Stream<List<Map<String, dynamic>>> getOrderStream(String orderId) {
    return client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .limit(1);
  }

  static Future<Map<String, dynamic>?> getActiveOrder(String userId) async {
    try {
      final data = await client
          .from('orders')
          .select('*, vehicles(make, model, license_plate)')
          .eq('user_id', userId)
          .neq('status', 'DELIVERED')
          .neq('status', 'CANCELLED')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return data;
    } catch (e) {
      debugPrint('Error fetching active order: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getOrders(String userId) async {
    try {
      final data = await client
          .from('orders')
          .select('*, vehicles(make, model, license_plate)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return [];
    }
  }

  static Future<void> updateOrderDriver({
    required String orderId,
    required String driverName,
    required String driverPhoto,
    required String driverVehicle,
  }) async {
    await client.from('orders').update({
      'driver_name': driverName,
      'driver_photo': driverPhoto,
      'driver_vehicle': driverVehicle,
      'status': 'ON_THE_WAY',
    }).eq('id', orderId);

    final orderData = await client.from('orders').select('user_id').eq('id', orderId).single();
    final userId = orderData['user_id'];
    
    if (userId != null) {
      await NotificationService.sendNotification(
        userId: userId,
        title: 'Driver Assigned!',
        body: '$driverName is on the way with your fuel.',
      );
    }
  }

  static Future<void> updateDriverLocation(String orderId, double lat, double lng) async {
    await client.from('orders').update({
      'driver_latitude': lat,
      'driver_longitude': lng,
    }).eq('id', orderId);
  }

  static Future<void> completeOrder(String orderId) async {
    await client.from('orders').update({'status': 'DELIVERED'}).eq('id', orderId);

    final orderData = await client.from('orders').select('user_id').eq('id', orderId).single();
    final userId = orderData['user_id'];
    
    if (userId != null) {
      await NotificationService.sendNotification(
        userId: userId,
        title: 'Fuel Delivered!',
        body: 'Your fuel has been delivered successfully. Have a great day!',
      );
    }
  }

  static Future<void> submitReview({
    required String orderId,
    required String userId,
    required double rating,
    String? feedback,
  }) async {
    await client.from('reviews').insert({
      'order_id': orderId,
      'user_id': userId,
      'rating': rating,
      'feedback': feedback,
    });
  }
}
