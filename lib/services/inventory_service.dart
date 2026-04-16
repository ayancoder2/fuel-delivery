import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InventoryService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> getFuelPrices() async {
    try {
      final data = await client
          .from('fuel_prices')
          .select()
          .order('name');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return [];
    }
  }

  static Future<bool> checkFuelInventory(String fuelType, double quantity) async {
    try {
      final data = await client
          .from('fuel_inventory')
          .select('total_available')
          .eq('fuel_type', fuelType)
          .maybeSingle();
      
      if (data == null) return false;
      final double available = (data['total_available'] as num).toDouble();
      return available >= quantity;
    } catch (e) {
      return false;
    }
  }

  static Future<void> decrementFuelInventory(String fuelType, double quantity) async {
    try {
      final data = await client
          .from('fuel_inventory')
          .select('total_available')
          .eq('fuel_type', fuelType)
          .single();
      
      final double current = (data['total_available'] as num).toDouble();
      
      await client
          .from('fuel_inventory')
          .update({'total_available': current - quantity})
          .eq('fuel_type', fuelType);
    } catch (e) {
      debugPrint('Error updating inventory: $e');
    }
  }

  static Future<Map<String, dynamic>?> validateDiscount(String code) async {
    try {
      final now = DateTime.now().toIso8601String();
      final data = await client
          .from('discounts')
          .select()
          .eq('code', code.toUpperCase())
          .eq('is_active', true)
          .gt('expires_at', now)
          .maybeSingle();

      if (data != null && data['usage_limit'] != null) {
        if (data['usage_count'] >= data['usage_limit']) return null;
      }
      return data;
    } catch (e) {
      return null;
    }
  }

  static Future<void> applyDiscountUsage(String discountId) async {
    try {
      final discount = await client
          .from('discounts')
          .select('usage_count')
          .eq('id', discountId)
          .single();
      
      int currentCount = discount['usage_count'] ?? 0;
      await client.from('discounts').update({
        'usage_count': currentCount + 1,
      }).eq('id', discountId);
    } catch (e) {
      debugPrint('Error incrementing discount usage: $e');
    }
  }

  /// Records a new fuel purchase (load) and increments inventory
  static Future<void> recordFuelLoad({
    required String fuelType,
    required double quantity,
    required String loadNumber,
  }) async {
    try {
      // 1. Record the load
      await client.from('fuel_loads').insert({
        'load_number': loadNumber,
        'fuel_type': fuelType,
        'purchased_quantity': quantity,
        'remaining_quantity': quantity,
        'cost_per_gal': 2.50, // Simulated purchase cost
        'sell_price': 3.49,    // Simulated selling price
        'status': 'Active',    // Mark as Active so it can be used
      });

      // 2. Update Inventory (Upsert logic)
      final existing = await client
          .from('fuel_inventory')
          .select('total_available')
          .eq('fuel_type', fuelType)
          .maybeSingle();

      if (existing != null) {
        final double current = (existing['total_available'] as num).toDouble();
        await client
            .from('fuel_inventory')
            .update({'total_available': current + quantity})
            .eq('fuel_type', fuelType);
      } else {
        await client.from('fuel_inventory').insert({
          'fuel_type': fuelType,
          'total_available': quantity,
        });
      }
    } catch (e) {
      debugPrint('Error recording fuel load: $e');
      rethrow;
    }
  }
}
