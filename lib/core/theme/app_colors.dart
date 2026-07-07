import 'package:flutter/material.dart';

/// Brand palette drawn from the Anthropic Arena crest:
/// a white shield with a double gold chevron on near-black.
abstract final class AppColors {
  // Core brand
  static const ink = Color(0xFF0A0C10);
  static const surfaceDark = Color(0xFF13161D);
  static const surfaceDarkRaised = Color(0xFF1B2029);
  static const strokeDark = Color(0xFF262C38);
  static const gold = Color(0xFFF5A623);
  static const goldBright = Color(0xFFFFC14D);
  static const goldDeep = Color(0xFF8C6D1F);
  static const cream = Color(0xFFF7F5F2);

  // Light mode
  static const backgroundLight = Color(0xFFF4F5F7);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const strokeLight = Color(0xFFE3E6EC);
  static const inkText = Color(0xFF12141A);

  // Feedback
  static const success = Color(0xFF3DC97C);
  static const danger = Color(0xFFEF5D60);
  static const info = Color(0xFF4FC3F7);

  // Leaderboard metals
  static const silver = Color(0xFFB9C0CC);
  static const bronze = Color(0xFFCD8A4B);
}
