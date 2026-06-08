import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';

import '../../core/currency_formatter.dart';
import '../../core/theme.dart';
import '../../domain/entities/scan_result.dart';
import '../providers/purchase_provider.dart';

class ConfirmScanPage extends ConsumerStatefulWidget {
  final ScanResult scanResult;
  final File imageFile;

  const ConfirmScanPage({
    super.key,
    required this.scanResult,
    required this.imageFile,
  });

  @override
  ConsumerState<ConfirmScanPage> createState() => _ConfirmScanPageState();
}

class _ConfirmScanPageState extends ConsumerState<ConfirmScanPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _showRawText = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.scanResult.detectedName ?? '',
    );
    _priceController = TextEditingController(
      text: widget.scanResult.detectedPrice != null
          ? widget.scanResult.detectedPrice!.toStringAsFixed(
              widget.scanResult.detectedPrice! ==
                      widget.scanResult.detectedPrice!.truncateToDouble()
                  ? 0
                  : 2,
            )
          : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final name = _nameController.text.trim();
    final priceText = _priceController.text.trim();
    final price = CurrencyFormatter.parse(priceText) ??
        double.tryParse(priceText.replaceAll(',', '.')) ??
        0.0;

    await ref.read(purchaseProvider.notifier).addItem(
          name: name.isEmpty ? 'Producto sin nombre' : name,
          price: price,
        );

    if (mounted) {
      // Pop scan page AND confirm page back to home
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Producto detectado'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Detection status banner
              _DetectionBanner(scanResult: widget.scanResult)
                  .animate()
                  .fadeIn(duration: 300.ms),

              const Gap(24),

              // Image preview
              _ImagePreview(imageFile: widget.imageFile)
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 100.ms),

              const Gap(24),

              // Fields section title
              Text(
                'Revisá y editá si es necesario',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.onSurfaceMuted,
                  letterSpacing: 0.5,
                ),
              ).animate().fadeIn(delay: 150.ms),

              const Gap(14),

              // Name field
              _buildNameField()
                  .animate()
                  .fadeIn(duration: 350.ms, delay: 200.ms)
                  .slideY(begin: 0.1),

              const Gap(14),

              // Price field
              _buildPriceField()
                  .animate()
                  .fadeIn(duration: 350.ms, delay: 260.ms)
                  .slideY(begin: 0.1),

              const Gap(20),

              // Raw OCR text toggle
              _buildRawTextToggle()
                  .animate()
                  .fadeIn(duration: 350.ms, delay: 320.ms),

              const Gap(32),

              // Action buttons
              _buildButtons()
                  .animate()
                  .fadeIn(duration: 350.ms, delay: 380.ms)
                  .slideY(begin: 0.1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(
          label: 'Nombre del producto',
          icon: Icons.label_outline_rounded,
          confidence: widget.scanResult.hasName,
        ),
        const Gap(8),
        TextFormField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          style: GoogleFonts.outfit(
            fontSize: 16,
            color: AppTheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Ej: Coca Cola 2.25L',
            suffixIcon: _nameController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded,
                        color: AppTheme.onSurfaceMuted, size: 18),
                    onPressed: () => setState(() => _nameController.clear()),
                  )
                : null,
          ),
          onChanged: (_) => setState(() {}),
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Ingresá un nombre para el producto';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(
          label: 'Precio',
          icon: Icons.attach_money_rounded,
          confidence: widget.scanResult.hasPrice,
        ),
        const Gap(8),
        TextFormField(
          controller: _priceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.outfit(
            fontSize: 22,
            color: AppTheme.primary,
            fontWeight: FontWeight.w700,
          ),
          decoration: const InputDecoration(
            hintText: '0',
            prefixText: '\$ ',
            prefixStyle: TextStyle(
              fontSize: 22,
              color: AppTheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Ingresá el precio';
            }
            final parsed = double.tryParse(
                v.trim().replaceAll(',', '.').replaceAll(RegExp(r'[^\d.]'), ''));
            if (parsed == null || parsed <= 0) {
              return 'Precio inválido';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRawTextToggle() {
    if (widget.scanResult.rawText.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _showRawText = !_showRawText),
          child: Row(
            children: [
              Icon(
                _showRawText
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppTheme.onSurfaceMuted,
              ),
              const Gap(6),
              Text(
                'Ver texto detectado por OCR',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppTheme.onSurfaceMuted,
                ),
              ),
            ],
          ),
        ),
        if (_showRawText) ...[
          const Gap(10),
          AnimatedContainer(
            duration: 200.ms,
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.scanResult.rawText,
              style: GoogleFonts.sourceCodePro(
                fontSize: 12,
                color: AppTheme.onSurfaceMuted,
                height: 1.6,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.surface,
                    ),
                  )
                : const Icon(Icons.add_shopping_cart_rounded),
            label: Text(_isSaving ? 'Guardando…' : 'Agregar a la lista'),
          ),
        ),
        const Gap(12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.onSurfaceMuted,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Cancelar'),
          ),
        ),
      ],
    );
  }
}

// ── Detection Banner ──────────────────────────────────────────────────────────

class _DetectionBanner extends StatelessWidget {
  final ScanResult scanResult;

  const _DetectionBanner({required this.scanResult});

  @override
  Widget build(BuildContext context) {
    final hasName = scanResult.hasName;
    final hasPrice = scanResult.hasPrice;
    final bothDetected = hasName && hasPrice;

    Color color;
    IconData icon;
    String message;

    if (bothDetected) {
      color = AppTheme.primary;
      icon = Icons.check_circle_rounded;
      message = 'Producto y precio detectados correctamente';
    } else if (hasPrice && !hasName) {
      color = AppTheme.warning;
      icon = Icons.warning_amber_rounded;
      message = 'Precio detectado · Completá el nombre manualmente';
    } else if (hasName && !hasPrice) {
      color = AppTheme.warning;
      icon = Icons.warning_amber_rounded;
      message = 'Nombre detectado · Ingresá el precio manualmente';
    } else {
      color = AppTheme.error;
      icon = Icons.error_outline_rounded;
      message = 'No se detectó texto claro · Completá los campos manualmente';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const Gap(10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Image Preview ─────────────────────────────────────────────────────────────

class _ImagePreview extends StatelessWidget {
  final File imageFile;

  const _ImagePreview({required this.imageFile});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 180,
        width: double.infinity,
        color: AppTheme.surfaceCard,
        child: Image.file(
          imageFile,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.broken_image_rounded,
                color: AppTheme.onSurfaceMuted, size: 40),
          ),
        ),
      ),
    );
  }
}

// ── Field Label ───────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool confidence;

  const _FieldLabel({
    required this.label,
    required this.icon,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.onSurfaceMuted),
        const Gap(6),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: AppTheme.onSurfaceMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Gap(8),
        if (confidence)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Auto-detectado',
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
