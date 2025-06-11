// patientDetail.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'medicineDetail.dart';
import 'package:medica_test/backend/addMedicine.dart';

// Updated database service to use Supabase
// Updated DatabaseService class for patientDetail.dart
class DatabaseService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Get patient data by ID from Supabase
  static Future<Map<String, dynamic>?> getPatientById(String patientId) async {
    try {
      final response = await _supabase
          .from('Patients')
          .select('*')
          .eq('patient_id', int.parse(patientId))
          .single();

      return response;
    } catch (e) {
      print('Error fetching patient data: $e');
      return null;
    }
  }

  // Get prescription data for a patient (Updated to include note)
  static Future<Map<String, dynamic>?> getPatientPrescription(
      String patientId, String doctorId) async {
    try {
      final response = await _supabase
          .from('Prescriptions')
          .select('*') // This will include diagnosis and note
          .eq('patient_id', int.parse(patientId))
          .eq('doctor_id', int.parse(doctorId))
          .order('prescribed_on', ascending: false)
          .limit(1)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error fetching prescription data: $e');
      return null;
    }
  }

  // Get all medicines from Supabase
  static Future<List<Map<String, dynamic>>> getAllMedicines() async {
    try {
      final response = await _supabase
          .from('Medicines')
          .select('*')
          .order('name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching medicines: $e');
      return [];
    }
  }

  // Get medicines by form
  static Future<List<Map<String, dynamic>>> getMedicinesByForm(
      String form) async {
    try {
      final response = await _supabase
          .from('Medicines')
          .select('*')
          .eq('form', form)
          .order('name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching medicines by form: $e');
      return [];
    }
  }

  // Update or create prescription (Already includes note)
  static Future<Map<String, dynamic>> updatePrescription({
    required String patientId,
    required String doctorId,
    required String diagnosis,
    required String note,
    int? prescriptionId,
  }) async {
    try {
      if (prescriptionId != null) {
        // Update existing prescription
        final response = await _supabase
            .from('Prescriptions')
            .update({
              'diagnosis': diagnosis,
              'note': note,
              'prescribed_on': DateTime.now().toIso8601String(),
            })
            .eq('prescriptions_id', prescriptionId)
            .select()
            .single();

        return {
          'success': true,
          'data': response,
          'message': 'Prescription updated successfully'
        };
      } else {
        // Create new prescription
        final response = await _supabase
            .from('Prescriptions')
            .insert({
              'doctor_id': int.parse(doctorId),
              'patient_id': int.parse(patientId),
              'diagnosis': diagnosis,
              'note': note,
              'prescribed_on': DateTime.now().toIso8601String(),
            })
            .select()
            .single();

        return {
          'success': true,
          'data': response,
          'message': 'Prescription created successfully'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'data': null,
        'message': 'Error saving prescription: $e'
      };
    }
  }
}

// Local database service for medicines (keeping existing functionality)
class LocalDatabaseService {
  static final LocalDatabaseService _instance =
      LocalDatabaseService._internal();

  factory LocalDatabaseService() {
    return _instance;
  }

  LocalDatabaseService._internal();

  // Save medicines for a patient
  Future<void> saveMedicines(
      String patientId, List<Map<String, dynamic>> medicines) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'medicines_$patientId';
    await prefs.setString(key, jsonEncode(medicines));
  }

  // Get medicines for a patient
  Future<List<Map<String, dynamic>>> getMedicinesByPatientId(
      String patientId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'medicines_$patientId';
    final medicinesJson = prefs.getString(key);
    if (medicinesJson == null) return [];

    return List<Map<String, dynamic>>.from(jsonDecode(medicinesJson)
        .map((item) => Map<String, dynamic>.from(item)));
  }
}

