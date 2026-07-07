import 'package:flutter/material.dart';

void main() {
  runApp(const TrolleyApp());
}

// ==========================================
// THE BRAND COLOR PALETTE CONFIGURATION
// ==========================================
class AppTheme {
  static const Color deepNavy = Color(0xFF0A2947);
  static const Color softCream = Color(0xFFF3E4C9);
  static const Color mutedSage = Color(0xFFD3D4C0);
  static const Color warmTerracotta = Color(0xFF8B5E3C);
  
  static const Color textDark = Color(0xFF1A2530);
  static const Color textMuted = Color(0xFF627282);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: softCream,
      colorScheme: const ColorScheme.light(
        primary: deepNavy,
        secondary: warmTerracotta,
        surface: softCream,
        outline: mutedSage,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: softCream,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: deepNavy, size: 22),
        titleTextStyle: TextStyle(
          color: deepNavy,
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: deepNavy, fontWeight: FontWeight.w800, fontSize: 32, letterSpacing: -0.5),
        titleMedium: TextStyle(color: textDark, fontWeight: FontWeight.w700, fontSize: 18),
        bodyLarge: TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.w500),
        bodyMedium: TextStyle(color: textMuted, fontSize: 14),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: mutedSage, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: mutedSage, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: deepNavy, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14, fontWeight: FontWeight.w400),
      ),
// Look for this block around line 66 in your lib/main.dart
      cardTheme: CardThemeData(
        color: Colors.white.withOpacity(0.6),
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: mutedSage, width: 0.5),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) return warmTerracotta;
          return Colors.white.withOpacity(0.8);
        }),
        side: const BorderSide(color: mutedSage, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}

// ==========================================
// APPLICATION ENTRY WIDGETS
// ==========================================
class TrolleyApp extends StatelessWidget {
  const TrolleyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trolley',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const InitialWorkspacePage(),
    );
  }
}

class InitialWorkspacePage extends StatelessWidget {
  const InitialWorkspacePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. Give the AppBar a solid Deep Navy background
      appBar: AppBar(
        backgroundColor: AppTheme.deepNavy,
        title: const Text(
          'Trolley', 
          style: TextStyle(color: AppTheme.softCream, fontWeight: FontWeight.w900)
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppTheme.softCream),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 2. Premium Hero Banner header card using your Deep Navy
          Container(
            width: double.infinity,
            color: AppTheme.deepNavy,
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 32, top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Shopping Engine',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: AppTheme.softCream, // Cream text on Navy background
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Optimized aisle routing for Sri Lankan supermarkets.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mutedSage, // Sage subtext on Navy background
                  ),
                ),
              ],
            ),
          ),
          
          // 3. Main content body area (Soft Cream background)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Try adding "Parippu 1kg or Anchor powder"...',
                      prefixIcon: Icon(Icons.add_shopping_cart_rounded, color: AppTheme.deepNavy),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    'Active Shopping List', 
                    style: TextStyle(color: AppTheme.deepNavy, fontWeight: FontWeight.bold, fontSize: 16)
                  ),
                  const SizedBox(height: 8),

                  Card(
                    child: ListTile(
                      leading: Checkbox(value: true, onChanged: (val) {}),
                      title: const Text('Keeri Samba Rice'),
                      subtitle: const Text('Grains & Staples'),
                      trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}