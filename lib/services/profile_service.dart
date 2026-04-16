import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  static SupabaseClient get client => Supabase.instance.client;

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
    
    await client.from('profiles').update(updates).eq('id', userId);
  }

  static Future<String?> uploadAvatar(String userId, List<int> bytes, String extension) async {
    final fileName = '$userId.${DateTime.now().millisecondsSinceEpoch}.$extension';
    
    await client.storage.from('avatars').uploadBinary(
          fileName,
          Uint8List.fromList(bytes),
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    final String publicUrl = client.storage.from('avatars').getPublicUrl(fileName);
    return publicUrl;
  }

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
}
