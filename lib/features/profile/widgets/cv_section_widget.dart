import 'package:flutter/material.dart';
import 'package:nearwork/core/constants/app_colors.dart';
import 'package:nearwork/core/models/resume_item.dart';

class CvSectionWidget extends StatelessWidget {
  final List<ResumeItem> resumes;
  final Stream<List<ResumeItem>>? resumesStream;
  final VoidCallback? onUploadTap;
  final Future<void> Function(String id)? onDeleteResume;
  final Future<void> Function(String id)? onSetDefault;
  final bool isUploading;

  const CvSectionWidget({
    super.key,
    this.resumes = const [],
    this.resumesStream,
    this.onUploadTap,
    this.onDeleteResume,
    this.onSetDefault,
    this.isUploading = false,
  });

  static const int _maxResumes = 5;

  ResumeItem? get _defaultResume =>
      resumes.where((r) => r.isDefault).firstOrNull;

  void _showResumeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => resumesStream != null
          ? StreamBuilder<List<ResumeItem>>(
              stream: resumesStream,
              initialData: resumes,
              builder: (context, snap) => _ResumeSheet(
                resumes: snap.data ?? resumes,
                maxResumes: _maxResumes,
                isUploading: isUploading,
                onUploadTap: onUploadTap,
                onDeleteResume: onDeleteResume,
                onSetDefault: onSetDefault,
              ),
            )
          : _ResumeSheet(
              resumes: resumes,
              maxResumes: _maxResumes,
              isUploading: isUploading,
              onUploadTap: onUploadTap,
              onDeleteResume: onDeleteResume,
              onSetDefault: onSetDefault,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasResume = resumes.isNotEmpty;

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Resume',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              if (hasResume)
                Text(
                  '${resumes.length} resume${resumes.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => _showResumeSheet(context),
            child: CustomPaint(
              painter: _DashedBorderPainter(
                color: Colors.grey.shade300,
                borderRadius: 12,
                dashWidth: 5,
                dashGap: 4,
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: hasResume
                    ? _buildResumeCard(_defaultResume ?? resumes.first)
                    : _buildEmptyCard(),
              ),
            ),
          ),
          if (isUploading)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Uploading resume...',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResumeCard(ResumeItem resume) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.picture_as_pdf_rounded,
            color: AppColors.primary,
            size: 26,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                resume.fileName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${resume.fileSize} · ${resume.fileType}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        Icon(
          Icons.chevron_right_rounded,
          color: Colors.grey.shade400,
          size: 22,
        ),
      ],
    );
  }

  Widget _buildEmptyCard() {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.upload_file_rounded,
            color: Colors.grey.shade400,
            size: 26,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'No resume added',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap to upload your CV',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.add_circle_outline_rounded,
          color: AppColors.primary,
          size: 22,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Resume management bottom sheet
// ─────────────────────────────────────────────────────────────────────────────
class _ResumeSheet extends StatelessWidget {
  final List<ResumeItem> resumes;
  final int maxResumes;
  final bool isUploading;
  final VoidCallback? onUploadTap;
  final Future<void> Function(String id)? onDeleteResume;
  final Future<void> Function(String id)? onSetDefault;

  const _ResumeSheet({
    required this.resumes,
    required this.maxResumes,
    required this.isUploading,
    this.onUploadTap,
    this.onDeleteResume,
    this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Resumes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${resumes.length}/$maxResumes',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Tap to set as default. Default resume is used when applying.',
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
            ),
          ),
          const SizedBox(height: 16),

          ...List.generate(resumes.length, (i) {
            final resume = resumes[i];
            return Padding(
              padding: EdgeInsets.only(bottom: i < resumes.length - 1 ? 10 : 0),
              child: GestureDetector(
                onTap: () => onSetDefault?.call(resume.id),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: resume.isDefault
                        ? AppColors.primary.withValues(alpha: 0.05)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: resume.isDefault
                          ? AppColors.primary.withValues(alpha: 0.4)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: resume.isDefault
                                ? AppColors.primary
                                : Colors.grey.shade400,
                            width: 2,
                          ),
                        ),
                        child: resume.isDefault
                            ? Center(
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    resume.fileName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (resume.isDefault) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Default',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${resume.fileSize} · ${resume.updatedLabel}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final confirm = await _showDeleteDialog(
                            context,
                            resume.fileName,
                          );
                          if (confirm == true) {
                            onDeleteResume?.call(resume.id);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          if (resumes.isNotEmpty) const SizedBox(height: 16),

          if (isUploading)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 14),
                    Text(
                      'Uploading resume...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (resumes.length < maxResumes)
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                onUploadTap?.call();
              },
              child: CustomPaint(
                painter: _DashedBorderPainter(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  borderRadius: 14,
                  dashWidth: 6,
                  dashGap: 4,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cloud_upload_outlined,
                          color: AppColors.primary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Tap to upload a resume',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'PDF format recommended · ${maxResumes - resumes.length} slots remaining',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteDialog(BuildContext context, String fileName) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Icon(
              Icons.delete_outline_rounded,
              color: Colors.red.shade600,
              size: 24,
            ),
            const SizedBox(width: 10),
            const Text(
              'Delete Resume',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "$fileName"?',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;
  final double dashWidth;
  final double dashGap;
  final double strokeWidth;

  _DashedBorderPainter({
    required this.color,
    this.borderRadius = 12,
    this.dashWidth = 5,
    this.dashGap = 4,
  }) : strokeWidth = 1;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );
    final path = Path()..addRRect(rrect);
    final dashedPath = _dashPath(path, dashWidth: dashWidth, dashGap: dashGap);
    canvas.drawPath(dashedPath, paint);
  }

  Path _dashPath(
    Path source, {
    required double dashWidth,
    required double dashGap,
  }) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        dest.addPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          Offset.zero,
        );
        distance = next + dashGap;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
