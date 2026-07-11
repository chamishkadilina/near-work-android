import 'dart:io';

import 'package:syncfusion_flutter_pdf/pdf.dart';

// Extracts plain text from a resume PDF entirely on-device, right before the
// file is uploaded to Cloudinary. Cloudinary's raw PDF delivery is blocked on
// this account (see PdfPreviewPage), so the original bytes can never be
// re-fetched later — this is the only point where the text is readable.
class ResumeTextExtractor {
  // Firestore documents cap out at ~1MB; no resume needs anywhere near this,
  // it's just a safety ceiling.
  static const _maxChars = 20000;

  static Future<String> extractText(File pdfFile) async {
    PdfDocument? document;
    try {
      final bytes = await pdfFile.readAsBytes();
      document = PdfDocument(inputBytes: bytes);
      final text = PdfTextExtractor(document).extractText();
      final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
      return normalized.length > _maxChars
          ? normalized.substring(0, _maxChars)
          : normalized;
    } catch (_) {
      // Scanned/image-only PDFs or a corrupt file yield no text layer —
      // callers treat an empty string as "not enough data to score".
      return '';
    } finally {
      document?.dispose();
    }
  }
}
