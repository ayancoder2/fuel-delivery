import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RefundService {
  static SupabaseClient get client => Supabase.instance.client;

  /// Submits a new refund request for an order
  static Future<void> requestRefund({
    required String orderId,
    required String userId,
    required double amount,
    required String reason,
  }) async {
    try {
      await client.from('refunds').insert({
        'order_id': orderId,
        'user_id': userId,
        'amount': amount,
        'reason': reason,
        'status': 'PENDING',
      });
      
      // Optional: Logic to notify admin or update order meta-data
    } catch (e) {
      debugPrint('Error requesting refund: $e');
      rethrow;
    }
  }

  /// Fetches all refund requests for a specific user
  static Future<List<Map<String, dynamic>>> getRefunds(String userId) async {
    try {
      final data = await client
          .from('refunds')
          .select('*, orders(fuel_type, quantity, total_price)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetching refunds: $e');
      return [];
    }
  }

  /// Fetches a refund request for a specific order if it exists
  static Future<Map<String, dynamic>?> getRefundByOrder(String orderId) async {
    try {
      final data = await client
          .from('refunds')
          .select()
          .eq('order_id', orderId)
          .maybeSingle();
      
      return data;
    } catch (e) {
      return null;
    }
  }
}
