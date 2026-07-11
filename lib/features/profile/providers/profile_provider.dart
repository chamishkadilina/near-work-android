import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nearwork/features/profile/models/resume_item.dart';
import 'package:nearwork/features/profile/services/cloudinary_service.dart';
import 'package:nearwork/features/profile/services/profile_service.dart';
import 'package:nearwork/features/profile/services/resume_text_extractor.dart';

class ProfileProvider extends ChangeNotifier {
  final CloudinaryService _cloudinary = CloudinaryService();
  final ProfileService _profileService = ProfileService();

  bool _isUploadingPhoto = false;
  bool _isUploadingBanner = false;
  bool _isUploadingResume = false;
  bool _isSaving = false;
  String? _error;

  bool get isUploadingPhoto => _isUploadingPhoto;
  bool get isUploadingBanner => _isUploadingBanner;
  bool get isUploadingResume => _isUploadingResume;
  bool get isSaving => _isSaving;
  String? get error => _error;

  Stream<List<ResumeItem>> resumesStream(String uid) =>
      _profileService.resumesStream(uid);

  Future<void> updateProfilePhoto(String uid, File imageFile) async {
    _isUploadingPhoto = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _cloudinary.uploadFile(
        file: imageFile,
        folder: 'nearwork/profiles/$uid/photos',
      );
      await _profileService.updateUserFields(uid, {
        'photoURL': result.secureUrl,
      });
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Error uploading profile photo: $e');
    }
    _isUploadingPhoto = false;
    notifyListeners();
  }

  Future<void> updateBannerPhoto(String uid, File imageFile) async {
    _isUploadingBanner = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _cloudinary.uploadFile(
        file: imageFile,
        folder: 'nearwork/profiles/$uid/banners',
      );
      await _profileService.updateUserFields(uid, {
        'bannerURL': result.secureUrl,
      });
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Error uploading banner: $e');
    }
    _isUploadingBanner = false;
    notifyListeners();
  }

  Future<void> uploadResume(String uid, File pdfFile) async {
    _isUploadingResume = true;
    _error = null;
    notifyListeners();
    try {
      final count = await _profileService.getResumeCount(uid);
      if (count >= 5) {
        _error = 'Maximum 5 resumes allowed';
        _isUploadingResume = false;
        notifyListeners();
        return;
      }
      // Extract text locally in parallel with the upload — this is the only
      // point the raw PDF bytes are available; Cloudinary's raw delivery is
      // blocked so the text can never be recovered from the uploaded file.
      final results = await Future.wait([
        _cloudinary.uploadFile(
          file: pdfFile,
          folder: 'nearwork/profiles/$uid/resumes',
          resourceType: 'image',
        ),
        ResumeTextExtractor.extractText(pdfFile),
      ]);
      final result = results[0] as CloudinaryUploadResult;
      final resumeText = results[1] as String;
      final bytes = pdfFile.lengthSync();
      final fileSize = bytes < 1024 * 1024
          ? '${(bytes / 1024).toStringAsFixed(0)} KB'
          : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

      final resume = ResumeItem(
        id: '',
        fileName: pdfFile.path.split('/').last,
        fileSize: fileSize,
        fileUrl: result.secureUrl,
        publicId: result.publicId,
        uploadedAt: DateTime.now(),
        isDefault: count == 0,
        resumeText: resumeText,
      );
      await _profileService.addResume(uid, resume);
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Error uploading resume: $e');
    }
    _isUploadingResume = false;
    notifyListeners();
  }

  Future<void> deleteResume(String uid, String resumeId) async {
    try {
      final resumes = await _profileService.resumesStream(uid).first;
      final deleted = resumes.firstWhere((r) => r.id == resumeId);
      await _profileService.deleteResume(uid, resumeId);
      if (deleted.isDefault) {
        final remaining = resumes.where((r) => r.id != resumeId).toList();
        if (remaining.isNotEmpty) {
          await _profileService.setDefaultResume(uid, remaining.first.id);
        }
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Error deleting resume: $e');
    }
  }

  Future<void> setDefaultResume(String uid, String resumeId) async {
    try {
      await _profileService.setDefaultResume(uid, resumeId);
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Error setting default: $e');
    }
  }

  Future<void> updateProfileInfo(
    String uid, {
    String? about,
    String? location,
  }) async {
    _isSaving = true;
    _error = null;
    notifyListeners();
    try {
      final fields = <String, dynamic>{};
      if (about != null) fields['about'] = about;
      if (location != null) fields['location'] = location;
      if (fields.isNotEmpty) {
        await _profileService.updateUserFields(uid, fields);
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Error updating profile: $e');
    }
    _isSaving = false;
    notifyListeners();
  }
}
