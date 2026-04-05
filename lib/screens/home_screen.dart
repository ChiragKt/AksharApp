import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../models/recognition_state.dart';
import '../widgets/mode_selector.dart';
import '../widgets/type_toggle.dart';
import 'draw_screen.dart';
import 'camera_screen.dart';
import 'image_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  Widget _buildActiveScreen(RecognitionMode mode) {
    switch (mode) {
      case RecognitionMode.draw:   return const DrawScreen();
      case RecognitionMode.camera: return const CameraScreen();
      case RecognitionMode.image:  return const ImageScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RecognitionState>(
      builder: (context, state, _) {
        return Scaffold(
          backgroundColor: AppTheme.bgDark,
          body: Stack(
            children: [
              // ── Decorative background ──────────────────────────────
              const _TraditionalBackground(),

              SafeArea(
                child: Column(
                  children: [
                    // Header
                    const _AksharHeader(),

                    // Divider with ornament
                    const _OrnamentalDivider(),

                    const SizedBox(height: 12),

                    // Type toggle
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: TypeToggle(),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.2),

                    const SizedBox(height: 12),

                    // Mode selector
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ModeSelector(selected: state.mode, onSelect: state.setMode),
                    ).animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: 12),

                    // Active screen
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(anim),
                            child: child,
                          ),
                        ),
                        child: KeyedSubtree(
                          key: ValueKey(state.mode),
                          child: _buildActiveScreen(state.mode),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Akshar Header ─────────────────────────────────────────────────────────────

class _AksharHeader extends StatelessWidget {
  const _AksharHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          // Logo — flat matte medallion (was gradient)
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.teal,
              border: Border.all(color: AppTheme.gold.withValues(alpha: 0.5), width: 1.5),
            ),
            child: const Center(
              child: Text(
                'A',
                style: TextStyle(
                  fontFamily: 'Tiro',
                  fontSize: 24,
                  color: AppTheme.bgDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ).animate().scale(delay: 100.ms, curve: Curves.elasticOut, duration: 800.ms),

          const SizedBox(width: 14),

          // Title block
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Akshar',
                style: TextStyle(
                  fontFamily: 'Tiro',
                  fontSize: 26,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.cream,
                  letterSpacing: 3,
                ),
              ),
              Text(
                'Script Recognition',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.gold.withValues(alpha: 0.8),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 150.ms).slideX(begin: -0.1),

          const Spacer(),

          // Live badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.teal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.teal.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppTheme.teal, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                const Text('LIVE', style: TextStyle(fontFamily: 'Tiro', fontSize: 10, color: AppTheme.teal, letterSpacing: 1.2)),
              ],
            ),
          ).animate().fadeIn(delay: 250.ms),
        ],
      ),
    );
  }
}

// ── Ornamental Divider ────────────────────────────────────────────────────────

class _OrnamentalDivider extends StatelessWidget {
  const _OrnamentalDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: Container(height: 0.5, color: AppTheme.borderGold)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text('✦', style: TextStyle(color: AppTheme.gold.withValues(alpha: 0.7), fontSize: 12)),
          ),
          Expanded(child: Container(height: 0.5, color: AppTheme.borderGold)),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }
}

// ── Traditional Background — flat matte, no gradient shaders ─────────────────

class _TraditionalBackground extends StatelessWidget {
  const _TraditionalBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PatternPainter(),
      child: Container(),
    );
  }
}

class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Subtle dot grid — rangoli motif (matte, no gradient)
    final dotPaint = Paint()..color = AppTheme.gold.withValues(alpha: 0.06);
    const spacing = 32.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, dotPaint);
      }
    }

    // Subtle flat tint at top — teal
    final tealPaint = Paint()..color = AppTheme.teal.withValues(alpha: 0.04);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.3), tealPaint);

    // Subtle flat tint at bottom — gold
    final goldPaint = Paint()..color = AppTheme.gold.withValues(alpha: 0.03);
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.7, size.width, size.height * 0.3), goldPaint);
  }

  @override
  bool shouldRepaint(_PatternPainter old) => false;
}
