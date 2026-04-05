import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../models/recognition_state.dart';
import '../services/recognition_service.dart';
import '../widgets/results_panel.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  String? _capturedPath;

  Future<void> _capture(BuildContext context) async {
    final state = context.read<RecognitionState>();
    state.setProcessing();
    final path = await RecognitionService.instance.captureFromCamera();
    if (path == null) { state.setError('Capture cancelled.'); return; }
    setState(() => _capturedPath = path);
    try {
      final results = await RecognitionService.instance.recognizeFromImage(imagePath: path, isDigitMode: state.isDigitMode);
      if (results.isEmpty) state.setError('कुछ नहीं मिला — Nothing found. Try again.');
      else state.setResults(results);
    } catch (e) { state.setError('Error: $e'); }
  }

  void _reset(RecognitionState state) { setState(() => _capturedPath = null); state.clearAll(); }

  @override
  Widget build(BuildContext context) {
    return Consumer<RecognitionState>(
      builder: (context, state, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: AppTheme.cardGradient,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderGold),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _capturedPath != null
                        ? Stack(fit: StackFit.expand, children: [
                            Image.file(File(_capturedPath!), fit: BoxFit.cover),
                            if (state.status == RecognitionStatus.processing)
                              Container(color: AppTheme.bgDark.withValues(alpha: 0.7),
                                  child: Center(child: CircularProgressIndicator(color: AppTheme.teal, strokeWidth: 2))),
                          ])
                        : _Placeholder(icon: Icons.camera_alt_rounded, line1: 'कैमरा खोलें', line2: 'Point camera at text or digits'),
                  ),
                ).animate().fadeIn().scale(begin: const Offset(0.97, 0.97)),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  if (_capturedPath != null) ...[
                    _OutlineBtn(icon: Icons.refresh_rounded, label: 'दोबारा', onTap: () => _reset(state)),
                    const SizedBox(width: 12),
                  ],
                  Expanded(child: _GoldBtn(
                    icon: Icons.camera_alt_rounded,
                    label: _capturedPath == null ? 'कैमरा  ·  Open Camera' : 'फिर खींचें  ·  Retake',
                    isLoading: state.status == RecognitionStatus.processing,
                    onTap: () => _capture(context),
                  )),
                ],
              ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2),
              const SizedBox(height: 14),
              if (state.hasResults || state.status == RecognitionStatus.error)
                Expanded(flex: 2,
                  child: ResultsPanel(results: state.results, status: state.status, errorMessage: state.errorMessage, isDigitMode: state.isDigitMode)
                      .animate().fadeIn().slideY(begin: 0.3)),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _Placeholder extends StatelessWidget {
  final IconData icon;
  final String line1, line2;
  const _Placeholder({required this.icon, required this.line1, required this.line2});

  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 52, color: AppTheme.gold.withValues(alpha: 0.25)),
    const SizedBox(height: 12),
    Text(line1, style: const TextStyle(fontFamily: 'Tiro', color: AppTheme.textSub, fontSize: 15)),
    const SizedBox(height: 4),
    Text(line2, style: TextStyle(fontSize: 11, color: AppTheme.textSub.withValues(alpha: 0.5))),
  ]));
}

class _OutlineBtn extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _OutlineBtn({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: Container(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.borderGold)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: AppTheme.textSub),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontFamily: 'Tiro', color: AppTheme.textSub, fontWeight: FontWeight.w600)),
      ])));
}

class _GoldBtn extends StatelessWidget {
  final IconData icon; final String label; final bool isLoading; final VoidCallback onTap;
  const _GoldBtn({required this.icon, required this.label, required this.isLoading, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: isLoading ? null : onTap,
    child: Container(padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(gradient: AppTheme.goldGradient, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppTheme.gold.withValues(alpha: 0.3), blurRadius: 18, offset: const Offset(0, 6))]),
      child: Center(child: isLoading
          ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.bgDark))
          : Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 17, color: AppTheme.bgDark),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontFamily: 'Tiro', fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.bgDark)),
            ]))));
}
