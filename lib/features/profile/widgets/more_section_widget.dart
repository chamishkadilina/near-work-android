import 'package:flutter/material.dart';
import 'package:nearwork/features/profile/widgets/more_item_card.dart';

class MoreSectionWidget extends StatelessWidget {
  final VoidCallback onFaqTap;
  final VoidCallback onSupportTap;
  final VoidCallback onPrivacyTap;
  final VoidCallback onTermsTap;
  final VoidCallback onShareAppTap;
  final VoidCallback onSignOutTap;

  const MoreSectionWidget({
    super.key,
    required this.onFaqTap,
    required this.onSupportTap,
    required this.onPrivacyTap,
    required this.onTermsTap,
    required this.onShareAppTap,
    required this.onSignOutTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        MoreItemCard(
          title: 'FAQ',
          icon: Icons.help_outline_rounded,
          onTap: onFaqTap,
        ),
        MoreItemCard(
          title: 'Support Center',
          icon: Icons.headset_mic_rounded,
          onTap: onSupportTap,
        ),
        MoreItemCard(
          title: 'Privacy Policy',
          icon: Icons.privacy_tip_outlined,
          onTap: onPrivacyTap,
        ),
        MoreItemCard(
          title: 'Terms & Conditions',
          icon: Icons.description_outlined,
          onTap: onTermsTap,
        ),
        MoreItemCard(
          title: 'Share App',
          icon: Icons.share_rounded,
          onTap: onShareAppTap,
        ),
        MoreItemCard(
          title: 'Sign Out',
          icon: Icons.logout_rounded,
          isDanger: true,
          onTap: onSignOutTap,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
