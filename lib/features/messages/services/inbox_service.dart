import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nearwork/features/messages/models/conversation.dart';

class InboxService {
  final _db = FirebaseFirestore.instance;
  CollectionReference get _col => _db.collection('conversations');

  // Cached photo URLs so inbox tiles don't re-fetch on every rebuild.
  final _photoCache = <String, String>{};

  Future<String> getUserPhotoUrl(String uid) async {
    if (uid.isEmpty) return '';
    if (_photoCache.containsKey(uid)) return _photoCache[uid]!;
    try {
      final doc = await _db.collection('users').doc(uid).get();
      final url = doc.data()?['photoURL'] as String? ?? '';
      _photoCache[uid] = url;
      return url;
    } catch (_) {
      return '';
    }
  }

  // Returns existing conversation id if applicant already applied to this job.
  // Uses a single-field query (auto-indexed) + client-side filter to avoid
  // requiring the composite (applicantId, jobId) Firestore index.
  Future<String?> existingConversationId(
    String applicantId,
    String jobId,
  ) async {
    final snap = await _col.where('applicantId', isEqualTo: applicantId).get();
    for (final doc in snap.docs) {
      if ((doc.data() as Map<String, dynamic>)['jobId'] == jobId) return doc.id;
    }
    return null;
  }

  // Creates a conversation then the initial application message sequentially.
  // Two writes are needed because the message rule uses get() on the parent
  // conversation — a batch would fail since the doc doesn't exist yet at
  // rule-evaluation time.
  Future<String> apply({
    required String applicantId,
    required String applicantName,
    required String recruiterId,
    required String jobId,
    required String jobTitle,
    required String jobEmployer,
    required String jobImageUrl,
    required String coverNote,
    required String resumeUrl,
    required String resumeName,
    required int matchScore,
  }) async {
    final convRef = _col.doc();
    final firstMessage = coverNote.isNotEmpty
        ? coverNote
        : 'Applied for $jobTitle';

    await convRef.set({
      'applicantId': applicantId,
      'applicantName': applicantName,
      'recruiterId': recruiterId,
      'jobId': jobId,
      'jobTitle': jobTitle,
      'jobEmployer': jobEmployer,
      'jobImageUrl': jobImageUrl,
      'coverNote': coverNote,
      'resumeUrl': resumeUrl,
      'resumeName': resumeName,
      'matchScore': matchScore,
      'status': 'pending',
      'lastMessage': firstMessage,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'appliedAt': FieldValue.serverTimestamp(),
      'unreadByRecruiter': true,
      'unreadByApplicant': false,
    });

    try {
      await convRef.collection('messages').add({
        'senderId': applicantId,
        'text': firstMessage,
        'type': 'application',
        'resumeUrl': resumeUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Roll back the orphaned conversation so the user can try again.
      await convRef.delete().catchError((_) {});
      rethrow;
    }

    return convRef.id;
  }

  // All conversations where I am the job seeker.
  // Sorted client-side to avoid the composite (applicantId, lastMessageAt) index.
  Stream<List<Conversation>> applicantConversations(String userId) {
    return _col.where('applicantId', isEqualTo: userId).snapshots().map((s) {
      final list = s.docs.map(Conversation.fromFirestore).toList()
        ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      return list;
    });
  }

  // All conversations where I am the recruiter.
  // Sorted client-side to avoid the composite (recruiterId, lastMessageAt) index.
  Stream<List<Conversation>> recruiterConversations(String userId) {
    return _col.where('recruiterId', isEqualTo: userId).snapshots().map((s) {
      final list = s.docs.map(Conversation.fromFirestore).toList()
        ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      return list;
    });
  }

  // Real-time messages in a conversation, oldest first.
  Stream<List<Message>> messages(String conversationId) {
    return _col
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((s) => s.docs.map(Message.fromFirestore).toList());
  }

  Future<void> sendMessage(
    String conversationId,
    String senderId,
    String text,
  ) async {
    final convRef = _col.doc(conversationId);
    final batch = _db.batch();

    batch.set(convRef.collection('messages').doc(), {
      'senderId': senderId,
      'text': text,
      'type': 'text',
      'resumeUrl': '',
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.update(convRef, {
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> sendResumeMessage({
    required String conversationId,
    required String senderId,
    required String text,
    required String resumeUrl,
    required String resumeName,
  }) async {
    final convRef = _col.doc(conversationId);
    final batch = _db.batch();

    batch.set(convRef.collection('messages').doc(), {
      'senderId': senderId,
      'text': text,
      'type': 'resume',
      'resumeUrl': resumeUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.update(convRef, {
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> markViewedByRecruiter(String conversationId) async {
    await _col.doc(conversationId).update({
      'unreadByRecruiter': false,
      'status': 'viewed',
    });
  }

  Future<void> markViewedByApplicant(String conversationId) async {
    await _col.doc(conversationId).update({'unreadByApplicant': false});
  }

  Future<void> updateStatus(String conversationId, String status) async {
    final update = <String, dynamic>{'status': status};
    // When recruiter replies/updates status, applicant should see it.
    if (status == 'shortlisted' || status == 'rejected') {
      update['unreadByApplicant'] = true;
    }
    await _col.doc(conversationId).update(update);
  }

  Future<Conversation?> getConversation(String conversationId) async {
    final doc = await _col.doc(conversationId).get();
    if (!doc.exists) return null;
    return Conversation.fromFirestore(doc);
  }

  Future<void> markRecruiterReplied(String conversationId) async {
    await _col.doc(conversationId).update({'unreadByApplicant': true});
  }

  Future<void> deleteConversation(String conversationId) async {
    await _col.doc(conversationId).delete();
  }

  // Restores a deleted conversation using the same document ID so both
  // parties see it again. (Messages sub-collection is untouched.)
  Future<void> restoreConversation(Conversation conv) async {
    await _col.doc(conv.id).set(conv.toFirestore());
  }
}
