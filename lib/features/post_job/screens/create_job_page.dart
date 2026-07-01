import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:nearwork/core/constants/app_colors.dart';
import 'package:nearwork/features/auth/providers/auth_provider.dart';
import 'package:nearwork/features/post_job/models/job.dart';
import 'package:nearwork/features/post_job/providers/post_job_provider.dart';

class CreateJobPage extends StatefulWidget {
  const CreateJobPage({super.key});

  @override
  State<CreateJobPage> createState() => _CreateJobPageState();
}

class _CreateJobPageState extends State<CreateJobPage> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _employerCtrl = TextEditingController();
  final _salaryMinCtrl = TextEditingController();
  final _salaryMaxCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  String _category = 'IT & Technology';
  String _type = 'Full Time';
  String _education = 'No Requirement';
  String _experience = 'No Experience';
  bool _negotiable = false;

  LatLng? _selectedLocation;
  Set<Marker> _markers = {};

  static const _categories = [
    'IT & Technology',
    'Construction',
    'Driving & Logistics',
    'Retail & Sales',
    'Healthcare',
    'Education',
    'Hospitality',
    'Finance',
  ];

  static const _educationLevels = [
    'No Requirement',
    'Ordinary Level',
    'Advanced Level',
    'Diploma',
    'NVQ Level 3',
    'NVQ Level 4',
    'Degree',
  ];

  static const _experienceLevels = [
    'No Experience',
    '0 years',
    '1 – 2 Years',
    '2+ years',
    '3+ Years',
    '5+ Years',
  ];

  static const _sriLankaCenter = LatLng(7.8731, 80.7718);

  @override
  void dispose() {
    _titleCtrl.dispose();
    _employerCtrl.dispose();
    _salaryMinCtrl.dispose();
    _salaryMaxCtrl.dispose();
    _descriptionCtrl.dispose();
    _locationCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _selectedLocation = position;
      _markers = {
        Marker(
          markerId: const MarkerId('selected'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      };
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please tap on the map to set job location')),
      );
      return;
    }

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final job = Job(
      id: '',
      title: _titleCtrl.text.trim(),
      employer: _employerCtrl.text.trim(),
      category: _category,
      type: _type,
      location: _locationCtrl.text.trim(),
      salaryMin: double.tryParse(_salaryMinCtrl.text) ?? 0,
      salaryMax: double.tryParse(_salaryMaxCtrl.text) ?? 0,
      negotiable: _negotiable,
      education: _education,
      experience: _experience,
      description: _descriptionCtrl.text.trim(),
      latitude: _selectedLocation!.latitude,
      longitude: _selectedLocation!.longitude,
      phone: _phoneCtrl.text.trim(),
      postedBy: user.uid,
      state: 'pending',
      createdAt: DateTime.now(),
    );

    final success = await context.read<PostJobProvider>().createJob(job);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job submitted for review!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PostJobProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text(
          'Post a Job',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTextField(_titleCtrl, 'Job Title', required: true),
            const SizedBox(height: 14),
            _buildTextField(_employerCtrl, 'Company / Employer', required: true),
            const SizedBox(height: 14),

            // Category
            _buildDropdown('Category', _category, _categories, (v) {
              setState(() => _category = v!);
            }),
            const SizedBox(height: 14),

            // Job Type toggle
            _sectionLabel('Job Type'),
            const SizedBox(height: 6),
            Row(
              children: ['Full Time', 'Part Time'].map((t) {
                final selected = _type == t;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: t == 'Full Time' ? 8 : 0, left: t == 'Part Time' ? 8 : 0),
                    child: GestureDetector(
                      onTap: () => setState(() => _type = t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected ? AppColors.primary : Colors.grey.shade300,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            t,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: selected ? Colors.white : Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Salary
            Row(
              children: [
                Expanded(child: _buildTextField(_salaryMinCtrl, 'Salary Min (LKR)', required: true, keyboard: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField(_salaryMaxCtrl, 'Salary Max (LKR)', required: true, keyboard: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _negotiable,
                    onChanged: (v) => setState(() => _negotiable = v!),
                    activeColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text('Negotiable', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 14),

            // Education & Experience
            _buildDropdown('Education', _education, _educationLevels, (v) {
              setState(() => _education = v!);
            }),
            const SizedBox(height: 14),
            _buildDropdown('Experience', _experience, _experienceLevels, (v) {
              setState(() => _experience = v!);
            }),
            const SizedBox(height: 14),

            // Description
            _buildTextField(_descriptionCtrl, 'Job Description', required: true, maxLines: 5),
            const SizedBox(height: 14),

            // Phone
            _buildTextField(_phoneCtrl, 'Contact Phone', keyboard: TextInputType.phone),
            const SizedBox(height: 14),

            // Location text
            _buildTextField(_locationCtrl, 'Location Name (e.g. Colombo 07)', required: true),
            const SizedBox(height: 14),

            // Map picker
            _sectionLabel('Tap on map to set job location'),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 200,
                child: GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: _sriLankaCenter,
                    zoom: 7.5,
                  ),
                  onTap: _onMapTap,
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: false,
                  minMaxZoomPreference: const MinMaxZoomPreference(7, 18),
                  cameraTargetBounds: CameraTargetBounds(
                    LatLngBounds(
                      southwest: const LatLng(5.919, 79.695),
                      northeast: const LatLng(9.835, 81.879),
                    ),
                  ),
                ),
              ),
            ),
            if (_selectedLocation != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ),
            const SizedBox(height: 24),

            // Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: provider.isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: provider.isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Submit for Review',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Colors.grey.shade600,
    ),
  );

  Widget _buildTextField(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboard,
      inputFormatters: keyboard == TextInputType.number
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      validator: required
          ? (v) => v == null || v.trim().isEmpty ? 'Required' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 14, color: Colors.grey.shade500),
        filled: true,
        fillColor: Colors.white,
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
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 14, color: Colors.grey.shade500),
        filled: true,
        fillColor: Colors.white,
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
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
