import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;
import 'package:mimu/data/services/dio_api_client.dart';

class SecureUploadResult {
  final String fileId;
  final String? blurhash;
  final Uint8List fileKey; // 32 bytes, ChaCha20-Poly1305 key (share via E2EE message)
  final Uint8List nonce; // 12 bytes
  final String? checksumSha256; // sha256 of encrypted bytes (hex)

  const SecureUploadResult({
    required this.fileId,
    required this.fileKey,
    required this.nonce,
    this.blurhash,
    this.checksumSha256,
  });
}

/// Secure media upload:
/// 1) Encrypt file locally (ChaCha20-Poly1305)
/// 2) POST /api/v1/files/presign
/// 3) PUT encrypted bytes to upload_url
/// 4) POST /api/v1/files/confirm
///
/// The `fileKey`+`nonce` must be sent to peer inside encrypted message payload.
class SecureMediaService {
  final Dio _dio = DioApiClient().dio;
  final Cipher _cipher = Chacha20.poly1305Aead();

  Future<SecureUploadResult> uploadEncryptedFile({
    required File file,
    required String fileType, // image | video | audio | voice | document
    required String contentType,
    String? filename,
    bool computeBlurhash = true,
  }) async {
    final plain = await file.readAsBytes();

    String? blur;
    int? width;
    int? height;
    if (computeBlurhash && fileType == 'image') {
      try {
        final decoded = img.decodeImage(plain);
        if (decoded != null) {
          width = decoded.width;
          height = decoded.height;
          // 4x3 is a good default for chat previews.
          blur = BlurHash.encode(decoded, numCompX: 4, numCompY: 3).hash;
        }
      } catch (_) {
        // ignore blurhash failures
      }
    }

    final key = await _cipher.newSecretKey();
    final keyBytes = Uint8List.fromList(await key.extractBytes());
    final nonce = Uint8List.fromList(_cipher.newNonce());

    final box = await _cipher.encrypt(
      plain,
      secretKey: key,
      nonce: nonce,
    );

    // We upload: nonce(12) || mac(16) || ciphertext
    final encrypted = BytesBuilder()
      ..add(box.nonce)
      ..add(box.mac.bytes)
      ..add(box.cipherText);
    final encryptedBytes = encrypted.toBytes();

    final presignResp = await _dio.post(
      '/api/v1/files/presign',
      data: {
        'size': encryptedBytes.length,
        'content_type': contentType,
        'filename': filename ?? file.uri.pathSegments.last,
        'file_type': fileType,
      },
    );

    final presign = presignResp.data as Map;
    final uploadUrl = presign['upload_url']?.toString() ?? '';
    final fileId = presign['file_id']?.toString() ?? '';
    if (uploadUrl.isEmpty || fileId.isEmpty) {
      throw StateError('Invalid presign response');
    }

    // Direct PUT to S3/MinIO (no Authorization header)
    await Dio().put(
      uploadUrl,
      data: Stream.fromIterable([encryptedBytes]),
      options: Options(
        headers: {
          'Content-Type': contentType,
          'Content-Length': encryptedBytes.length,
        },
      ),
    );

    // sha256 of encrypted bytes (hex)
    final sha = Sha256();
    final checksum = await sha.hash(encryptedBytes);
    final checksumHex = checksum.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    await _dio.post(
      '/api/v1/files/confirm',
      data: {
        'file_id': fileId,
        'actual_size': encryptedBytes.length,
        'checksum': checksumHex,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
      },
    );

    return SecureUploadResult(
      fileId: fileId,
      blurhash: blur,
      fileKey: keyBytes,
      nonce: nonce,
      checksumSha256: checksumHex,
    );
  }

  /// Helper to embed decryption info into message payload JSON.
  static Map<String, dynamic> buildFilePointerPayload({
    required String fileId,
    required Uint8List fileKey,
    required Uint8List nonce,
    String? blurhash,
    String? mime,
    int? size,
  }) {
    return {
      't': 'file',
      'file_id': fileId,
      'key': base64Encode(fileKey),
      'nonce': base64Encode(nonce),
      if (blurhash != null) 'blurhash': blurhash,
      if (mime != null) 'mime': mime,
      if (size != null) 'size': size,
    };
  }
}

