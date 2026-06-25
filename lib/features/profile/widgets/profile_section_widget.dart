import 'package:flutter/material.dart';
import 'package:nearwork/core/constants/app_colors.dart';

class ProfileSectionWidget extends StatelessWidget {
  final String displayName;
  final String email;
  final String? photoURL;
  final VoidCallback? onEditTap;

  const ProfileSectionWidget({
    super.key,
    required this.displayName,
    required this.email,
    this.photoURL,
    this.onEditTap,
  });

  static const double _bannerHeight = 120;
  static const double _avatarRadius = 48;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Banner
              Container(
                height: _bannerHeight,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1B2A1D),
                      Color(0xFF1E3C24),
                      Color(0xFF234A2B),
                    ],
                  ),
                ),
              ),

              // Avatar — overlaps banner
              Positioned(
                left: 20,
                bottom: -_avatarRadius,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: _avatarRadius,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: photoURL != null && photoURL!.isNotEmpty
                        ? NetworkImage(photoURL!)
                        : null,
                    child: photoURL == null || photoURL!.isEmpty
                        ? const Icon(
                            Icons.person_rounded,
                            size: 46,
                            color: AppColors.primary,
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),

          // Edit button — right-aligned below banner
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16, top: 16),
              child: GestureDetector(
                onTap: onEditTap,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit_rounded,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ),

          // Spacer for avatar overflow
          SizedBox(height: _avatarRadius - 48),

          // Name + email
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName
                            .split(' ')
                            .map(
                              (w) => w.isNotEmpty
                                  ? '${w[0].toUpperCase()}${w.substring(1)}'
                                  : '',
                            )
                            .join(' '),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.verified_user,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Passionate about finding the right opportunities. '
                  'Open to new roles and networking.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gampaha, Western Province, Sri Lanka',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
