import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:nearwork/core/constants/app_colors.dart';
import 'package:nearwork/features/post_job/models/job.dart';
import 'package:nearwork/features/explore/providers/job_provider.dart';
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
  BitmapDescriptor? _customIcon;

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
  final Set<String> _selectedJobTypes = {'Full Time'};
  RangeValues _salary = const RangeValues(40000, 200000);
  double _distance = 5;
  String _selectedCategory = 'All';
  final Set<String> _selectedExperiences = {};

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
    _loadCustomIcon();
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

  Future<void> _loadCustomIcon() async {
    try {
      _customIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(32, 32)),
        'assets/icons/job_marker.png',
      );
    } catch (_) {
      _customIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueAzure,
      );
    }
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
    final filtered = _allJobKeywords
        .where((kw) => kw.toLowerCase().contains(query))
        .toList();
    setState(() {
      _suggestions = filtered;
      _showSuggestions = true;
    });
  }

  void _selectSuggestion(String suggestion) {
    _searchController.text = suggestion;
    // Move cursor to end
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    _searchFocus.unfocus();
    setState(() => _showSuggestions = false);
    // todo: trigger search/filter with selected suggestion
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _suggestions = [];
      _showSuggestions = false;
    });
  }

  // ─────────────────────────────────────────────────────────────────────────────
  Set<Marker> _buildMarkers(List<Job> jobs) {
    final icon =
        _customIcon ??
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);

    return jobs.map((job) {
      return Marker(
        markerId: MarkerId(job.id),
        position: LatLng(job.latitude, job.longitude),
        icon: icon,
        onTap: () => _showJobBottomSheet(job),
      );
    }).toSet();
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

  String _formatSalary(double v) {
    final formatted = v.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return 'LKR $formatted';
  }

  void _resetFilters() => setState(() {
    _selectedJobTypes
      ..clear()
      ..add('Full Time');
    _salary = const RangeValues(_salaryInitialStart, _salaryInitialEnd);
    _distance = 5;
    _selectedCategory = 'All';
    _selectedExperiences.clear();
  });

  bool get _hasActiveFilters {
    if (_selectedJobTypes.length != 1 ||
        !_selectedJobTypes.contains('Full Time'))
      return true;
    if (_salary.start != _salaryInitialStart ||
        _salary.end != _salaryInitialEnd)
      return true;
    if (_distance != 5) return true;
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
    final markers = _buildMarkers(jobProvider.jobs);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(onTap: _dismissAll, child: _buildMap(markers)),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _buildSearchAndFilter(),
            ),
            _buildLocationButton(),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  //  Search bar + suggestions + expanding filter panel
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildSearchAndFilter() {
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
              if (_showSuggestions) _buildSuggestionsPanel(),
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
          // Clear button — visible only when text exists
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
  Widget _buildSuggestionsPanel() {
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
          // Results list — max 5 visible, scrollable
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
                final query = _searchController.text.trim().toLowerCase();
                return _SuggestionTile(
                  label: item,
                  query: query,
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
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
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
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : Colors.grey.shade200,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          type == 'Full Time'
                              ? Icons.access_time_filled_rounded
                              : Icons.timelapse_rounded,
                          size: 15,
                          color: selected ? Colors.white : Colors.black45,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          type,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
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
  Widget _buildDistanceSection() => Column(
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
              initialCameraPosition: const CameraPosition(
                target: _userLocation,
                zoom: 11.5,
              ),
              onMapCreated: (c) => _filterMapController = c,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              mapToolbarEnabled: false,
              scrollGesturesEnabled: false,
              zoomGesturesEnabled: false,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              circles: {
                Circle(
                  circleId: const CircleId('range'),
                  center: _userLocation,
                  radius: _distance * 1000,
                  fillColor: AppColors.primary.withOpacity(0.12),
                  strokeColor: AppColors.primary.withOpacity(0.5),
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
          onChanged: (v) => setState(() => _distance = v),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('1 km', style: _axisStyle),
            Text(
              '${_distance.toStringAsFixed(0)} km radius',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            Text('25 km', style: _axisStyle),
          ],
        ),
      ),
    ],
  );

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
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected ? AppColors.primary : Colors.grey.shade200,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 13,
                      color: selected ? Colors.white : Colors.black45,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
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
  Widget _buildExperienceSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionLabel('Experience Level'),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
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
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 170),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : Colors.grey.shade400,
                          width: 1.5,
                        ),
                      ),
                      child: selected
                          ? const Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: selected ? AppColors.primary : Colors.black87,
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
              foregroundColor: Colors.black54,
              padding: const EdgeInsets.symmetric(vertical: 13),
              side: BorderSide(color: Colors.grey.shade300),
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
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: _closeFilter,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
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
    await _controller?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 17,
        ),
      ),
    );
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
    bool isSaved = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
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
                                color: Colors.black87,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              job.employer,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
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
                                if (job.state == 'active') ...[
                                  const Spacer(),
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
                          _infoTableRow('Location', job.location, isLast: true),
                        const SizedBox(height: 20),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'About the role',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
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
                            color: isSaved ? AppColors.primary : Colors.black54,
                            onTap: () =>
                                setSheetState(() => isSaved = !isSaved),
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
                            onTap: () => _showMessageDialog(job),
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
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Apply Now',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
                      color: Colors.black87,
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
            color: Color(0xFF1A1A2E),
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
                color: Colors.black87,
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
                    color: Colors.black87,
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

  Future<void> _showMessageDialog(Job job) async {
    final hasWhatsApp = job.whatsApp.isNotEmpty;
    await showDialog<void>(
      context: context,
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
            color: Color(0xFF1A1A2E),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // In-App Chat
            ListTile(
              onTap: () {
                Navigator.pop(ctx);
                // TODO: navigate to in-app chat
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
                  color: hasWhatsApp ? Colors.black87 : Colors.grey.shade400,
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
//  _SuggestionTile — highlights the matched portion in the label
// ─────────────────────────────────────────────────────────────────────────────
class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({
    required this.label,
    required this.query,
    required this.onTap,
  });

  final String label;
  final String query;
  final VoidCallback onTap;

  // Deterministic dummy count — stable across rebuilds, unique per keyword
  int get _dummyCount {
    const counts = [3, 5, 7, 8, 12, 14, 6, 9, 11, 4];
    return counts[label.length % counts.length];
  }

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
            color: Colors.black87,
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
            // ── Dummy result count ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                '$_dummyCount',
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
