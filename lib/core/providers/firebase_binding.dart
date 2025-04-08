// firebase_binding.dart
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'storage_repository.dart';

class FirebaseBinding extends Bindings {
  @override
  void dependencies() {
    // Register Firebase services
    Get.put<FirebaseFirestore>(FirebaseFirestore.instance);
    Get.put<FirebaseAuth>(FirebaseAuth.instance);
    Get.put<FirebaseStorage>(FirebaseStorage.instance);
    Get.put<GoogleSignIn>(GoogleSignIn());

    // Register StorageRepository (see next file)
    Get.put<StorageRepository>(
      StorageRepository(firebaseStorage: Get.find<FirebaseStorage>()),
    );
  }
}
