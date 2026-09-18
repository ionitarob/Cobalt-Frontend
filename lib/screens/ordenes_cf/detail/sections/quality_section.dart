import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/cobalt_theme.dart';
import '../../../../core/colors.dart';
import '../../../../core/api_client.dart';
import '../../../../models/orderops/order_detail.dart';
import '../order_detail_controller.dart';

class QualitySection extends StatefulWidget {
  const QualitySection({super.key, required this.controller});

  final OrderDetailController controller;

  @override
  State<QualitySection> createState() => _QualitySectionState();
}

class _QualitySectionState extends State<QualitySection> {
  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final f = result.files.first;
    await widget.controller.uploadFile(
      bytes: f.bytes!,
      fileName: f.name,
      scope: 'quality',
    );
  }

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    final photos = widget.controller.detail?.photos
            .where((p) => p.scope.contains('quality'))
            .toList() ??
        [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeaderRow(count: photos.length, onUpload: _pickAndUpload, ct: ct),
        const SizedBox(height: 12),
        if (photos.isEmpty)
          _EmptyState(ct: ct)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in photos)
                _PhotoTile(photo: p, controller: widget.controller),
            ],
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.count,
    required this.onUpload,
    required this.ct,
  });

  final int count;
  final VoidCallback onUpload;
  final CobaltPalette ct;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'FOTOS DE CALIDAD',
          style: TextStyle(
            color: ct.textHint,
            fontSize: 9.5,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: CobaltColors.cobalt.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: CobaltColors.cobaltLight,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.camera_alt, size: 18),
          color: CobaltColors.cobaltLight,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          onPressed: onUpload,
          tooltip: 'Subir foto',
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.ct});

  final CobaltPalette ct;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        color: ct.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ct.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt_outlined, color: ct.textHint, size: 22),
          const SizedBox(height: 4),
          Text(
            'Sin fotos de calidad',
            style: TextStyle(color: ct.textHint, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _PhotoTile extends StatefulWidget {
  const _PhotoTile({required this.photo, required this.controller});

  final AgentOrderPhoto photo;
  final OrderDetailController controller;

  @override
  State<_PhotoTile> createState() => _PhotoTileState();
}

class _PhotoTileState extends State<_PhotoTile> {
  bool _hovered = false;

  static const _imageExts = {'.jpg', '.jpeg', '.png', '.webp'};

  bool get _isImage {
    final lower = widget.photo.fileName.toLowerCase();
    return _imageExts.any((ext) => lower.endsWith(ext));
  }

  bool get _isPdf => widget.photo.fileName.toLowerCase().endsWith('.pdf');

  String get _resolvedUrl {
    final path = widget.photo.filePath;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final base = ApiClient.instance.dio.options.baseUrl;
    final trimmedBase = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$trimmedBase$normalizedPath';
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ct = context.ct;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ct.surfaceElevated,
        title: Text(
          'Eliminar foto',
          style: TextStyle(color: ct.textPrimary, fontSize: 15),
        ),
        content: Text(
          '¿Eliminar "${widget.photo.fileName}"?',
          style: TextStyle(color: ct.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: ct.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.controller.deleteFile(widget.photo.id);
    }
  }

  void _openPreview(BuildContext context) {
    if (!_isImage) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: InteractiveViewer(
            child: Image.network(_resolvedUrl, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    final isPrivileged = widget.controller.isPrivileged;
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => _openPreview(context),
        child: AnimatedScale(
          scale: _hovered ? 0.97 : 1.0,
          duration: disableAnimations
              ? Duration.zero
              : const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: ct.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ct.border),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: _buildThumbnail(ct),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.67),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(7),
                      ),
                    ),
                    child: Text(
                      widget.photo.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ct.textPrimary,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
                if (isPrivileged && _hovered)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: _DeleteButton(
                      onTap: () => _confirmDelete(context),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(CobaltPalette ct) {
    if (_isImage) {
      return Image.network(
        _resolvedUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Icon(
          Icons.broken_image_outlined,
          color: ct.textHint,
          size: 36,
        ),
      );
    }
    if (_isPdf) {
      return Center(
        child: Icon(Icons.picture_as_pdf, color: CobaltColors.cobaltLight, size: 48),
      );
    }
    return Center(
      child: Icon(Icons.insert_drive_file, color: ct.textHint, size: 48),
    );
  }
}

// ---------------------------------------------------------------------------

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close, color: Colors.white, size: 13),
      ),
    );
  }
}
