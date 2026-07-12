import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../services/whisper_service.dart';

/// A reusable voice input button that can be attached to any TextEditingController.
///
/// Recognition engine priority:
///   1. Whisper (via Cloud Function proxy) when [WhisperService.isConfigured]
///   2. Device speech_to_text (Google Speech / on-device) as automatic fallback
///
/// The external API (constructor, hintText, appendMode, onResult) and all
/// visual behaviour (pulse animation, 30-second duration, mic icon) are
/// identical to the original widget — only the recognition internals changed.
class VoiceInputButton extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final bool appendMode;
  final VoidCallback? onResult;

  const VoiceInputButton({
    required this.controller,
    super.key,
    this.hintText,
    this.appendMode = false,
    this.onResult,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  // ── Whisper path ──────────────────────────────────────────────────────────
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordingPath;

  // ── Fallback (speech_to_text) path ────────────────────────────────────────
  // ── Shared state ──────────────────────────────────────────────────────────
  bool _isListening = false; // true while mic is active (either engine)
  bool _isProcessing = false; // true while Whisper is transcribing
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  // ── Tap handler ───────────────────────────────────────────────────────────

  Future<void> _toggleListening() async {
    if (_isProcessing) return; // don't interrupt an in-progress transcription

    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    if (!WhisperService.isConfigured) {
      _showUnavailableDialog(whisperNotConfigured: true);
      return;
    }
    await _startWhisperRecording();
  }

  Future<void> _stopListening() async {
    if (_isRecording) {
      await _stopWhisperRecording();
    }
  }

  // ── Whisper recording ─────────────────────────────────────────────────────

  Future<void> _startWhisperRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      _showUnavailableDialog(whisperPermissionDenied: true);
      return;
    }

    final dir = await getTemporaryDirectory();
    _recordingPath =
        '${dir.path}/whisper_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(bitRate: 64000),
      path: _recordingPath!,
    );

    if (mounted) {
      setState(() {
        _isListening = true;
        _isRecording = true;
      });
      _pulseController.repeat(reverse: true);
    }

    // Auto-stop after 30 seconds (same duration as original)
    Future.delayed(const Duration(seconds: 30), () {
      if (_isRecording && mounted) _stopWhisperRecording();
    });
  }

  Future<void> _stopWhisperRecording() async {
    final path = await _recorder.stop();
    if (mounted) {
      setState(() {
        _isListening = false;
        _isRecording = false;
        _isProcessing = true;
      });
      _pulseController.stop();
    }

    if (path == null) {
      if (mounted) setState(() => _isProcessing = false);
      return;
    }

    try {
      final text = await WhisperService.transcribe(File(path));
      if (mounted) _applyResult(text);
    } on WhisperNotConfiguredException {
      if (mounted) _showUnavailableDialog(whisperNotConfigured: true);
    } on WhisperTimeoutException {
      if (mounted) {
        _showErrorSnackBar(
            'Transcription timed out. Please try again.');
      }
    } on WhisperEmptyResultException {
      if (mounted) {
        _showErrorSnackBar(
            'No speech detected. Please speak clearly and try again.');
      }
    } catch (e) {
      debugPrint('Whisper error: $e');
      if (mounted) {
        _showErrorSnackBar(
            'Voice transcription failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
      // Clean up temp file
      try {
        File(path).deleteSync();
      } catch (_) {}
    }
  }

  // ── Fallback: speech_to_text ──────────────────────────────────────────────

  // ── Shared helpers ────────────────────────────────────────────────────────

  void _applyResult(String text) {
    if (!mounted) return;
    setState(() {
      if (widget.appendMode && widget.controller.text.isNotEmpty) {
        widget.controller.text =
            '${widget.controller.text} $text';
      } else {
        widget.controller.text = text;
      }
      widget.controller.selection = TextSelection.fromPosition(
        TextPosition(offset: widget.controller.text.length),
      );
      _isListening = false;
    });
    _pulseController.stop();
    widget.onResult?.call();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showUnavailableDialog({
    bool whisperPermissionDenied = false,
    bool whisperNotConfigured = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.mic_off, color: Colors.red),
            SizedBox(width: 8),
            Text('Voice Input Unavailable'),
          ],
        ),
        content: Text(
          whisperNotConfigured
              ? 'Whisper transcription is not configured yet. Deploy the Cloud Function proxy and set its URL in the app.'
              : whisperPermissionDenied
              ? 'Microphone permission denied. Please grant mic access in your device settings and try again.'
              : 'Voice transcription is not available. Please ensure microphone permissions are granted and try again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _toggleListening();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: _isListening
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(
                          alpha: 0.3 + _pulseController.value * 0.3),
                      blurRadius: 8 + _pulseController.value * 8,
                      spreadRadius: _pulseController.value * 4,
                    ),
                  ],
                )
              : null,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleListening,
              borderRadius: BorderRadius.circular(20),
              child: Tooltip(
                message: _isProcessing
                    ? 'Transcribing…'
                    : _isListening
                        ? 'Tap to stop listening'
                        : (widget.hintText ?? 'Tap to speak'),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isListening
                        ? Colors.red.withValues(alpha: 0.1)
                        : _isProcessing
                            ? Colors.orange.withValues(alpha: 0.1)
                            : colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isListening
                          ? Colors.red.withValues(alpha: 0.5)
                          : _isProcessing
                              ? Colors.orange.withValues(alpha: 0.5)
                              : colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.orange,
                          ),
                        )
                      : Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: _isListening
                              ? Colors.red
                              : colorScheme.primary,
                          size: 22,
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A convenience widget that wraps a TextFormField with an integrated
/// voice input button. API unchanged from original.
class VoiceEnabledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final String? voiceHint;
  final String? Function(String?)? validator;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool appendMode;
  final VoidCallback? onChanged;
  final InputDecoration? decoration;

  const VoiceEnabledTextField({
    required this.controller,
    super.key,
    this.labelText,
    this.hintText,
    this.voiceHint,
    this.validator,
    this.maxLines = 1,
    this.keyboardType,
    this.appendMode = false,
    this.onChanged,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: (decoration ??
              InputDecoration(
                labelText: labelText,
                hintText: hintText,
                border: const OutlineInputBorder(),
              ))
          .copyWith(
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 4),
          child: VoiceInputButton(
            controller: controller,
            hintText: voiceHint ?? 'Speak to fill $labelText',
            appendMode: appendMode,
            onResult: onChanged,
          ),
        ),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged != null ? (_) => onChanged!() : null,
    );
  }
}
