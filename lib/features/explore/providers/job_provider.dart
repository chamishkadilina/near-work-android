import 'package:flutter/foundation.dart';
import 'package:nearwork/features/post_job/models/job.dart';
import 'package:nearwork/features/post_job/services/job_service.dart';

class JobProvider extends ChangeNotifier {
  final JobService _jobService = JobService();

  List<Job> _jobs = [];
  bool _isLoading = false;
  String? _error;

  List<Job> get jobs => _jobs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchJobs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _jobs = await _jobService.getActiveJobs();
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error fetching jobs: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
  }
}
