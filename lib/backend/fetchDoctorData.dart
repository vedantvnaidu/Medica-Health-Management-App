//fetchDoctorData.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class DoctorAuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Authenticate doctor with contact and password
  static Future<Map<String, dynamic>?> authenticateDoctor({
    required String contact,
    required String password,
  }) async {
    try {
      // Query the Doctors table for matching contact and password
      final response = await _supabase
          .from('Doctors')
          .select('*')
          .eq('contact', int.parse(contact))
          .eq('password', password)
          .maybeSingle();

      if (response != null) {
        // Doctor found - authentication successful
        return {
          'success': true,
          'message': 'Login successful!',
          'doctor': response,
        };
      } else {
        // No matching doctor found
        return {
          'success': false,
          'message': 'Invalid mobile number or password',
          'doctor': null,
        };
      }
    } on PostgrestException catch (e) {
      // Handle Supabase/PostgreSQL errors
      print('Supabase error during doctor authentication: ${e.message}');
      return {
        'success': false,
        'message': 'Database error occurred. Please try again.',
        'doctor': null,
      };
    } on FormatException catch (e) {
      // Handle number parsing errors
      print('Format error during doctor authentication: $e');
      return {
        'success': false,
        'message': 'Invalid mobile number format',
        'doctor': null,
      };
    } catch (e) {
      // Handle any other unexpected errors
      print('Unexpected error during doctor authentication: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
        'doctor': null,
      };
    }
  }

  /// Get doctor profile by ID
  static Future<Map<String, dynamic>?> getDoctorById(int doctorId) async {
    try {
      final response = await _supabase
          .from('Doctors')
          .select('*')
          .eq('doctor_id', doctorId)
          .single();

      return {
        'success': true,
        'doctor': response,
      };
    } on PostgrestException catch (e) {
      print('Supabase error getting doctor profile: ${e.message}');
      return {
        'success': false,
        'message': 'Failed to load doctor profile',
      };
    } catch (e) {
      print('Unexpected error getting doctor profile: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Update doctor profile
  static Future<Map<String, dynamic>?> updateDoctorProfile({
    required int doctorId,
    String? name,
    int? contact,
    String? specialization,
  }) async {
    try {
      Map<String, dynamic> updateData = {};

      if (name != null) updateData['name'] = name;
      if (contact != null) updateData['contact'] = contact;
      if (specialization != null) updateData['specialization'] = specialization;

      if (updateData.isEmpty) {
        return {
          'success': false,
          'message': 'No data to update',
        };
      }

      final response = await _supabase
          .from('Doctors')
          .update(updateData)
          .eq('doctor_id', doctorId)
          .select()
          .single();

      return {
        'success': true,
        'message': 'Profile updated successfully',
        'doctor': response,
      };
    } on PostgrestException catch (e) {
      print('Supabase error updating doctor profile: ${e.message}');
      return {
        'success': false,
        'message': 'Failed to update profile',
      };
    } catch (e) {
      print('Unexpected error updating doctor profile: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Change doctor password
  static Future<Map<String, dynamic>?> changePassword({
    required int doctorId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // First verify current password
      final verifyResponse = await _supabase
          .from('Doctors')
          .select('password')
          .eq('doctor_id', doctorId)
          .eq('password', currentPassword)
          .maybeSingle();

      if (verifyResponse == null) {
        return {
          'success': false,
          'message': 'Current password is incorrect',
        };
      }

      // Update to new password
      await _supabase
          .from('Doctors')
          .update({'password': newPassword}).eq('doctor_id', doctorId);

      return {
        'success': true,
        'message': 'Password changed successfully',
      };
    } on PostgrestException catch (e) {
      print('Supabase error changing password: ${e.message}');
      return {
        'success': false,
        'message': 'Failed to change password',
      };
    } catch (e) {
      print('Unexpected error changing password: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Get all doctors (for admin purposes or doctor listing)
  static Future<Map<String, dynamic>?> getAllDoctors() async {
    try {
      final response = await _supabase
          .from('Doctors')
          .select('doctor_id, name, contact, specialization, rating')
          .order('name');

      return {
        'success': true,
        'doctors': response,
      };
    } on PostgrestException catch (e) {
      print('Supabase error getting all doctors: ${e.message}');
      return {
        'success': false,
        'message': 'Failed to load doctors',
      };
    } catch (e) {
      print('Unexpected error getting all doctors: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Get doctors by specialization
  static Future<Map<String, dynamic>?> getDoctorsBySpecialization(
      String specialization) async {
    try {
      final response = await _supabase
          .from('Doctors')
          .select('doctor_id, name, contact, specialization, rating')
          .eq('specialization', specialization)
          .order('rating', ascending: false);

      return {
        'success': true,
        'doctors': response,
      };
    } on PostgrestException catch (e) {
      print('Supabase error getting doctors by specialization: ${e.message}');
      return {
        'success': false,
        'message': 'Failed to load doctors',
      };
    } catch (e) {
      print('Unexpected error getting doctors by specialization: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }
}
