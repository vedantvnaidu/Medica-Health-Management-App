// fetchData.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Authenticates user with mobile number and password
  /// Returns user data if successful, null if failed
  static Future<Map<String, dynamic>?> authenticateUser({
    required String contact,
    required String password,
  }) async {
    try {
      // Query the Patients table to find user with matching contact and password
      final response = await _supabase
          .from('Patients')
          .select('*')
          .eq('contact', int.parse(contact))
          .eq('password', password)
          .maybeSingle();

      if (response != null) {
        // User found and credentials match
        return {
          'success': true,
          'user': response,
          'message': 'Login successful'
        };
      } else {
        // No user found with matching credentials
        return {
          'success': false,
          'user': null,
          'message': 'Invalid mobile number or password'
        };
      }
    } on PostgrestException catch (e) {
      // Database error
      return {
        'success': false,
        'user': null,
        'message': 'Database error: ${e.message}'
      };
    } catch (e) {
      // Other errors (network, parsing, etc.)
      return {
        'success': false,
        'user': null,
        'message': 'An error occurred: ${e.toString()}'
      };
    }
  }

  /// Creates a new patient record
  static Future<Map<String, dynamic>> createPatient({
    required String name,
    required String password,
    required String dob,
    required int age,
    required int gender,
    required int contact,
    required String address,
  }) async {
    try {
      final response = await _supabase
          .from('Patients')
          .insert({
            'name': name,
            'password': password,
            'dob': dob,
            'age': age,
            'gender': gender,
            'contact': contact,
            'address': address,
          })
          .select()
          .single();

      return {
        'success': true,
        'user': response,
        'message': 'Account created successfully'
      };
    } on PostgrestException catch (e) {
      return {
        'success': false,
        'user': null,
        'message': 'Database error: ${e.message}'
      };
    } catch (e) {
      return {
        'success': false,
        'user': null,
        'message': 'An error occurred: ${e.toString()}'
      };
    }
  }

  /// Checks if a contact number already exists
  static Future<bool> doesContactExist(int contact) async {
    try {
      final response = await _supabase
          .from('Patients')
          .select('patient_id')
          .eq('contact', contact)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking contact existence: $e');
      return false;
    }
  }

  /// Gets patient data by patient_id
  static Future<Map<String, dynamic>?> getPatientById(int patientId) async {
    try {
      final response = await _supabase
          .from('Patients')
          .select('*')
          .eq('patient_id', patientId)
          .single();

      return response;
    } catch (e) {
      print('Error fetching patient data: $e');
      return null;
    }
  }

  /// Updates patient information
  static Future<Map<String, dynamic>> updatePatient({
    required int patientId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final response = await _supabase
          .from('Patients')
          .update(updates)
          .eq('patient_id', patientId)
          .select()
          .single();

      return {
        'success': true,
        'user': response,
        'message': 'Profile updated successfully'
      };
    } on PostgrestException catch (e) {
      return {
        'success': false,
        'user': null,
        'message': 'Database error: ${e.message}'
      };
    } catch (e) {
      return {
        'success': false,
        'user': null,
        'message': 'An error occurred: ${e.toString()}'
      };
    }
  }
}
