import 'package:flutter/material.dart';
import 'package:nearwork/core/constants/app_colors.dart';

class ResumeItem {
  final String id;
  final String fileName;
  final String fileSize;
  final String fileType;
  final String updatedLabel;
  bool isDefault;

  ResumeItem({
    required this.id,
    required this.fileName,
    required this.fileSize,
    this.fileType = 'PDF Document',
    required this.updatedLabel,
    this.isDefault = false,
  });
}

class CvSectionWidget extends StatefulWidget {
  const CvSectionWidget({super.key});

  @override
  State<CvSectionWidget> createState() => _CvSectionWidgetState();
}

class _CvSectionWidgetState extends State<CvSectionWidget> {
  static const int _maxResumes = 5;

  final List<ResumeItem> _resumes = [
    ResumeItem(
      id: '1',
      fileName: 'Chamishka_CV_2025.pdf',
      fileSize: '245 KB',
      updatedLabel: 'Updated 3 days ago',
      isDefault: true,
    ),
    ResumeItem(
      id: '2',
      fileName: 'Chamishka_Cover_Letter.pdf',
      fileSize: '128 KB',
      updatedLabel: 'Updated 1 week ago',
    ),
  ];

  ResumeItem? get _defaultResume =>
      _resumes.where((r) => r.isDefault).firstOrNull;

  void _setDefault(String id) {
    setState(() {
      for (final r in _resumes) {
        r.isDefault = r.id == id;
      }
    });
  }

  void _deleteResume(String id) {
    setState(() {
      final wasDefault = _resumes.firstWhere((r) => r.id == id).isDefault;
      _resumes.removeWhere((r) => r.id == id);
      if (wasDefault && _resumes.isNotEmpty) {
        _resumes.first.isDefault = true;
      }
    });
  }

  void _showResumeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title + count
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
                    '${_resumes.length}/$_maxResumes',
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

              // Resume list
              if (_resumes.isNotEmpty)
                ...List.generate(_resumes.length, (i) {
                  final resume = _resumes[i];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: i < _resumes.length - 1 ? 10 : 0,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        setSheetState(() => _setDefault(resume.id));
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
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
                            // Radio indicator
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

                            // PDF icon
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.picture_as_pdf_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // File info
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
                                            color: AppColors.primary
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(4),
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

                            // Delete button
                            GestureDetector(
                              onTap: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                    backgroundColor: Colors.white,
                                    contentPadding: const EdgeInsets.fromLTRB(
                                      24, 16, 24, 16,
                                    ),
                                    actionsPadding: const EdgeInsets.fromLTRB(
                                      16, 0, 16, 16,
                                    ),
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
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Are you sure you want to delete "${resume.fileName}"?',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        const Text(
                                          'This action cannot be undone.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      OutlinedButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: AppColors.primary,
                                            width: 1.5,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
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
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red.shade600,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                        ),
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm != true) return;
                                setSheetState(() => _deleteResume(resume.id));
                                setState(() {});
                                if (_resumes.isEmpty && context.mounted) {
                                  Navigator.pop(context);
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

              if (_resumes.isNotEmpty) const SizedBox(height: 16),

              // Upload zone
              if (_resumes.length < _maxResumes)
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: implement file picker
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
                            'PDF format recommended · ${_maxResumes - _resumes.length} slots remaining',
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultResume = _defaultResume;
    final hasResume = _resumes.isNotEmpty;

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
                  '${_resumes.length} resume${_resumes.length > 1 ? 's' : ''}',
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
            onTap: _showResumeSheet,
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
                    ? _buildResumeCard(defaultResume!)
                    : _buildEmptyCard(),
              ),
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
