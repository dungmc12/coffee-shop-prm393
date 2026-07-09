import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AppTheme - định nghĩa toàn bộ màu sắc & kiểu chữ cho app.
/// Gom về một chỗ để dễ chỉnh và giúp giao diện đồng bộ, đẹp.
/// - Font: Be Vietnam Pro (Google Fonts - hỗ trợ tiếng Việt).
/// - Icon: bộ Iconsax (package iconsax_flutter, nguồn iconsax.io).
class AppTheme {
  // ----- Bảng màu chủ đạo (tông cà phê) -----
  static const Color primary = Color(0xFF6F4E37); // Nâu cà phê
  static const Color primaryDark = Color(0xFF3E2B1F); // Nâu đậm (gradient)
  static const Color accent = Color(0xFFD9A066); // Vàng caramel
  static const Color background = Color(0xFFF9F5F0); // Kem nhạt
  static const Color card = Colors.white;
  static const Color textDark = Color(0xFF2E2420);
  static const Color textGrey = Color(0xFF9C8F86);
  static const Color success = Color(0xFF4CAF50);
  static const Color danger = Color(0xFFE05D5D);

  /// Gradient nâu cà phê dùng cho header, banner, nút nổi bật.
  static const LinearGradient coffeeGradient = LinearGradient(
    colors: [primaryDark, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Bóng đổ nhẹ dùng chung cho các thẻ (card) tự vẽ.
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: primaryDark.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  /// ThemeData dùng chung cho MaterialApp.
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      // Áp font Be Vietnam Pro cho toàn bộ chữ trong app.
      textTheme: GoogleFonts.beVietnamProTextTheme(base.textTheme).apply(
        bodyColor: textDark,
        displayColor: textDark,
      ),
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        secondary: accent,
        surface: card,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.beVietnamPro(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textDark,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.beVietnamPro(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: GoogleFonts.beVietnamPro(color: textGrey, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEFE6DC)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEFE6DC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 1.6),
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
