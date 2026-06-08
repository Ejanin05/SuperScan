import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';

import '../../core/currency_formatter.dart';
import '../../core/theme.dart';
import '../../domain/entities/purchase_item.dart';
import '../providers/purchase_provider.dart';

class EditItemPage extends ConsumerStatefulWidget {
  final PurchaseItem item;

  const EditItemPage({super.key, required this.item});

  @override
  ConsumerState<EditItemPage> createState() => _EditItemPageState();
}

class _EditItemPageState extends ConsumerState<EditItemPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _priceController = TextEditingController(
      text: widget.item.price == widget.item.price.truncateToDouble()
          ? widget.item.price.toStringAsFixed(0)
          : widget.item.price.toStringAsFixed(2),
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
        double.tryParse(
            priceText.replaceAll(',', '.').replaceAll(RegExp(r'[^\d.]'), '')) ??
        0.0;

    final updated = widget.item.copyWith(
      name: name.isEmpty ? widget.item.name : name,
      price: price,
    );

    await ref.read(purchaseProvider.notifier).updateItem(updated);

    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: const Text('Eliminar producto'),
        content: Text('¿Eliminás "${widget.item.name}" de la lista?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ref.read(purchaseProvider.notifier).deleteItem(widget.item.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Editar producto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
            tooltip: 'Eliminar',
            onPressed: _delete,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit_rounded,
                        color: AppTheme.primary, size: 22),
                  ),
                  const Gap(14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.name,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          CurrencyFormatter.format(widget.item.price),
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            const Gap(28),

            // Name field
            _FieldLabel(label: 'Nombre del producto',
                icon: Icons.label_outline_rounded),
            const Gap(8),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: AppTheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(hintText: 'Ej: Coca Cola 2.25L'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Ingresá un nombre';
                }
                return null;
              },
            ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.08),

            const Gap(20),

            // Price field
            _FieldLabel(label: 'Precio', icon: Icons.attach_money_rounded),
            const Gap(8),
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.outfit(
                fontSize: 24,
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
              ),
              decoration: const InputDecoration(
                hintText: '0',
                prefixText: '\$ ',
                prefixStyle: TextStyle(
                  fontSize: 24,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Ingresá el precio';
                final parsed = double.tryParse(v
                    .trim()
                    .replaceAll(',', '.')
                    .replaceAll(RegExp(r'[^\d.]'), ''));
                if (parsed == null || parsed <= 0) return 'Precio inválido';
                return null;
              },
            ).animate().fadeIn(delay: 140.ms).slideY(begin: 0.08),

            const Gap(36),

            // Save button
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.surface),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_isSaving ? 'Guardando…' : 'Guardar cambios'),
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

            const Gap(12),

            // Cancel button
            SizedBox(
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
            ).animate().fadeIn(delay: 240.ms),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final IconData icon;

  const _FieldLabel({required this.label, required this.icon});

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
      ],
    );
  }
}
