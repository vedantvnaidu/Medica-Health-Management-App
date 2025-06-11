import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'decryptQr.dart';

class ScanQrScreen extends StatefulWidget {
  @override
  _ScanQrScreenState createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  MobileScannerController cameraController = MobileScannerController();
  String? result;
  bool isFlashOn = false;
  bool isScanning = true;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full screen camera
          Positioned.fill(
            child: MobileScanner(
              controller: cameraController,
              onDetect: _onDetect,
            ),
          ),

          // Top section with "Find a QR code" text
          Positioned(
            top: MediaQuery.of(context).padding.top + 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  'Find a QR code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),

          // Custom corner-only overlay
          Positioned.fill(
            child: CustomPaint(
              painter: QrCornerOverlayPainter(),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 100,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Flash button
                GestureDetector(
                  onTap: _toggleFlash,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFlashOn
                          ? Icons.flashlight_on_sharp
                          : Icons.flashlight_off_sharp,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),

                // Gallery button
                GestureDetector(
                  onTap: _pickImageFromGallery,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.photo_library,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Show Add Patient Popup when QR is detected
          if (result != null)
            AddPatientPopup(
              qrData: result!,
              onAddPatient: _processQrResult,
              onScanAgain: _resetScan,
            ),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (image != null) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text('Scanning QR code...'),
                ],
              ),
            );
          },
        );

        // Analyze the image for QR codes
        final result = await cameraController.analyzeImage(image.path);

        // Dismiss loading dialog
        Navigator.of(context).pop();

        if (result != null && result.barcodes.isNotEmpty) {
          final barcode = result.barcodes.first;
          if (barcode.rawValue != null) {
            setState(() {
              this.result = barcode.rawValue;
              isScanning = false;
            });
            // Stop camera when QR is detected from gallery
            cameraController.stop();
            _vibrate();

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('QR code detected from image!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          // No QR code found in the image
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No QR code found in the selected image'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      // Dismiss loading dialog if it's still showing
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error scanning image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && isScanning) {
      final barcode = barcodes.first;
      if (barcode.rawValue != null) {
        setState(() {
          result = barcode.rawValue;
          isScanning = false;
        });
        // Stop camera when QR is detected
        cameraController.stop();

        // Provide haptic feedback
        _vibrate();
      }
    }
  }

  void _toggleFlash() async {
    await cameraController.toggleTorch();
    setState(() {
      isFlashOn = !isFlashOn;
    });
  }

  void _resetScan() {
    setState(() {
      result = null;
      isScanning = true;
    });
    cameraController.start();
  }

  void _processQrResult(Map<String, dynamic> patientData) {
    // Navigate back to dashboard with patient data
    Navigator.pop(context, patientData);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Patient data scanned successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _vibrate() {
    // Add haptic feedback when QR is scanned
    // You might need to add haptic_feedback package for this
    // HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}

// Custom painter for corner-only QR overlay
class QrCornerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final frameSize = 200.0;
    final cornerLength = 30.0;

    // Calculate frame boundaries
    final left = centerX - frameSize / 2;
    final right = centerX + frameSize / 2;
    final top = centerY - frameSize / 2;
    final bottom = centerY + frameSize / 2;

    // Draw corner brackets
    // Top-left corner
    canvas.drawLine(Offset(left, top + cornerLength), Offset(left, top), paint);
    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), paint);

    // Top-right corner
    canvas.drawLine(
        Offset(right - cornerLength, top), Offset(right, top), paint);
    canvas.drawLine(
        Offset(right, top), Offset(right, top + cornerLength), paint);

    // Bottom-left corner
    canvas.drawLine(
        Offset(left, bottom - cornerLength), Offset(left, bottom), paint);
    canvas.drawLine(
        Offset(left, bottom), Offset(left + cornerLength, bottom), paint);

    // Bottom-right corner
    canvas.drawLine(
        Offset(right - cornerLength, bottom), Offset(right, bottom), paint);
    canvas.drawLine(
        Offset(right, bottom), Offset(right, bottom - cornerLength), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
