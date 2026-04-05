import 'dart:ui';
import 'package:flutter/foundation.dart';

enum RecognitionMode { draw, camera, image }

enum RecognitionStatus { idle, processing, done, error }

class RecognitionResult {
  final String label;
  final double confidence;
  final String type; // 'digit' | 'sentence'

  const RecognitionResult({
    required this.label,
    required this.confidence,
    required this.type,
  });
}

class DrawPoint {
  final Offset offset;
  final bool isStart;

  const DrawPoint({required this.offset, this.isStart = false});
}

class RecognitionState extends ChangeNotifier {
  RecognitionMode _mode = RecognitionMode.draw;
  RecognitionStatus _status = RecognitionStatus.idle;
  List<RecognitionResult> _results = [];
  List<DrawPoint> _drawPoints = [];
  String? _errorMessage;
  bool _isDigitMode = true; // true = digit, false = sentence/text

  // ── Getters ──────────────────────────────────────────────────────
  RecognitionMode get mode => _mode;
  RecognitionStatus get status => _status;
  List<RecognitionResult> get results => _results;
  List<DrawPoint> get drawPoints => _drawPoints;
  String? get errorMessage => _errorMessage;
  bool get isDigitMode => _isDigitMode;
  bool get hasResults => _results.isNotEmpty;

  RecognitionResult? get topResult =>
      _results.isNotEmpty ? _results.first : null;

  // ── Mode setters ──────────────────────────────────────────────────
  void setMode(RecognitionMode mode) {
    _mode = mode;
    clearAll();
    notifyListeners();
  }

  void toggleRecognitionType() {
    _isDigitMode = !_isDigitMode;
    clearAll();
    notifyListeners();
  }

  void setRecognitionType(bool isDigit) {
    if (_isDigitMode != isDigit) {
      _isDigitMode = isDigit;
      clearAll();
      notifyListeners();
    }
  }

  // ── Drawing ───────────────────────────────────────────────────────
  void addPoint(Offset offset, {bool isStart = false}) {
    _drawPoints.add(DrawPoint(offset: offset, isStart: isStart));
    notifyListeners();
  }

  void clearDrawing() {
    _drawPoints.clear();
    _results.clear();
    _status = RecognitionStatus.idle;
    notifyListeners();
  }

  // ── Recognition ───────────────────────────────────────────────────
  void setProcessing() {
    _status = RecognitionStatus.processing;
    _results.clear();
    _errorMessage = null;
    notifyListeners();
  }

  void setResults(List<RecognitionResult> results) {
    _results = results;
    _status = RecognitionStatus.done;
    notifyListeners();
  }

  void setError(String message) {
    _errorMessage = message;
    _status = RecognitionStatus.error;
    notifyListeners();
  }

  void clearAll() {
    _drawPoints.clear();
    _results.clear();
    _status = RecognitionStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }
}
