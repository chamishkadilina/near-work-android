import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nearwork/core/constants/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  ExploreFilterSheet
//  Call: _showFilterSheet(context) from the filter icon in the search bar.
// ─────────────────────────────────────────────────────────────────────────────

void showFilterSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.35),
    builder: (_) => const _FilterSheetContent(),
  );
}

// ── Current user location (dummy – Sri Lanka, Negombo area) ──────────────────
const _kUserLocation = LatLng(7.2083, 79.8358);

class _FilterSheetContent extends StatefulWidget {
  const _FilterSheetContent();

  @override
  State<_FilterSheetContent> createState() => _FilterSheetContentState();
}

class _FilterSheetContentState extends State<_FilterSheetContent> {
  // ── State ──────────────────────────────────────────────────────────────────

  // Job type
  final Set<String> _selectedJobTypes = {'Full Time'};

  // Salary
  RangeValues _salary = const RangeValues(20000, 100000);

  // Distance (km)
  double _distance = 10;

  // Job category
  String? _selectedCategory;

  // Experience
  String? _selectedExperience;

  GoogleMapController? _mapController;

  // ── Statics ────────────────────────────────────────────────────────────────
  static const _jobTypes = ['Full Time', 'Part Time'];

  static const _categories = [
    ('IT & Technology', Icons.computer_rounded),
    ('Construction', Icons.construction_rounded),
    ('Driving & Logistics', Icons.local_shipping_rounded),
    ('Retail & Sales', Icons.storefront_rounded),
    ('Healthcare', Icons.health_and_safety_rounded),
    ('Education', Icons.school_rounded),
    ('Hospitality', Icons.hotel_rounded),
    ('Finance', Icons.account_balance_rounded),
    ('Other', Icons.more_horiz_rounded),
  ];

  static const _experiences = [
    ('No Experience', Icons.emoji_people_rounded),
    ('1 – 2 Years', Icons.trending_up_rounded),
    ('3+ Years', Icons.workspace_premium_rounded),
  ];

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _formatSalary(double v) {
    if (v >= 1000) return 'Rs ${(v / 1000).toStringAsFixed(0)}k';
    return 'Rs ${v.toStringAsFixed(0)}';
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return Container(
      // Sheet clips to rounded top corners
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // Occupy up to 92 % of screen height
      constraints: BoxConstraints(maxHeight: mq.size.height * 0.92),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildHeader(context),
          const Divider(height: 1, thickness: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: mq.viewInsets.bottom + 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionGap(),
                  _buildJobType(),
                  _sectionDivider(),
                  _buildSalaryRange(),
                  _sectionDivider(),
                  _buildDistance(),
                  _sectionDivider(),
                  _buildJobCategory(),
                  _sectionDivider(),
                  _buildExperienceLevel(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          _buildApplyButton(context),
        ],
      ),
    );
  }

