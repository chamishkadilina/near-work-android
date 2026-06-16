import 'package:flutter/material.dart';
import 'package:nearwork/core/constants/app_colors.dart';

// ── Dummy job model ────────────────────────────────────────────────────────────
class JobModel {
  final String id;
  final String title;
  final String employer;
  final String category;
  final String type; // Full Time / Part Time / Contract
  final String location;
  final String salaryMin;
  final String salaryMax;
  final bool negotiable;
  final String education;
  final String experience;
  final String description;
  final String postedAgo;
  final String state; // 'active' | 'pending' | 'closed'
  final int viewCount;

  const JobModel({
    required this.id,
    required this.title,
    required this.employer,
    required this.category,
    required this.type,
    required this.location,
    required this.salaryMin,
    required this.salaryMax,
    this.negotiable = false,
    required this.education,
    required this.experience,
    required this.description,
    required this.postedAgo,
    this.state = 'active',
    this.viewCount = 0,
  });
}

// ── Dummy data ─────────────────────────────────────────────────────────────────
final List<JobModel> dummyActiveJobs = [
  JobModel(
    id: 'j1',
    title: 'Senior Flutter Developer',
    employer: 'TechCore Solutions',
    category: 'IT & Technology',
    type: 'Full Time',
    location: 'Colombo',
    salaryMin: '150,000',
    salaryMax: '200,000',
    education: 'Degree',
    experience: '3 – 5 Years',
    description:
        'We are looking for an experienced Flutter developer to join our growing mobile team. You will work on consumer-facing apps used by thousands of Sri Lankans daily.\n\n'
        '• Build and maintain cross-platform mobile apps\n'
        '• Collaborate with UI/UX designers and backend engineers\n'
        '• Write clean, testable code with proper documentation\n'
        '• Participate in code reviews and architecture decisions',
    postedAgo: '2 days ago',
    state: 'active',
    viewCount: 312,
  ),
  JobModel(
    id: 'j2',
    title: 'Delivery Rider',
    employer: 'QuickMove Logistics',
    category: 'Driving & Logistics',
    type: 'Full Time',
    location: 'Gampaha',
    salaryMin: '55,000',
    salaryMax: '75,000',
    negotiable: true,
    education: 'No Requirement',
    experience: 'No Experience',
    description:
        'Join our fast-growing logistics team as a delivery rider. Valid motorcycle licence required.\n\n'
        '• Daily parcel deliveries across Gampaha district\n'
        '• Fuel allowance and OT pay provided\n'
        '• Flexible shifts available',
    postedAgo: '5 days ago',
    state: 'active',
    viewCount: 87,
  ),
];

final List<JobModel> dummyPendingJobs = [
  JobModel(
    id: 'j3',
    title: 'Retail Store Assistant',
    employer: 'FashionHub Lanka',
    category: 'Retail & Sales',
    type: 'Full Time',
    location: 'Kandy',
    salaryMin: '45,000',
    salaryMax: '60,000',
    education: 'Ordinary Level',
    experience: 'No Experience',
    description:
        'We are expanding our Kandy outlet and need enthusiastic retail assistants.\n\n'
        '• Assist customers and maintain store displays\n'
        '• Handle POS transactions\n'
        '• Maintain stock and cleanliness',
    postedAgo: '1 day ago',
    state: 'pending',
    viewCount: 0,
  ),
];

final List<JobModel> dummyClosedJobs = [
  JobModel(
    id: 'j4',
    title: 'Hotel Receptionist',
    employer: 'Serenity Hotels & Resorts',
    category: 'Hospitality',
    type: 'Full Time',
    location: 'Negombo',
    salaryMin: '65,000',
    salaryMax: '85,000',
    education: 'Advanced Level',
    experience: '1 – 2 Years',
    description:
        'Looking for a professional and well-presented receptionist for our beachfront property.\n\n'
        '• Manage check-in / check-out and reservations\n'
        '• Respond to guest queries in English and Sinhala\n'
        '• Coordinate with housekeeping and F&B teams',
    postedAgo: '3 weeks ago',
    state: 'closed',
    viewCount: 541,
  ),
];

// ── View count helper ──────────────────────────────────────────────────────────
String _formatViewCount(int v) {
  if (v < 1000) return v.toString();
  if (v < 1000000) {
    return '${(v / 1000).toStringAsFixed(1).replaceAll('.0', '')}K';
  }
  return '${(v / 1000000).toStringAsFixed(1).replaceAll('.0', '')}M';
}

// ── JobCard widget ─────────────────────────────────────────────────────────────
class JobCard extends StatefulWidget {
  final JobModel job;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onViewOnMap;

  const JobCard({
    super.key,
    required this.job,
    this.onEdit,
    this.onDelete,
    this.onViewOnMap,
  });

  @override
  State<JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<JobCard> {
  bool _expanded = false;

  bool get _isGrayedOut => widget.job.state != 'active';

  Color get _primaryColor =>
      _isGrayedOut ? Colors.grey.shade500 : AppColors.primary;

  @override
  Widget build(BuildContext context) {
    final job = widget.job;

    return Stack(
      children: [
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company icon
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.business_rounded,
                        color: _primaryColor,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title + employer
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _isGrayedOut
                                  ? Colors.grey.shade600
                                  : Colors.black87,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            job.employer,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // View count
                    if (job.state == 'active')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.visibility,
                              size: 12,
                              color: AppColors.primary.withOpacity(0.8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatViewCount(job.viewCount),
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.primary.withOpacity(0.9),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Chips row ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _chip(Icons.access_time_rounded, job.type),
                    _chip(Icons.location_on_rounded, job.location),
                    _chip(Icons.category_rounded, job.category),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Salary + posted ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      job.negotiable
                          ? 'Rs. ${job.salaryMin} – ${job.salaryMax} (Negotiable)'
                          : 'Rs. ${job.salaryMin} – ${job.salaryMax}',
                      style: TextStyle(
                        color: _isGrayedOut
                            ? Colors.grey.shade500
                            : AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      job.postedAgo,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Show / Hide Details toggle ─────────────────────────────────
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Text(
                        _expanded ? 'Hide Details' : 'Show Details',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: _primaryColor,
                        ),
                      ),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: _primaryColor,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Expandable details ────────────────────────────────────────
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: _expanded
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey.shade100,
                    ),
                    const SizedBox(height: 12),
                    _detailRow('Education', job.education),
                    _detailRow('Experience', job.experience),
                    _detailRow('Job Type', job.type),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        job.description,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Colors.black87,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
                secondChild: const SizedBox(height: 12),
              ),

              // ── Divider ────────────────────────────────────────────────────
              Divider(height: 1, thickness: 1, color: Colors.grey.shade100),

              // ── Action buttons ────────────────────────────────────────────
              Row(
                children: [
                  _actionBtn(
                    icon: Icons.edit_outlined,
                    label: 'Edit',
                    color: _primaryColor,
                    onTap: widget.onEdit,
                  ),
                  _vDivider(),
                  _actionBtn(
                    icon: Icons.map_outlined,
                    label: 'View',
                    color: _primaryColor,
                    onTap: widget.onViewOnMap,
                  ),
                  _vDivider(),
                  _actionBtn(
                    icon: Icons.share_outlined,
                    label: 'Share',
                    color: _primaryColor,
                    onTap: () {},
                  ),
                  _vDivider(),
                  _actionBtn(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete',
                    color: Colors.grey.shade600,
                    onTap: widget.onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Gray overlay for non-active ───────────────────────────────────
        if (_isGrayedOut)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade500),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 40, color: Colors.grey.shade200);
}
