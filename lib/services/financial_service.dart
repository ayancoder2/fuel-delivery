import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FinancialService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<Map<String, dynamic>?> getWalletInfo(String userId) async {
    try {
      final data = await client
          .from('profiles')
          .select('wallet_balance, loyalty_points')
          .eq('id', userId)
          .single();
      return data;
    } catch (e) {
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
      return [];
    }
  }

  static Future<void> processWalletTransaction({
    required String userId,
    required double amount,
    required String type,
    required String description,
  }) async {
    final profile = await getWalletInfo(userId);
    double currentBalance = (profile?['wallet_balance'] ?? 0.0).toDouble();
    
    double newBalance = type == 'TOPUP' 
        ? currentBalance + amount 
        : currentBalance - amount;

    await client.from('profiles').update({
      'wallet_balance': newBalance,
    }).eq('id', userId);

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
      int pointsToEarn = amount.floor();

      await client.from('profiles').update({
        'loyalty_points': currentPoints + pointsToEarn,
      }).eq('id', userId);
    } catch (e) {
      debugPrint('Error awarding points: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getPaymentMethods(String userId) async {
    try {
      final data = await client
          .from('payment_methods')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
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
    if (isDefault) {
      await client
          .from('payment_methods')
          .update({'is_default': false})
          .eq('user_id', userId);
    }

    await client.from('payment_methods').insert({
      'user_id': userId,
      'card_type': cardType,
      'last_4': last4,
      'expiry_date': expiryDate,
      'is_default': isDefault,
    });
  }

  static Future<void> deletePaymentMethod(String id) async {
    await client.from('payment_methods').delete().eq('id', id);
  }
}
