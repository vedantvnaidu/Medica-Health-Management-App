//addPrescription.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class PrescriptionService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Create a new prescription
  static Future<Map<String, dynamic>?> createPrescription({
    required int doctorId,
    required int patientId,
    String? diagnosis,
    String? note,
  }) async {
    try {
      // Create prescription with current timestamp
      final response = await _supabase
          .from('Prescriptions')
          .insert({
            'doctor_id': doctorId,
            'patient_id': patientId,
            'prescribed_on': DateTime.now().toIso8601String(),
            if (diagnosis != null) 'diagnosis': diagnosis,
            if (note != null) 'note': note,
          })
          .select()
          .single();

      return {
        'success': true,
        'message': 'Prescription created successfully!',
        'prescription': response,
      };
    } on PostgrestException catch (e) {
      print('Supabase error creating prescription: ${e.message}');
      return {
        'success': false,
        'message': 'Failed to create prescription: ${e.message}',
        'prescription': null,
      };
    } catch (e) {
      print('Unexpected error creating prescription: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred while creating prescription',
        'prescription': null,
      };
    }
  }

  /// Get prescriptions by doctor ID
  static Future<Map<String, dynamic>?> getPrescriptionsByDoctor(
      int doctorId) async {
    try {
      final response = await _supabase
          .from('Prescriptions')
          .select('''
            prescriptions_id,
            doctor_id,
            patient_id,
            prescribed_on,
            diagnosis,
            note,
            Patients!inner(name, age, gender, contact)
          ''')
          .eq('doctor_id', doctorId)
          .order('prescribed_on', ascending: false);

      return {
        'success': true,
        'prescriptions': response,
      };
    } on PostgrestException catch (e) {
      print('Supabase error getting prescriptions by doctor: ${e.message}');
      return {
        'success': false,
        'message': 'Failed to load prescriptions',
        'prescriptions': [],
      };
    } catch (e) {
      print('Unexpected error getting prescriptions by doctor: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
        'prescriptions': [],
      };
    }
  }

  /// Get prescriptions by patient ID
  static Future<Map<String, dynamic>?> getPrescriptionsByPatient(
      int patientId) async {
    try {
      final response = await _supabase
          .from('Prescriptions')
          .select('''
            prescriptions_id,
            doctor_id,
            patient_id,
            prescribed_on,
            diagnosis,
            note,
            Doctors!inner(name, specialization, contact)
          ''')
          .eq('patient_id', patientId)
          .order('prescribed_on', ascending: false);

      return {
        'success': true,
        'prescriptions': response,
      };
    } on PostgrestException catch (e) {
      print('Supabase error getting prescriptions by patient: ${e.message}');
      return {
        'success': false,
        'message': 'Failed to load prescriptions',
        'prescriptions': [],
      };
    } catch (e) {
      print('Unexpected error getting prescriptions by patient: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
        'prescriptions': [],
      };
    }
  }

  /// Get prescription by ID
  static Future<Map<String, dynamic>?> getPrescriptionById(
      int prescriptionId) async {
    try {
      final response = await _supabase.from('Prescriptions').select('''
            prescriptions_id,
            doctor_id,
            patient_id,
            prescribed_on,
            diagnosis,
            note,
            Doctors!inner(name, specialization, contact),
            Patients!inner(name, age, gender, contact, address, dob)
          ''').eq('prescriptions_id', prescriptionId).single();

      return {
        'success': true,
        'prescription': response,
      };
    } on PostgrestException catch (e) {
      print('Supabase error getting prescription by ID: ${e.message}');
      return {
        'success': false,
        'message': 'Failed to load prescription details',
        'prescription': null,
      };
    } catch (e) {
      print('Unexpected error getting prescription by ID: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
        'prescription': null,
      };
    }
  }

  /// Update prescription
  static Future<Map<String, dynamic>?> updatePrescription({
    required int prescriptionId,
    String? diagnosis,
    String? note,
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        'prescribed_on': DateTime.now().toIso8601String(),
      };

      if (diagnosis != null) updateData['diagnosis'] = diagnosis;
      if (note != null) updateData['note'] = note;

      final response = await _supabase
          .from('Prescriptions')
          .update(updateData)
          .eq('prescriptions_id', prescriptionId)
          .select()
          .single();

      return {
        'success': true,
        'message': 'Prescription updated successfully',
        'prescription': response,
      };
    } on PostgrestException catch (e) {
      print('Supabase error updating prescription: ${e.message}');
      return {
        'success': false,
        'message': 'Failed to update prescription: ${e.message}',
        'prescription': null,
      };
    } catch (e) {
      print('Unexpected error updating prescription: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
        'prescription': null,
      };
    }
  }

  /// Delete prescription
  static Future<Map<String, dynamic>?> deletePrescription(
      int prescriptionId) async {
    try {
      await _supabase
          .from('Prescriptions')
          .delete()
          .eq('prescriptions_id', prescriptionId);

      return {
        'success': true,
        'message': 'Prescription deleted successfully',
      };
    } on PostgrestException catch (e) {
      print('Supabase error deleting prescription: ${e.message}');
      return {
        'success': false,
        'message': 'Failed to delete prescription: ${e.message}',
      };
    } catch (e) {
      print('Unexpected error deleting prescription: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Get prescription count for doctor
  static Future<Map<String, dynamic>?> getPrescriptionCountByDoctor(
      int doctorId) async {
    try {
      // Perform a head request for count only:
      final int count = await _supabase
          .from('Prescriptions')
          .count() // ← new count() method
          .eq('doctor_id', doctorId);

      return {
        'success': true,
        'count': count, // directly the int returned
      };
    } on PostgrestException catch (e) {
      print('Supabase error getting prescription count: ${e.message}');
      return {
        'success': false,
        'message': 'Failed to get prescription count: ${e.message}',
        'count': 0,
      };
    } catch (e) {
      print('Unexpected error getting prescription count: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
        'count': 0,
      };
    }
  }

  /// Check if prescription exists for doctor-patient pair
  static Future<Map<String, dynamic>?> checkExistingPrescription({
    required int doctorId,
    required int patientId,
  }) async {
    try {
      final response = await _supabase
          .from('Prescriptions')
          .select('prescriptions_id, prescribed_on, diagnosis, note')
          .eq('doctor_id', doctorId)
          .eq('patient_id', patientId)
          .order('prescribed_on', ascending: false)
          .limit(1)
          .maybeSingle();

      return {
        'success': true,
        'exists': response != null,
        'latest_prescription': response,
      };
    } on PostgrestException catch (e) {
      print('Supabase error checking existing prescription: ${e.message}');
      return {
        'success': false,
        'message': 'Failed to check existing prescription',
        'exists': false,
        'latest_prescription': null,
      };
    } catch (e) {
      print('Unexpected error checking existing prescription: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
        'exists': false,
        'latest_prescription': null,
      };
    }
  }
}
