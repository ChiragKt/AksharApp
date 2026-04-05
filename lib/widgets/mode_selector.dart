import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models/recognition_state.dart';

class ModeSelector extends StatelessWidget {
  final RecognitionMode selected;
  final void Function(RecognitionMode) onSelect;

  const ModeSelector({super.key, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ModeTab(mode: RecognitionMode.draw,   icon: Icons.draw_rounded,         label: 'Likhna', devanagari: 'लिखें', selected: selected, onSelect: onSelect),
        const SizedBox(width: 8),
        _ModeTab(mode: RecognitionMode.camera, icon: Icons.camera_alt_rounded,   label: 'Camera', devanagari: 'कैमरा', selected: selected, onSelect: onSelect),
        const SizedBox(width: 8),
        _ModeTab(mode: RecognitionMode.image,  icon: Icons.photo_library_rounded, label: 'Chitra', devanagari: 'चित्र', selected: selected, onSelect: onSelect),
      ],
    );
  }
}

class _ModeTab extends StatelessWidget {
  final RecognitionMode mode;
  final IconData icon;
  final String label;
  final String devanagari;
  final RecognitionMode selected;
  final void Function(RecognitionMode) onSelect;

  const _ModeTab({
    required this.mode, required this.icon, required this.label,
    required this.devanagari, required this.selected, required this.onSelect,
  });

  bool get isSelected => selected == mode;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.teal.withValues(alpha: 0.15) : AppTheme.bgSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppTheme.teal.withValues(alpha: 0.6) : AppTheme.borderGold,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: isSelected ? AppTheme.teal : AppTheme.textSub),
              const SizedBox(height: 3),
              Text(devanagari, style: TextStyle(fontFamily: 'Tiro', fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? AppTheme.teal : AppTheme.textSub)),
              Text(label, style: TextStyle(fontSize: 9, color: isSelected ? AppTheme.teal.withValues(alpha: 0.8) : AppTheme.textSub.withValues(alpha: 0.6), letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
