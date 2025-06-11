// doctorDashboard.dart

import 'package:flutter/material.dart';
import 'package:medica_test/doctor/patientDetail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medica_test/backend/scanQr.dart';
import 'package:medica_test/backend/matchDoctorPatient.dart'; // Add this import

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> patients = [];
  bool _isLoading = false;
  bool _isDoctorDataLoading = true;

  // Doctor data variables
  String doctorName = '';
  String doctorSpecialization = '';
  String doctorContact = '';
  String currentDoctorId = '';
  double doctorRating = 0.0;
  int activePatients = 0;

  @override
  void initState() {
    super.initState();
    _loadDoctorData();
  }

  // Load doctor data from SharedPreferences
  Future<void> _loadDoctorData() async {
    setState(() => _isDoctorDataLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if doctor is logged in
      bool isLoggedIn = prefs.getBool('is_doctor_logged_in') ?? false;

      if (!isLoggedIn) {
        // Handle case where doctor is not logged in
        _handleLogout();
        return;
      }

      setState(() {
        currentDoctorId = prefs.getString('current_doctor_id') ?? '';
        doctorName = prefs.getString('doctor_name') ?? 'Dr. Unknown';
        doctorSpecialization =
            prefs.getString('doctor_specialization') ?? 'General Practice';
        doctorContact = prefs.getString('doctor_contact') ?? '';
        doctorRating = prefs.getDouble('doctor_rating') ?? 0.0;
      });

      print(
          'Doctor data loaded: $doctorName, $doctorSpecialization, Rating: $doctorRating');

      // After loading doctor data, fetch patients
      await _fetchPatients();
    } catch (error) {
      print('Error loading doctor data: $error');
      setState(() {
        doctorName = 'Dr. Unknown';
        doctorSpecialization = 'General Practice';
        doctorRating = 0.0;
        activePatients = 0;
      });
    } finally {
      setState(() => _isDoctorDataLoading = false);
    }
  }

  // Handle logout
  void _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (mounted) {
      Navigator.pushReplacementNamed(
          context, '/login'); // Adjust route as needed
    }
  }

  // Fetch patients from database using the new service
  Future<void> _fetchPatients() async {
    setState(() => _isLoading = true);

    try {
      if (currentDoctorId.isEmpty) {
        throw Exception('Doctor ID not found');
      }

      // Use the new service to fetch doctor's patients
      final result = await DoctorPatientService.getDoctorPatients(
        doctorId: currentDoctorId,
      );

      if (mounted) {
        if (result['success']) {
          setState(() {
            patients = List<Map<String, dynamic>>.from(result['patients']);
            activePatients = patients.length;
            _isLoading = false;
          });
        } else {
          // Handle error case
          setState(() {
            patients = [];
            activePatients = 0;
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Error fetching patients'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching patients: $error'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          patients = [];
          activePatients = 0;
          _isLoading = false;
        });
      }
    }
  }

  // Build star rating widget
  Widget _buildStarRating(double rating) {
    List<Widget> stars = [];
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;

    // Add full stars
    for (int i = 0; i < fullStars; i++) {
      stars.add(Icon(Icons.star, color: Colors.yellow, size: 16));
    }

    // Add half star if needed
    if (hasHalfStar) {
      stars.add(Icon(Icons.star_half, color: Colors.yellow, size: 16));
    }

    // Add empty stars to make total of 5
    int remainingStars = 5 - fullStars - (hasHalfStar ? 1 : 0);
    for (int i = 0; i < remainingStars; i++) {
      stars.add(Icon(Icons.star_border, color: Colors.yellow, size: 16));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: stars,
    );
  }

  // Format date string for display
  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      DateTime date = DateTime.parse(dateString);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Medika'),
        actions: [
          IconButton(icon: Icon(Icons.search), onPressed: () {}),
          IconButton(icon: Icon(Icons.filter_list), onPressed: () {}),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Doctor Info Section
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.black,
            child: _isDoctorDataLoading
                ? Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(
                            'https://st4.depositphotos.com/1017986/21088/i/450/depositphotos_210888716-stock-photo-happy-doctor-with-clipboard-at.jpg'),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doctorName,
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            _buildInfoRow(doctorSpecialization, Colors.red),
                            SizedBox(height: 4),
                            _buildRatingRow(),
                            SizedBox(height: 4),
                            _buildInfoRow("Active Patients: $activePatients",
                                Colors.blue),
                            if (doctorContact.isNotEmpty) ...[
                              SizedBox(height: 4),
                              _buildInfoRow(
                                  "Contact: $doctorContact", Colors.green),
                            ]
                          ],
                        ),
                      ),
                    ],
                  ),
          ),

          // Patients List Section
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async {
                      await _loadDoctorData(); // This will also refresh patients
                    },
                    child: patients.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline,
                                    size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('No patients found',
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.grey[600])),
                                SizedBox(height: 8),
                                Text('Pull down to refresh',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey[500])),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: patients.length,
                            itemBuilder: (context, index) {
                              final patient = patients[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 16.0),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            PatientDetailScreen(
                                          id: patient['patient_id'].toString(),
                                        ),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              patient['name'] ??
                                                  'Unknown Patient',
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.white),
                                              textAlign: TextAlign.left,
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'ID: ${patient['patient_id']}',
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white70),
                                              textAlign: TextAlign.left,
                                            ),
                                            if (patient['diagnosis'] !=
                                                null) ...[
                                              SizedBox(height: 2),
                                              Text(
                                                'Diagnosis: ${patient['diagnosis']}',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.white60),
                                                textAlign: TextAlign.left,
                                              ),
                                            ],
                                            if (patient['prescribed_on'] !=
                                                null) ...[
                                              SizedBox(height: 2),
                                              Text(
                                                'Last Visit: ${_formatDate(patient['prescribed_on'])}',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.white60),
                                                textAlign: TextAlign.left,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ScanQrScreen()),
          );
        },
        child: Icon(Icons.qr_code_scanner),
        backgroundColor: Colors.green,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.view_list),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Dailies',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_box),
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

  Widget _buildInfoRow(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: color, width: 3),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(left: 8),
        child: Text(
          text,
          style: TextStyle(fontSize: 14, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildRatingRow() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.yellow, width: 3),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(left: 8),
        child: Row(
          children: [
            Text(
              "Rating: ",
              style: TextStyle(fontSize: 14, color: Colors.white),
            ),
            _buildStarRating(doctorRating),
            SizedBox(width: 8),
            Text(
              "(${doctorRating.toStringAsFixed(1)})",
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleLogout();
              },
              child: Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
