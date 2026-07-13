import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

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
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _available = false;
  bool _isListening = false;
  bool _disposed = false;
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      final ok = await _speech.initialize(
        onError: (e) {
          if (_disposed || !mounted) return;
          _safeSetState(() => _isListening = false);
          _safePulseStop();
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(
              content: Text('Voice error: ${e.errorMsg}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        },
        onStatus: (s) {
          if (_disposed || !mounted) return;
          if (s == 'done' || s == 'notListening') {
            _safeSetState(() => _isListening = false);
            _safePulseStop();
          }
        },
      );
      if (mounted && !_disposed) {
        setState(() => _available = ok);
      }
    } catch (_) {}
  }

  void _safeSetState(VoidCallback fn) {
    if (!_disposed && mounted) setState(fn);
  }

  void _safePulseStop() {
    if (!_disposed) _pulse.stop();
  }

  void _safePulseRepeat() {
    if (!_disposed) _pulse.repeat(reverse: true);
  }

  Future<void> _toggle() async {
    if (_disposed) return;

    if (!_available) {
      await _initSpeech();
      if (!_available) {
        if (!mounted || _disposed) return;
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text(
                'Microphone not available. Allow mic access in browser.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    if (_isListening) {
      await _speech.stop();
      _safeSetState(() => _isListening = false);
      _safePulseStop();
    } else {
      _safeSetState(() => _isListening = true);
      _safePulseRepeat();

      await _speech.listen(
        onResult: (result) {
          if (_disposed || !mounted) return;
          if (result.finalResult) {
            final text = result.recognizedWords.trim();
            if (text.isNotEmpty) {
              if (widget.appendMode && widget.controller.text.isNotEmpty) {
                widget.controller.text = '${widget.controller.text} $text';
              } else {
                widget.controller.text = text;
              }
              widget.controller.selection = TextSelection.fromPosition(
                TextPosition(offset: widget.controller.text.length),
              );
              widget.onResult?.call();
            }
            _safeSetState(() => _isListening = false);
            _safePulseStop();
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
        localeId: 'en_US',
        cancelOnError: false,
        partialResults: false,
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _pulse.dispose();
    // Don't call _speech.stop() here — it triggers onStatus which
    // would try to access disposed AnimationController
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) => GestureDetector(
        onTap: _toggle,
        child: Tooltip(
          message: _isListening
              ? 'Tap to stop'
              : (widget.hintText ?? 'Tap to speak'),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isListening
                  ? Colors.red.withValues(alpha: 0.12)
                  : cs.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isListening
                    ? Colors.red
                        .withValues(alpha: 0.4 + _pulse.value * 0.3)
                    : cs.primary.withValues(alpha: 0.25),
              ),
              boxShadow: _isListening
                  ? [
                      BoxShadow(
                        color: Colors.red.withValues(
                            alpha: 0.15 + _pulse.value * 0.2),
                        blurRadius: 8 + _pulse.value * 8,
                        spreadRadius: _pulse.value * 3,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              size: 22,
              color: _isListening ? Colors.red : cs.primary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Convenience wrapper: TextFormField + voice button as suffix icon.
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
