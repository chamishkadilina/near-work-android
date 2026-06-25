import 'package:flutter/material.dart';
import 'package:nearwork/core/constants/app_colors.dart';
import 'package:nearwork/core/services/app_share_service.dart';
import 'package:nearwork/features/auth/providers/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:nearwork/features/profile/screens/faq_page.dart';
import 'package:nearwork/features/profile/widgets/cv_section_widget.dart';
import 'package:nearwork/features/profile/widgets/logout_dialog.dart';
import 'package:nearwork/features/profile/widgets/more_section_widget.dart';
import 'package:nearwork/features/profile/widgets/profile_section_widget.dart';
import 'package:nearwork/features/profile/widgets/saved_jobs_section_widget.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Future<void> _launchUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the link')),
        );
      }
    }
  }

  Future<void> _handleShareApp() async {
    try {
      await AppShareService.shareApp();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unable to share app at the moment'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
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

            return SingleChildScrollView(
              child: Column(
                children: [
                  // Profile Section
                  ProfileSectionWidget(
                    displayName: username,
                    email: email,
                    photoURL: photoURL.isNotEmpty ? photoURL : null,
                    onEditTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Edit profile coming soon!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // CV Section
                  const CvSectionWidget(),

                  const SizedBox(height: 12),

                  // Saved Jobs Section
                  SavedJobsSectionWidget(),

                  const SizedBox(height: 12),

                  // More Section
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
                      final bool? shouldLogout = await LogoutDialog.show(
                        context,
                      );
                      if (shouldLogout == true) {
                        if (mounted) {
                          await authProvider.signOut();
                        }
                      }
                    },
                  ),

                  // Version
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      final info = snapshot.data!;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Text(
                          'Version ${info.version} (${info.buildNumber})',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      );
                    },
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
