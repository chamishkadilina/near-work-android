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

  static String _formatAppShareMessage() {
    return 'Hey! Check out NearWork - it finds jobs near your location on a map. '
        'You can filter by salary, apply with your CV, call or chat with employers, '
        'and even get directions to the workplace. You can post jobs too.\n'
        '\n'
        'It\'s free and made for Sri Lanka.\n'
        '\n'
        'https://play.google.com/store/apps/details?id=com.chamishkadilina.nearwork';
  }
}
