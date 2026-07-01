import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:nearwork/features/profile/services/cloudinary_config.dart';

class CloudinaryUploadResult {
  final String secureUrl;
  final String publicId;

  const CloudinaryUploadResult({
    required this.secureUrl,
    required this.publicId,
  });
}

class CloudinaryService {
  Future<CloudinaryUploadResult> uploadFile({
    required File file,
    required String folder,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(CloudinaryConfig.uploadUrl),
    );

    request.fields['upload_preset'] = CloudinaryConfig.uploadPreset;
    request.fields['folder'] = folder;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('Upload failed: ${response.body}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    return CloudinaryUploadResult(
      secureUrl: data['secure_url'] as String,
      publicId: data['public_id'] as String,
    );
  }
}
