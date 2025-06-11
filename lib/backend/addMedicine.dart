// addMedicine.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medica_test/doctor/medicineDetail.dart';

class MedicineService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Convert meal timing string to database integer value
  static int _convertMealTiming(String timing) {
    switch (timing.toLowerCase()) {
      case 'before':
        return -1;
      case 'after':
        return 1;
      case 'no':
      default:
        return 0;
    }
  }

  /// Calculate duration in days between start and end date
  static int _calculateDurationDays(DateTime startDate, DateTime endDate) {
    return endDate.difference(startDate).inDays +
        1; // +1 to include both start and end dates
  }

  /// Get medicine ID from the Medicines table by name and form
  static Future<int?> _getMedicineId(String medicineName, String form) async {
    try {
      final response = await _supabase
          .from('Medicines')
          .select('medicine_id')
          .eq('name', medicineName)
          .eq('form', form)
          .maybeSingle();

      return response?['medicine_id'];
    } catch (e) {
      print('Error fetching medicine ID: $e');
      return null;
    }
  }

  /// Save medicines to Prescription_Medicines table
  static Future<Map<String, dynamic>> savePrescriptionMedicines({
    required int prescriptionId,
    required List<MedicineEntry> medicines,
  }) async {
    try {
      // Validate that all medicines have required data
      for (int i = 0; i < medicines.length; i++) {
        final medicine = medicines[i];

        if (medicine.nameController.text.trim().isEmpty) {
          return {
            'success': false,
            'message': 'Medicine ${i + 1}: Name is required',
          };
        }

        if (medicine.startDate == null || medicine.endDate == null) {
          return {
            'success': false,
            'message': 'Medicine ${i + 1}: Start and end dates are required',
          };
        }

        if (medicine.startDate!.isAfter(medicine.endDate!)) {
          return {
            'success': false,
            'message': 'Medicine ${i + 1}: Start date cannot be after end date',
          };
        }
      }

      // Delete existing medicines for this prescription first
      await _supabase
          .from('Prescription_Medicines')
          .delete()
          .eq('prescription_id', prescriptionId);

      // Prepare data for batch insert
      List<Map<String, dynamic>> medicineData = [];

      for (int i = 0; i < medicines.length; i++) {
        final medicine = medicines[i];

        // Get medicine ID from database
        int? medicineId = medicine.medicineId ??
            await _getMedicineId(
                medicine.nameController.text.trim(), medicine.form);

        if (medicineId == null) {
          return {
            'success': false,
            'message':
                'Medicine ${i + 1}: Could not find medicine "${medicine.nameController.text}" in database',
          };
        }

        // Calculate duration in days
        int durationDays =
            _calculateDurationDays(medicine.startDate!, medicine.endDate!);

        // Prepare medicine data
        medicineData.add({
          'prescription_id': prescriptionId,
          'medicine_id': medicineId,
          'breakfast': _convertMealTiming(medicine.beforeAfterBreakfast),
          'lunch': _convertMealTiming(medicine.beforeAfterLunch),
          'dinner': _convertMealTiming(medicine.beforeAfterDinner),
          'dose_volume': medicine.dosageController.text.trim().isEmpty
              ? 'As prescribed'
              : medicine.dosageController.text.trim(),
          'duration_days': durationDays,
        });
      }

      // Insert all medicines in batch
      if (medicineData.isNotEmpty) {
        await _supabase.from('Prescription_Medicines').insert(medicineData);
      }

      return {
        'success': true,
        'message':
            'Successfully saved ${medicineData.length} medicine(s) to prescription',
        'medicines_count': medicineData.length,
      };
    } on PostgrestException catch (e) {
      print('Supabase error saving prescription medicines: ${e.message}');
      return {
        'success': false,
        'message': 'Database error: ${e.message}',
      };
    } catch (e) {
      print('Unexpected error saving prescription medicines: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred while saving medicines: $e',
      };
    }
  }

  /// Get medicines for a prescription
  static Future<Map<String, dynamic>> getPrescriptionMedicines(
      int prescriptionId) async {
    try {
      final response = await _supabase
          .from('Prescription_Medicines')
          .select('''
            prescr_med_id,
            prescription_id,
            medicine_id,
            breakfast,
            lunch,
            dinner,
            dose_volume,
            duration_days,
            Medicines!inner(name, form, description)
          ''')
          .eq('prescription_id', prescriptionId)
          .order('prescr_med_id', ascending: true);

      return {
        'success': true,
        'medicines': response,
      };
    } on PostgrestException catch (e) {
      print('Supabase error getting prescription medicines: ${e.message}');
      return {
        'success': false,
        'message': 'Failed to load medicines: ${e.message}',
        'medicines': [],
      };
    } catch (e) {
      print('Unexpected error getting prescription medicines: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
        'medicines': [],
      };
    }
  }

  /// Delete a specific medicine from prescription
  static Future<Map<String, dynamic>> deletePrescriptionMedicine(
      int prescrMedId) async {
    try {
      await _supabase
          .from('Prescription_Medicines')
          .delete()
          .eq('prescr_med_id', prescrMedId);

      return {
        'success': true,
        'message': 'Medicine removed from prescription successfully',
      };
    } on PostgrestException catch (e) {
      print('Supabase error deleting prescription medicine: ${e.message}');
      return {
        'success': false,
        'message': 'Failed to remove medicine: ${e.message}',
      };
    } catch (e) {
      print('Unexpected error deleting prescription medicine: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Update a specific medicine in prescription
  static Future<Map<String, dynamic>> updatePrescriptionMedicine({
    required int prescrMedId,
    required int medicineId,
    required String breakfast,
    required String lunch,
    required String dinner,
    required String doseVolume,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      int durationDays = _calculateDurationDays(startDate, endDate);

      await _supabase.from('Prescription_Medicines').update({
        'medicine_id': medicineId,
        'breakfast': _convertMealTiming(breakfast),
        'lunch': _convertMealTiming(lunch),
        'dinner': _convertMealTiming(dinner),
        'dose_volume':
            doseVolume.trim().isEmpty ? 'As prescribed' : doseVolume.trim(),
        'duration_days': durationDays,
      }).eq('prescr_med_id', prescrMedId);

      return {
        'success': true,
        'message': 'Medicine updated successfully',
      };
    } on PostgrestException catch (e) {
      print('Supabase error updating prescription medicine: ${e.message}');
      return {
        'success': false,
        'message': 'Failed to update medicine: ${e.message}',
      };
    } catch (e) {
      print('Unexpected error updating prescription medicine: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Get medicines count for a prescription
  static Future<Map<String, dynamic>> getPrescriptionMedicinesCount(
      int prescriptionId) async {
    try {
      final int count = await _supabase
          .from('Prescription_Medicines')
          .count()
          .eq('prescription_id', prescriptionId);

      return {
        'success': true,
        'count': count,
      };
    } on PostgrestException catch (e) {
      print('Supabase error getting medicines count: ${e.message}');
      return {
        'success': false,
        'message': 'Failed to get medicines count: ${e.message}',
        'count': 0,
      };
    } catch (e) {
      print('Unexpected error getting medicines count: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
        'count': 0,
      };
    }
  }

  /// Convert database meal timing integer back to string (for reading data)
  static String convertMealTimingToString(int timing) {
    switch (timing) {
      case -1:
        return 'Before';
      case 1:
        return 'After';
      case 0:
      default:
        return 'No';
    }
  }

  /// Validate medicine data before saving
  static Map<String, dynamic> validateMedicineData(
      List<MedicineEntry> medicines) {
    if (medicines.isEmpty) {
      return {
        'valid': false,
        'message': 'At least one medicine is required',
      };
    }

    for (int i = 0; i < medicines.length; i++) {
      final medicine = medicines[i];

      if (medicine.nameController.text.trim().isEmpty) {
        return {
          'valid': false,
          'message': 'Medicine ${i + 1}: Name is required',
        };
      }

      if (medicine.startDate == null || medicine.endDate == null) {
        return {
          'valid': false,
          'message': 'Medicine ${i + 1}: Start and end dates are required',
        };
      }

      if (medicine.startDate!.isAfter(medicine.endDate!)) {
        return {
          'valid': false,
          'message': 'Medicine ${i + 1}: Start date cannot be after end date',
        };
      }

      // Check if at least one meal timing is not "No"
      if (medicine.beforeAfterBreakfast == 'No' &&
          medicine.beforeAfterLunch == 'No' &&
          medicine.beforeAfterDinner == 'No') {
        return {
          'valid': false,
          'message':
              'Medicine ${i + 1}: Please select at least one meal timing (Breakfast, Lunch, or Dinner)',
        };
      }
    }

    return {
      'valid': true,
      'message': 'All medicine data is valid',
    };
  }
}
