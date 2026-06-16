import 'package:flutter/material.dart';
import 'package:nearwork/core/constants/app_colors.dart';

class ProfileSectionWidget extends StatelessWidget {
  final String displayName;
  final String email;
  final String? photoURL;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onEditTap;

  const ProfileSectionWidget({
    super.key,
    required this.displayName,
    required this.email,
    this.photoURL,
    this.onSettingsTap,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Stack(
        children: [
          Row(
            children: [
              // Profile Avatar
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      backgroundImage: photoURL != null && photoURL!.isNotEmpty
                          ? NetworkImage(photoURL!)
                          : null,
                      child: photoURL == null || photoURL!.isEmpty
                          ? Icon(
                              Icons.person_rounded,
                              size: 32,
                              color: AppColors.primary,
                            )
                          : null,
                    ),
                  ),

                  // Edit icon — bottom right of avatar
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: GestureDetector(
                      onTap: onEditTap,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 0),
                    Text(
                      email,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Spacer for settings icon
              const SizedBox(width: 36),
            ],
          ),

          // Settings icon — top right
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.settings_rounded),
              color: AppColors.primary,
              iconSize: 22,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onSettingsTap,
            ),
          ),
        ],
      ),
    );
  }
}
