import 'package:flutter/material.dart';
import 'package:nearwork/core/constants/app_colors.dart';

class MoreItemCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final void Function()? onTap;
  final Color? iconColor;
  final Color? textColor;
  final bool isDanger;

  const MoreItemCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.textColor,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final finalIconColor = isDanger
        ? Colors.red.shade600
        : (iconColor ?? AppColors.primary);
    final finalTextColor = isDanger
        ? Colors.red.shade600
        : (textColor ?? AppColors.textPrimary);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          child: Row(
            children: [
              // Icon with background
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDanger
                      ? Colors.red.withOpacity(0.1)
                      : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  color: finalIconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),

              // Title
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: finalTextColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),

              // Chevron
              Icon(
                Icons.chevron_right_rounded,
                color: finalIconColor.withOpacity(0.6),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
