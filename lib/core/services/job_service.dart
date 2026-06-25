import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nearwork/core/models/job.dart';

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
}
