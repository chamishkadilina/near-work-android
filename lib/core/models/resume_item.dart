import 'package:cloud_firestore/cloud_firestore.dart';

class ResumeItem {
  final String id;
  final String fileName;
  final String fileSize;
  final String fileType;
  final String fileUrl;
  final String publicId;
  final DateTime uploadedAt;
  bool isDefault;

  ResumeItem({
    required this.id,
    required this.fileName,
    required this.fileSize,
    this.fileType = 'PDF Document',
    required this.fileUrl,
    this.publicId = '',
    required this.uploadedAt,
    this.isDefault = false,
  });

  String get updatedLabel {
    final diff = DateTime.now().difference(uploadedAt);
    if (diff.inDays > 30) return 'Updated ${diff.inDays ~/ 30} months ago';
    if (diff.inDays > 0) return 'Updated ${diff.inDays} days ago';
    if (diff.inHours > 0) return 'Updated ${diff.inHours} hours ago';
    return 'Just now';
  }

  factory ResumeItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ResumeItem(
      id: doc.id,
      fileName: data['fileName'] ?? '',
      fileSize: data['fileSize'] ?? '',
      fileType: data['fileType'] ?? 'PDF Document',
      fileUrl: data['fileUrl'] ?? '',
      publicId: data['publicId'] ?? '',
      uploadedAt:
          (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isDefault: data['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fileName': fileName,
      'fileSize': fileSize,
      'fileType': fileType,
      'fileUrl': fileUrl,
      'publicId': publicId,
      'isDefault': isDefault,
      'uploadedAt': FieldValue.serverTimestamp(),
    };
  }
}
