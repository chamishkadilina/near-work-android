import 'package:flutter/foundation.dart';
import 'package:nearwork/features/post_job/models/job.dart';
import 'package:nearwork/features/post_job/services/job_service.dart';

class PostJobProvider extends ChangeNotifier {
  final JobService _jobService = JobService();

  bool _isSubmitting = false;
  String? _error;

  bool get isSubmitting => _isSubmitting;
  String? get error => _error;

  Stream<List<Job>> userJobsByState(String uid, String state) =>
      _jobService.userJobsByState(uid, state);

  Future<bool> createJob(Job job) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      await _jobService.createJob(job);
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Error creating job: $e');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteJob(String jobId) async {
    try {
      await _jobService.deleteJob(jobId);
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Error deleting job: $e');
    }
  }
}
