import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // upload a file (study notes, resources, etc.)
  Future<String> uploadFile(String uid, String fileName, File file) async {
    final ref = _storage.ref().child('uploads/$uid/$fileName');
    final uploadTask = await ref.putFile(file);
    final downloadUrl = await uploadTask.ref.getDownloadURL();
    return downloadUrl;
  }

  // upload profile picture
  Future<String> uploadProfileImage(String uid, File imageFile) async {
    final ref = _storage.ref().child('profiles/$uid/avatar.jpg');
    final uploadTask = await ref.putFile(imageFile);
    final downloadUrl = await uploadTask.ref.getDownloadURL();
    return downloadUrl;
  }

  // delete a file
  Future<void> deleteFile(String path) async {
    try {
      await _storage.ref().child(path).delete();
    } catch (e) {
      // file might not exist, ignore
    }
  }

  // list files for a user
  Future<List<Reference>> listUserFiles(String uid) async {
    final result = await _storage.ref().child('uploads/$uid').listAll();
    return result.items;
  }
}
