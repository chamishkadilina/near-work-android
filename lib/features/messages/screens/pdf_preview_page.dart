import 'package:flutter/material.dart';
import 'package:nearwork/core/constants/app_colors.dart';
import 'package:nearwork/features/profile/services/cloudinary_config.dart';

class PdfPreviewPage extends StatelessWidget {
  final String url;
  final String fileName;

  const PdfPreviewPage({super.key, required this.url, required this.fileName});

  // Extract Cloudinary public_id from a secure_url.
  // Works for image/upload URLs only (raw/upload cannot be page-transformed).
  String? get _publicId {
    if (!url.contains('/image/upload/')) return null;
    final uri = Uri.parse(url);
    var remainder = uri.path.replaceFirst(RegExp(r'^/[^/]+/image/upload/'), '');
    remainder = remainder.replaceFirst(RegExp(r'^v\d+/'), '');
    final dot = remainder.lastIndexOf('.');
    return dot != -1 ? remainder.substring(0, dot) : remainder;
  }

  String _pageUrl(String publicId, int page) =>
      'https://res.cloudinary.com/${CloudinaryConfig.cloudName}'
      '/image/upload/pg_$page,w_1200,q_auto:best/$publicId.jpg';

  @override
  Widget build(BuildContext context) {
    final publicId = _publicId;

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Resume',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            Text(
              fileName,
              style: const TextStyle(fontSize: 11.5, color: Colors.white70),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: publicId == null
          ? _buildReuploadPrompt()
          : ListView.separated(
              padding: const EdgeInsets.all(8),
              // Render up to 10 pages; pages beyond the PDF's actual count
              // return an error and collapse to zero height.
              itemCount: 10,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (ctx, i) => _buildPage(publicId, i + 1),
            ),
    );
  }

  Widget _buildPage(String publicId, int page) {
    return Image.network(
      _pageUrl(publicId, page),
      fit: BoxFit.fitWidth,
      width: double.infinity,
      loadingBuilder: (ctx, child, progress) {
        if (progress == null) return child;
        return AspectRatio(
          aspectRatio: 1 / 1.414,
          child: Container(
            color: Colors.white,
            child: Center(
              child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                    : null,
                color: AppColors.primary,
              ),
            ),
          ),
        );
      },
      // Pages beyond the PDF page count return a Cloudinary error — hide them.
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildReuploadPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.picture_as_pdf_rounded,
              size: 56,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Preview unavailable',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Delete this resume from your profile and re-upload it to enable preview.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}