// Helper class for dosage suggestions
class DosageSuggestions {
  static const Map<String, List<String>> _suggestions = {
    'Syrup': ['Half a spoon', 'One spoon', 'Two spoons'],
    'Tablet': ['Half tablet', 'One tablet', 'Two tablets'],
    'Capsule': ['One capsule', 'Two capsules', 'Three capsules'],
    'Drops': ['1 drop', '2 drops', '3 drops', '4 drops', '5 drops'],
    'Patch': ['One patch', 'Two patches'],
    // Forms without dosage suggestions: Injection, Inhaler, Gel, Cream, Ointment
  };

  static List<String>? getSuggestions(String form) {
    return _suggestions[form];
  }

  static bool hasDosageSuggestions(String form) {
    return _suggestions.containsKey(form);
  }
}

class PatientDetailScreen extends StatefulWidget {
  final String id;

  const PatientDetailScreen({
    Key? key,
    required this.id,
  }) : super(key: key);

  @override
  _PatientDetailScreenState createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  final _localDb = LocalDatabaseService();
  Map<String, dynamic>? _patientData;
  Map<String, dynamic>? _prescriptionData;
  bool _isLoading = true;
  String? _error;
  String _currentDoctorId = '';
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  List<MedicineEntry> _medicines = [MedicineEntry()];

  @override
  void initState() {
    super.initState();
    _loadDoctorId();
  }

