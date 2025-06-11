// fetchPatientDetails.dart - Updated Version

import 'package:supabase_flutter/supabase_flutter.dart';

class PatientDetailsService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetches complete patient details including prescriptions and medicines
  static Future<Map<String, dynamic>?> getCompletePatientDetails(
      int patientId) async {
    try {
      // Get patient basic information
      final patientData = await _getPatientBasicInfo(patientId);
      if (patientData == null) {
        return null;
      }

      // Get patient prescriptions with medicines
      final prescriptionsData =
          await _getPatientPrescriptionsWithMedicines(patientId);

      return {
        'patient': patientData,
        'prescriptions': prescriptionsData,
      };
    } catch (e) {
      print('Error fetching complete patient details: $e');
      return null;
    }
  }

  /// Gets basic patient information
  static Future<Map<String, dynamic>?> _getPatientBasicInfo(
      int patientId) async {
    try {
      final response = await _supabase
          .from('Patients')
          .select('*')
          .eq('patient_id', patientId)
          .single();

      return response;
    } catch (e) {
      print('Error fetching patient basic info: $e');
      return null;
    }
  }

  /// Gets all prescriptions for a patient with associated medicines
  static Future<List<Map<String, dynamic>>>
      _getPatientPrescriptionsWithMedicines(int patientId) async {
    try {
      // Get all prescriptions for the patient with doctor details
      final prescriptions = await _supabase
          .from('Prescriptions')
          .select('''
          *,
          Doctors (
            doctor_id,
            name,
            specialization
          )
        ''')
          .eq('patient_id', patientId)
          .order('prescribed_on', ascending: false);

      List<Map<String, dynamic>> prescriptionsWithMedicines = [];

      // For each prescription, get the associated medicines
      for (var prescription in prescriptions) {
        final prescriptionId = prescription['prescriptions_id'];

        // Get medicines for this prescription
        final medicines = await _getPrescriptionMedicines(prescriptionId);

        // Add medicines and doctor info to the prescription data
        Map<String, dynamic> prescriptionWithMedicines = Map.from(prescription);
        prescriptionWithMedicines['medicines'] = medicines;

        prescriptionsWithMedicines.add(prescriptionWithMedicines);
      }

      return prescriptionsWithMedicines;
    } catch (e) {
      print('Error fetching patient prescriptions: $e');
      return [];
    }
  }

  /// Gets medicines for a specific prescription
  static Future<List<Map<String, dynamic>>> _getPrescriptionMedicines(
      int prescriptionId) async {
    try {
      // Get prescription medicines with medicine details
      final prescriptionMedicines =
          await _supabase.from('Prescription_Medicines').select('''
            *,
            Medicines (
              medicine_id,
              name,
              form,
              description
            )
          ''').eq('prescription_id', prescriptionId);

      // Format the data for easier use
      List<Map<String, dynamic>> formattedMedicines = [];

      for (var prescMed in prescriptionMedicines) {
        final medicine = prescMed['Medicines'];

        formattedMedicines.add({
          'prescr_med_id': prescMed['prescr_med_id'],
          'medicine_id': prescMed['medicine_id'],
          'name': medicine['name'],
          'form': medicine['form'],
          'description': medicine['description'],
          'breakfast': prescMed['breakfast'],
          'lunch': prescMed['lunch'],
          'dinner': prescMed['dinner'],
          'dose_volume': prescMed['dose_volume'],
          'duration_days': prescMed['duration_days'],
        });
      }

      return formattedMedicines;
    } catch (e) {
      print('Error fetching prescription medicines: $e');
      return [];
    }
  }

  /// Gets formatted medicine data for dashboard display
  static Future<List<Map<String, dynamic>>> getFormattedMedicinesForDashboard(
      int patientId) async {
    try {
      final completeData = await getCompletePatientDetails(patientId);
      if (completeData == null || completeData['prescriptions'] == null) {
        return [];
      }

      List<Map<String, dynamic>> allMedicines = [];
      final prescriptions =
          completeData['prescriptions'] as List<Map<String, dynamic>>;

      for (var prescription in prescriptions) {
        final prescribedOn = prescription['prescribed_on'];
        final diagnosis = prescription['diagnosis'];
        final note = prescription['note'];
        final doctorData = prescription['Doctors'];
        final medicines =
            prescription['medicines'] as List<Map<String, dynamic>>;

        for (var medicine in medicines) {
          // Calculate end date based on duration
          DateTime startDate = DateTime.parse(prescribedOn);
          DateTime endDate =
              startDate.add(Duration(days: medicine['duration_days']));

          allMedicines.add({
            'name': medicine['name'],
            'type': medicine['form'],
            'description': medicine['description'],
            'start_date': prescribedOn,
            'end_date': endDate.toIso8601String(),
            'breakfast': _formatDosageForDisplay(
                medicine['breakfast'], medicine['dose_volume']),
            'lunch': _formatDosageForDisplay(
                medicine['lunch'], medicine['dose_volume']),
            'dinner': _formatDosageForDisplay(
                medicine['dinner'], medicine['dose_volume']),
            'duration_days': medicine['duration_days'],
            'diagnosis': diagnosis,
            'note': note,
            'doctor_name':
                doctorData != null ? doctorData['name'] : 'Unknown Doctor',
            'doctor_specialization':
                doctorData != null ? doctorData['specialization'] : 'Unknown',
          });
        }
      }

      return allMedicines;
    } catch (e) {
      print('Error formatting medicines for dashboard: $e');
      return [];
    }
  }

  /// Formats dosage information for display
  /// -1: before meal, 0: not prescribed, 1: after meal
  static String _formatDosageForDisplay(dynamic timingValue, String volume) {
    if (timingValue == null) return 'No';

    int timing;
    if (timingValue is int) {
      timing = timingValue;
    } else if (timingValue is String) {
      timing = int.tryParse(timingValue) ?? 0;
    } else {
      return 'No';
    }

    switch (timing) {
      case -1:
        return '-1 x $volume'; // Before meal
      case 1:
        return '1 x $volume'; // After meal
      case 0:
      default:
        return 'No'; // Not prescribed
    }
  }

  /// Legacy method for backward compatibility
  /// @deprecated Use _formatDosageForDisplay instead
  static String _formatDosage(int count, String volume) {
    if (count == 0) return 'No';
    return '$count x $volume';
  }

  /// Gets all prescriptions for a patient (without medicines details)
  static Future<List<Map<String, dynamic>>> getPatientPrescriptions(
      int patientId) async {
    try {
      final response = await _supabase
          .from('Prescriptions')
          .select('''
            *,
            Doctors (
              name,
              specialization
            )
          ''')
          .eq('patient_id', patientId)
          .order('prescribed_on', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching patient prescriptions: $e');
      return [];
    }
  }

  /// Gets current active medicines for a patient
  static Future<List<Map<String, dynamic>>> getCurrentActiveMedicines(
      int patientId) async {
    try {
      final allMedicines = await getFormattedMedicinesForDashboard(patientId);
      final currentDate = DateTime.now();

      // Filter medicines that are currently active
      final activeMedicines = allMedicines.where((medicine) {
        try {
          final startDate = DateTime.parse(medicine['start_date']);
          final endDate = DateTime.parse(medicine['end_date']);

          return currentDate.isAfter(startDate) &&
              currentDate.isBefore(endDate);
        } catch (e) {
          print('Error parsing dates for medicine: ${medicine['name']}');
          return false;
        }
      }).toList();

      return activeMedicines;
    } catch (e) {
      print('Error fetching current active medicines: $e');
      return [];
    }
  }

  /// Gets medicine history for a patient
  static Future<List<Map<String, dynamic>>> getMedicineHistory(
      int patientId) async {
    try {
      final allMedicines = await getFormattedMedicinesForDashboard(patientId);
      final currentDate = DateTime.now();

      // Filter medicines that have ended
      final historyMedicines = allMedicines.where((medicine) {
        try {
          final endDate = DateTime.parse(medicine['end_date']);
          return currentDate.isAfter(endDate);
        } catch (e) {
          print('Error parsing end date for medicine: ${medicine['name']}');
          return false;
        }
      }).toList();

      // Sort by end date (most recent first)
      historyMedicines.sort((a, b) {
        try {
          final dateA = DateTime.parse(a['end_date']);
          final dateB = DateTime.parse(b['end_date']);
          return dateB.compareTo(dateA);
        } catch (e) {
          return 0;
        }
      });

      return historyMedicines;
    } catch (e) {
      print('Error fetching medicine history: $e');
      return [];
    }
  }

  /// Helper method to parse timing value and return readable format
  /// -1: Before meal, 0: Not prescribed, 1: After meal
  static Map<String, dynamic> parseDosageTiming(
      dynamic timingValue, String volume) {
    if (timingValue == null) {
      return {'prescribed': false, 'timing': 'Not prescribed', 'dosage': 'No'};
    }

    int timing;
    if (timingValue is int) {
      timing = timingValue;
    } else if (timingValue is String) {
      timing = int.tryParse(timingValue) ?? 0;
    } else {
      return {'prescribed': false, 'timing': 'Not prescribed', 'dosage': 'No'};
    }

    switch (timing) {
      case -1:
        return {
          'prescribed': true,
          'timing': 'Before meal',
          'dosage': volume,
          'timingCode': -1
        };
      case 1:
        return {
          'prescribed': true,
          'timing': 'After meal',
          'dosage': volume,
          'timingCode': 1
        };
      case 0:
      default:
        return {
          'prescribed': false,
          'timing': 'Not prescribed',
          'dosage': 'No'
        };
    }
  }

  /// Gets detailed medicine schedule for a specific medicine
  static Map<String, dynamic> getMedicineScheduleDetails(
      Map<String, dynamic> medicine) {
    return {
      'breakfast': parseDosageTiming(
          medicine['breakfast'], medicine['dose_volume'] ?? 'tablet'),
      'lunch': parseDosageTiming(
          medicine['lunch'], medicine['dose_volume'] ?? 'tablet'),
      'dinner': parseDosageTiming(
          medicine['dinner'], medicine['dose_volume'] ?? 'tablet'),
    };
  }
}
