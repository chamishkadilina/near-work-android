import 'package:nearwork/features/post_job/models/job.dart';

// Plain keyword-overlap matching between a resume's extracted text and a
// job's title/category/description — no AI/ML, just token intersection.
class ResumeMatchService {
  // Sentinel meaning "not enough data to score" (empty resume text, e.g. a
  // scanned/image-only PDF with no text layer, or no resume attached at all).
  static const int notScored = -1;

  static const _stopwords = {
    'the', 'and', 'for', 'are', 'with', 'you', 'your', 'will', 'have',
    'has', 'this', 'that', 'from', 'able', 'must', 'can', 'all',
    'any', 'our', 'per', 'job', 'work', 'working', 'role', 'position',
    'candidate', 'candidates', 'applicant', 'looking', 'required',
    'requirements', 'preferred', 'responsibilities', 'about', 'into',
    'over', 'under', 'more', 'than', 'they', 'them', 'their', 'who',
    'what', 'when', 'where', 'why', 'how', 'not', 'but', 'also',
  };

  static int score(Job job, String resumeText) {
    if (resumeText.trim().isEmpty) return notScored;

    final jobKeywords = _keywords(
      '${job.title} ${job.category} ${job.description}',
    );
    if (jobKeywords.isEmpty) return notScored;

    final resumeWords = _tokenize(resumeText);
    final matched = jobKeywords.where(resumeWords.contains).length;
    final ratio = matched / jobKeywords.length;
    return (ratio * 10).round().clamp(0, 10);
  }

  static Set<String> _tokenize(String text) => text
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((w) => w.length > 2)
      .toSet();

  static Set<String> _keywords(String text) =>
      _tokenize(text).difference(_stopwords);
}
