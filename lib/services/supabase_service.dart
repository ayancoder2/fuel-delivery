import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final client = Supabase.instance.client;

  // --- Auth ---
  static User? get currentUser => client.auth.currentUser;
  static bool get isAuthenticated => client.auth.currentSession != null;

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'phone_number': phone,
      },
    );
    
    return response;
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // --- Profiles ---
  static Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final data = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return data;
    } catch (e) {
      return null;
    }
  }

  static Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? subscriptionPlan,
  }) async {
    final updates = <String, dynamic>{
      'id': userId,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (fullName != null) updates['full_name'] = fullName;
    if (phone != null) updates['phone_number'] = phone;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (subscriptionPlan != null) updates['subscription_plan'] = subscriptionPlan;
    
    await client.from('profiles').upsert(updates);
  }

  static Future<String?> uploadAvatar(String userId, List<int> bytes, String extension) async {
    final fileName = '$userId.${DateTime.now().millisecondsSinceEpoch}.$extension';
    final filePath = fileName; // Fixed: unnecessary string interpolation

    await client.storage.from('avatars').uploadBinary(
          filePath,
          Uint8List.fromList(bytes),
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    final String publicUrl = client.storage.from('avatars').getPublicUrl(filePath);
    return publicUrl;
  }

  // --- Vehicles ---
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
    await client.from('vehicles').insert({
      'user_id': userId,
      'make': make,
      'model': model,
      'license_plate': plate,
      'color': color,
      'fuel_type': fuelType,
      'type': type,
      'year': year,
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
    final response = await client.from('vehicles').update({
      'make': make,
      'model': model,
      'license_plate': plate,
      'color': color,
      'fuel_type': fuelType,
      'type': type,
      'year': year,
    }).eq('id', vehicleId).select();
    
    if (response.isEmpty) {
      throw Exception('Failed to update. Check if your Supabase table has an UPDATE RLS policy enabled.');
    }
  }

  static Future<void> deleteVehicle(String vehicleId) async {
    await client.from('vehicles').delete().eq('id', vehicleId);
  }

  // --- Orders ---
  static Future<void> updateDriverLocation(String orderId, double lat, double lng) async {
    await client.from('orders').update({
      'driver_latitude': lat,
      'driver_longitude': lng,
    }).eq('id', orderId);
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
      debugPrint('Error fetching orders: $e');
      return [];
    }
  }

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
  }) async {
    final response = await client.from('orders').insert({
      'user_id': userId,
      'vehicle_id': vehicleId,
      'fuel_type': fuelType,
      'quantity': quantity,
      'total_price': totalPrice,
      'delivery_address': address,
      'latitude': lat,
      'longitude': lng,
      'scheduled_time': scheduledTime?.toIso8601String(),
    }).select().single();
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

  // --- Reviews ---
  static Future<void> submitReview({
    required String orderId,
    required String userId,
    required int rating,
    String feedback = '',
  }) async {
    try {
      await client.from('reviews').insert({
        'order_id': orderId,
        'user_id': userId,
        'rating': rating,
        'feedback': feedback,
      });
    } catch (e) {
      debugPrint('Error submitting review: $e');
    }
  }

  // --- Fuel Prices ---
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

  // --- Addresses ---
  static Future<List<Map<String, dynamic>>> getAddresses(String userId) async {
    try {
      final data = await client
          .from('addresses')
          .select()
          .eq('user_id', userId)
          .order('created_at');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return [];
    }
  }

  static Future<void> addAddress({
    required String userId,
    required String title,
    required String address,
    required double latitude,
    required double longitude,
    bool isDefault = false,
  }) async {
    await client.from('addresses').insert({
      'user_id': userId,
      'title': title,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'is_default': isDefault,
    });
  }

  static Future<void> updateAddress({
    required String addressId,
    required String title,
    required String address,
    required double latitude,
    required double longitude,
    bool isDefault = false,
  }) async {
    await client.from('addresses').update({
      'title': title,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'is_default': isDefault,
    }).eq('id', addressId);
  }

  static Future<void> deleteAddress(String addressId) async {
    await client.from('addresses').delete().eq('id', addressId);
  }

  // --- Payment Methods ---
  static Future<List<Map<String, dynamic>>> getPaymentMethods(String userId) async {
    try {
      final data = await client
          .from('payment_methods')
          .select()
          .eq('user_id', userId)
          .order('created_at');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetching payment methods: $e');
      return [];
    }
  }

  static Future<void> addPaymentMethod({
    required String userId,
    required String cardType,
    required String last4,
    required String expiryDate,
    bool isDefault = false,
  }) async {
    await client.from('payment_methods').insert({
      'user_id': userId,
      'card_type': cardType,
      'last_4': last4,
      'expiry_date': expiryDate,
      'is_default': isDefault,
    });
  }

  static Future<void> deletePaymentMethod(String methodId) async {
    await client.from('payment_methods').delete().eq('id', methodId);
  }

  // --- Coupons ---
  static Future<Map<String, dynamic>?> validateCoupon(String code) async {
    try {
      final now = DateTime.now().toIso8601String();
      final data = await client
          .from('coupons')
          .select()
          .eq('code', code.toUpperCase())
          .eq('is_active', true)
          .gt('expiry_date', now)
          .maybeSingle();

      if (data != null && data['usage_limit'] != null) {
        if (data['usage_count'] >= data['usage_limit']) return null;
      }

      return data;
    } catch (e) {
      debugPrint('Error validating coupon: $e');
      return null;
    }
  }

  static Future<void> incrementCouponUsage(String code) async {
    try {
      final coupon = await client
          .from('coupons')
          .select('usage_count')
          .eq('code', code.toUpperCase())
          .single();
      
      int currentCount = coupon['usage_count'] ?? 0;
      await client.from('coupons').update({
        'usage_count': currentCount + 1,
      }).eq('code', code.toUpperCase());
    } catch (e) {
      debugPrint('Error incrementing coupon usage: $e');
    }
  }

  // --- Wallet & Loyalty ---
  static Future<Map<String, dynamic>?> getWalletInfo(String userId) async {
    try {
      final data = await client
          .from('profiles')
          .select('wallet_balance, loyalty_points')
          .eq('id', userId)
          .single();
      return data;
    } catch (e) {
      debugPrint('Error fetching wallet info: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getWalletTransactions(String userId) async {
    try {
      final data = await client
          .from('wallet_transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
      return [];
    }
  }

  static Future<void> processWalletTransaction({
    required String userId,
    required double amount,
    required String type,
    required String description,
  }) async {
    // 1. Get current balance
    final profile = await getWalletInfo(userId);
    double currentBalance = (profile?['wallet_balance'] ?? 0.0).toDouble();
    
    // 2. Calculate new balance
    double newBalance = type == 'TOPUP' 
        ? currentBalance + amount 
        : currentBalance - amount;

    // 3. Update profile balance
    await client.from('profiles').update({
      'wallet_balance': newBalance,
    }).eq('id', userId);

    // 4. Record transaction
    await client.from('wallet_transactions').insert({
      'user_id': userId,
      'amount': amount,
      'type': type,
      'description': description,
    });
  }

  static Future<void> awardLoyaltyPoints(String userId, double amount) async {
    try {
      final profile = await getWalletInfo(userId);
      int currentPoints = profile?['loyalty_points'] ?? 0;
      int pointsToEarn = amount.floor(); // 1 point per $1 spent

      await client.from('profiles').update({
        'loyalty_points': currentPoints + pointsToEarn,
      }).eq('id', userId);
    } catch (e) {
      debugPrint('Error awarding points: $e');
    }
  }
}
