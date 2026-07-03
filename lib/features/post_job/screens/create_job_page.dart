import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:nearwork/core/constants/app_colors.dart';
import 'package:nearwork/features/auth/providers/auth_provider.dart';
import 'package:nearwork/features/post_job/models/job.dart';
import 'package:nearwork/features/post_job/providers/post_job_provider.dart';
import 'package:nearwork/features/post_job/screens/location_picker_page.dart';
import 'package:nearwork/features/profile/services/cloudinary_service.dart';

class CreateJobPage extends StatefulWidget {
  const CreateJobPage({super.key});

  @override
  State<CreateJobPage> createState() => _CreateJobPageState();
}

class _CreateJobPageState extends State<CreateJobPage> {
  int _currentStep = 0;

  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _employerCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  final _salaryMinCtrl = TextEditingController();
  final _salaryMaxCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();

  String _category = 'No Category';
  String _type = 'Full Time';
  String _education = 'Open to All';
  String _experience = 'Entry Level';
  String _salaryType = 'fixed'; // 'fixed' | 'range' | 'negotiable'
  bool _whatsappSameAsPhone = false;
  bool _categoryExpanded = false;
  bool _educationExpanded = false;
  bool _experienceExpanded = false;

  LatLng? _selectedLocation;
  Set<Marker> _markers = {};
  bool _mapLocationError = false;
  int _locationVersion = 0;

  File? _jobImage;
  bool _isSubmitting = false;

  static const _categories = [
    'No Category',
    'IT & Technology',
    'Construction',
    'Driving & Logistics',
    'Retail & Sales',
    'Healthcare',
    'Education',
    'Hospitality',
    'Finance',
  ];

  static const _categoryIcons = <String, IconData>{
    'No Category': Icons.apps_outlined,
    'IT & Technology': Icons.computer_outlined,
    'Construction': Icons.construction,
    'Driving & Logistics': Icons.local_shipping_outlined,
    'Retail & Sales': Icons.storefront_outlined,
    'Healthcare': Icons.local_hospital_outlined,
    'Education': Icons.school_outlined,
    'Hospitality': Icons.restaurant_outlined,
    'Finance': Icons.account_balance_outlined,
  };

  static const _educationLevels = [
    'Open to All',
    'Ordinary Level',
    'Advanced Level',
    'Diploma',
    'NVQ Level 3',
    'NVQ Level 4',
    'Degree',
  ];

  static const _educationIcons = <String, IconData>{
    'Open to All': Icons.people_outline,
    'Ordinary Level': Icons.looks_one_outlined,
    'Advanced Level': Icons.looks_two_outlined,
    'Diploma': Icons.card_membership_outlined,
    'NVQ Level 3': Icons.looks_3_outlined,
    'NVQ Level 4': Icons.looks_4_outlined,
    'Degree': Icons.school_outlined,
  };

  static const _experienceLevels = [
    'Entry Level',
    '1 – 2 Years',
    '2 – 3 Years',
    '3 – 5 Years',
    '5 – 10 Years',
    '10+ Years',
  ];

  static const _experienceIcons = <String, IconData>{
    'Entry Level': Icons.fiber_new_outlined,
    '1 – 2 Years': Icons.timer_outlined,
    '2 – 3 Years': Icons.schedule_outlined,
    '3 – 5 Years': Icons.trending_up_outlined,
    '5 – 10 Years': Icons.trending_up,
    '10+ Years': Icons.emoji_events_outlined,
  };

  static const _stepTitles = ['Job Basics', 'Requirements', 'Location'];
  static const _sriLankaCenter = LatLng(7.8731, 80.7718);

