import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

void main() async {
  await dotenv.load(fileName: '.env');
  final client = SupabaseClient(dotenv.get('SUPABASE_URL')!, dotenv.get('SUPABASE_ANON_KEY')!);

  // authenticate
  await client.auth.signInWithPassword(email: 'n@n.com', password: 'password123'); // we don't know the password...
}
