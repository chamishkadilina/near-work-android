import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nearwork/core/models/resume_item.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateUserFields(String uid, Map<String, dynamic> fields) async {
    await _firestore.collection('users').doc(uid).update(fields);
  }

  CollectionReference _resumesRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('resumes');

  Stream<List<ResumeItem>> resumesStream(String uid) {
    return _resumesRef(uid)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ResumeItem.fromFirestore).toList());
  }

  Future<int> getResumeCount(String uid) async {
    final snap = await _resumesRef(uid).count().get();
    return snap.count ?? 0;
  }

  Future<void> addResume(String uid, ResumeItem resume) async {
    await _resumesRef(uid).add(resume.toFirestore());
  }

  Future<void> deleteResume(String uid, String resumeId) async {
    await _resumesRef(uid).doc(resumeId).delete();
  }

  Future<void> setDefaultResume(String uid, String resumeId) async {
    final batch = _firestore.batch();
    final snap = await _resumesRef(uid).get();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isDefault': doc.id == resumeId});
    }
    await batch.commit();
  }
}
