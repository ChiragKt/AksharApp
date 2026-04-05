import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../models/recognition_state.dart';
import '../services/recognition_service.dart';
import '../widgets/results_panel.dart';

class ImageScreen extends StatefulWidget {
  const ImageScreen({super.key});
  @override
  State<ImageScreen> createState() => _ImageScreenState();
}

class _ImageScreenState extends State<ImageScreen> {
  String? _imagePath;

  Future<void> _pickImage(BuildContext context) async {
    final path = await RecognitionService.instance.pickImageFromGallery();
    if (path == null) return;
    setState(() => _imagePath = path);
    final state = context.read<RecognitionState>();
    state.setProcessing();
    try {
      final results = await RecognitionService.instance.recognizeFromImage(imagePath: path, isDigitMode: state.isDigitMode);
      if (results.isEmpty) state.setError('चित्र में कुछ नहीं मिला — Nothing found in image.');
      else state.setResults(results);
    } catch (e) { state.setError('Error: $e'); }
  }

  void _reset(RecognitionState state) { setState(() => _imagePath = null); state.clearAll(); }

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
                child: GestureDetector(
                  onTap: _imagePath == null ? () => _pickImage(context) : null,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: AppTheme.cardGradient,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _imagePath == null ? AppTheme.teal.withValues(alpha: 0.4) : AppTheme.borderGold,
                        width: _imagePath == null ? 1.5 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: _imagePath != null
                          ? Stack(fit: StackFit.expand, children: [
                              Image.file(File(_imagePath!), fit: BoxFit.contain),
                              if (state.status == RecognitionStatus.processing)
                                Container(color: AppTheme.bgDark.withValues(alpha: 0.7),
                                    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                                      CircularProgressIndicator(color: AppTheme.teal, strokeWidth: 2),
                                      const SizedBox(height: 12),
                                      const Text('स्कैन हो रहा है…', style: TextStyle(fontFamily: 'Tiro', fontSize: 13, color: AppTheme.teal, letterSpacing: 1)),
                                    ]))),
                            ])
                          : _ImagePlaceholder(),
                    ),
                  ),
                ).animate().fadeIn().scale(begin: const Offset(0.97, 0.97)),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  if (_imagePath != null) ...[
                    _OutlineBtn(icon: Icons.delete_outline_rounded, label: 'हटाएं', onTap: () => _reset(state)),
                    const SizedBox(width: 12),
                  ],
                  Expanded(child: _GoldBtn(
                    icon: Icons.photo_library_rounded,
                    label: _imagePath == null ? 'चित्र चुनें  ·  Choose Image' : 'बदलें  ·  Change',
                    isLoading: state.status == RecognitionStatus.processing,
                    onTap: () => _pickImage(context),
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

class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 72, height: 72,
      decoration: BoxDecoration(shape: BoxShape.circle,
        border: Border.all(color: AppTheme.teal.withValues(alpha: 0.35), width: 1.5)),
      child: Icon(Icons.add_photo_alternate_outlined, size: 34, color: AppTheme.teal.withValues(alpha: 0.5))),
    const SizedBox(height: 14),
    const Text('चित्र चुनें', style: TextStyle(fontFamily: 'Tiro', color: AppTheme.textSub, fontSize: 15)),
    const SizedBox(height: 4),
    Text('Tap to select an image', style: TextStyle(fontSize: 11, color: AppTheme.textSub.withValues(alpha: 0.5))),
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
