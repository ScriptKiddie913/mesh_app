import 'package:flutter/material.dart';

class MeshTheme {
  // Colors
  static const bg0      = Color(0xFF050A0F); // deepest bg
  static const bg1      = Color(0xFF0A1520); // card bg
  static const bg2      = Color(0xFF0F1E30); // elevated
  static const accent   = Color(0xFF00E5FF); // primary cyan
  static const accentR  = Color(0xFFFF2D2D); // critical red
  static const accentY  = Color(0xFFFFBB00); // warning amber
  static const accentG  = Color(0xFF00FF88); // success green
  static const textPri  = Color(0xFFE8F4FF);
  static const textSec  = Color(0xFF5A7A9A);
  static const textDim  = Color(0xFF2A4A6A);
  static const border   = Color(0xFF1A3A5A);
  static const borderHi = Color(0xFF00E5FF);

  // Typography
  static const String fontMono  = 'JetBrainsMono'; 
  static const String fontSans  = 'ShareTechMono'; 

  // Spacing grid (4px base)
  static const double s1 = 4, s2 = 8, s3 = 12, s4 = 16,
                      s5 = 20, s6 = 24, s8 = 32, s10 = 40;

  // Border widths
  static const double borderThin = 0.5;
  static const double borderNorm = 1.0;
  static const double borderThick = 2.0;

  static const Color grid       = Color(0x0A00E5FF); // very faint cyan grid
  static const Color scanline   = Color(0x05FFFFFF); // very faint scanline

  // ZERO rounded corners — everything is square
  static const BorderRadius sharp = BorderRadius.zero;
  static const double radius = 0;

  static const BoxConstraints tacticalConstraints = BoxConstraints(maxWidth: 600);
}