  @override
  void dispose() {
    for (var medicine in _medicines) {
      medicine.dispose();
    }
    _diagnosisController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctorId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentDoctorId = prefs.getString('current_doctor_id') ?? '';
      await _fetchPatientData();
    } catch (e) {
      setState(() {
        _error = 'Error loading doctor data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchPatientData() async {
    try {
      // Fetch patient details from Supabase
      final patientData = await DatabaseService.getPatientById(widget.id);

      if (patientData == null) {
        throw 'Patient not found';
      }

      // Fetch prescription data
      final prescriptionData = await DatabaseService.getPatientPrescription(
          widget.id, _currentDoctorId);

      // Fetch medicines for this patient from local storage
      final medicinesData = await _localDb.getMedicinesByPatientId(widget.id);

      setState(() {
        _patientData = patientData;
        _prescriptionData = prescriptionData;

        // Set diagnosis and note text
        _diagnosisController.text = prescriptionData?['diagnosis'] ?? '';
        _noteController.text = prescriptionData?['note'] ?? '';

        // Clear existing medicines
        for (var medicine in _medicines) {
          medicine.dispose();
        }

        // Convert response to MedicineEntry objects
        if (medicinesData.isNotEmpty) {
          _medicines = List<MedicineEntry>.from(
              medicinesData.map((med) => MedicineEntry.fromJson(med)));
        } else {
          _medicines = [MedicineEntry()]; // Default empty medicine entry
        }

        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = 'Error fetching data: $error';
        _isLoading = false;
      });
    }
  }

  // Updated _savePrescriptionAndMedicines method for patientDetail.dart
// Add this import at the top of patientDetail.dart:
// import 'addMedicine.dart';

  Future<void> _savePrescriptionAndMedicines() async {
    try {
      // 1️⃣ Validate prescription-level fields:
      final diagnosisText = _diagnosisController.text.trim();
      if (diagnosisText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a diagnosis.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // (Optional) Require a note:
      // final noteText = _noteController.text.trim();
      // if (noteText.isEmpty) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(
      //       content: Text('Please enter a note.'),
      //       backgroundColor: Colors.red,
      //     ),
      //   );
      //   return;
      // }

      // 2️⃣ Validate each medicine entry:
      // Expect validateMedicineData to return:
      // { 'valid': bool, 'field': String, 'message': String }
      final validationResult = MedicineService.validateMedicineData(_medicines);
      if (!validationResult['valid']) {
        final field = validationResult['field'] ?? 'Medicine';
        final message = validationResult['message'] ?? 'is invalid';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$field $message'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 3️⃣ Show loading indicator:
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // 4️⃣ Save or update prescription:
      final prescriptionResult = await DatabaseService.updatePrescription(
        patientId: widget.id,
        doctorId: _currentDoctorId,
        diagnosis: diagnosisText,
        note: _noteController.text.trim(),
        prescriptionId: _prescriptionData?['prescriptions_id'],
      );

      if (!prescriptionResult['success']) {
        throw prescriptionResult['message'];
      }

      final prescriptionId = prescriptionResult['data']['prescriptions_id'];

      // 5️⃣ Save prescription_medicines:
      final medicineResult = await MedicineService.savePrescriptionMedicines(
        prescriptionId: prescriptionId,
        medicines: _medicines,
      );

      if (!medicineResult['success']) {
        throw medicineResult['message'];
      }

      // 6️⃣ Persist to local storage:
      final medicineDataList =
          _medicines.map((m) => m.toJson()).toList(growable: false);
      await _localDb.saveMedicines(widget.id, medicineDataList);

      // 7️⃣ Dismiss loading:
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // 8️⃣ Show success SnackBar:
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Prescription and ${medicineResult['medicines_count']} medicine(s) saved successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      // 9️⃣ Refresh the screen:
      await _fetchPatientData();
    } catch (error) {
      // Dismiss loading if still showing:
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      // Show error SnackBar:
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Not available';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _formatDateTime(String? dateString) {
    if (dateString == null) return 'Not available';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }

  Future<void> _selectDateRange(BuildContext context, int index) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _medicines[index].startDate = picked.start;
        _medicines[index].endDate = picked.end;
      });
    }
  }

  void _addNewMedicine() {
    setState(() {
      _medicines.add(MedicineEntry());
    });
  }

  void _removeMedicine(int index) {
    if (_medicines.length > 1) {
      _medicines[index].dispose();
      setState(() {
        _medicines.removeAt(index);
      });
    }
  }

  String _getGenderString(int? gender) {
    switch (gender) {
      case 0:
        return 'Female';
      case 1:
        return 'Male';
      case 2:
        return 'Other';
      default:
        return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text(_error!)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_patientData?['name'] ?? 'Patient Details'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Patient Details',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildPatientInfo(),
              const SizedBox(height: 16),
              ..._medicines.asMap().entries.map((entry) {
                final index = entry.key;
                return Column(
                  children: [
                    MedicineEntryWidget(
                      entry: _medicines[index],
                      index: index,
                      onRemove: _medicines.length > 1
                          ? () => _removeMedicine(index)
                          : null,
                      onDateRangeSelect: () => _selectDateRange(context, index),
                      onUpdate: () => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }).toList(),
              TextButton.icon(
                onPressed: _addNewMedicine,
                icon: const Icon(Icons.add),
                label: const Text('Add a new Medicine'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 16),
              // Note text field
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: "Note",
                  border: OutlineInputBorder(),
                  hintText: "Enter additional notes...",
                ),
                maxLines: 3,
                minLines: 2,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _savePrescriptionAndMedicines,
                child: const Text("Save Prescription & Medicines"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientInfo() {
    return Card(
      elevation: 2,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${_patientData?['name'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                Text('Age: ${_patientData?['age']?.toString() ?? 'N/A'}',
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                Text('Gender: ${_getGenderString(_patientData?['gender'])}',
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                Text('Date of Birth: ${_formatDate(_patientData?['dob'])}',
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                Text(
                    'Contact: ${_patientData?['contact']?.toString() ?? 'N/A'}',
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                Text(
                    'Last Visited: ${_formatDateTime(_prescriptionData?['prescribed_on'])}',
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 16),
                // Diagnosis text field
                TextField(
                  controller: _diagnosisController,
                  decoration: const InputDecoration(
                    labelText: "Diagnosis",
                    border: OutlineInputBorder(),
                    hintText: "Enter patient diagnosis...",
                  ),
                  maxLines: 3,
                  minLines: 2,
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Text(
              'ID: ${_patientData?['patient_id'] ?? 'N/A'}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
