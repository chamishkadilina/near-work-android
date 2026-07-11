import 'package:flutter/material.dart';
import 'package:nearwork/core/constants/app_colors.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  static const List<({String question, String answer})> _faqs = [
    (
      question: 'What is NearWork?',
      answer:
          'NearWork is Sri Lanka\'s first location-based job finder app. '
          'It helps you discover job opportunities near your area using an interactive map, '
          'so you can find work close to home.',
    ),
    (
      question: 'Is NearWork free to use?',
      answer:
          'Yes, NearWork is completely free for both job seekers and job posters. '
          'There are no hidden charges or premium plans.',
    ),
    (
      question: 'How do I search for jobs?',
      answer:
          'Open the Explore tab to see jobs on the map. You can use the search bar '
          'to find specific roles (e.g. "Cashier", "Driver") or tap the filter icon '
          'to narrow results by job type, salary range, distance, category, and experience level.',
    ),
    (
      question: 'How do I apply for a job?',
      answer:
          'Tap on a job marker on the map to view the details. From there you can '
          'apply directly by submitting your CV, chat with the employer, call them, '
          'or get directions to the workplace.',
    ),
    (
      question: 'Can I post a job on NearWork?',
      answer:
          'Yes! Go to the Post Job tab, fill in the job details such as title, salary, '
          'location, and requirements, then publish it. Your job will appear on the map '
          'for nearby job seekers to discover.',
    ),
    (
      question: 'How do I upload or update my CV?',
      answer:
          'Go to your Profile and tap the CV section. You can upload a PDF of your CV '
          'which will be used when you apply for jobs directly through the app.',
    ),
    (
      question: 'How does the map-based search work?',
      answer:
          'NearWork plots job listings as markers on a map of Sri Lanka. '
          'You can zoom in to your area, use the location button to centre the map '
          'on your current position, and tap any marker to view the job details.',
    ),
    (
      question: 'Can I save jobs to view later?',
      answer:
          'Yes. When viewing a job\'s details, tap the Save button. '
          'You can find all your saved jobs in the Profile tab under Saved Jobs.',
    ),
    (
      question: 'How do I contact an employer?',
      answer:
          'From the job details sheet you can tap Chat to message the employer directly, '
          'or tap Call to ring them. You can also tap Direction to open Google Maps '
          'and navigate to the job location.',
    ),
    (
      question: 'Is NearWork available outside Sri Lanka?',
      answer:
          'NearWork is currently designed exclusively for Sri Lanka. '
          'All job listings and map coverage are focused on Sri Lankan locations.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text(
          'Frequently Asked Questions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: _faqs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final faq = _faqs[index];
          return _FaqTile(question: faq.question, answer: faq.answer);
        },
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _animCtrl;
  late final Animation<double> _expandAnim;
  late final Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeInOutCubic,
    );
    _rotateAnim = Tween<double>(begin: 0, end: 0.5).animate(_expandAnim);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _animCtrl.forward() : _animCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _expanded
                ? AppColors.primary.withValues(alpha: 0.3)
                : Colors.grey.shade200,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _expanded
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  RotationTransition(
                    turns: _rotateAnim,
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: _expanded
                          ? AppColors.primary
                          : Colors.grey.shade500,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
            SizeTransition(
              sizeFactor: _expandAnim,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Text(
                  widget.answer,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Colors.black54,
                    height: 1.55,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
