import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../models/recognition_state.dart';

class TypeToggle extends StatelessWidget {
  const TypeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RecognitionState>(
      builder: (context, state, _) {
        return Container(
          height: 50,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.bgSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderGold, width: 1),
          ),
          child: Stack(
            children: [
              // Sliding indicator
              AnimatedAlign(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOut,
                alignment: state.isDigitMode ? Alignment.centerLeft : Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.goldGradient,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: AppTheme.gold.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 3))],
                    ),
                  ),
                ),
              ),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => state.setRecognitionType(true),
                      child: Container(
                        color: Colors.transparent,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.tag_rounded, size: 16, color: state.isDigitMode ? AppTheme.bgDark : AppTheme.textSub),
                            const SizedBox(width: 6),
                            Text('अंक  Digit',
                                style: TextStyle(
                                  fontFamily: 'Tiro',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: state.isDigitMode ? AppTheme.bgDark : AppTheme.textSub,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => state.setRecognitionType(false),
                      child: Container(
                        color: Colors.transparent,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.text_fields_rounded, size: 16, color: !state.isDigitMode ? AppTheme.bgDark : AppTheme.textSub),
                            const SizedBox(width: 6),
                            Text('अक्षर  Text',
                                style: TextStyle(
                                  fontFamily: 'Tiro',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: !state.isDigitMode ? AppTheme.bgDark : AppTheme.textSub,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
