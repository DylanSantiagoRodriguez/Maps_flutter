import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:maps/app/app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  final url = dotenv.env['SUPABASE_URL'];
  final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
  if (url == null || anonKey == null) {
    debugPrint('Supabase env variables missing: SUPABASE_URL or SUPABASE_ANON_KEY');
  } else {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }
  runApp(const MyApp());
}
