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
