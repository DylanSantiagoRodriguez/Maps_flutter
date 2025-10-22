import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchReminders() async {
    final data = await client
        .from('reminders')
        .select()
        .order('scheduled_at', ascending: true);
    // data is List<dynamic> of Map<String, dynamic>
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> createReminder(Map<String, dynamic> payload) async {
    final inserted = await client
        .from('reminders')
        .insert(payload)
        .select()
        .single();
    return Map<String, dynamic>.from(inserted);
  }

  Future<Map<String, dynamic>> updateReminder(String id, Map<String, dynamic> payload) async {
    final updated = await client
        .from('reminders')
        .update(payload)
        .eq('id', id)
        .select()
        .single();
    return Map<String, dynamic>.from(updated);
  }

  Future<void> deleteReminder(String id) async {
    await client.from('reminders').delete().eq('id', id);
  }
}