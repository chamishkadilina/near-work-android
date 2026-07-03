import 'package:cloud_firestore/cloud_firestore.dart';

class Job {
  final String id;
  final String title;
  final String employer;
  final String category;
  final String type;
  final String location;
  final double salaryMin;
  final double salaryMax;
  final String salaryType; // 'fixed' | 'range' | 'negotiable'
  final String education;
  final String experience;
  final String description;
  final double latitude;
  final double longitude;
  final String phone;
  final String whatsApp;
  final String imageUrl;
  final String postedBy;
  final String postedByName;
  final String postedByEmail;
  final DateTime createdAt;
  final String state;
  final int viewCount;

  const Job({
    required this.id,
    required this.title,
    required this.employer,
    required this.category,
    required this.type,
    required this.location,
    required this.salaryMin,
    required this.salaryMax,
    this.salaryType = 'fixed',
    required this.education,
    required this.experience,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.phone = '',
    this.whatsApp = '',
    this.imageUrl = '',
    this.postedBy = '',
    this.postedByName = '',
    this.postedByEmail = '',
    required this.createdAt,
    this.state = 'active',
    this.viewCount = 0,
  });

  factory Job.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Job(
      id: doc.id,
      title: data['title'] ?? '',
      employer: data['employer'] ?? '',
      category: data['category'] ?? '',
      type: data['type'] ?? '',
      location: data['location'] ?? '',
      salaryMin: (data['salaryMin'] ?? 0).toDouble(),
      salaryMax: (data['salaryMax'] ?? 0).toDouble(),
      salaryType: data['salaryType'] ?? 'fixed',
      education: data['education'] ?? '',
      experience: data['experience'] ?? '',
      description: data['description'] ?? '',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      phone: data['phone'] ?? '',
      whatsApp: data['whatsApp'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      postedBy: data['postedBy'] ?? '',
      postedByName: data['postedByName'] ?? '',
      postedByEmail: data['postedByEmail'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      state: data['state'] ?? 'active',
      viewCount: data['viewCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'employer': employer,
      'category': category,
      'type': type,
      'location': location,
      'salaryMin': salaryMin,
      'salaryMax': salaryMax,
      'salaryType': salaryType,
      'education': education,
      'experience': experience,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'whatsApp': whatsApp,
      'imageUrl': imageUrl,
      'postedBy': postedBy,
      'postedByName': postedByName,
      'postedByEmail': postedByEmail,
      'createdAt': FieldValue.serverTimestamp(),
      'state': state,
      'viewCount': viewCount,
    };
  }

  String get formattedSalary {
    switch (salaryType) {
      case 'range':
        return 'Rs ${_formatNumber(salaryMin.toInt())} – ${_formatNumber(salaryMax.toInt())}';
      case 'negotiable':
        return 'Negotiable';
      default:
        return 'Rs ${_formatNumber(salaryMin.toInt())}';
    }
  }

  String get postedAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 30) return '${diff.inDays ~/ 30} months ago';
    if (diff.inDays > 0) return '${diff.inDays} days ago';
    if (diff.inHours > 0) return '${diff.inHours} hours ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} minutes ago';
    return 'Just now';
  }

  static String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}
