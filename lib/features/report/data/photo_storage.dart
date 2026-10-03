import 'dart:typed_data';

import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/services/firebase_functions.dart';

abstract interface class PhotoStorage {
  Future<void> upload({required String incidentId, required Uint8List bytes});
}

class PhotoStorageException implements Exception {
  const PhotoStorageException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DemoPhotoStorage implements PhotoStorage {
  @override
  Future<void> upload(
      {required String incidentId, required Uint8List bytes}) async {}
}

class FirebasePhotoStorage implements PhotoStorage {
  const FirebasePhotoStorage();

  @override
  Future<void> upload(
      {required String incidentId, required Uint8List bytes}) async {
    try {
      await firebaseFunctionsForApp()
          .httpsCallable('uploadIncidentPhoto')
          .call(<String, Object>{
        'incidentId': incidentId,
        'jpegBase64': base64Encode(bytes)
      });
    } on FirebaseFunctionsException {
      throw const PhotoStorageException(
          'The optional photo could not be uploaded.');
    } catch (_) {
      throw const PhotoStorageException('Photo upload failed.');
    }
  }
}
