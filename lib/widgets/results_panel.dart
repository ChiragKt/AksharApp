import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../app_theme.dart';
import '../models/recognition_state.dart';

class ResultsPanel extends StatelessWidget {
  final List<RecognitionResult> results;
  final RecognitionStatus status;
  final String? errorMessage;
  final bool isDigitMode;

  const ResultsPanel({
    super.key,
    required this.results,
    required this.status,
    required this.errorMessage,
    required this.isDigitMode,
  });

  @override
  Widget build(BuildContext context) {
    if (status == RecognitionStatus.error) return _ErrorCard(message: errorMessage ?? 'Unknown error');
    if (results.isEmpty) return const SizedBox.shrink();

    final top = results.first;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard, // flat matte — was cardGradient
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderGold, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderGold, width: 0.5)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Row(
              children: [
                Text('✦', style: TextStyle(color: AppTheme.gold.withValues(alpha: 0.7), fontSize: 10)),
                const SizedBox(width: 8),
                const Text(
                  'RESULT',
                  style: TextStyle(fontFamily: 'Tiro', fontSize: 10, color: AppTheme.textSub, letterSpacing: 2),
                ),
                const Spacer(),
                Text(
                  '${results.length} candidate${results.length > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 10, color: AppTheme.textSub),
                ),
              ],
            ),
          ),

          // ── Top result ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    top.label,
                    style: const TextStyle(
                      fontFamily: 'Tiro',
                      fontSize: 40,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.cream,
                      letterSpacing: 3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                      .animate()
                      .fadeIn()
                      .scale(begin: const Offset(0.85, 0.85), curve: Curves.elasticOut, duration: 600.ms),
                ),
                const SizedBox(width: 12),
                _ConfidenceBadge(confidence: top.confidence),
              ],
            ),
          ),

          // ── Other candidates ───────────────────────────────────────
          if (results.length > 1) const Divider(height: 1, color: AppTheme.borderGold),
          if (results.length > 1)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: results.length - 1,
                itemBuilder: (context, i) {
                  final r = results[i + 1];
                  return _CandidateTile(result: r, index: i + 1)
                      .animate(delay: Duration(milliseconds: 60 * i))
                      .fadeIn()
                      .slideX(begin: 0.1);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final double confidence;
  const _ConfidenceBadge({required this.confidence});

  Color get _color {
    if (confidence > 0.8) return AppTheme.teal;
    if (confidence > 0.5) return AppTheme.gold;
    return AppTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${(confidence * 100).toStringAsFixed(0)}%',
          style: TextStyle(fontFamily: 'Tiro', fontSize: 24, fontWeight: FontWeight.w700, color: _color),
        ),
        const Text(
          'Confidence',
          style: TextStyle(fontFamily: 'Tiro', fontSize: 10, color: AppTheme.textSub, letterSpacing: 0.5),
        ),
      ],
    );
  }
}

class _CandidateTile extends StatelessWidget {
  final RecognitionResult result;
  final int index;
  const _CandidateTile({required this.result, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: AppTheme.bgSurface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.borderGold),
            ),
            child: Center(
              child: Text('$index', style: const TextStyle(fontFamily: 'Tiro', fontSize: 10, color: AppTheme.textSub)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(result.label,
                style: const TextStyle(fontFamily: 'Tiro', fontSize: 15, color: AppTheme.cream),
                overflow: TextOverflow.ellipsis),
          ),
          Text(
            '${(result.confidence * 100).toStringAsFixed(0)}%',
            style: const TextStyle(fontFamily: 'Tiro', fontSize: 11, color: AppTheme.textSub),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontFamily: 'Tiro', color: AppTheme.error.withValues(alpha: 0.9), fontSize: 13),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().shake(hz: 2, offset: const Offset(4, 0));
  }
}
