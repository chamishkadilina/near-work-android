import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:nearwork/core/constants/app_colors.dart';
import 'package:nearwork/core/services/resume_match_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nearwork/core/utils/share_utils.dart';
import 'package:nearwork/features/post_job/models/job.dart';
import 'package:nearwork/features/post_job/services/job_service.dart';
import 'package:nearwork/features/explore/providers/job_provider.dart';
import 'package:nearwork/features/messages/providers/inbox_provider.dart';
import 'package:nearwork/features/messages/services/inbox_service.dart';
import 'package:nearwork/features/messages/screens/chat_screen.dart';
import 'package:nearwork/features/profile/models/resume_item.dart';
import 'package:nearwork/features/profile/providers/profile_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => ExplorePageState();
}

class ExplorePageState extends State<ExplorePage>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _controller;
  GoogleMapController? _filterMapController;
  // Marker icons built from each job's own post image, keyed by job id so
  // a given job's image is only fetched/decoded once.
  final Map<String, BitmapDescriptor> _markerIconCache = {};
  final _jobService = JobService();
  final _inboxService = InboxService();

  // ── Filter panel animation ───────────────────────────────────────────────────
  bool _filterOpen = false;
  late final AnimationController _animCtrl;
  late final Animation<double> _expandAnim;

  // ── Search ───────────────────────────────────────────────────────────────────
  late final TextEditingController _searchController;
  final FocusNode _searchFocus = FocusNode();
  List<String> _suggestions = [];
  bool _showSuggestions = false;

  // ── Filter state ─────────────────────────────────────────────────────────────
  final Set<String> _selectedJobTypes = Set.from(_jobTypes);
  RangeValues _salary = const RangeValues(40000, 200000);
  double _distance = 25;
  String _selectedCategory = 'All';
  final Set<String> _selectedExperiences = {};

  // ── Location ──────────────────────────────────────────────────────────────────
  Position? _currentPosition;

  // ── Map ──────────────────────────────────────────────────────────────────────
  static const _initial = CameraPosition(
    target: LatLng(7.8731, 80.7718),
    zoom: 8,
  );
  static const _userLocation = LatLng(7.2083, 79.8358);

  // ── Statics ───────────────────────────────────────────────────────────────────
  static const _jobTypes = ['Full Time', 'Part Time'];
  static const _categories = [
    ('All', Icons.apps_rounded),
    ('IT & Technology', Icons.computer_rounded),
    ('Construction', Icons.construction_rounded),
    ('Driving & Logistics', Icons.local_shipping_rounded),
    ('Retail & Sales', Icons.storefront_rounded),
    ('Healthcare', Icons.health_and_safety_rounded),
    ('Education', Icons.school_rounded),
    ('Hospitality', Icons.hotel_rounded),
    ('Finance', Icons.account_balance_rounded),
  ];
  static const _experiences = ['No Experience', '1 – 2 Years', '3+ Years'];

  // ── All searchable job keywords ───────────────────────────────────────────────
  static const _allJobKeywords = [
    'Barista',
    'Bartender',
    'Baker',
    'Branch Manager',
    'Brand Executive',
    'Bus Driver',
    'Cashier',
    'Chef',
    'Civil Engineer',
    'Cleaner',
    'Construction Worker',
    'Customer Service',
    'Data Analyst',
    'Delivery Driver',
    'Electrician',
    'Factory Worker',
    'Financial Analyst',
    'Graphic Designer',
    'Hotel Receptionist',
    'IT Support',
    'Mechanic',
    'Nurse',
    'Office Assistant',
    'Plumber',
    'Receptionist',
    'Retail Assistant',
    'Sales Executive',
    'Security Guard',
    'Software Developer',
    'Teacher',
    'Technician',
    'Waiter',
    'Warehouse Worker',
    'Web Developer',
  ];

  // salary constants
  static const double _salaryMin = 0;
  static const double _salaryMax = 250000;
  static const int _salaryDivisions = 25;
  static const double _salaryInitialStart = 40000;
  static const double _salaryInitialEnd = 200000;

  // ── Lifecycle ─────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);
    _searchFocus.addListener(() {
      if (!_searchFocus.hasFocus) {
        setState(() => _showSuggestions = false);
      }
    });
    _requestLocationSilently();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _expandAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeInOutCubic,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JobProvider>().fetchJobs();
    });
  }

  Future<void> _requestLocationSilently() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever)
        return;

      // Use last-known position instantly while waiting for GPS fix
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && mounted) {
        setState(() => _currentPosition = lastKnown);
        final cp = CameraPosition(
          target: LatLng(lastKnown.latitude, lastKnown.longitude),
          zoom: _distanceToZoom(_distance),
        );
        _controller?.animateCamera(CameraUpdate.newCameraPosition(cp));
        _filterMapController?.animateCamera(CameraUpdate.newCameraPosition(cp));
      }

      // Then get the accurate current fix
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() => _currentPosition = position);
      final cp = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: _distanceToZoom(_distance),
      );
      _controller?.animateCamera(CameraUpdate.newCameraPosition(cp));
      _filterMapController?.animateCamera(CameraUpdate.newCameraPosition(cp));
    } catch (_) {}
  }

  double _distanceToZoom(double distKm) {
    if (distKm <= 2) return 13.5;
    if (distKm <= 5) return 12.0;
    if (distKm <= 10) return 11.0;
    if (distKm <= 20) return 10.0;
    return 9.5;
  }

  // ── Job-photo markers ─────────────────────────────────────────────────────────
  // Builds a circular map marker straight from the job's own posted image.
  // No placeholder marker is used while the image is loading.
  Future<void> _loadJobMarkerIcon(Job job) async {
    if (_markerIconCache.containsKey(job.id)) return;
    if (job.imageUrl.isEmpty) return;

    try {
      final icon = await _bitmapFromNetworkImage(job.imageUrl);
      if (!mounted) return;
      _markerIconCache[job.id] = icon;
      setState(() {});
    } catch (_) {
      // No default icon; if load fails, the job is not shown on the map.
    }
  }

  Future<BitmapDescriptor> _bitmapFromNetworkImage(String url) async {
    const size = 106;
    const border = 8.0;
    const innerPadding = 6.0;

    final data = await NetworkAssetBundle(Uri.parse(url)).load(url);
    final bytes = data.buffer.asUint8List();

    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: size,
      targetHeight: size,
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);
    final radius = size / 2;
    final innerRadius = radius - border - innerPadding;

    // White circular backing behind the photo.
    canvas.drawCircle(center, radius, Paint()..color = Colors.white);

    // Clip the photo into a circle and draw it inside the white backing.
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: innerRadius)),
    );
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromCircle(center: center, radius: innerRadius),
      Paint()..filterQuality = FilterQuality.high,
    );
    canvas.restore();

    // Brand-colored circular outline.
    canvas.drawCircle(
      center,
      radius - border / 2,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = border,
    );

    final rendered = await recorder.endRecording().toImage(size, size);
    final byteData = await rendered.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _animCtrl.dispose();
    _controller?.dispose();
    _filterMapController?.dispose();
    super.dispose();
  }

  // ── Search logic ──────────────────────────────────────────────────────────────
  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    final allJobs = context.read<JobProvider>().jobs;
    final seen = <String>{};
    final suggestions = <String>[];
    // Real job terms first (titles, employers, categories)
    for (final job in allJobs) {
      for (final term in [
        job.title,
        job.employer,
        job.category,
        job.location,
      ]) {
        final lower = term.toLowerCase();
        if (lower.contains(query) && seen.add(lower)) {
          suggestions.add(term);
        }
      }
    }
    // Static keywords that have at least one matching job
    for (final kw in _allJobKeywords) {
      final kwLower = kw.toLowerCase();
      if (kwLower.contains(query) && !seen.contains(kwLower)) {
        final hasJobs = allJobs.any(
          (j) =>
              j.title.toLowerCase().contains(kwLower) ||
              j.employer.toLowerCase().contains(kwLower) ||
              j.category.toLowerCase().contains(kwLower),
        );
        if (hasJobs && seen.add(kwLower)) suggestions.add(kw);
      }
    }
    setState(() {
      _suggestions = suggestions.take(8).toList();
      _showSuggestions = true;
    });
  }

  void _selectSuggestion(String suggestion) {
    _searchController.removeListener(_onSearchChanged);
    _searchController.text = suggestion;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    _searchController.addListener(_onSearchChanged);
    _searchFocus.unfocus();
    setState(() => _showSuggestions = false);
  }

  void _clearSearch() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.clear();
    _searchController.addListener(_onSearchChanged);
    setState(() {
      _suggestions = [];
      _showSuggestions = false;
    });
  }

  // ── Filter logic ──────────────────────────────────────────────────────────────
  List<Job> _applyFilters(List<Job> allJobs) {
    var jobs = allJobs;

    // Search text
    final q = _searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      jobs = jobs
          .where(
            (j) =>
                j.title.toLowerCase().contains(q) ||
                j.employer.toLowerCase().contains(q) ||
                j.category.toLowerCase().contains(q) ||
                j.location.toLowerCase().contains(q),
          )
          .toList();
    }

    // Job type (show all when both are selected)
    if (_selectedJobTypes.length < _jobTypes.length) {
      jobs = jobs.where((j) => _selectedJobTypes.contains(j.type)).toList();
    }

    // Salary (only apply when changed from default)
    if (_salary.start != _salaryInitialStart ||
        _salary.end != _salaryInitialEnd) {
      jobs = jobs.where((j) {
        if (j.salaryType == 'negotiable') return true;
        final jobMax = j.salaryMax > 0 ? j.salaryMax : j.salaryMin;
        return j.salaryMin <= _salary.end && jobMax >= _salary.start;
      }).toList();
    }

    // Category
    if (_selectedCategory != 'All') {
      jobs = jobs.where((j) => j.category == _selectedCategory).toList();
    }

    // Experience
    if (_selectedExperiences.isNotEmpty) {
      jobs = jobs
          .where((j) => _selectedExperiences.contains(j.experience))
          .toList();
    }

    // Distance — only filter when below max (25 km = "any distance")
    // Requires a real GPS fix; skip silently if not yet acquired
    if (_distance < 25 && _currentPosition != null) {
      final userLat = _currentPosition!.latitude;
      final userLng = _currentPosition!.longitude;
      jobs = jobs.where((j) {
        if (j.latitude == 0 && j.longitude == 0) return true;
        final distM = Geolocator.distanceBetween(
          userLat,
          userLng,
          j.latitude,
          j.longitude,
        );
        return distM / 1000 <= _distance;
      }).toList();
    }

    return jobs;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  Set<Marker> _buildMarkers(List<Job> jobs) {
    return jobs
        .where((job) {
          if (!_markerIconCache.containsKey(job.id)) _loadJobMarkerIcon(job);
          return _markerIconCache.containsKey(job.id);
        })
        .map((job) {
          final icon = _markerIconCache[job.id]!;
          return Marker(
            markerId: MarkerId(job.id),
            position: LatLng(job.latitude, job.longitude),
            icon: icon,
            onTap: () => _showJobBottomSheet(job),
          );
        })
        .toSet();
  }

  void _toggleFilter() {
    setState(() => _filterOpen = !_filterOpen);
    _filterOpen ? _animCtrl.forward() : _animCtrl.reverse();
  }

  void _closeFilter() {
    if (_filterOpen) {
      setState(() => _filterOpen = false);
      _animCtrl.reverse();
    }
    if (_distance >= 25) {
      _controller?.animateCamera(
        CameraUpdate.newCameraPosition(_sriLankaOverview),
      );
    } else {
      final pos = _currentPosition;
      if (pos != null) {
        _controller?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(pos.latitude, pos.longitude),
              zoom: _distanceToZoom(_distance),
            ),
          ),
        );
      }
    }
  }

  void _cancelFilter() {
    _resetFilters();
    if (_filterOpen) {
      setState(() => _filterOpen = false);
      _animCtrl.reverse();
    }
  }

  void _dismissAll() {
    _searchFocus.unfocus();
    setState(() => _showSuggestions = false);
    _cancelFilter();
  }

  String _fmtViews(int v) {
    if (v < 1000) return '$v';
    if (v < 1000000)
      return '${(v / 1000).toStringAsFixed(1).replaceAll('.0', '')}K';
    return '${(v / 1000000).toStringAsFixed(1).replaceAll('.0', '')}M';
  }

  String _formatSalary(double v) {
    final formatted = v.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return 'LKR $formatted';
  }

  void _resetFilters() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.clear();
    _searchController.addListener(_onSearchChanged);
    setState(() {
      _suggestions = [];
      _showSuggestions = false;
      _selectedJobTypes
        ..clear()
        ..addAll(_jobTypes);
      _salary = const RangeValues(_salaryInitialStart, _salaryInitialEnd);
      _distance = 25;
      _selectedCategory = 'All';
      _selectedExperiences.clear();
    });
  }

  bool get _hasActiveFilters {
    if (_searchController.text.trim().isNotEmpty) return true;
    if (_selectedJobTypes.length != _jobTypes.length) return true;
    if (_salary.start != _salaryInitialStart ||
        _salary.end != _salaryInitialEnd)
      return true;
    if (_distance != 25) return true;
    if (_selectedCategory != 'All') return true;
    if (_selectedExperiences.isNotEmpty) return true;
    return false;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final jobProvider = context.watch<JobProvider>();
    final filteredJobs = _applyFilters(jobProvider.jobs);
    final markers = _buildMarkers(filteredJobs);

    return Scaffold(
      body: Stack(
        children: [
          GestureDetector(onTap: _dismissAll, child: _buildMap(markers)),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: _buildSearchAndFilter(jobProvider.jobs),
          ),
          _buildLocationButton(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  //  Search bar + suggestions + expanding filter panel
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildSearchAndFilter(List<Job> allJobs) {
    return AnimatedBuilder(
      animation: _expandAnim,
      builder: (context, _) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10 + _expandAnim.value * 0.06),
              blurRadius: 12 + _expandAnim.value * 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSearchRow(),
              // ── Suggestions dropdown ─────────────────────────────────────
              if (_showSuggestions) _buildSuggestionsPanel(allJobs),
              // ── Filter body ──────────────────────────────────────────────
              SizeTransition(
                sizeFactor: _expandAnim,
                axisAlignment: -1,
                child: _buildFilterBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Search row ────────────────────────────────────────────────────────────────
  Widget _buildSearchRow() {
    final active = _hasActiveFilters;
    final hasText = _searchController.text.isNotEmpty;
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Search icon
          Icon(
            Icons.search,
            color: _showSuggestions
                ? AppColors.primary
                : (_filterOpen ? AppColors.primary : AppColors.textSecondary),
            size: 22,
          ),
          const SizedBox(width: 8),
          // Text field
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => setState(() => _showSuggestions = false),
              decoration: const InputDecoration(
                hintText: 'Search barista, retail, delivery...',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          // Clear button - visible only when text exists
          if (hasText)
            GestureDetector(
              onTap: _clearSearch,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          const SizedBox(width: 4),
          // Filter toggle
          GestureDetector(
            onTap: _toggleFilter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: active || _filterOpen
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.tune,
                color: active || _filterOpen
                    ? AppColors.primary
                    : AppColors.textSecondary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Suggestions panel ─────────────────────────────────────────────────────────
  Widget _buildSuggestionsPanel(List<Job> allJobs) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
        if (_suggestions.isEmpty)
          // No results state
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(width: 10),
                Text(
                  'No results for "${_searchController.text}"',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          )
        else
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: _filterOpen ? 104 : 256),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, index) {
                final item = _suggestions[index];
                final label = item.toLowerCase();
                final count = allJobs
                    .where(
                      (j) =>
                          j.title.toLowerCase().contains(label) ||
                          j.employer.toLowerCase().contains(label) ||
                          j.category.toLowerCase().contains(label),
                    )
                    .length;
                return _SuggestionTile(
                  label: item,
                  query: _searchController.text.trim().toLowerCase(),
                  count: count,
                  onTap: () => _selectSuggestion(item),
                );
              },
            ),
          ),
      ],
    );
  }

  // ── Filter body ───────────────────────────────────────────────────────────────
  Widget _buildFilterBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.57,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildJobTypeSection(),
                _filterDivider(),
                _buildSalarySection(),
                _filterDivider(),
                _buildDistanceSection(),
                _filterDivider(),
                _buildCategorySection(),
                _filterDivider(),
                _buildExperienceSection(),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
        _buildBottomButtons(),
      ],
    );
  }

  Widget _filterDivider() =>
      Divider(height: 1, thickness: 1, color: Colors.grey.shade100);

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    ),
  );

  // ── 1. Job Type ───────────────────────────────────────────────────────────────
  Widget _buildJobTypeSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionLabel('Job Type'),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          children: _jobTypes.map((type) {
            final selected = _selectedJobTypes.contains(type);
            final isLast = type == _jobTypes.last;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: isLast ? 0 : 10),
                child: GestureDetector(
                  onTap: () => setState(() {
                    if (selected) {
                      if (_selectedJobTypes.length > 1)
                        _selectedJobTypes.remove(type);
                    } else {
                      _selectedJobTypes.add(type);
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : Colors.grey.shade200,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          type == 'Full Time'
                              ? Icons.access_time_outlined
                              : Icons.timelapse_rounded,
                          size: 15,
                          color: selected ? Colors.white : Colors.black45,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          type,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: selected ? Colors.white : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    ],
  );

  // ── 2. Salary ─────────────────────────────────────────────────────────────────
  Widget _buildSalarySection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionLabel('Salary Range (per month)'),
      SliderTheme(
        data: _sliderTheme,
        child: RangeSlider(
          values: _salary,
          min: _salaryMin,
          max: _salaryMax,
          divisions: _salaryDivisions,
          onChanged: (v) => setState(() => _salary = v),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _salaryChip(_formatSalary(_salary.start)),
            _salaryChip(_formatSalary(_salary.end)),
          ],
        ),
      ),
    ],
  );

  Widget _salaryChip(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.primary.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
    ),
  );

  // ── 3. Distance ───────────────────────────────────────────────────────────────
  static const _sriLankaOverview = CameraPosition(
    target: LatLng(7.8731, 80.7718),
    zoom: 7.5,
  );

  Widget _buildDistanceSection() {
    final isAny = _distance >= 25;
    final center = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : _userLocation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Distance'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 160,
              child: GoogleMap(
                initialCameraPosition: isAny
                    ? _sriLankaOverview
                    : CameraPosition(
                        target: center,
                        zoom: _distanceToZoom(_distance),
                      ),
                onMapCreated: (c) {
                  _filterMapController = c;
                  final dist = _distance;
                  final pos = _currentPosition;
                  if (dist >= 25) {
                    c.animateCamera(
                      CameraUpdate.newCameraPosition(_sriLankaOverview),
                    );
                  } else if (pos != null) {
                    c.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: LatLng(pos.latitude, pos.longitude),
                          zoom: _distanceToZoom(dist),
                        ),
                      ),
                    );
                  }
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: false,
                mapToolbarEnabled: false,
                scrollGesturesEnabled: false,
                zoomGesturesEnabled: false,
                rotateGesturesEnabled: false,
                tiltGesturesEnabled: false,
                circles: isAny
                    ? {}
                    : {
                        Circle(
                          circleId: const CircleId('range'),
                          center: center,
                          radius: _distance * 1000,
                          fillColor: AppColors.primary.withValues(alpha: 0.12),
                          strokeColor: AppColors.primary.withValues(alpha: 0.5),
                          strokeWidth: 2,
                        ),
                      },
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        SliderTheme(
          data: _sliderTheme,
          child: Slider(
            value: _distance,
            min: 1,
            max: 25,
            divisions: 24,
            onChanged: (v) {
              setState(() => _distance = v);
              if (v >= 25) {
                _filterMapController?.animateCamera(
                  CameraUpdate.newCameraPosition(_sriLankaOverview),
                );
              } else {
                final pos = _currentPosition;
                if (pos != null) {
                  _filterMapController?.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: LatLng(pos.latitude, pos.longitude),
                        zoom: _distanceToZoom(v),
                      ),
                    ),
                  );
                }
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1 km', style: _axisStyle),
              Text(
                _distance >= 25
                    ? 'Any distance'
                    : '${_distance.toStringAsFixed(0)} km radius',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              Text('Any', style: _axisStyle),
            ],
          ),
        ),
      ],
    );
  }

  // ── 4. Job Category ───────────────────────────────────────────────────────────
  Widget _buildCategorySection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionLabel('Job Category'),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((c) {
            final label = c.$1;
            final icon = c.$2;
            final selected = _selectedCategory == label;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 170),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? AppColors.primary : Colors.grey.shade200,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 14,
                      color: selected ? Colors.white : Colors.black45,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: selected ? Colors.white : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    ],
  );

  // ── 5. Experience ─────────────────────────────────────────────────────────────
  static const _experienceChipIcons = <String, IconData>{
    'No Experience': Icons.fiber_new_outlined,
    '1 – 2 Years': Icons.timer_outlined,
    '3+ Years': Icons.trending_up_outlined,
  };

  Widget _buildExperienceSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionLabel('Experience Level'),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _experiences.map((label) {
            final selected = _selectedExperiences.contains(label);
            return GestureDetector(
              onTap: () => setState(() {
                if (selected) {
                  _selectedExperiences.remove(label);
                } else {
                  _selectedExperiences.add(label);
                }
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 170),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? AppColors.primary : Colors.grey.shade200,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _experienceChipIcons[label] ?? Icons.work_outline,
                      size: 14,
                      color: selected ? Colors.white : Colors.black45,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: selected ? Colors.white : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    ],
  );

  // ── Bottom buttons ────────────────────────────────────────────────────────────
  Widget _buildBottomButtons() => Container(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: Colors.grey.shade100)),
    ),
    child: Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _cancelFilter,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _closeFilter,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Apply Filters',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    ),
  );

  SliderThemeData get _sliderTheme => SliderTheme.of(context).copyWith(
    activeTrackColor: AppColors.primary,
    inactiveTrackColor: Colors.grey.shade200,
    thumbColor: Colors.white,
    thumbShape: const RoundSliderThumbShape(
      enabledThumbRadius: 9,
      elevation: 4,
    ),
    overlayColor: AppColors.primary.withOpacity(0.12),
    overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
    rangeThumbShape: const RoundRangeSliderThumbShape(
      enabledThumbRadius: 9,
      elevation: 4,
    ),
    trackHeight: 3.5,
  );

  TextStyle get _axisStyle =>
      const TextStyle(fontSize: 11, color: Colors.black38);

  // ─────────────────────────────────────────────────────────────────────────────
  //  Map
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildMap(Set<Marker> markers) => GoogleMap(
    initialCameraPosition: _initial,
    onMapCreated: (c) => _controller = c,
    markers: markers,
    myLocationEnabled: true,
    myLocationButtonEnabled: false,
    zoomControlsEnabled: false,
    compassEnabled: false,
    mapToolbarEnabled: false,
    mapType: MapType.normal,
    padding: const EdgeInsets.only(top: 96),
    minMaxZoomPreference: const MinMaxZoomPreference(8, 18),
    cameraTargetBounds: CameraTargetBounds(
      LatLngBounds(
        southwest: const LatLng(5.919, 79.695),
        northeast: const LatLng(9.835, 81.879),
      ),
    ),
  );

  Widget _buildLocationButton() => Positioned(
    bottom: 16,
    right: 16,
    child: Container(
      width: 54,
      height: 54,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: IconButton(
        icon: Transform.rotate(
          angle: 0.75,
          child: const Icon(Icons.navigation, color: AppColors.primary),
        ),
        onPressed: _moveToCurrentLocation,
      ),
    ),
  );

  Future<void> _moveToCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever)
      return;
    final position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() => _currentPosition = position);
      final target = LatLng(position.latitude, position.longitude);
      if (_distance < 25) {
        final cp = CameraPosition(
          target: target,
          zoom: _distanceToZoom(_distance),
        );
        _controller?.animateCamera(CameraUpdate.newCameraPosition(cp));
        _filterMapController?.animateCamera(CameraUpdate.newCameraPosition(cp));
      } else {
        _controller?.animateCamera(
          CameraUpdate.newCameraPosition(_sriLankaOverview),
        );
      }
    }
  }

  Future<void> _openDirections(Job job) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${job.latitude},${job.longitude}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  //  Job detail bottom sheet
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> showJobSheet(Job job) async {
    await _controller?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(job.latitude, job.longitude), zoom: 15),
      ),
    );
    if (mounted) _showJobBottomSheet(job);
  }

  void _showJobBottomSheet(Job job) {
    _jobService.incrementViewCount(job.id);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    bool isSaved = false;
    bool savedLoaded = false;
    bool isApplyLoading = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          if (!savedLoaded && uid.isNotEmpty) {
            savedLoaded = true;
            _jobService.isJobSaved(uid, job.id).then((saved) {
              setSheetState(() => isSaved = saved);
            });
          }
          return DraggableScrollableSheet(
            initialChildSize: 0.78,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Drag handle
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 8),
                    child: Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: job.imageUrl.isNotEmpty
                              ? Image.network(
                                  job.imageUrl,
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.contain,
                                  errorBuilder: (ctx, e, st) =>
                                      _sheetImageFallback(),
                                )
                              : _sheetImageFallback(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                job.employer,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    job.postedAgo,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  StreamBuilder<int>(
                                    stream: _jobService.streamViewCount(job.id),
                                    initialData: job.viewCount,
                                    builder: (context, snapshot) => Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.visibility_outlined,
                                          size: 12,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          _fmtViews(snapshot.data ?? 0),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),

                                  if (job.state == 'active') ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.verified,
                                            size: 12,
                                            color: Color(0xFF2E7D32),
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Verified',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF2E7D32),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () => shareJob(job),
                                    child: Icon(
                                      Icons.share_outlined,
                                      size: 16,
                                      color: Colors.grey.shade400,
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

                  Divider(height: 1, color: Colors.grey.shade200),

                  // Scrollable body
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          _infoTableRow('Category', job.category),
                          _infoTableRow('Job type', job.type),
                          _infoTableRow('Salary', job.formattedSalary),
                          _infoTableRow('Education required', job.education),
                          _infoTableRow('Experience required', job.experience),
                          if (job.location.isNotEmpty)
                            _infoTableRow(
                              'Location',
                              job.location,
                              isLast: true,
                            ),
                          const SizedBox(height: 20),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'About the role',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              job.description,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.65,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
                  ),

                  // Footer
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            _footerIconBtn(
                              icon: isSaved
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              label: 'Save',
                              color: isSaved
                                  ? AppColors.primary
                                  : Colors.black54,
                              onTap: () async {
                                final next = !isSaved;
                                setSheetState(() => isSaved = next);
                                if (next) {
                                  await _jobService.saveJob(uid, job.id);
                                } else {
                                  await _jobService.unsaveJob(uid, job.id);
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            _footerIconBtn(
                              icon: Icons.phone_outlined,
                              label: 'Call',
                              color: Colors.black54,
                              onTap: () => _showCallDialog(job),
                            ),
                            const SizedBox(width: 8),
                            _footerIconBtn(
                              icon: Icons.message_outlined,
                              label: 'Message',
                              color: Colors.black54,
                              onTap: () => _showMessageDialog(context, job),
                            ),
                            const SizedBox(width: 8),
                            _footerIconBtn(
                              icon: Icons.directions_outlined,
                              label: 'Directions',
                              color: Colors.black54,
                              onTap: () => _openDirections(job),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Builder(
                          builder: (sheetCtx) {
                            final uid =
                                FirebaseAuth.instance.currentUser?.uid ?? '';
                            final isOwnJob =
                                uid.isNotEmpty && job.postedBy == uid;
                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isOwnJob || isApplyLoading
                                    ? null
                                    : () async {
                                        setSheetState(
                                          () => isApplyLoading = true,
                                        );
                                        await _showApplyDialog(sheetCtx, job);
                                        try {
                                          setSheetState(
                                            () => isApplyLoading = false,
                                          );
                                        } catch (_) {}
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: isApplyLoading
                                      ? AppColors.primary
                                      : Colors.grey.shade300,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: isApplyLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        isOwnJob
                                            ? 'Your Job Listing'
                                            : 'Apply Now',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _infoTableRow(String label, String value, {bool isLast = false}) =>
      Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 175,
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Colors.black54,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!isLast)
            Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
        ],
      );

  Future<void> _showCallDialog(Job job) async {
    if (job.phone.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: const Text(
          'Call Employer',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              job.employer,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.phone_outlined, size: 15, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  job.phone,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
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
                    'Cancel',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Call',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await launchUrl(Uri.parse('tel:${job.phone}'));
    }
  }

  Future<void> _showMessageDialog(BuildContext sheetCtx, Job job) async {
    final hasWhatsApp = job.whatsApp.isNotEmpty;
    await showDialog<void>(
      context: sheetCtx,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: const Text(
          'Contact Employer',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // In-App Chat
            ListTile(
              onTap: () {
                Navigator.pop(ctx);
                _showApplyDialog(sheetCtx, job);
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              title: const Text(
                'In-App Chat',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Message through NearWork',
                style: TextStyle(fontSize: 12),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                size: 18,
                color: Colors.black45,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            const Divider(height: 1),
            // WhatsApp
            ListTile(
              onTap: hasWhatsApp
                  ? () async {
                      Navigator.pop(ctx);
                      final cleaned = job.whatsApp.replaceAll(
                        RegExp(r'\D'),
                        '',
                      );
                      final intl = cleaned.startsWith('0')
                          ? '94${cleaned.substring(1)}'
                          : cleaned;
                      await launchUrl(
                        Uri.parse('https://wa.me/$intl'),
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: hasWhatsApp
                      ? const Color(0xFFE8F5E9)
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chat_outlined,
                  color: hasWhatsApp
                      ? const Color(0xFF25D366)
                      : Colors.grey.shade400,
                  size: 18,
                ),
              ),
              title: Text(
                'WhatsApp',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: hasWhatsApp
                      ? AppColors.textPrimary
                      : Colors.grey.shade400,
                ),
              ),
              subtitle: Text(
                hasWhatsApp
                    ? 'Open in WhatsApp'
                    : 'Employer has not provided a WhatsApp number',
                style: TextStyle(
                  fontSize: 12,
                  color: hasWhatsApp ? Colors.black54 : Colors.grey.shade400,
                ),
              ),
              trailing: hasWhatsApp
                  ? const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: Colors.black45,
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showApplyDialog(BuildContext sheetCtx, Job job) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final userName =
        FirebaseAuth.instance.currentUser?.displayName ?? 'Anonymous';

    // Pre-fetch: check for an existing application and load saved resumes.
    // Errors are surfaced as a SnackBar so the user always gets feedback.
    String? existingId;
    List<ResumeItem> resumes = const [];
    try {
      existingId = await _inboxService.existingConversationId(uid, job.id);
      if (!mounted || !sheetCtx.mounted) return;

      if (existingId != null) {
        _showAlreadyAppliedDialog(sheetCtx, job, existingId, uid);
        return;
      }

      resumes = await context.read<ProfileProvider>().resumesStream(uid).first;
      if (!mounted || !sheetCtx.mounted) return;
    } catch (e) {
      if (mounted) {
        final sm = ScaffoldMessenger.of(context);
        sm.clearSnackBars();
        final entry = sm.showSnackBar(
          const SnackBar(
            content: Text('Could not load application form. Please try again.'),
            backgroundColor: Colors.redAccent,
            duration: Duration(days: 1),
          ),
        );
        Future.delayed(const Duration(seconds: 3), () {
          try {
            entry.close();
          } catch (_) {}
        });
      }
      return;
    }

    final coverCtrl = TextEditingController();
    // Pre-select default resume if one exists
    ResumeItem? selectedResume;
    for (final r in resumes) {
      if (r.isDefault) {
        selectedResume = r;
        break;
      }
    }
    String? pendingConvId;

    await showDialog<void>(
      context: sheetCtx,
      barrierDismissible: false,
      builder: (dlgCtx) {
        bool isSubmitting = false;
        String? localError;

        return StatefulBuilder(
          builder: (_, setDlgState) => AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Apply for ${job.title}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${job.employer} · ${job.type}',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (localError != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        localError!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    'Cover note',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: coverCtrl,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _applyInputDecoration(
                      'Briefly introduce yourself… (optional)',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Resume',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (resumes.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.upload_file_outlined,
                            size: 18,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'No resumes added yet. Upload one in Profile.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...resumes.map((r) {
                      final isSelected = selectedResume?.id == r.id;
                      return GestureDetector(
                        onTap: () => setDlgState(
                          () => selectedResume = isSelected ? null : r,
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.06)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.grey.shade200,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.picture_as_pdf_rounded,
                                  size: 18,
                                  color: Colors.red.shade400,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.fileName,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${r.fileSize} · ${r.updatedLabel}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (r.isDefault)
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Default',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 6),
                              Icon(
                                isSelected
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                size: 20,
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.grey.shade300,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isSubmitting
                          ? null
                          : () => Navigator.pop(dlgCtx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setDlgState(() {
                                isSubmitting = true;
                                localError = null;
                              });
                              final convId = await context
                                  .read<InboxProvider>()
                                  .applyForJob(
                                    job: job,
                                    applicantId: uid,
                                    applicantName: userName,
                                    coverNote: coverCtrl.text.trim(),
                                    resumeUrl: selectedResume?.fileUrl ?? '',
                                    resumeName: selectedResume?.fileName ?? '',
                                    jobImageUrl: job.imageUrl,
                                    matchScore: selectedResume == null
                                        ? ResumeMatchService.notScored
                                        : ResumeMatchService.score(
                                            job,
                                            selectedResume!.resumeText,
                                          ),
                                  );
                              if (convId != null) {
                                pendingConvId = convId;
                                if (dlgCtx.mounted) {
                                  Navigator.pop(dlgCtx);
                                }
                              } else {
                                setDlgState(() {
                                  isSubmitting = false;
                                  localError =
                                      context
                                          .read<InboxProvider>()
                                          .applyError ??
                                      'Failed to send. Try again.';
                                });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Send Application',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    // Delay dispose until the dialog dismiss animation has fully completed
    // (~150 ms). Disposing immediately while the route is still animating
    // out causes a "TextEditingController used after dispose" assertion
    // because the TextField's AnimatedState still holds a listener reference.
    Future.delayed(const Duration(milliseconds: 400), coverCtrl.dispose);

    final convId = pendingConvId;
    if (convId != null && mounted) {
      if (sheetCtx.mounted) Navigator.pop(sheetCtx);
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      final entry = messenger.showSnackBar(
        SnackBar(
          content: Text('Application sent to ${job.employer}!'),
          backgroundColor: AppColors.primary,
          duration: const Duration(days: 1),
          action: SnackBarAction(
            label: 'View Chat',
            textColor: Colors.white,
            onPressed: () async {
              final nav = Navigator.of(context);
              final conv = await _inboxService.getConversation(convId);
              if (conv != null) {
                nav.push(
                  MaterialPageRoute(
                    builder: (_) =>
                        ChatScreen(conversation: conv, currentUserId: uid),
                  ),
                );
              }
            },
          ),
        ),
      );
      Future.delayed(const Duration(seconds: 3), () {
        try {
          entry.close();
        } catch (_) {}
      });
    }
  }

  void _showAlreadyAppliedDialog(
    BuildContext sheetCtx,
    Job job,
    String convId,
    String uid,
  ) {
    showDialog<void>(
      context: sheetCtx,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        title: const Text(
          'Already Applied',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'You\'ve already applied for ${job.title} at ${job.employer}.',
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(dlgCtx),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Dismiss'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final nav = Navigator.of(context);
                    Navigator.pop(dlgCtx);
                    if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                    final conv = await _inboxService.getConversation(convId);
                    if (conv != null) {
                      nav.push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            conversation: conv,
                            currentUserId: uid,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('View Chat'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _applyInputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(fontSize: 13.5, color: Colors.grey.shade400),
    filled: true,
    fillColor: const Color(0xFFF8F9FB),
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
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  );

  Widget _sheetImageFallback() => Container(
    width: 72,
    height: 72,
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(
      Icons.business_center_outlined,
      size: 30,
      color: Colors.grey.shade400,
    ),
  );

  Widget _footerIconBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  _SuggestionTile - highlights the matched portion in the label
// ─────────────────────────────────────────────────────────────────────────────
class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({
    required this.label,
    required this.query,
    required this.count,
    required this.onTap,
  });

  final String label;
  final String query;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Build a RichText that bolds the matched segment
    final lowerLabel = label.toLowerCase();
    final matchStart = lowerLabel.indexOf(query);
    final List<TextSpan> spans = [];

    if (matchStart == -1 || query.isEmpty) {
      spans.add(
        TextSpan(
          text: label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w400,
          ),
        ),
      );
    } else {
      final matchEnd = matchStart + query.length;
      if (matchStart > 0) {
        spans.add(
          TextSpan(
            text: label.substring(0, matchStart),
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: label.substring(matchStart, matchEnd),
          style: TextStyle(
            fontSize: 14,
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      if (matchEnd < label.length) {
        spans.add(
          TextSpan(
            text: label.substring(matchEnd),
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        );
      }
    }

    return InkWell(
      onTap: onTap,
      splashColor: AppColors.primary.withValues(alpha: 0.06),
      highlightColor: AppColors.primary.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.work_outline_rounded,
              size: 16,
              color: Colors.grey.shade400,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(text: TextSpan(children: spans)),
            ),
            // ── Result count ─────────────────────────────────────────────
            if (count > 0)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black45,
                  ),
                ),
              ),
            // ── Arrow icon ───────────────────────────────────────────────
            Icon(
              Icons.north_west_rounded,
              size: 14,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
