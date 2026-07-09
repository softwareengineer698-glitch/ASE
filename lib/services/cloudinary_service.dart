import 'dart:io';

import 'package:cloudinary_public/cloudinary_public.dart';

import '../config/cloudinary_config.dart';

class CloudinaryUploadResult {
  final String secureUrl;
  final String publicId;

  const CloudinaryUploadResult({
    required this.secureUrl,
    required this.publicId,
  });
}

class CloudinaryService {
  CloudinaryService()
      : _client = CloudinaryPublic(
          CloudinaryConfig.cloudName,
          CloudinaryConfig.uploadPreset,
        );

  final CloudinaryPublic _client;

  Future<CloudinaryUploadResult> uploadDonationImage({
    required File file,
    required String donationId,
    required int index,
  }) async {
    if (CloudinaryConfig.cloudName.startsWith('YOUR_') ||
        CloudinaryConfig.uploadPreset.startsWith('YOUR_')) {
      throw Exception(
        'Cloudinary unsigned upload is not configured. Set cloudName and uploadPreset.',
      );
    }

    final response = await _client.uploadFile(
      CloudinaryFile.fromFile(
        file.path,
        resourceType: CloudinaryResourceType.Image,
        folder: 'donations/$donationId',
        publicId: 'image_$index',
      ),
    );

    return CloudinaryUploadResult(
      secureUrl: response.secureUrl,
      publicId: response.publicId,
    );
  }
}