  // ── Drag handle ─────────────────────────────────────────────────────────────
  Widget _buildHandle() => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 6),
    child: Center(
      child: Container(
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    ),
  );

  // ── Header row ──────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 2, 8, 12),
    child: Row(
      children: [
        const Text(
          'Filters',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const Spacer(),
        // Reset button
        TextButton(
          onPressed: _resetFilters,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Reset all',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.close, size: 22, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ],
    ),
  );

  // ── Section label ────────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
        letterSpacing: 0.1,
      ),
    ),
  );

  Widget _sectionGap() => const SizedBox(height: 20);
  Widget _sectionDivider() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
  );

  // ── 1. Job Type ─────────────────────────────────────────────────────────────
  Widget _buildJobType() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionLabel('Job Type'),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: _jobTypes.map((type) {
            final selected = _selectedJobTypes.contains(type);
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: type == _jobTypes.last ? 0 : 12,
                ),
                child: GestureDetector(
                  onTap: () => setState(() {
                    if (selected) {
                      if (_selectedJobTypes.length > 1) {
                        _selectedJobTypes.remove(type);
                      }
                    } else {
                      _selectedJobTypes.add(type);
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : Colors.grey.shade300,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          type == 'Full Time'
                              ? Icons.access_time_filled_rounded
                              : Icons.timelapse_rounded,
                          size: 16,
                          color: selected ? Colors.white : Colors.black45,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          type,
                          style: TextStyle(
                            fontSize: 13.5,
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

  // ── 2. Salary Range ─────────────────────────────────────────────────────────
  Widget _buildSalaryRange() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionLabel('Salary Range (per month)'),
      // Value bubble row
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _salaryBubble(_formatSalary(_salary.start), isStart: true),
            Container(height: 1, width: 24, color: Colors.grey.shade300),
            _salaryBubble(_formatSalary(_salary.end), isStart: false),
          ],
        ),
      ),
      const SizedBox(height: 10),
      SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: AppColors.primary,
          inactiveTrackColor: Colors.grey.shade200,
          thumbColor: Colors.white,
          thumbShape: const RoundSliderThumbShape(
            enabledThumbRadius: 10,
            elevation: 4,
          ),
          overlayColor: AppColors.primary.withOpacity(0.12),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
          trackHeight: 4,
          rangeThumbShape: const RoundRangeSliderThumbShape(
            enabledThumbRadius: 10,
            elevation: 4,
          ),
          rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
        ),
        child: RangeSlider(
          values: _salary,
          min: 0,
          max: 300000,
          divisions: 60,
          onChanged: (v) => setState(() => _salary = v),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Rs 0', style: _axisStyle),
            Text('Rs 300k', style: _axisStyle),
          ],
        ),
      ),
    ],
  );

  Widget _salaryBubble(String text, {required bool isStart}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.primary.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
    ),
  );

  TextStyle get _axisStyle =>
      const TextStyle(fontSize: 11, color: Colors.black38);

  // ── 3. Distance ─────────────────────────────────────────────────────────────
  Widget _buildDistance() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionLabel('Distance'),
      // Mini map
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: _kUserLocation,
                    zoom: 11.5,
                  ),
                  onMapCreated: (c) => _mapController = c,
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
                      center: _kUserLocation,
                      radius: _distance * 1000,
                      fillColor: AppColors.primary.withOpacity(0.12),
                      strokeColor: AppColors.primary.withOpacity(0.55),
                      strokeWidth: 2,
                    ),
                  },
                ),
                // Gradient overlay at edges for polish
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 1.0,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.04),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Distance label badge
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.radio_button_checked,
                          size: 12,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_distance.toStringAsFixed(0)} km',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 14),
      // Distance slider
      SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: AppColors.primary,
          inactiveTrackColor: Colors.grey.shade200,
          thumbColor: Colors.white,
          thumbShape: const RoundSliderThumbShape(
            enabledThumbRadius: 10,
            elevation: 4,
          ),
          overlayColor: AppColors.primary.withOpacity(0.12),
          trackHeight: 4,
        ),
        child: Slider(
          value: _distance,
          min: 1,
          max: 100,
          divisions: 99,
          onChanged: (v) => setState(() => _distance = v),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('1 km', style: _axisStyle),
            Text(
              '${_distance.toStringAsFixed(0)} km radius',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            Text('100 km', style: _axisStyle),
          ],
        ),
      ),
    ],
  );

  // ── 4. Job Category ──────────────────────────────────────────────────────────
  Widget _buildJobCategory() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionLabel('Job Category'),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((c) {
            final label = c.$1;
            final icon = c.$2;
            final selected = _selectedCategory == label;
            return GestureDetector(
              onTap: () =>
                  setState(() => _selectedCategory = selected ? null : label),
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

  // ── 5. Experience Level ──────────────────────────────────────────────────────
  Widget _buildExperienceLevel() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionLabel('Experience Level'),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: _experiences.map((e) {
            final label = e.$1;
            final icon = e.$2;
            final selected = _selectedExperience == label;
            return GestureDetector(
              onTap: () =>
                  setState(() => _selectedExperience = selected ? null : label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withOpacity(0.06)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? AppColors.primary : Colors.grey.shade200,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withOpacity(0.12)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        size: 18,
                        color: selected ? AppColors.primary : Colors.black45,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: selected ? AppColors.primary : Colors.black87,
                        ),
                      ),
                    ),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: selected ? 1 : 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.white,
                        ),
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

  // ── Apply button ─────────────────────────────────────────────────────────────
  Widget _buildApplyButton(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, mq.padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Apply Filters',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  // ── Reset ─────────────────────────────────────────────────────────────────────
  void _resetFilters() {
    setState(() {
      _selectedJobTypes
        ..clear()
        ..add('Full Time');
      _salary = const RangeValues(20000, 100000);
      _distance = 10;
      _selectedCategory = null;
      _selectedExperience = null;
    });
  }
}
