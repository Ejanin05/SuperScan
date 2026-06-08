import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';
import '../../domain/entities/scan_result.dart';
import '../providers/purchase_provider.dart';
import 'confirm_scan_page.dart';

class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key});

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isProcessing = false;
  String _statusText = 'Apuntá la cámara a la etiqueta del producto';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _statusText = 'No se encontró cámara disponible');
        return;
      }

      final camera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      if (!mounted) return;

      setState(() => _isInitialized = true);
    } catch (e) {
      if (mounted) {
        setState(() => _statusText = 'Error al iniciar la cámara: $e');
      }
    }
  }

  Future<void> _captureAndProcess() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusText = 'Procesando imagen…';
    });

    try {
      final xFile = await _controller!.takePicture();
      final imageFile = File(xFile.path);

      setState(() => _statusText = 'Detectando texto…');

      final ocrUseCase = ref.read(processImageUseCaseProvider);
      final ScanResult result = await ocrUseCase(imageFile);

      if (!mounted) return;

      // Navigate to confirmation regardless (user can edit)
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConfirmScanPage(
            scanResult: result,
            imageFile: imageFile,
          ),
        ),
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusText = 'Apuntá la cámara a la etiqueta del producto';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusText = 'Error al procesar la imagen. Intentá de nuevo.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          if (_isInitialized && _controller != null)
            CameraPreview(_controller!)
          else
            const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),

          // Scan overlay
          _ScanOverlay(),

          // Top bar
          _buildTopBar(context),

          // Bottom controls
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
              if (_controller != null && _isInitialized)
                IconButton(
                  icon: const Icon(Icons.flash_auto_rounded, color: Colors.white),
                  onPressed: () async {
                    final mode = _controller!.value.flashMode;
                    await _controller!.setFlashMode(
                      mode == FlashMode.off ? FlashMode.auto : FlashMode.off,
                    );
                    setState(() {});
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          children: [
            Text(
              _statusText,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _isProcessing ? null : _captureAndProcess,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isProcessing
                      ? AppTheme.primary.withOpacity(0.5)
                      : AppTheme.primary,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: _isProcessing
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(
                end: _isProcessing ? 1.0 : 1.05,
                duration: 800.ms,
                curve: Curves.easeInOut,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Scan Frame Overlay ────────────────────────────────────────────────────────

class _ScanOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ScanFramePainter(),
      child: Container(),
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const margin = 48.0;
    const cornerLength = 28.0;
    final rect = Rect.fromLTRB(margin, size.height * 0.2,
        size.width - margin, size.height * 0.65);

    // Draw semi-transparent overlay
    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    // Outer rect minus scan area
    final outerPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final innerPath = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)));
    final overlayPath = Path.combine(
      PathOperation.difference,
      outerPath,
      innerPath,
    );
    canvas.drawPath(overlayPath, overlayPaint);

    // Corner markers
    final r = rect;
    final corners = [
      // Top-left
      [Offset(r.left, r.top + cornerLength), Offset(r.left, r.top),
       Offset(r.left + cornerLength, r.top)],
      // Top-right
      [Offset(r.right - cornerLength, r.top), Offset(r.right, r.top),
       Offset(r.right, r.top + cornerLength)],
      // Bottom-right
      [Offset(r.right, r.bottom - cornerLength), Offset(r.right, r.bottom),
       Offset(r.right - cornerLength, r.bottom)],
      // Bottom-left
      [Offset(r.left + cornerLength, r.bottom), Offset(r.left, r.bottom),
       Offset(r.left, r.bottom - cornerLength)],
    ];

    for (final corner in corners) {
      final path = Path()
        ..moveTo(corner[0].dx, corner[0].dy)
        ..lineTo(corner[1].dx, corner[1].dy)
        ..lineTo(corner[2].dx, corner[2].dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
