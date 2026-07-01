class CloudinaryConfig {
  CloudinaryConfig._();

  static const String cloudName = 'djdmwk2nq';
  static const String uploadPreset = 'ml_default';

  static String get uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/auto/upload';
}
