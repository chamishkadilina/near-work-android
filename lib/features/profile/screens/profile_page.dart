import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nearwork/core/constants/app_colors.dart';
import 'package:nearwork/features/profile/models/resume_item.dart';
import 'package:nearwork/core/services/app_share_service.dart';
import 'package:nearwork/features/auth/providers/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:nearwork/features/profile/providers/profile_provider.dart';
import 'package:nearwork/features/profile/screens/faq_page.dart';
import 'package:nearwork/features/profile/widgets/cv_section_widget.dart';
import 'package:nearwork/features/profile/widgets/logout_dialog.dart';
import 'package:nearwork/features/profile/widgets/more_section_widget.dart';
import 'package:nearwork/features/profile/widgets/profile_section_widget.dart';
import 'package:nearwork/features/post_job/models/job.dart';
import 'package:nearwork/features/profile/widgets/saved_jobs_section_widget.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends StatefulWidget {
  final void Function(Job)? onViewOnMap;

  const ProfilePage({super.key, this.onViewOnMap});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Future<void> _launchUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        final sm = ScaffoldMessenger.of(context);
        sm.clearSnackBars();
        final e1 = sm.showSnackBar(const SnackBar(
          content: Text('Could not open the link'),
          duration: Duration(days: 1),
        ));
        Future.delayed(const Duration(seconds: 3), () { try { e1.close(); } catch (_) {} });
      }
    }
  }

  Future<void> _handleShareApp() async {
    try {
      await AppShareService.shareApp();
    } catch (_) {
      if (mounted) {
        final sm2 = ScaffoldMessenger.of(context);
        sm2.clearSnackBars();
        final e2 = sm2.showSnackBar(SnackBar(
          content: const Text('Unable to share app at the moment'),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(days: 1),
        ));
        Future.delayed(const Duration(seconds: 3), () { try { e2.close(); } catch (_) {} });
      }
    }
  }

  Future<void> _handleResumeUpload(String uid) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.single.path == null) return;
    if (mounted) {
      context.read<ProfileProvider>().uploadResume(
        uid,
        File(result.files.single.path!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final profileProvider = context.watch<ProfileProvider>();
    final user = authProvider.user;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Not authenticated',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading profile: ${snapshot.error}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              );
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(
                child: Text(
                  'User not found',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              );
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final username = userData['username'] as String? ?? 'User';
            final email = userData['email'] as String? ?? 'No email';
            final photoURL = userData['photoURL'] as String? ?? '';
            final about = userData['about'] as String? ?? '';
            final location = userData['location'] as String? ?? '';
            final bannerURL = userData['bannerURL'] as String? ?? '';

            return SingleChildScrollView(
              child: Column(
                children: [
                  ProfileSectionWidget(
                    uid: user.uid,
                    displayName: username,
                    email: email,
                    photoURL: photoURL.isNotEmpty ? photoURL : null,
                    bannerURL: bannerURL.isNotEmpty ? bannerURL : null,
                    about: about,
                    location: location,
                  ),

                  const SizedBox(height: 12),

                  StreamBuilder<List<ResumeItem>>(
                    stream: profileProvider.resumesStream(user.uid),
                    builder: (context, resumeSnap) {
                      final resumes = resumeSnap.data ?? [];
                      return CvSectionWidget(
                        resumes: resumes,
                        resumesStream: profileProvider.resumesStream(user.uid),
                        isUploading: profileProvider.isUploadingResume,
                        onUploadTap: () => _handleResumeUpload(user.uid),
                        onDeleteResume: (id) =>
                            profileProvider.deleteResume(user.uid, id),
                        onSetDefault: (id) =>
                            profileProvider.setDefaultResume(user.uid, id),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  SavedJobsSectionWidget(onJobTap: widget.onViewOnMap),

                  const SizedBox(height: 12),

                  MoreSectionWidget(
                    onFaqTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FaqPage()),
                    ),
                    onSupportTap: () => _launchUrl(
                      'https://sites.google.com/view/nearwork-help-center/home',
                    ),
                    onPrivacyTap: () => _launchUrl(
                      'https://sites.google.com/view/nearwork-privacy-policy/home',
                    ),
                    onTermsTap: () => _launchUrl(
                      'https://sites.google.com/view/nearwork-terms-of-use/home',
                    ),
                    onShareAppTap: _handleShareApp,
                    onSignOutTap: () async {
                      final shouldLogout = await LogoutDialog.show(context);
                      if (shouldLogout == true && mounted) {
                        await authProvider.signOut();
                      }
                    },
                  ),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
