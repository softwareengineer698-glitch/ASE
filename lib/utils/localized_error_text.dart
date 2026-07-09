import 'package:easy_localization/easy_localization.dart';

String localizedErrorText(String? message, String fallbackKey) {
  final value = message?.trim();
  if (value == null || value.isEmpty) return fallbackKey.tr();

  final looksLikeTranslationKey = RegExp(r'^[a-z0-9_]+$').hasMatch(value);
  return looksLikeTranslationKey ? value.tr() : value;
}
