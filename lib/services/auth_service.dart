import 'package:flutter/material.dart'; // Import for debugPrint
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  Future<bool> isAdmin() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      debugPrint('isAdmin check: No user is currently logged in.');
      return false;
    }

    try {
      final response = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id) // This is correct: user.id links to profiles.id
          .maybeSingle();

      if (response == null) {
        debugPrint('isAdmin check: No profile found for user ${user.id}.');
        return false;
      }
      
      final isAdmin = response['role'] == 'admin';
      debugPrint('isAdmin check: User role is "${response['role']}". Is admin: $isAdmin');
      return isAdmin;

    } catch (e) {
      debugPrint('Error checking admin role: $e');
      return false;
    }
  }
}