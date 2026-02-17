import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrGenerator {
  /// Generates a QR code image as Uint8List (PNG format) from the given [data].
  static Future<Uint8List?> generateQrBytes(String data) async {
    try {
      final image = await QrPainter(
        data: data,
        version: QrVersions.auto,
        gapless: false,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
      ).toImage(300); // 300x300 px

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  /// Generates a QR code with text overlay below it
  static Future<Uint8List?> generateQrBytesWithText(String data, String text) async {
    try {
      const qrSize = 300.0;
      const textHeight = 60.0;
      const totalHeight = qrSize + textHeight;

      // Generate QR code
      final qrImage = await QrPainter(
        data: data,
        version: QrVersions.auto,
        gapless: false,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
      ).toImage(300.0);

      // Create canvas with extra space for text
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, qrSize, totalHeight));

      // Draw white background
      canvas.drawRect(
        Rect.fromLTWH(0, 0, qrSize, totalHeight),
        Paint()..color = Colors.white,
      );

      // Draw QR code
      canvas.drawImage(qrImage, Offset.zero, Paint());

      // Draw text below QR
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      textPainter.layout(minWidth: 0, maxWidth: qrSize);
      
      final textOffset = Offset(
        (qrSize - textPainter.width) / 2,
        qrSize + (textHeight - textPainter.height) / 2,
      );
      
      textPainter.paint(canvas, textOffset);

      // Convert to image
      final picture = recorder.endRecording();
      final finalImage = await picture.toImage(300, 360);
      final byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
      
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }
}
