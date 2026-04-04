import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: '.env');
  final client = SupabaseClient(dotenv.get('SUPABASE_URL')!, dotenv.get('SUPABASE_ANON_KEY')!);
  final res = await client.from('fuel_prices').select();
  print(res);
}
