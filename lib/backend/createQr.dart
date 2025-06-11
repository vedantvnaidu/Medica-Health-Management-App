// lib/widgets/createQr.dart

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;

/// A dialog that generates, encrypts, and displays a QR code from the given patientId,
/// and provides a button to share the encrypted QR data as text.
class QrCodeDialog extends StatelessWidget {
  /// The patient ID to encode in the QR code.
  final int patientId;

  /// 32-byte secret key for AES encryption. In production, safely store & retrieve.
  static const _secretKey = 'my32lengthsupersecretnooneknows1';

  /// 16-byte IV for AES encryption. In production, randomly generate per message.
  static const _iv = '8bytesiv12345678';

  const QrCodeDialog({Key? key, required this.patientId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Prepare encryption
    final key = encrypt_pkg.Key.fromUtf8(_secretKey);
    final iv = encrypt_pkg.IV.fromUtf8(_iv);
    final encrypter = encrypt_pkg.Encrypter(
        encrypt_pkg.AES(key, mode: encrypt_pkg.AESMode.cbc));
    final plainText = patientId.toString();
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    final encryptedBase64 = encrypted.base64;

    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.all(10),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            // QR Code display
            Expanded(
              child: Center(
                child: QrImageView(
                  data: encryptedBase64,
                  version: QrVersions.auto,
                  size: 300.0,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            // Share button
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Sharing the encrypted data text
                  Share.share('Encrypted Patient Data: \$encryptedBase64');
                },
                icon: Icon(Icons.share),
                label: Text('Share QR'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blueGrey[700],
                ),
              ),
            ),
            SizedBox(height: 16),
            // Optional: Show encrypted text for debugging
            Text(
              'Encrypted (base64):\n\$encryptedBase64',
              style: TextStyle(color: Colors.white70, fontSize: 10),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Decrypted: \${encrypter.decrypt(encrypted, iv: iv)}',
              style: TextStyle(color: Colors.white70, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/*
Decryption example (e.g., in scanning app):

import 'package:encrypt/encrypt.dart' as encrypt_pkg;

void decryptData(String base64Text) {
  final key = encrypt_pkg.Key.fromUtf8('my32lengthsupersecretnooneknows1');
  final iv = encrypt_pkg.IV.fromUtf8('8bytesiv12345678');
  final encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(key, mode: encrypt_pkg.AESMode.cbc));
  final encrypted = encrypt_pkg.Encrypted.fromBase64(base64Text);
  final decrypted = encrypter.decrypt(encrypted, iv: iv);
  print('Decrypted patientId: \$decrypted');
}
*/
