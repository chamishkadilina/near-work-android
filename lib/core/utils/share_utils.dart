import 'package:share_plus/share_plus.dart';
import 'package:nearwork/features/post_job/models/job.dart';

const _playStoreUrl =
    'https://play.google.com/store/apps/details?id=com.chamishkadilina.nearwork';

Future<void> shareJob(Job job) async {
  final text =
      '${job.title} - ${job.employer}\n'
      '${job.location}  ·  ${job.type}  ·  ${job.formattedSalary}/mo\n\n'
      'View full description, requirements & apply on NearWork:\n'
      '$_playStoreUrl';

  await SharePlus.instance.share(
    ShareParams(
      text: text,
      subject: '${job.title} at ${job.employer} – NearWork',
    ),
  );
}
