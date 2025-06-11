//decryptQr.dart

import 'package:flutter/material.dart';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;
import 'package:shared_preferences/shared_preferences.dart';
import 'fetchData.dart'; // Import your AuthService
import 'addPrescription.dart'; // Import PrescriptionService

class AddPatientPopup extends StatefulWidget {
  final String qrData;
  final Function(Map<String, dynamic>) onAddPatient;
  final VoidCallback onScanAgain;

  const AddPatientPopup({
    Key? key,
    required this.qrData,
    required this.onAddPatient,
    required this.onScanAgain,
  }) : super(key: key);

  @override
  _AddPatientPopupState createState() => _AddPatientPopupState();
}

class _AddPatientPopupState extends State<AddPatientPopup> {
  String? decryptedData;
  String? errorMessage;
  Map<String, dynamic>? patientData;
  bool isLoading = false;
  bool isCreatingPrescription = false;
  String? patientId;
  int? currentDoctorId;

  @override
  void initState() {
    super.initState();
    _loadDoctorData();
    _decryptAndFetchPatientData();
  }

  // Load current doctor data from SharedPreferences
  Future<void> _loadDoctorData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? doctorIdString = prefs.getString('current_doctor_id');

      if (doctorIdString != null && doctorIdString.isNotEmpty) {
        currentDoctorId = int.tryParse(doctorIdString);
        print('Current doctor ID loaded: $currentDoctorId');
      } else {
        print('No doctor ID found in preferences');
      }
    } catch (e) {
      print('Error loading doctor data: $e');
    }
  }

  void _decryptAndFetchPatientData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Try to decrypt the QR data
      final decrypted = _decryptData(widget.qrData);
      setState(() {
        decryptedData = decrypted;
      });

      // Extract patient_id from decrypted data
      patientId = _extractPatientId(decrypted);

      if (patientId != null && patientId!.isNotEmpty) {
        // Fetch patient data from database
        await _fetchPatientFromDatabase(int.parse(patientId!));
      } else {
        throw Exception('No valid patient_id found in QR code');
      }
    } catch (e) {
      // If decryption fails, try to parse as plain text
      try {
        setState(() {
          decryptedData = widget.qrData;
        });

        patientId = _extractPatientId(widget.qrData);

        if (patientId != null && patientId!.isNotEmpty) {
          await _fetchPatientFromDatabase(int.parse(patientId!));
        } else {
          throw Exception('No valid patient_id found in QR code');
        }
      } catch (parseError) {
        setState(() {
          errorMessage =
              'Failed to decrypt QR code or extract patient ID: ${parseError.toString()}';
          isLoading = false;
          patientData = null;
        });
      }
    }
  }

  String _decryptData(String base64Text) {
    try {
      final key = encrypt_pkg.Key.fromUtf8('my32lengthsupersecretnooneknows1');
      final iv = encrypt_pkg.IV.fromUtf8('8bytesiv12345678');
      final encrypter = encrypt_pkg.Encrypter(
        encrypt_pkg.AES(key, mode: encrypt_pkg.AESMode.cbc),
      );
      final encrypted = encrypt_pkg.Encrypted.fromBase64(base64Text);
      final decrypted = encrypter.decrypt(encrypted, iv: iv);
      return decrypted;
    } catch (e) {
      throw Exception('Decryption failed: ${e.toString()}');
    }
  }

  String? _extractPatientId(String data) {
    // If the decrypted data is just the patient_id
    if (RegExp(r'^\d+$').hasMatch(data.trim())) {
      return data.trim();
    }

    // If it's comma-separated values and patient_id is at a specific position
    List<String> parts = data.split(',');
    if (parts.length > 5) {
      return parts[5].trim(); // Assuming patient_id is at index 5
    }

    // If it's JSON format
    if (data.trim().startsWith('{') && data.trim().endsWith('}')) {
      try {
        // You might need to use json.decode here if you have JSON data
        // For now, we'll try to extract patient_id from a simple pattern
        RegExp regExp = RegExp(r'"patient_id"\s*:\s*"?(\d+)"?');
        Match? match = regExp.firstMatch(data);
        if (match != null) {
          return match.group(1);
        }
      } catch (e) {
        print('Error parsing JSON: $e');
      }
    }

    return null;
  }

  Future<void> _fetchPatientFromDatabase(int patientId) async {
    try {
      final fetchedPatientData = await AuthService.getPatientById(patientId);

      if (fetchedPatientData != null) {
        setState(() {
          patientData = {
            'patient_id': fetchedPatientData['patient_id']?.toString() ?? '',
            'name': fetchedPatientData['name'] ?? 'N/A',
            'age': fetchedPatientData['age'] ?? 0,
            'gender': _getGenderString(fetchedPatientData['gender']),
            'contact': fetchedPatientData['contact']?.toString() ?? 'N/A',
            'address': fetchedPatientData['address'] ?? 'N/A',
            'dob': fetchedPatientData['dob'] ?? 'N/A',
            'currentdate': DateTime.now().toString().split(' ')[0],
          };
          isLoading = false;
          errorMessage = null;
        });
      } else {
        setState(() {
          errorMessage = 'Patient not found in database';
          isLoading = false;
          patientData = null;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to fetch patient data: ${e.toString()}';
        isLoading = false;
        patientData = null;
      });
    }
  }

  // Create prescription for the patient
  Future<void> _createPrescription() async {
    if (currentDoctorId == null || patientId == null) {
      _showErrorDialog('Missing doctor or patient information');
      return;
    }

    setState(() {
      isCreatingPrescription = true;
    });

    try {
      // Check if prescription already exists
      final existingResult =
          await PrescriptionService.checkExistingPrescription(
        doctorId: currentDoctorId!,
        patientId: int.parse(patientId!),
      );

      if (existingResult?['exists'] == true) {
        // Show confirmation dialog for existing prescription
        bool shouldContinue = await _showConfirmationDialog(
          'Prescription Already Exists',
          'A prescription already exists for this patient. Do you want to create a new one?',
        );

        if (!shouldContinue) {
          setState(() {
            isCreatingPrescription = false;
          });
          return;
        }
      }

      // Create new prescription
      final result = await PrescriptionService.createPrescription(
        doctorId: currentDoctorId!,
        patientId: int.parse(patientId!),
      );

      if (result?['success'] == true) {
        // Success - show success dialog and add patient
        await _showSuccessDialog('Prescription created successfully!');
        widget.onAddPatient(patientData!);
      } else {
        _showErrorDialog(result?['message'] ?? 'Failed to create prescription');
      }
    } catch (e) {
      _showErrorDialog('An error occurred while creating prescription: $e');
    } finally {
      setState(() {
        isCreatingPrescription = false;
      });
    }
  }

  Future<bool> _showConfirmationDialog(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Continue'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _showSuccessDialog(String message) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Success'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showErrorDialog(String message) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getGenderString(dynamic gender) {
    if (gender == null) return 'Unknown';
    if (gender is int) {
      switch (gender) {
        case 1:
          return 'Male';
        case 2:
          return 'Female';
        case 3:
          return 'Other';
        default:
          return 'Unknown';
      }
    }
    return gender.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.8),
        child: Center(
          child: Container(
            margin: EdgeInsets.all(20),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'QR Code Detected',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 16),

                  if (isLoading) ...[
                    Container(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Fetching patient data...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (errorMessage != null) ...[
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 24),
                          SizedBox(height: 8),
                          Text(
                            errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Raw QR Data:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            widget.qrData,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                              fontFamily: 'monospace',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (decryptedData != null &&
                              decryptedData != widget.qrData) ...[
                            SizedBox(height: 4),
                            Text(
                              'Decrypted Data:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              decryptedData!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                                fontFamily: 'monospace',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ] else if (patientData != null) ...[
                    // Show decryption success info
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.verified_user,
                                  color: Colors.green, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Patient Data Retrieved',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Patient ID: ${patientId ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (currentDoctorId != null) ...[
                            SizedBox(height: 2),
                            Text(
                              'Doctor ID: $currentDoctorId',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: 16),

                    // Patient information display
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Patient Information:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 12),
                          _buildInfoRow('Name', patientData!['name'] ?? 'N/A'),
                          _buildInfoRow(
                              'Age', '${patientData!['age'] ?? 'N/A'}'),
                          _buildInfoRow(
                              'Gender', patientData!['gender'] ?? 'N/A'),
                          _buildInfoRow(
                              'Contact', patientData!['contact'] ?? 'N/A'),
                          _buildInfoRow(
                              'Address', patientData!['address'] ?? 'N/A'),
                          _buildInfoRow(
                              'Date of Birth', patientData!['dob'] ?? 'N/A'),
                          _buildInfoRow('Patient ID',
                              patientData!['patient_id'] ?? 'N/A'),
                          _buildInfoRow('Scanned Date',
                              patientData!['currentdate'] ?? 'N/A'),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: 24),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (patientData != null &&
                          errorMessage == null &&
                          !isLoading)
                        ElevatedButton(
                          onPressed: isCreatingPrescription
                              ? null
                              : _createPrescription,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          child: isCreatingPrescription
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text('Creating...'),
                                  ],
                                )
                              : Text('Add Patient'),
                        ),
                      ElevatedButton(
                        onPressed: (isLoading || isCreatingPrescription)
                            ? null
                            : widget.onScanAgain,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: Text('Scan Again'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
