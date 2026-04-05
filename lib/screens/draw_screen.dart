import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../models/recognition_state.dart';
import '../services/recognition_service.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/results_panel.dart';

class DrawScreen extends StatefulWidget {
  const DrawScreen({super.key});
  @override
  State<DrawScreen> createState() => _DrawScreenState();
}

class _DrawScreenState extends State<DrawScreen> {
  final GlobalKey _canvasKey = GlobalKey();

  Future<void> _recognize(BuildContext context) async {
    final state = context.read<RecognitionState>();
    if (state.drawPoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('पहले लिखें — Draw something first!', style: TextStyle(fontFamily: 'Tiro')),
        backgroundColor: AppTheme.bgSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    state.setProcessing();
    try {
      final size = _canvasKey.currentContext?.size ?? const Size(300, 300);
      final results = await RecognitionService.instance.recognizeDrawn(
        points: state.drawPoints, isDigitMode: state.isDigitMode, canvasSize: size,
      );
      if (results.isEmpty) state.setError('पहचान नहीं हुई — Nothing recognized. Try again!');
      else state.setResults(results);
    } catch (e) {
      state.setError('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RecognitionState>(
      builder: (context, state, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // ── Canvas ──────────────────────────────────────────────
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: AppTheme.cardGradient,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: state.status == RecognitionStatus.processing
                          ? AppTheme.teal.withValues(alpha: 0.6) : AppTheme.borderGold,
                      width: state.status == RecognitionStatus.processing ? 1.5 : 1,
                    ),
                    boxShadow: state.status == RecognitionStatus.processing
                        ? [BoxShadow(color: AppTheme.teal.withValues(alpha: 0.12), blurRadius: 24, spreadRadius: 2)]
                        : [],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        Positioned.fill(child: DrawingCanvas(
                          key: _canvasKey,
                          points: state.drawPoints,
                          onPointAdded: (o, s) => state.addPoint(o, isStart: s),
                        )),
                        if (state.drawPoints.isEmpty)
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('✍', style: TextStyle(fontSize: 40, color: AppTheme.gold.withValues(alpha: 0.3))),
                                const SizedBox(height: 10),
                                Text(
                                  state.isDigitMode ? 'अंक लिखें\nDraw a digit' : 'अक्षर लिखें\nWrite text',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontFamily: 'Tiro', color: AppTheme.textSub.withValues(alpha: 0.5), fontSize: 14, height: 1.6),
                                ),
                              ],
                            ),
                          ),
                        if (state.status == RecognitionStatus.processing)
                          _ProcessingOverlay(),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 100.ms).scale(begin: const Offset(0.97, 0.97)),
              ),

              const SizedBox(height: 14),

              // ── Buttons ─────────────────────────────────────────────
              Row(
                children: [
                  _OutlineBtn(icon: Icons.refresh_rounded, label: 'मिटाएं', onTap: state.clearDrawing),
                  const SizedBox(width: 12),
                  Expanded(child: _PrimaryBtn(
                    isLoading: state.status == RecognitionStatus.processing,
                    onTap: () => _recognize(context),
                  )),
                ],
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

              const SizedBox(height: 14),

              if (state.hasResults || state.status == RecognitionStatus.error)
                Expanded(
                  flex: 2,
                  child: ResultsPanel(
                    results: state.results, status: state.status,
                    errorMessage: state.errorMessage, isDigitMode: state.isDigitMode,
                  ).animate().fadeIn().slideY(begin: 0.3),
                ),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _ProcessingOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.bgDark.withValues(alpha: 0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.teal)),
            const SizedBox(height: 14),
            const Text('विश्लेषण…', style: TextStyle(fontFamily: 'Tiro', fontSize: 14, color: AppTheme.teal, letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _OutlineBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.borderGold)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: AppTheme.textSub),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontFamily: 'Tiro', color: AppTheme.textSub, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

class _PrimaryBtn extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;
  const _PrimaryBtn({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: isLoading ? null : onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        gradient: isLoading ? null : AppTheme.goldGradient,
        color: isLoading ? AppTheme.bgSurface : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isLoading ? [] : [BoxShadow(color: AppTheme.gold.withValues(alpha: 0.3), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: Center(child: isLoading
          ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.teal))
          : const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.auto_awesome_rounded, size: 17, color: AppTheme.bgDark),
              SizedBox(width: 8),
              Text('पहचानें  ·  Recognize',
                  style: TextStyle(fontFamily: 'Tiro', fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.bgDark, letterSpacing: 0.5)),
            ])),
    ),
  );
}
