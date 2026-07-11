import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nearwork/core/services/resume_match_service.dart';

class Conversation {
  final String id;
  final String applicantId;
  final String applicantName;
  final String recruiterId;
  final String jobId;
  final String jobTitle;
  final String jobEmployer;
  final String jobImageUrl;
  final String coverNote;
  final String resumeUrl;
  final String resumeName;
  final String status; // pending | viewed | shortlisted | rejected
  final String lastMessage;
  final DateTime lastMessageAt;
  final DateTime appliedAt;
  final bool unreadByRecruiter;
  final bool unreadByApplicant;
  final int matchScore; // 0-10, or ResumeMatchService.notScored if unscored

  const Conversation({
    required this.id,
    required this.applicantId,
    required this.applicantName,
    required this.recruiterId,
    required this.jobId,
    required this.jobTitle,
    required this.jobEmployer,
    this.jobImageUrl = '',
    this.coverNote = '',
    this.resumeUrl = '',
    this.resumeName = '',
    this.status = 'pending',
    required this.lastMessage,
    required this.lastMessageAt,
    required this.appliedAt,
    this.unreadByRecruiter = true,
    this.unreadByApplicant = false,
    this.matchScore = ResumeMatchService.notScored,
  });

  String get applicantInitials {
    final parts = applicantName.trim().split(' ');
    if (parts.isEmpty || applicantName.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String get employerInitials {
    final parts = jobEmployer.trim().split(' ');
    if (parts.isEmpty || jobEmployer.isEmpty) return 'R';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  factory Conversation.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Conversation(
      id: doc.id,
      applicantId: d['applicantId'] ?? '',
      applicantName: d['applicantName'] ?? '',
      recruiterId: d['recruiterId'] ?? '',
      jobId: d['jobId'] ?? '',
      jobTitle: d['jobTitle'] ?? '',
      jobEmployer: d['jobEmployer'] ?? '',
      jobImageUrl: d['jobImageUrl'] ?? '',
      coverNote: d['coverNote'] ?? '',
      resumeUrl: d['resumeUrl'] ?? '',
      resumeName: d['resumeName'] ?? '',
      status: d['status'] ?? 'pending',
      lastMessage: d['lastMessage'] ?? '',
      lastMessageAt: (d['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      appliedAt: (d['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadByRecruiter: d['unreadByRecruiter'] ?? true,
      unreadByApplicant: d['unreadByApplicant'] ?? false,
      matchScore: d['matchScore'] ?? ResumeMatchService.notScored,
    );
  }

  Map<String, dynamic> toFirestore() => {
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
    'status': status,
    'lastMessage': lastMessage,
    'lastMessageAt': FieldValue.serverTimestamp(),
    'appliedAt': FieldValue.serverTimestamp(),
    'unreadByRecruiter': unreadByRecruiter,
    'unreadByApplicant': unreadByApplicant,
    'matchScore': matchScore,
  };
}

class Message {
  final String id;
  final String senderId;
  final String text;
  final String type; // 'application' | 'text'
  final String resumeUrl;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.senderId,
    required this.text,
    this.type = 'text',
    this.resumeUrl = '',
    required this.createdAt,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      senderId: d['senderId'] ?? '',
      text: d['text'] ?? '',
      type: d['type'] ?? 'text',
      resumeUrl: d['resumeUrl'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'senderId': senderId,
    'text': text,
    'type': type,
    'resumeUrl': resumeUrl,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
