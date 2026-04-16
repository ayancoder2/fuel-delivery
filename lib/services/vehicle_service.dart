import 'package:supabase_flutter/supabase_flutter.dart';

class VehicleService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> getVehicles(String userId) async {
    try {
      final data = await client
          .from('vehicles')
          .select()
          .eq('user_id', userId)
          .order('created_at');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return [];
    }
  }

  static Future<void> addVehicle({
    required String userId,
    required String make,
    required String model,
    required String plate,
    String? color,
    String? fuelType,
    String? type,
    int? year,
  }) async {
    // Ensure the profile exists first (Self-Healing) - Wrapped in try-catch to prevent blocking
    try {
      final user = client.auth.currentUser;
      if (user != null) {
        await client.from('profiles').upsert({
          'id': user.id,
          'email': user.email ?? '',
          'full_name': user.userMetadata?['full_name'] ?? 'New User',
          'phone_number': user.userMetadata?['phone_number'],
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('Profile self-heal failed: $e');
    }

    await client.from('vehicles').insert({
      'user_id': userId,
      'make': make,
      'model': model,
      'license_plate': plate,
      'color': color,
      'fuel_type': fuelType,
      'type': type,
      'year': year,
      'tank_capacity': 0.0,
    });
  }

  static Future<void> updateVehicle({
    required String vehicleId,
    required String make,
    required String model,
    required String plate,
    String? color,
    String? fuelType,
    String? type,
    int? year,
  }) async {
    await client.from('vehicles').update({
      'make': make,
      'model': model,
      'license_plate': plate,
      'color': color,
      'fuel_type': fuelType,
      'type': type,
      'year': year,
      'tank_capacity': 0.0,
    }).eq('id', vehicleId);
  }

  static Future<void> deleteVehicle(String vehicleId) async {
    await client.from('vehicles').delete().eq('id', vehicleId);
  }
}
