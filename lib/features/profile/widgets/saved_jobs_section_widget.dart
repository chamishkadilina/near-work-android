import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nearwork/core/constants/app_colors.dart';
import 'package:nearwork/features/post_job/models/job.dart';
import 'package:nearwork/features/post_job/services/job_service.dart';

String _fmtViews(int v) {
  if (v < 1000) return '$v';
  if (v < 1000000)
    return '${(v / 1000).toStringAsFixed(1).replaceAll('.0', '')}K';
  return '${(v / 1000000).toStringAsFixed(1).replaceAll('.0', '')}M';
}

class SavedJobsSectionWidget extends StatelessWidget {
  final void Function(Job)? onJobTap;

  const SavedJobsSectionWidget({super.key, this.onJobTap});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final jobService = JobService();

    return StreamBuilder<List<Job>>(
      stream: jobService.streamSavedJobs(uid),
      builder: (context, snapshot) {
        final jobs = snapshot.data ?? [];

        if (jobs.isEmpty) {
          return Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bookmark_border_rounded,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No saved jobs yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Save jobs from the Explore tab to find them here',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Saved Jobs',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${jobs.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: jobs.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: Colors.grey.shade100),
                  itemBuilder: (context, index) => _JobSavedCard(
                    job: jobs[index],
                    onTap: onJobTap,
                    uid: uid,
                    jobService: jobService,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _JobSavedCard extends StatelessWidget {
  final Job job;
  final String uid;
  final JobService jobService;
  final void Function(Job)? onTap;

  const _JobSavedCard({
    required this.job,
    required this.uid,
    required this.jobService,
    this.onTap,
  });

  void _unsaveWithUndo(BuildContext context) {
    jobService.unsaveJob(uid, job.id);
    final sm = ScaffoldMessenger.of(context);
    sm.clearSnackBars();
    final entry = sm.showSnackBar(SnackBar(
      content: const Text('Removed from saved jobs'),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(days: 1),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () => jobService.saveJob(uid, job.id),
      ),
    ));
    Future.delayed(
      const Duration(seconds: 3),
      () { try { entry.close(); } catch (_) {} },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(job.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _unsaveWithUndo(context),
      background: Container(
        color: Colors.red.shade600,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_remove_rounded, color: Colors.white, size: 26),
            SizedBox(height: 4),
            Text(
              'Remove',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: InkWell(
        onTap: () => onTap?.call(job),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: const Color(0xFFF8F9FB),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: image + title + employer
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: job.imageUrl.isNotEmpty
                            ? Image.network(
                                job.imageUrl,
                                width: 56,
                                height: 56,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => _fallback(),
                              )
                            : _fallback(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              job.employer,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Location row — full width from left edge
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 12,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          job.location,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          job.type,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Salary row — full width from left edge
                  Row(
                    children: [
                      Text(
                        job.formattedSalary,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.visibility_outlined,
                        size: 12,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _fmtViews(job.viewCount),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        job.postedAgo,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallback() => Container(
    width: 56,
    height: 56,
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(
      Icons.business_rounded,
      size: 28,
      color: AppColors.primary,
    ),
  );
}