  @override
  void initState() {
    super.initState();
    _phoneCtrl.addListener(() {
      if (_whatsappSameAsPhone) {
        _whatsappCtrl.text = _phoneCtrl.text;
        _whatsappCtrl.selection = TextSelection.fromPosition(
          TextPosition(offset: _whatsappCtrl.text.length),
        );
      }
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _employerCtrl.dispose();
    _salaryCtrl.dispose();
    _salaryMinCtrl.dispose();
    _salaryMaxCtrl.dispose();
    _descriptionCtrl.dispose();
    _locationCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsappCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickJobImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image != null) setState(() => _jobImage = File(image.path));
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerPage(initialLocation: _selectedLocation),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _selectedLocation = result;
        _mapLocationError = false;
        _locationVersion++;
        _markers = {
          Marker(
            markerId: const MarkerId('selected'),
            position: result,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        };
      });
    }
  }

  void _next() {
    final keys = [_step1Key, _step2Key, _step3Key];
    if (keys[_currentStep].currentState!.validate()) {
      if (_currentStep < 2) {
        setState(() => _currentStep++);
      } else {
        _submit();
      }
    }
  }

  bool _hasAnyData() {
    return _titleCtrl.text.isNotEmpty ||
        _employerCtrl.text.isNotEmpty ||
        _category != 'No Category' ||
        _type != 'Full Time' ||
        _education != 'Open to All' ||
        _experience != 'Entry Level' ||
        _salaryCtrl.text.isNotEmpty ||
        _salaryMinCtrl.text.isNotEmpty ||
        _salaryMaxCtrl.text.isNotEmpty ||
        _descriptionCtrl.text.isNotEmpty ||
        _locationCtrl.text.isNotEmpty ||
        _phoneCtrl.text.isNotEmpty ||
        _whatsappCtrl.text.isNotEmpty ||
        _selectedLocation != null ||
        _jobImage != null;
  }

  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else if (_hasAnyData()) {
      _showDiscardDialog();
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _showDiscardDialog() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: const Text(
          'Discard Job Post?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A2E),
          ),
        ),
        content: Text(
          'You have unsaved details. If you go back now, all your progress will be lost.',
          style: TextStyle(
            fontSize: 13.5,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Keep Editing',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Discard',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.pop(context);
  }

  Future<void> _submit() async {
    if (_selectedLocation == null) {
      setState(() => _mapLocationError = true);
      return;
    }

    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final postJobProvider = context.read<PostJobProvider>();

    setState(() => _isSubmitting = true);

    try {
      String imageUrl = '';
      if (_jobImage != null) {
        final result = await CloudinaryService().uploadFile(
          file: _jobImage!,
          folder: 'nearwork/jobs',
        );
        imageUrl = result.secureUrl;
      }

      final double salaryMin;
      final double salaryMax;
      if (_salaryType == 'range') {
        salaryMin =
            double.tryParse(_salaryMinCtrl.text.replaceAll(',', '')) ?? 0;
        salaryMax =
            double.tryParse(_salaryMaxCtrl.text.replaceAll(',', '')) ?? 0;
      } else if (_salaryType == 'negotiable') {
        salaryMin = 0;
        salaryMax = 0;
      } else {
        final amount =
            double.tryParse(_salaryCtrl.text.replaceAll(',', '')) ?? 0;
        salaryMin = amount;
        salaryMax = amount;
      }

      final whatsAppNum = _whatsappSameAsPhone
          ? _phoneCtrl.text.trim()
          : _whatsappCtrl.text.trim();

      final job = Job(
        id: '',
        title: _titleCtrl.text.trim(),
        employer: _employerCtrl.text.trim(),
        category: _category,
        type: _type,
        location: _locationCtrl.text.trim(),
        salaryMin: salaryMin,
        salaryMax: salaryMax,
        salaryType: _salaryType,
        education: _education,
        experience: _experience,
        description: _descriptionCtrl.text.trim(),
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        phone: _phoneCtrl.text.trim(),
        whatsApp: whatsAppNum,
        imageUrl: imageUrl,
        postedBy: user.uid,
        postedByName: user.displayName ?? '',
        postedByEmail: user.email ?? '',
        state: 'pending',
        createdAt: DateTime.now(),
      );

      final success = await postJobProvider.createJob(job);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job submitted for review!')),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: IndexedStack(
                index: _currentStep,
                children: [_buildStep1(), _buildStep2(), _buildStep3()],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ── Header (app bar + step indicator) ───────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: _back,
                  ),
                  const Expanded(
                    child: Text(
                      'Post a Job',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      for (int i = 0; i < 3; i++) ...[
                        if (i > 0)
                          Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: 2,
                              color: i <= _currentStep
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                        _buildStepCircle(i),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _stepTitles[0],
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: _currentStep == 0
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: _currentStep == 0
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _stepTitles[1],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: _currentStep == 1
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: _currentStep == 1
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _stepTitles[2],
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: _currentStep == 2
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: _currentStep == 2
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.6),
                          ),
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

  Widget _buildStepCircle(int step) {
    final isCompleted = step < _currentStep;
    final isActive = step == _currentStep;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted || isActive
            ? Colors.white
            : Colors.white.withValues(alpha: 0.3),
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, color: AppColors.primary, size: 16)
            : Text(
                '${step + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isActive
                      ? AppColors.primary
                      : Colors.white.withValues(alpha: 0.7),
                ),
              ),
      ),
    );
  }

  // ── Step 1: Job Basics ───────────────────────────────────────────────────────

  Widget _buildStep1() {
    return Form(
      key: _step1Key,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _stepHeader(
            'Tell us about the position',
            'Job title, company and category',
          ),
          const SizedBox(height: 20),
          Text(
            'Job Title',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          _field(
            _titleCtrl,
            'e.g. Senior Software Engineer',
            required: true,
            hintMode: true,
          ),
          const SizedBox(height: 16),
          Text(
            'Company / Employer',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          _field(
            _employerCtrl,
            'e.g. ABC Holdings (Pvt) Ltd',
            required: true,
            hintMode: true,
          ),

          const SizedBox(height: 16),
          Text(
            'Category',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          // Tappable trigger row
          GestureDetector(
            onTap: () => setState(() => _categoryExpanded = !_categoryExpanded),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _categoryExpanded
                      ? AppColors.primary
                      : Colors.grey.shade200,
                  width: _categoryExpanded ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _categoryIcons[_category]!,
                    size: 20,
                    color: _categoryExpanded
                        ? AppColors.primary
                        : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _category,
                      style: TextStyle(
                        fontSize: 14,
                        color: _category == 'No Category'
                            ? Colors.grey.shade500
                            : Colors.black87,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _categoryExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: _categoryExpanded
                          ? AppColors.primary
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Animated expanding chip panel
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            child: _categoryExpanded
                ? Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((c) {
                        final selected = _category == c;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _category = c;
                            _categoryExpanded = false;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : Colors.grey.shade200,
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _categoryIcons[c]!,
                                  size: 14,
                                  color: selected
                                      ? Colors.white
                                      : Colors.black45,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  c,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: selected
                                        ? Colors.white
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          Text(
            'Job Type',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final t in ['Full Time', 'Part Time']) ...[
                if (t == 'Part Time') const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _type = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _type == t
                            ? AppColors.primary
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _type == t
                              ? AppColors.primary
                              : Colors.grey.shade200,
                          width: _type == t ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            t == 'Full Time'
                                ? Icons.access_time_outlined
                                : Icons.timelapse_rounded,
                            size: 15,
                            color: _type == t ? Colors.white : Colors.black45,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            t,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: _type == t ? Colors.white : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Job image upload
          Text(
            'Company / Job Banner Image',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickJobImage,
            child: _jobImage == null
                ? _buildImagePlaceholder()
                : _buildImagePreview(),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 56,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 14),
            Text(
              'Tap to add a job image',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'JPG, PNG recommended',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox.expand(
              child: Image.file(_jobImage!, fit: BoxFit.contain),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => setState(() => _jobImage = null),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: _pickJobImage,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Change',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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

  // ── Step 2: Requirements ─────────────────────────────────────────────────────

  Widget _buildStep2() {
    return Form(
      key: _step2Key,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _stepHeader(
            'Requirements & Details',
            'Salary, qualifications and description',
          ),
          const SizedBox(height: 20),

          _buildSalaryCard(),
          const SizedBox(height: 16),

          Text(
            'Education',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          // Education trigger row
          GestureDetector(
            onTap: () =>
                setState(() => _educationExpanded = !_educationExpanded),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _educationExpanded
                      ? AppColors.primary
                      : Colors.grey.shade200,
                  width: _educationExpanded ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _educationIcons[_education]!,
                    size: 20,
                    color: _educationExpanded
                        ? AppColors.primary
                        : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _education,
                      style: TextStyle(
                        fontSize: 14,
                        color: _education == 'Open to All'
                            ? Colors.grey.shade500
                            : Colors.black87,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _educationExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: _educationExpanded
                          ? AppColors.primary
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            child: _educationExpanded
                ? Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _educationLevels.map((e) {
                        final selected = _education == e;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _education = e;
                            _educationExpanded = false;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : Colors.grey.shade200,
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _educationIcons[e]!,
                                  size: 14,
                                  color: selected
                                      ? Colors.white
                                      : Colors.black45,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  e,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: selected
                                        ? Colors.white
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),

          Text(
            'Experience',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          // Experience trigger row
          GestureDetector(
            onTap: () =>
                setState(() => _experienceExpanded = !_experienceExpanded),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _experienceExpanded
                      ? AppColors.primary
                      : Colors.grey.shade200,
                  width: _experienceExpanded ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _experienceIcons[_experience]!,
                    size: 20,
                    color: _experienceExpanded
                        ? AppColors.primary
                        : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _experience,
                      style: TextStyle(
                        fontSize: 14,
                        color: _experience == 'Entry Level'
                            ? Colors.grey.shade500
                            : Colors.black87,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _experienceExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: _experienceExpanded
                          ? AppColors.primary
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            child: _experienceExpanded
                ? Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _experienceLevels.map((e) {
                        final selected = _experience == e;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _experience = e;
                            _experienceExpanded = false;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : Colors.grey.shade200,
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _experienceIcons[e]!,
                                  size: 14,
                                  color: selected
                                      ? Colors.white
                                      : Colors.black45,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  e,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: selected
                                        ? Colors.white
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),

          Text(
            'Job Description',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descriptionCtrl,
            maxLines: 5,
            textAlignVertical: TextAlignVertical.top,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
            decoration: InputDecoration(
              hintText:
                  'Describe the role, responsibilities, and requirements...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.error),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryCard() {
    final lkrStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: Colors.grey.shade400,
    );

    InputDecoration salaryField(String hint) =>
        _inputDecoration(hint, null, hintMode: true).copyWith(
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 8),
            child: Text('LKR', style: lkrStyle),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Salary (LKR / month)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final t in ['Fixed', 'Range', 'Negotiable'])
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _salaryType = t.toLowerCase()),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      Radio<String>(
                        value: t.toLowerCase(),
                        groupValue: _salaryType,
                        onChanged: (v) => setState(() => _salaryType = v!),
                        activeColor: AppColors.primary,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      Text(
                        t,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _salaryType == t.toLowerCase()
                              ? AppColors.primary
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (_salaryType == 'fixed')
          TextFormField(
            controller: _salaryCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
            decoration: salaryField('e.g. 75,000'),
          )
        else if (_salaryType == 'range')
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _salaryMinCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                  decoration: salaryField('e.g. 50,000'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 15, left: 8, right: 8),
                child: Text(
                  '–',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: _salaryMaxCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                  decoration: salaryField('e.g. 120,000'),
                ),
              ),
            ],
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.handshake_outlined,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(width: 8),
                Text(
                  'Salary will be discussed during interview',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Step 3: Location & Contact ───────────────────────────────────────────────

  Widget _buildStep3() {
    const labelStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Color(0xFF757575),
    );

    return Form(
      key: _step3Key,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _stepHeader(
            'Location & Contact',
            'Where the job is and how to reach you',
          ),
          const SizedBox(height: 20),

          const Text('Location Name', style: labelStyle),
          const SizedBox(height: 8),
          _field(
            _locationCtrl,
            'e.g. Colombo 07, Kandy, Galle',
            required: true,
            hintMode: true,
          ),
          const SizedBox(height: 16),

          const Text('Job Location on Map', style: labelStyle),
          const SizedBox(height: 8),
          _buildLocationMapCard(),
          if (_mapLocationError)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                'Please set the job location on the map',
                style: TextStyle(fontSize: 12, color: AppColors.error),
              ),
            ),
          const SizedBox(height: 16),

          const Text('Contact Phone', style: labelStyle),
          const SizedBox(height: 8),
          _field(
            _phoneCtrl,
            'e.g. +94 77 123 4567',
            keyboard: TextInputType.phone,
            icon: Icons.phone_outlined,
            hintMode: true,
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('WhatsApp Number', style: labelStyle),
              Row(
                children: [
                  Checkbox(
                    value: _whatsappSameAsPhone,
                    onChanged: (v) => setState(() {
                      _whatsappSameAsPhone = v ?? false;
                      if (_whatsappSameAsPhone) {
                        _whatsappCtrl.text = _phoneCtrl.text;
                      } else {
                        _whatsappCtrl.clear();
                      }
                    }),
                    activeColor: AppColors.primary,
                    side: BorderSide(color: Colors.grey.shade400, width: 1.5),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  Text(
                    'Same as phone',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),

          const SizedBox(height: 8),
          TextFormField(
            controller: _whatsappCtrl,
            keyboardType: TextInputType.phone,
            enabled: !_whatsappSameAsPhone,
            decoration:
                _inputDecoration(
                  'e.g. +94 77 123 4567',
                  null,
                  hintMode: true,
                ).copyWith(
                  prefixIcon: Icon(
                    Icons.chat_bubble_outline,
                    size: 18,
                    color: _whatsappSameAsPhone
                        ? const Color(0xFF25D366)
                        : Colors.grey.shade400,
                  ),
                  fillColor: _whatsappSameAsPhone
                      ? Colors.grey.shade50
                      : Colors.white,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF25D366),
                      width: 1.5,
                    ),
                  ),
                ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildLocationMapCard() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _mapLocationError
                  ? AppColors.error
                  : _selectedLocation != null
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: SizedBox(
              height: 200,
              child: GoogleMap(
                key: ValueKey(_locationVersion),
                initialCameraPosition: _selectedLocation != null
                    ? CameraPosition(target: _selectedLocation!, zoom: 15)
                    : const CameraPosition(target: _sriLankaCenter, zoom: 7.5),
                markers: _markers,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
                scrollGesturesEnabled: false,
                zoomGesturesEnabled: false,
                rotateGesturesEnabled: false,
                tiltGesturesEnabled: false,
                onTap: (_) => _openLocationPicker(),
              ),
            ),
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: GestureDetector(
            onTap: _openLocationPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _selectedLocation != null
                        ? Icons.edit_location_alt_outlined
                        : Icons.location_searching,
                    size: 13,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _selectedLocation != null
                        ? 'Change location'
                        : 'Tap to set job location on map',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Bottom navigation bar ────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isSubmitting ? null : _back,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Back',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentStep < 2 ? 'Next' : 'Submit for Review',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (_currentStep < 2) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward, size: 18),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared helpers ───────────────────────────────────────────────────────────

  Widget _stepHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
    IconData? icon,
    bool enabled = true,
    bool hintMode = false,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboard,
      enabled: enabled,
      inputFormatters: keyboard == TextInputType.number
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
      decoration: _inputDecoration(label, icon, hintMode: hintMode),
    );
  }

  InputDecoration _inputDecoration(
    String label,
    IconData? icon, {
    bool hintMode = false,
  }) {
    return InputDecoration(
      labelText: hintMode ? null : label,
      labelStyle: hintMode
          ? null
          : TextStyle(fontSize: 14, color: Colors.grey.shade500),
      hintText: hintMode ? label : null,
      hintStyle: hintMode
          ? TextStyle(fontSize: 14, color: Colors.grey.shade400)
          : null,
      prefixIcon: icon != null
          ? Icon(icon, size: 20, color: Colors.grey.shade400)
          : null,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}
