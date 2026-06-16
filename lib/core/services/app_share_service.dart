import 'package:share_plus/share_plus.dart';

class AppShareService {
  /// Shares the NearWork app with friends
  static Future<void> shareApp() async {
    try {
      final String shareText = _formatAppShareMessage();
      await SharePlus.instance.share(ShareParams(text: shareText));
    } catch (e) {
      rethrow;
    }
  }

  /// Formats the app share message
  static String _formatAppShareMessage() {
    final StringBuffer buffer = StringBuffer();

    // App Header
    buffer.writeln('💼 NearWork - Find Jobs Near You!');
    buffer.writeln();

    // Tagline
    buffer.writeln('Your next opportunity is just a tap away 🎯');
    buffer.writeln();

    // Key Features
    buffer.writeln('✨ Why Choose NearWork?');
    buffer.writeln('🗺️ Smart map-based job search');
    buffer.writeln('📍 Find jobs in your location');
    buffer.writeln('💰 Transparent salary information');
    buffer.writeln('⭐ Verified job listings');
    buffer.writeln('📱 Easy job application process');
    buffer.writeln('🔔 Real-time job notifications');
    buffer.writeln('💯 Completely FREE - No hidden charges!');
    buffer.writeln();

    // Social proof
    buffer.writeln('🌟 Join thousands of job seekers across Sri Lanka');
    buffer.writeln();

    // Call to action
    buffer.writeln('📲 Download NearWork now and start your job search:');
    buffer.writeln(
      'https://play.google.com/store/apps/details?id=com.nearwork.app',
    );
    buffer.writeln();
    buffer.writeln('Your dream job is waiting! 🚀');

    return buffer.toString();
  }
}
