import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Routes audio files to a Whisper transcription endpoint.
///
/// The OpenAI API key is NEVER stored client-side.
/// Audio is sent to a Cloud Function proxy that holds the key server-side.
///
/// ─── SETUP REQUIRED ────────────────────────────────────────────────────────
/// 1. Deploy the Cloud Function in functions/index.js (see whisperTranscribe).
/// 2. Replace [_proxyUrl] below with your deployed function URL.
///    Format: https://<region>-<project>.cloudfunctions.net/whisperTranscribe
///
/// While the proxy URL is a placeholder the widget falls back to the
/// device speech_to_text engine automatically (see VoiceInputButton).
/// ───────────────────────────────────────────────────────────────────────────
class WhisperService {
  // TODO: Replace with your deployed Cloud Function URL after running
  //       `firebase deploy --only functions`
  static const String _proxyUrl =
      'WHISPER_PROXY_URL_PLACEHOLDER';

  static bool get isConfigured =>
      _proxyUrl != 'WHISPER_PROXY_URL_PLACEHOLDER' &&
      _proxyUrl.startsWith('https://');

  /// Transcribes [audioFile] via the Whisper proxy.
  /// Returns the transcribed text, or throws on failure.
  static Future<String> transcribe(File audioFile) async {
    if (!isConfigured) {
      throw const WhisperNotConfiguredException();
    }

    final request = http.MultipartRequest('POST', Uri.parse(_proxyUrl));
    request.files.add(
      await http.MultipartFile.fromPath('audio', audioFile.path),
    );

    final streamed = await request.send().timeout(
      const Duration(seconds: 60),
      onTimeout: () => throw const WhisperTimeoutException(),
    );

    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode == 200) {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final text = (json['text'] as String?)?.trim() ?? '';
      if (text.isEmpty) throw const WhisperEmptyResultException();
      return text;
    } else {
      debugPrint('Whisper proxy error ${streamed.statusCode}: $body');
      throw WhisperApiException(streamed.statusCode, body);
    }
  }
}

// ── Typed exceptions ──────────────────────────────────────────────────────

class WhisperNotConfiguredException implements Exception {
  const WhisperNotConfiguredException();
  @override
  String toString() => 'Whisper proxy URL not configured.';
}

class WhisperTimeoutException implements Exception {
  const WhisperTimeoutException();
  @override
  String toString() => 'Whisper transcription timed out.';
}

class WhisperEmptyResultException implements Exception {
  const WhisperEmptyResultException();
  @override
  String toString() => 'Whisper returned an empty transcription.';
}

class WhisperApiException implements Exception {
  final int statusCode;
  final String body;
  const WhisperApiException(this.statusCode, this.body);
  @override
  String toString() => 'Whisper API error $statusCode: $body';
}
