import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:nearwork/features/messages/models/conversation.dart';
import 'package:nearwork/features/messages/services/inbox_service.dart';
import 'package:nearwork/features/post_job/models/job.dart';

class InboxProvider extends ChangeNotifier {
  final _service = InboxService();

  List<Conversation> _myApplications = [];
  List<Conversation> _recruiterConversations = [];
  StreamSubscription<List<Conversation>>? _appSub;
  StreamSubscription<List<Conversation>>? _recSub;

  bool _isApplying = false;
  String? _applyError;

  List<Conversation> get myApplications => _myApplications;
  List<Conversation> get recruiterConversations => _recruiterConversations;
  bool get isApplying => _isApplying;
  String? get applyError => _applyError;

  List<Conversation> get allConversations {
    final all = [..._myApplications, ..._recruiterConversations];
    all.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return all;
  }

  // Total unread: unread applicants for recruiter + unread replies for seeker.
  int get totalUnread {
    final recruiterUnread = _recruiterConversations.where((c) => c.unreadByRecruiter).length;
    final applicantUnread = _myApplications.where((c) => c.unreadByApplicant).length;
    return recruiterUnread + applicantUnread;
  }

  void init(String userId) {
    _appSub?.cancel();
    _recSub?.cancel();

    _appSub = _service.applicantConversations(userId).listen(
      (list) {
        _myApplications = list;
        notifyListeners();
      },
      onError: (e) {
        if (kDebugMode) print('applicantConversations stream error: $e');
      },
    );

    _recSub = _service.recruiterConversations(userId).listen(
      (list) {
        _recruiterConversations = list;
        notifyListeners();
      },
      onError: (e) {
        if (kDebugMode) print('recruiterConversations stream error: $e');
      },
    );
  }

  // Returns the conversation id on success, null on failure.
  // If the user already applied, returns the existing conversation id.
  Future<String?> applyForJob({
    required Job job,
    required String applicantId,
    required String applicantName,
    required String coverNote,
    required String resumeUrl,
    required String resumeName,
    required String jobImageUrl,
    required int matchScore,
  }) async {
    _isApplying = true;
    _applyError = null;
    notifyListeners();

    try {
      final existing = await _service.existingConversationId(applicantId, job.id);
      if (existing != null) {
        _isApplying = false;
        notifyListeners();
        return existing;
      }

      final convId = await _service.apply(
        applicantId: applicantId,
        applicantName: applicantName,
        recruiterId: job.postedBy,
        jobId: job.id,
        jobTitle: job.title,
        jobEmployer: job.employer,
        jobImageUrl: jobImageUrl,
        coverNote: coverNote,
        resumeUrl: resumeUrl,
        resumeName: resumeName,
        matchScore: matchScore,
      );

      _isApplying = false;
      notifyListeners();
      return convId;
    } catch (e) {
      _isApplying = false;
      _applyError = 'Failed to send application. Please try again.';
      if (kDebugMode) print('applyForJob error: $e');
      notifyListeners();
      return null;
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    await _service.deleteConversation(conversationId);
  }

  Future<void> restoreConversation(Conversation conv) async {
    await _service.restoreConversation(conv);
  }

  void clearApplyError() {
    _applyError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _appSub?.cancel();
    _recSub?.cancel();
    super.dispose();
  }
}
