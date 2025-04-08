// storage_repository.dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import '../failure.dart';
import '../type_def.dart';

class StorageRepository {
  final FirebaseStorage _firebaseStorage;

  StorageRepository({required FirebaseStorage firebaseStorage})
      : _firebaseStorage = firebaseStorage;

  FutureEither<String> storeFile({
    required String path,
    required String id,
    required dynamic file,
    int? index, // index is optional
  }) async {
    try {
      // Create a unique path using the index if provided
      final ref = index != null
          ? _firebaseStorage.ref().child(path).child('$id-$index')
          : _firebaseStorage.ref().child(path).child(id);

      UploadTask uploadTask;
      if (file is File) {
        uploadTask = ref.putFile(file);
      } else if (file is Uint8List) {
        uploadTask = ref.putData(file);
      } else {
        throw 'Unsupported file type';
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return right(downloadUrl);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  // New method for web:
  FutureEither<String> storeFileFromBytes({
    required String path,
    required String id,
    required Uint8List bytes,
    int? index,
  }) async {
    try {
      final ref = _firebaseStorage.ref().child(path).child(id);
      final uploadTask = ref.putData(bytes);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return right(downloadUrl);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}

File _convertUint8ListToFile(Uint8List bytes, String fileName) {
  if (kIsWeb) {
    // This function should not be used on the web.
    throw UnsupportedError("File conversion is not supported on the web");
  }
  final file = File('${Directory.systemTemp.path}/$fileName');
  file.writeAsBytesSync(bytes);
  return file;
}
