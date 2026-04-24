import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: '.env');
  final client = SupabaseClient(dotenv.get('SUPABASE_URL'), dotenv.get('SUPABASE_ANON_KEY'));
  
  await client.from('fuel_prices').update({'price': 2.85}).eq('name', 'Premium Diesel');
  await client.from('fuel_prices').update({'price': 3.12}).eq('name', 'Hi-Octane 97');
  await client.from('fuel_prices').update({'price': 2.72}).eq('name', 'Super Petrol');

  // ignore: avoid_print
  print('Prices updated!');
}
