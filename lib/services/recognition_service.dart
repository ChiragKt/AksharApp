import 'dart:math';
import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../models/recognition_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RecognitionService
// Handles: drawn-digit ML Kit digital ink, drawn-text ML Kit digital ink,
//          image-based OCR via ML Kit text recognition, camera OCR.
// ─────────────────────────────────────────────────────────────────────────────

class RecognitionService {
  // Singleton
  RecognitionService._();
  static final RecognitionService instance = RecognitionService._();

  // ML Kit
  final DigitalInkRecognizer _inkRecognizer =
      DigitalInkRecognizer(languageCode: 'en-US');
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  bool _inkModelReady = false;

  // ── Download ink model ────────────────────────────────────────────
  Future<void> ensureInkModelReady() async {
    if (_inkModelReady) return;
    final modelManager = DigitalInkRecognizerModelManager();
    final isDownloaded = await modelManager.isModelDownloaded('en-US');
    if (!isDownloaded) {
      await modelManager.downloadModel('en-US');
    }
    _inkModelReady = true;
  }

  // ── Drawn strokes → recognition ───────────────────────────────────
  Future<List<RecognitionResult>> recognizeDrawn({
    required List<DrawPoint> points,
    required bool isDigitMode,
    required Size canvasSize,
  }) async {
    await ensureInkModelReady();

    // Convert DrawPoints → ML Kit Ink strokes
    final List<Stroke> strokes = [];
    List<StrokePoint> currentStroke = [];

    for (final p in points) {
      if (p.isStart && currentStroke.isNotEmpty) {
        strokes.add(Stroke()..points.addAll(currentStroke));
        currentStroke = [];
      }
      currentStroke.add(StrokePoint(
        x: p.offset.dx,
        y: p.offset.dy,
        t: DateTime.now().millisecondsSinceEpoch,
      ));
    }
    if (currentStroke.isNotEmpty) {
      strokes.add(Stroke()..points.addAll(currentStroke));
    }

    if (strokes.isEmpty) return [];

    final ink = Ink();
    for (final s in strokes) {
      ink.strokes.add(s);
    }
    final candidates = await _inkRecognizer.recognize(ink);

    List<RecognitionResult> results = [];

    if (isDigitMode) {
      // Filter digit candidates and score them
      final digitCandidates = candidates
          .where((c) => RegExp(r'^\d+$').hasMatch(c.text.trim()))
          .toList();

      if (digitCandidates.isEmpty) {
        // fallback: grab any numeric parts from all candidates
        for (final c in candidates.take(5)) {
          final nums = RegExp(r'\d+').allMatches(c.text);
          for (final m in nums) {
            final score = 1.0 - (results.length * 0.15);
            results.add(RecognitionResult(
              label: m.group(0)!,
              confidence: score.clamp(0.1, 0.99),
              type: 'digit',
            ));
          }
        }
      } else {
        for (int i = 0; i < min(digitCandidates.length, 5); i++) {
          final score = 1.0 - i * 0.18;
          results.add(RecognitionResult(
            label: digitCandidates[i].text.trim(),
            confidence: score.clamp(0.1, 0.99),
            type: 'digit',
          ));
        }
      }
    } else {
      // Text / sentence mode
      for (int i = 0; i < min(candidates.length, 5); i++) {
        final score = 1.0 - i * 0.12;
        results.add(RecognitionResult(
          label: candidates[i].text,
          confidence: score.clamp(0.1, 0.99),
          type: 'sentence',
        ));
      }
    }

    return results;
  }

  // ── Image / camera → OCR ──────────────────────────────────────────
  Future<List<RecognitionResult>> recognizeFromImage({
    required String imagePath,
    required bool isDigitMode,
  }) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognized = await _textRecognizer.processImage(inputImage);

    final allText = recognized.text.trim();
    if (allText.isEmpty) return [];

    List<RecognitionResult> results = [];

    if (isDigitMode) {
      // Extract all digit sequences
      final matches = RegExp(r'\d+').allMatches(allText).toList();
      for (int i = 0; i < min(matches.length, 6); i++) {
        results.add(RecognitionResult(
          label: matches[i].group(0)!,
          confidence: 0.95 - i * 0.05,
          type: 'digit',
        ));
      }
    } else {
      // Split by newlines / sentences
      final lines = allText
          .split(RegExp(r'[\n\.!?]+'))
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      for (int i = 0; i < min(lines.length, 5); i++) {
        results.add(RecognitionResult(
          label: lines[i],
          confidence: 0.97 - i * 0.04,
          type: 'sentence',
        ));
      }
      if (results.isEmpty) {
        results.add(RecognitionResult(
          label: allText,
          confidence: 0.95,
          type: 'sentence',
        ));
      }
    }

    return results;
  }

  // ── Pick image from gallery ───────────────────────────────────────
  Future<String?> pickImageFromGallery() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
    return file?.path;
  }

  // ── Pick image from camera ────────────────────────────────────────
  Future<String?> captureFromCamera() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 95,
    );
    return file?.path;
  }

  void dispose() {
    _inkRecognizer.close();
    _textRecognizer.close();
  }
}
