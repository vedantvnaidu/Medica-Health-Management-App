// matchDoctorPatient.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'fetchData.dart';

class DoctorPatientService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetches all patients for a specific doctor
  /// Returns list of patient data with prescription details
  static Future<Map<String, dynamic>> getDoctorPatients({
    required String doctorId,
  }) async {
    try {
      // First, get all patient_ids from Prescriptions table for this doctor
      final prescriptionResponse = await _supabase
          .from('Prescriptions')
          .select('patient_id, prescribed_on, diagnosis')
          .eq('doctor_id', int.parse(doctorId))
          .order('prescribed_on', ascending: false);

      if (prescriptionResponse.isEmpty) {
        return {
          'success': true,
          'patients': <Map<String, dynamic>>[],
          'message': 'No patients found for this doctor'
        };
      }

      // Get unique patient IDs (in case same patient has multiple prescriptions)
      Set<int> uniquePatientIds = {};
      Map<int, Map<String, dynamic>> prescriptionData = {};

      for (var prescription in prescriptionResponse) {
        int patientId = prescription['patient_id'];
        uniquePatientIds.add(patientId);

        // Store the most recent prescription data for each patient
        if (!prescriptionData.containsKey(patientId)) {
          prescriptionData[patientId] = {
            'prescribed_on': prescription['prescribed_on'],
            'diagnosis': prescription['diagnosis'],
          };
        }
      }

      // Now fetch patient details for each unique patient_id
      List<Map<String, dynamic>> patients = [];

      for (int patientId in uniquePatientIds) {
        try {
          final patientData = await AuthService.getPatientById(patientId);

          if (patientData != null) {
            // Combine patient data with prescription data
            Map<String, dynamic> combinedData = Map.from(patientData);
            combinedData.addAll(prescriptionData[patientId]!);
            patients.add(combinedData);
          }
        } catch (e) {
          print('Error fetching patient $patientId: $e');
          // Continue with other patients even if one fails
        }
      }

      return {
        'success': true,
        'patients': patients,
        'message': 'Patients fetched successfully'
      };
    } on PostgrestException catch (e) {
      return {
        'success': false,
        'patients': <Map<String, dynamic>>[],
        'message': 'Database error: ${e.message}'
      };
    } catch (e) {
      return {
        'success': false,
        'patients': <Map<String, dynamic>>[],
        'message': 'An error occurred: ${e.toString()}'
      };
    }
  }

  /// Gets prescription history for a specific patient under this doctor
  static Future<List<Map<String, dynamic>>> getPatientPrescriptionHistory({
    required String doctorId,
    required String patientId,
  }) async {
    try {
      final response = await _supabase
          .from('Prescriptions')
          .select('*')
          .eq('doctor_id', int.parse(doctorId))
          .eq('patient_id', int.parse(patientId))
          .order('prescribed_on', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching prescription history: $e');
      return [];
    }
  }

  /// Adds a new prescription for a patient
  static Future<Map<String, dynamic>> addPrescription({
    required String doctorId,
    required String patientId,
    required String diagnosis,
  }) async {
    try {
      final response = await _supabase
          .from('Prescriptions')
          .insert({
            'doctor_id': int.parse(doctorId),
            'patient_id': int.parse(patientId),
            'diagnosis': diagnosis,
            'prescribed_on': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return {
        'success': true,
        'prescription': response,
        'message': 'Prescription added successfully'
      };
    } on PostgrestException catch (e) {
      return {
        'success': false,
        'prescription': null,
        'message': 'Database error: ${e.message}'
      };
    } catch (e) {
      return {
        'success': false,
        'prescription': null,
        'message': 'An error occurred: ${e.toString()}'
      };
    }
  }
}
