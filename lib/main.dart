import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

// ── Colour tokens ────────────────────────────────────────────────────────────
const _jade     = Color(0xFF5DD3B6);
const _sand     = Color(0xFF6E5034);
const _gold     = Color(0xFFCDB885);
const _parch    = Color(0xFFEFE1B5);
const _mahogany = Color(0xFF2A1A0E);
const _mahoganyDark = Color(0xFF1A0F08);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AksharApp());
}

class AksharApp extends StatelessWidget {
  const AksharApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'अक्षर · Akshar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: _jade,
          secondary: _gold,
          surface: _mahogany,
          onSurface: _parch,
        ),
        scaffoldBackgroundColor: _mahoganyDark,
        fontFamily: 'TiroDevanagariHindi',
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// ── Result model (unified digit + text) ──────────────────────────────────────
class RecognitionResult {
  final String text;
  final double confidence;
  final String type; // 'digit' or 'text'

  const RecognitionResult({
    required this.text,
    required this.confidence,
    required this.type,
  });
}

// ── Home screen ───────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final List<Offset?> _strokes = [];
  final ImagePicker _picker = ImagePicker();
  bool _isRecognizing = false;
  List<RecognitionResult> _results = [];

  late AnimationController _logoAnim;
  late Animation<double> _logoScale;
  late Animation<double> _logoGlow;

  @override
  void initState() {
    super.initState();
    _logoAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _logoScale = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _logoAnim, curve: Curves.easeInOut),
    );
    _logoGlow = Tween<double>(begin: 6.0, end: 18.0).animate(
      CurvedAnimation(parent: _logoAnim, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _logoAnim.dispose();
    super.dispose();
  }

  // ── Recognition ─────────────────────────────────────────────────────────────
  Future<void> _recognizeFromBytes(Uint8List bytes) async {
    setState(() {
      _isRecognizing = true;
      _results = [];
    });

    try {
      // On web, ML Kit native is unavailable – show a graceful message.
      if (kIsWeb) {
        await Future.delayed(const Duration(milliseconds: 600));
        setState(() {
          _results = [
            const RecognitionResult(
              text: 'On-device ML Kit is not supported on web.\n'
                  'Please run on iOS or Android for full recognition.',
              confidence: 0,
              type: 'text',
            ),
          ];
        });
        return;
      }

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: const Size(300, 300),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.bgra8888,
          bytesPerRow: 300 * 4,
        ),
      );

      final textRecognizer =
          TextRecognizer(script: TextRecognitionScript.devanagari);
      final recognized = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      final unified = <RecognitionResult>[];

      for (final block in recognized.blocks) {
        for (final line in block.lines) {
          final raw = line.text.trim();
          if (raw.isEmpty) continue;

          // Digit extraction
          final digits = RegExp(r'\d+').allMatches(raw);
          for (final m in digits) {
            unified.add(RecognitionResult(
              text: m.group(0)!,
              confidence: line.confidence ?? 0.9,
              type: 'digit',
            ));
          }

          // Full text line
          unified.add(RecognitionResult(
            text: raw,
            confidence: line.confidence ?? 0.85,
            type: 'text',
          ));
        }
      }

      // Deduplicate exact text matches
      final seen = <String>{};
      final deduped = unified.where((r) => seen.add(r.type + r.text)).toList();

      // Sort by confidence descending
      deduped.sort((a, b) => b.confidence.compareTo(a.confidence));

      setState(() {
        _results = deduped.isEmpty
            ? [
                const RecognitionResult(
                  text: 'No text recognised. Try again.',
                  confidence: 0,
                  type: 'text',
                )
              ]
            : deduped;
      });
    } catch (e) {
      setState(() {
        _results = [
          RecognitionResult(
            text: 'Error: $e',
            confidence: 0,
            type: 'text',
          )
        ];
      });
    } finally {
      setState(() => _isRecognizing = false);
    }
  }

  Future<Uint8List> _canvasToBytes() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 300, 300));
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 300, 300),
      Paint()..color = Colors.black,
    );
    final strokePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final path = Path();
    for (int i = 0; i < _strokes.length; i++) {
      if (_strokes[i] == null) continue;
      if (i == 0 || _strokes[i - 1] == null) {
        path.moveTo(_strokes[i]!.dx, _strokes[i]!.dy);
      } else {
        path.lineTo(_strokes[i]!.dx, _strokes[i]!.dy);
      }
    }
    canvas.drawPath(path, strokePaint);
    final picture = recorder.endRecording();
    final img = await picture.toImage(300, 300);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _recognizeDrawing() async {
    if (_strokes.isEmpty) return;
    final bytes = await _canvasToBytes();
    await _recognizeFromBytes(bytes);
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 90);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    await _recognizeFromBytes(bytes);
  }

  void _clearCanvas() {
    setState(() {
      _strokes.clear();
      _results = [];
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isWide = mq.size.width > 600;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.5),
            radius: 1.4,
            colors: [Color(0xFF3A200E), _mahoganyDark],
          ),
        ),
        child: SafeArea(
          child: isWide
              ? Row(
                  children: [
                    Expanded(child: _buildLeftPanel()),
                    const VerticalDivider(color: _sand, width: 1),
                    Expanded(child: _buildResultsPanel()),
                  ],
                )
              : Column(
                  children: [
                    Expanded(child: _buildLeftPanel()),
                    const Divider(color: _sand, height: 1),
                    _buildResultsPanel(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 8),
        _buildCanvas(),
        const SizedBox(height: 12),
        _buildActionButtons(),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Header / Logo ────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _logoAnim,
            builder: (_, child) => Transform.scale(
              scale: _logoScale.value,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _mahogany,
                  border: Border.all(color: _gold, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: _jade.withOpacity(0.45),
                      blurRadius: _logoGlow.value,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: _gold.withOpacity(0.25),
                      blurRadius: _logoGlow.value * 0.5,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'अ',
                    style: TextStyle(
                      fontFamily: 'TiroDevanagariHindi',
                      fontSize: 26,
                      color: _gold,
                      shadows: [
                        Shadow(
                          color: _jade.withOpacity(0.8),
                          blurRadius: _logoGlow.value * 0.6,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [_gold, _parch, _gold],
                ).createShader(bounds),
                child: const Text(
                  'अक्षर',
                  style: TextStyle(
                    fontFamily: 'TiroDevanagariHindi',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const Text(
                'Akshar · Script Recognition',
                style: TextStyle(
                  color: _jade,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          // Decorative dots
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(3, (i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: List.generate(3 - i, (j) => Container(
                  margin: const EdgeInsets.only(left: 4),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _gold.withOpacity(0.3 + i * 0.2),
                  ),
                )),
              ),
            )),
          ),
        ],
      ),
    );
  }

  // ── Canvas ───────────────────────────────────────────────────────────────────
  Widget _buildCanvas() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D0905),
            border: Border.all(color: _sand, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Stack(
              children: [
                // Rangoli dot grid
                CustomPaint(
                  painter: _DotGridPainter(),
                  child: const SizedBox.expand(),
                ),
                // Corner ornaments
                ..._cornerOrnaments(),
                // Drawing surface
                GestureDetector(
                  onPanUpdate: (d) => setState(
                      () => _strokes.add(d.localPosition)),
                  onPanEnd: (_) => setState(() => _strokes.add(null)),
                  child: CustomPaint(
                    painter: _StrokePainter(_strokes),
                    child: const SizedBox.expand(),
                  ),
                ),
                if (_strokes.isEmpty)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'लिखो',
                          style: TextStyle(
                            fontFamily: 'TiroDevanagariHindi',
                            fontSize: 28,
                            color: _sand.withOpacity(0.45),
                          ),
                        ),
                        Text(
                          'Draw here',
                          style: TextStyle(
                            fontSize: 13,
                            color: _sand.withOpacity(0.3),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _cornerOrnaments() {
    const size = 20.0;
    const style = TextStyle(color: _sand, fontSize: size);
    return [
      const Positioned(top: 4, left: 6, child: Text('✦', style: style)),
      const Positioned(top: 4, right: 6, child: Text('✦', style: style)),
      const Positioned(bottom: 4, left: 6, child: Text('✦', style: style)),
      const Positioned(bottom: 4, right: 6, child: Text('✦', style: style)),
    ];
  }

  // ── Action buttons ───────────────────────────────────────────────────────────
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              _AksharButton(
                label: 'पहचानो\nRecognise',
                icon: Icons.auto_fix_high_rounded,
                color: _jade,
                onTap: _recognizeDrawing,
              ),
              const SizedBox(width: 10),
              _AksharButton(
                label: 'मिटाओ\nClear',
                icon: Icons.clear_rounded,
                color: _sand,
                onTap: _clearCanvas,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _AksharButton(
                label: 'कैमरा\nCamera',
                icon: Icons.camera_alt_rounded,
                color: _gold,
                onTap: () => _pickImage(ImageSource.camera),
              ),
              const SizedBox(width: 10),
              _AksharButton(
                label: 'चित्र\nGallery',
                icon: Icons.photo_library_rounded,
                color: _gold,
                onTap: () => _pickImage(ImageSource.gallery),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Results panel ────────────────────────────────────────────────────────────
  Widget _buildResultsPanel() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'विश्वास · Results',
                  style: TextStyle(
                    color: _gold,
                    fontSize: 13,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_isRecognizing)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _jade,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isRecognizing
                  ? const Center(
                      child: Text(
                        'Recognising…',
                        style: TextStyle(color: _parch, fontSize: 14),
                      ),
                    )
                  : _results.isEmpty
                      ? Center(
                          child: Text(
                            'Results will appear here',
                            style: TextStyle(
                              color: _sand.withOpacity(0.6),
                              fontSize: 13,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _results.length,
                          separatorBuilder: (_, __) => Divider(
                            color: _sand.withOpacity(0.3),
                            height: 1,
                          ),
                          itemBuilder: (context, i) {
                            final r = _results[i];
                            return _ResultTile(result: r, rank: i + 1);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Result tile ───────────────────────────────────────────────────────────────
class _ResultTile extends StatelessWidget {
  final RecognitionResult result;
  final int rank;
  const _ResultTile({required this.result, required this.rank});

  @override
  Widget build(BuildContext context) {
    final isDigit = result.type == 'digit';
    final pct = (result.confidence * 100).clamp(0, 100).toStringAsFixed(0);
    final badgeColor = isDigit ? _jade : _gold;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rank badge
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _mahogany,
              border: Border.all(color: _sand, width: 1),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(color: _parch, fontSize: 11),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.text,
                  style: const TextStyle(
                    color: _parch,
                    fontSize: 15,
                    fontFamily: 'TiroDevanagariHindi',
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: badgeColor.withOpacity(0.5), width: 0.5),
                      ),
                      child: Text(
                        isDigit ? 'अंक · digit' : 'अक्षर · text',
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 9,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Confidence bar
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: result.confidence.clamp(0, 1),
                          backgroundColor: _sand.withOpacity(0.2),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(badgeColor),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$pct%',
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Custom button ─────────────────────────────────────────────────────────────
class _AksharButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AksharButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: color.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(10),
              color: color.withOpacity(0.06),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    height: 1.35,
                    fontFamily: 'TiroDevanagariHindi',
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Painters ──────────────────────────────────────────────────────────────────
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6E5034).withOpacity(0.18)
      ..strokeCap = StrokeCap.round;
    const spacing = 22.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _StrokePainter extends CustomPainter {
  final List<Offset?> strokes;
  const _StrokePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCDB885)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final path = Path();
    for (int i = 0; i < strokes.length; i++) {
      if (strokes[i] == null) continue;
      if (i == 0 || strokes[i - 1] == null) {
        path.moveTo(strokes[i]!.dx, strokes[i]!.dy);
      } else {
        path.lineTo(strokes[i]!.dx, strokes[i]!.dy);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _StrokePainter old) =>
      old.strokes != strokes;
}
