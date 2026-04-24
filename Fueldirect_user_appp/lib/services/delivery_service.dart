import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeliveryService {
  static SupabaseClient get client => Supabase.instance.client;

  /// Uploads a delivery proof image and saves the record in the database
  static Future<void> uploadDeliveryProof({
    required String orderId,
    required List<int> bytes,
    required String extension,
    String? caption,
  }) async {
    try {
      final fileName = '$orderId/${DateTime.now().millisecondsSinceEpoch}.$extension';
      
      // 1. Upload to Storage
      await client.storage.from('delivery_proofs').uploadBinary(
        fileName,
        Uint8List.fromList(bytes),
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      // 2. Get Public URL
      final String photoUrl = client.storage.from('delivery_proofs').getPublicUrl(fileName);

      // 3. Insert into Table
      await client.from('delivery_proofs').insert({
        'order_id': orderId,
        'photo_url': photoUrl,
        'caption': caption ?? 'Delivery completed',
      });
    } catch (e) {
      debugPrint('Error uploading delivery proof: $e');
      rethrow;
    }
  }

  /// Fetches all proofs for a specific order
  static Future<List<Map<String, dynamic>>> getDeliveryProofs(String orderId) async {
    try {
      final data = await client
          .from('delivery_proofs')
          .select()
          .eq('order_id', orderId);
      
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetching delivery proofs: $e');
      return [];
    }
  }
}
