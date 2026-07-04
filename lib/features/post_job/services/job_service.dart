import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nearwork/features/post_job/models/job.dart';

class JobService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _collection = 'jobs';

  Future<List<Job>> getActiveJobs() async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('state', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map(Job.fromFirestore).toList();
  }

  Future<void> createJob(Job job) async {
    await _firestore.collection(_collection).add(job.toFirestore());
  }

  Future<void> deleteJob(String jobId) async {
    await _firestore.collection(_collection).doc(jobId).delete();
  }

  Future<Job?> getJobById(String jobId) async {
    final doc = await _firestore.collection(_collection).doc(jobId).get();
    if (!doc.exists) return null;
    return Job.fromFirestore(doc);
  }

  Future<bool> isJobSaved(String uid, String jobId) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final ids = List<String>.from(doc.data()?['savedJobIds'] ?? []);
    return ids.contains(jobId);
  }

  Future<void> saveJob(String uid, String jobId) async {
    await _firestore.collection('users').doc(uid).update({
      'savedJobIds': FieldValue.arrayUnion([jobId]),
    });
  }

  Future<void> unsaveJob(String uid, String jobId) async {
    await _firestore.collection('users').doc(uid).update({
      'savedJobIds': FieldValue.arrayRemove([jobId]),
    });
  }

  Stream<List<Job>> streamSavedJobs(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .asyncMap((userDoc) async {
          final ids = List<String>.from(userDoc.data()?['savedJobIds'] ?? []);
          if (ids.isEmpty) return <Job>[];
          final jobs = await Future.wait(ids.map(getJobById));
          return jobs.whereType<Job>().toList();
        });
  }

  Future<void> incrementViewCount(String jobId) async {
    await _firestore.collection(_collection).doc(jobId).update({
      'viewCount': FieldValue.increment(1),
    });
  }

  Stream<int> streamViewCount(String jobId) {
    return _firestore
        .collection(_collection)
        .doc(jobId)
        .snapshots()
        .map((doc) => (doc.data()?['viewCount'] as int?) ?? 0);
  }

  Stream<List<Job>> userJobsByState(String uid, String state) {
    return _firestore
        .collection(_collection)
        .where('postedBy', isEqualTo: uid)
        .where('state', isEqualTo: state)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Job.fromFirestore).toList());
  }
}
