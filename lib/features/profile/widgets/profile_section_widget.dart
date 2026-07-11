import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:nearwork/core/constants/app_colors.dart';
import 'package:nearwork/features/profile/providers/profile_provider.dart';

class ProfileSectionWidget extends StatelessWidget {
  final String uid;
  final String displayName;
  final String email;
  final String? photoURL;
  final String? bannerURL;
  final String about;
  final String location;

  const ProfileSectionWidget({
    super.key,
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoURL,
    this.bannerURL,
    this.about = '',
    this.location = '',
  });

  static const double _bannerHeight = 120;
  static const double _avatarRadius = 48;

  String get _capitalizedName => displayName
      .split(' ')
      .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
      .join(' ');

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditProfileSheet(
        uid: uid,
        currentAbout: about,
        currentLocation: location,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();

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
                decoration: bannerURL != null
                    ? BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(bannerURL!),
                          fit: BoxFit.contain,
                        ),
                      )
                    : const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary,
                            AppColors.primaryDark,
                            AppColors.primaryDark,
                          ],
                        ),
                      ),
              ),
              if (provider.isUploadingBanner)
                Container(
                  height: _bannerHeight,
                  width: double.infinity,
                  color: Colors.black.withValues(alpha: 0.4),
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
                ),

              // Avatar
              Positioned(
                left: 20,
                bottom: -_avatarRadius,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: _avatarRadius,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.1,
                        ),
                        backgroundImage:
                            photoURL != null && photoURL!.isNotEmpty
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
                      if (provider.isUploadingPhoto)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Edit button
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16, top: 16),
              child: GestureDetector(
                onTap: () => _showEditSheet(context),
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

          // Name + info
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _capitalizedName,
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
                if (about.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    about,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    location,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Edit Profile Bottom Sheet (combined: photo/banner/info)
// ─────────────────────────────────────────────────────────────────────────────
class _EditProfileSheet extends StatefulWidget {
  final String uid;
  final String currentAbout;
  final String currentLocation;

  const _EditProfileSheet({
    required this.uid,
    required this.currentAbout,
    required this.currentLocation,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  bool _showInfoForm = false;
  late final TextEditingController _aboutCtrl;
  late final TextEditingController _locationCtrl;

  @override
  void initState() {
    super.initState();
    _aboutCtrl = TextEditingController(text: widget.currentAbout);
    _locationCtrl = TextEditingController(text: widget.currentLocation);
  }

  @override
  void dispose() {
    _aboutCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload(BuildContext context, bool isPhoto) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: isPhoto ? 800 : 1200,
      imageQuality: 85,
    );
    if (picked == null) return;
    if (context.mounted) {
      Navigator.pop(context);
      final provider = context.read<ProfileProvider>();
      if (isPhoto) {
        provider.updateProfilePhoto(widget.uid, File(picked.path));
      } else {
        provider.updateBannerPhoto(widget.uid, File(picked.path));
      }
    }
  }

  Future<void> _saveInfo() async {
    final provider = context.read<ProfileProvider>();
    await provider.updateProfileInfo(
      widget.uid,
      about: _aboutCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _showInfoForm ? 'Edit Info' : 'Edit Profile',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (!_showInfoForm) ...[
            _optionTile(
              icon: Icons.camera_alt_outlined,
              title: 'Change Profile Photo',
              onTap: () => _pickAndUpload(context, true),
            ),
            const SizedBox(height: 10),
            _optionTile(
              icon: Icons.image_outlined,
              title: 'Change Banner',
              onTap: () => _pickAndUpload(context, false),
            ),
            const SizedBox(height: 10),
            _optionTile(
              icon: Icons.edit_note_rounded,
              title: 'Edit About & Location',
              onTap: () => setState(() => _showInfoForm = true),
            ),
          ] else ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'About',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _aboutCtrl,
              maxLines: 3,
              maxLength: 200,
              decoration: _inputDecoration('Tell us about yourself...'),
            ),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Location',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _locationCtrl,
              maxLength: 100,
              decoration: _inputDecoration('e.g. Colombo, Sri Lanka').copyWith(
                prefixIcon: Icon(
                  Icons.location_on_outlined,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: provider.isSaving ? null : _saveInfo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: provider.isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
    filled: true,
    fillColor: Colors.grey.shade50,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.primary),
    ),
    contentPadding: const EdgeInsets.all(14),
  );

  Widget _optionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
