import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(FirebaseStorage.instance);
});

class StorageService {
  final FirebaseStorage _storage;
  final ImagePicker _picker = ImagePicker();

  StorageService(this._storage);

  /// Pick an image from Gallery or Camera
  Future<XFile?> pickImage({required ImageSource source}) async {
    return await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1024,
      maxHeight: 1024,
    );
  }

  /// Upload image file to Firebase Storage and return download URL
  /// Path format: coupons/{couponId}.jpg
  Future<String> uploadImage({required File file, required String path}) async {
    final ref = _storage.ref().child(path);
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  /// Delete image from Firebase Storage
  Future<void> deleteImage(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      // Ignore if image not found or already deleted
    }
  }

  /// Upload QR code bytes to Firebase Storage
  Future<String> uploadQrCode({required Uint8List data, required String path}) async {
    final ref = _storage.ref().child(path);
    final uploadTask = ref.putData(data, SettableMetadata(contentType: 'image/png'));
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
}
