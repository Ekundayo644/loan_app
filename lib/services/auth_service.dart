import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:loan_app/models/user.dart' show AppUser;  // ← Use AppUser

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============= REGISTER =============
  Future<AppUser> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String role = 'customer',
  }) async {
    try {
      // 1. Create auth user in Supabase Auth
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
          'role': role,
        },
      );

      if (authResponse.user == null) {
        throw Exception('Registration failed: No user returned');
      }

      // 2. Insert user details into 'users' table
      final userData = {
        'id': authResponse.user!.id,
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'role': role,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('users').insert(userData);

      // 3. Return AppUser object
      return AppUser.fromJson({
        'id': authResponse.user!.id,
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'role': role,
        'token': authResponse.session?.accessToken ?? '',
      });
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // ============= LOGIN =============
  Future<AppUser> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Login failed: No user returned');
      }

      // Get user details from 'users' table
      final userData = await _supabase
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .single();

      return AppUser.fromJson({
        ...userData,
        'token': response.session?.accessToken ?? '',
      });
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // ============= LOGOUT =============
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  // ============= GET CURRENT USER =============
  Future<AppUser?> getCurrentUser() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) return null;

      final userData = await _supabase
          .from('users')
          .select()
          .eq('id', session.user.id)
          .single();

      return AppUser.fromJson({
        ...userData,
        'token': session.accessToken,
      });
    } catch (e) {
      return null;
    }
  }

  // ============= GET TOKEN =============
  Future<String?> getToken() async {
    try {
      return _supabase.auth.currentSession?.accessToken;
    } catch (e) {
      return null;
    }
  }

  // ============= CHECK IF LOGGED IN =============
  bool isLoggedIn() {
    return _supabase.auth.currentSession != null;
  }

  // ============= RESET PASSWORD =============
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }
}