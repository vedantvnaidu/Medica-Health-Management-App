// patientDashboard.dart - With Pull-to-Refresh Functionality

import 'package:flutter/material.dart';
import 'package:medica_test/backend/fetchData.dart';
import 'package:medica_test/backend/fetchPatientDetails.dart';
import 'package:medica_test/backend/createQr.dart';

class PatientDashboardScreen extends StatefulWidget {
  final int userId;

  const PatientDashboardScreen({Key? key, required this.userId})
      : super(key: key);

  @override
  _PatientDashboardScreenState createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  List<Map<String, dynamic>> medicines = [];
  Map<String, dynamic>? patientDetails;
  bool isLoading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      setState(() {
        isLoading = true;
        error = '';
      });

      // Fetch patient basic details
      final patientData = await AuthService.getPatientById(widget.userId);

      if (patientData != null) {
        final formattedPatientData = {
          'name': patientData['name'] ?? 'Unknown',
          'age': patientData['age'] ?? 0,
          'gender': _convertGenderToString(patientData['gender']),
          'dob': patientData['dob'] ?? '',
        };

        // Fetch medicines using the new service
        final medicineData =
            await PatientDetailsService.getFormattedMedicinesForDashboard(
                widget.userId);

        setState(() {
          patientDetails = formattedPatientData;
          medicines = medicineData;
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to fetch patient data';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Failed to fetch data: ${e.toString()}';
        isLoading = false;
      });
      print('Error fetching patient data: $e');
    }
  }

  // Pull-to-refresh method
  Future<void> _refreshData() async {
    await fetchData();
  }

  String _convertGenderToString(dynamic gender) {
    if (gender == null) return 'Unknown';
    switch (gender) {
      case 1:
        return 'Male';
      case 0:
        return 'Female';
      case -1:
        return 'Other';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Patient Dashboard'),
        actions: [
          IconButton(icon: Icon(Icons.search), onPressed: () {}),
          IconButton(icon: Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      drawer: Drawer(),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : error.isNotEmpty
                ? _buildErrorContent()
                : _buildMainContent(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.view_list),
            label: 'Habits',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'To Do\'s',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: 'Rewards',
          ),
        ],
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.black,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildErrorContent() {
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height - 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                error,
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: fetchData,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          _buildPatientDetailsCard(context),
          _buildMedicinesList(),
        ],
      ),
    );
  }

  Widget _buildPatientDetailsCard(BuildContext context) {
    if (patientDetails == null) return SizedBox.shrink();

    return Card(
      margin: EdgeInsets.all(16),
      color: Colors.grey[800],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Patient Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.qr_code, color: Colors.white),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          QrCodeDialog(patientId: widget.userId),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Name', patientDetails!['name']),
                      SizedBox(height: 8),
                      _buildDetailRow('Age', '${patientDetails!['age']} years'),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Gender', patientDetails!['gender']),
                      SizedBox(height: 8),
                      _buildDetailRow(
                          'DOB', _formatDate(patientDetails!['dob'])),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMedicinesList() {
    if (medicines.isEmpty) {
      return Container(
        height: 200,
        child: Center(
          child: Text(
            'No medicines found',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: medicines.asMap().entries.map((entry) {
          final index = entry.key;
          final medicine = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Card(
              color: Colors.grey[800],
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Medicine header section
                    _buildMedicineHeader(medicine),
                    SizedBox(height: 16),

                    // Duration and dates section
                    _buildDurationSection(medicine),
                    SizedBox(height: 16),

                    // Dosage schedule section
                    _buildDosageSchedule(medicine),

                    // Description section (if available)
                    if (medicine['description'] != null &&
                        medicine['description'].toString().isNotEmpty)
                      _buildDescriptionSection(medicine['description']),

                    // Diagnosis section (if available)
                    if (medicine['diagnosis'] != null &&
                        medicine['diagnosis'].toString().isNotEmpty)
                      _buildDiagnosisSection(medicine['diagnosis']),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMedicineHeader(Map<String, dynamic> medicine) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.medical_services,
                color: Colors.green,
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicine['name'] ?? 'Unknown Medicine',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Type: ${medicine['type'] ?? 'Unknown'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Doctor information section
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.indigo.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.person_outline,
                color: Colors.indigo[200],
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prescribed by',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.indigo[200],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Dr. ${medicine['doctor_name'] ?? 'Unknown'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (medicine['doctor_specialization'] != null &&
                        medicine['doctor_specialization'] != 'Unknown')
                      Text(
                        medicine['doctor_specialization'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSection(Map<String, dynamic> medicine) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[700],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Start Date',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatDate(medicine['start_date']),
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'End Date',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatDate(medicine['end_date']),
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${medicine['duration_days']} days',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[200],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDosageSchedule(Map<String, dynamic> medicine) {
    List<Map<String, String>> schedule = [];

    // Process breakfast
    if (medicine['breakfast'] != null) {
      final breakfastInfo = _parseDosageInfo(medicine['breakfast']);
      if (breakfastInfo != null) {
        schedule.add({
          'time': 'Breakfast',
          'timing': breakfastInfo['timing']!,
          'dosage': breakfastInfo['dosage']!,
        });
      }
    }

    // Process lunch
    if (medicine['lunch'] != null) {
      final lunchInfo = _parseDosageInfo(medicine['lunch']);
      if (lunchInfo != null) {
        schedule.add({
          'time': 'Lunch',
          'timing': lunchInfo['timing']!,
          'dosage': lunchInfo['dosage']!,
        });
      }
    }

    // Process dinner
    if (medicine['dinner'] != null) {
      final dinnerInfo = _parseDosageInfo(medicine['dinner']);
      if (dinnerInfo != null) {
        schedule.add({
          'time': 'Dinner',
          'timing': dinnerInfo['timing']!,
          'dosage': dinnerInfo['dosage']!,
        });
      }
    }

    if (schedule.isEmpty) {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange, size: 20),
            SizedBox(width: 8),
            Text(
              'No dosage schedule available',
              style: TextStyle(color: Colors.orange, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dosage Schedule',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white54),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.blueGrey,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Meal Time',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Timing',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Dosage',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              // Schedule rows
              ...schedule.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: index % 2 == 0 ? Colors.grey[800] : Colors.grey[750],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Icon(
                              _getMealIcon(item['time']!),
                              color: Colors.white70,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(
                              item['time']!,
                              style:
                                  TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: item['timing'] == 'Before'
                                ? Colors.red.withOpacity(0.3)
                                : Colors.green.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item['timing']!,
                            style: TextStyle(
                              color: item['timing'] == 'Before'
                                  ? Colors.red[200]
                                  : Colors.green[200],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          item['dosage']!,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getMealIcon(String mealTime) {
    switch (mealTime.toLowerCase()) {
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      default:
        return Icons.restaurant;
    }
  }

  Map<String, String>? _parseDosageInfo(dynamic dosageValue) {
    if (dosageValue == null) return null;

    String dosageStr = dosageValue.toString();

    // Handle the case where dosage is in format "1 x volume" or just a number
    if (dosageStr.contains(' x ')) {
      List<String> parts = dosageStr.split(' x ');
      if (parts.length >= 2) {
        int count = int.tryParse(parts[0]) ?? 0;
        String volume = parts[1];

        if (count == -1) {
          return {'timing': 'Before', 'dosage': volume};
        } else if (count == 1) {
          return {'timing': 'After', 'dosage': volume};
        } else if (count == 0) {
          return null; // Not prescribed
        }
      }
    }

    // Handle direct numerical values
    int? numValue = int.tryParse(dosageStr);
    if (numValue != null) {
      switch (numValue) {
        case -1:
          return {'timing': 'Before', 'dosage': '1 tablet'};
        case 1:
          return {'timing': 'After', 'dosage': '1 tablet'};
        case 0:
          return null; // Not prescribed
      }
    }

    // Handle "No" or other string values
    if (dosageStr.toLowerCase() == 'no' || dosageStr == '0') {
      return null;
    }

    // Default case - treat as after meal
    return {'timing': 'After', 'dosage': dosageStr};
  }

  Widget _buildDescriptionSection(String description) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[200], size: 16),
                SizedBox(width: 8),
                Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[200],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosisSection(String diagnosis) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.purple.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_hospital, color: Colors.purple[200], size: 16),
                SizedBox(width: 8),
                Text(
                  'Diagnosis',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.purple[200],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              diagnosis,
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid Date';
    }
  }
}
