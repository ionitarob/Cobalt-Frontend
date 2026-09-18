import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/api_client.dart';
import '../../../../core/cobalt_theme.dart';
import '../../../../core/colors.dart';
import '../../../../models/orderops/order_detail.dart';
import '../order_detail_controller.dart';

class FilesSection extends StatefulWidget {
  const FilesSection({super.key, required this.controller});

  final OrderDetailController controller;

  @override
  State<FilesSection> createState() => _FilesSectionState();
}

class _FilesSectionState extends State<FilesSection> {
  Future<void> _pickFiles() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );
    if (result == null) return;
    for (final f in result.files) {
      if (f.bytes == null) continue;
      await widget.controller.uploadFile(
        bytes: f.bytes!,
        fileName: f.name,
        scope: 'archivo',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    final files = widget.controller.detail?.photos
            .where((p) => !p.scope.contains('quality'))
            .toList() ??
        [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeaderRow(count: files.length, onUpload: _pickFiles, ct: ct),
        const SizedBox(height: 12),
        CustomPaint(
          painter: _DashedBorderPainter(color: ct.border),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (files.isEmpty)
                  _EmptyState(ct: ct)
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final p in files)
                        _PhotoTile(
                          key: ValueKey(p.id),
                          photo: p,
                          controller: widget.controller,
                        ),
                    ],
                  ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Arrastra archivos aquí o usa el botón de carga',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: ct.textHint),
                  ),
                ),
              ],
            ),
          ),
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
          'ARCHIVOS',
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
          icon: const Icon(Icons.upload, size: 18),
          color: CobaltColors.cobaltLight,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          onPressed: onUpload,
          tooltip: 'Subir archivo',
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        Icon(Icons.upload_file_outlined, color: ct.textHint, size: 32),
        const SizedBox(height: 6),
        Text(
          'Sin archivos adjuntos',
          style: TextStyle(color: ct.textHint, fontSize: 12),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _PhotoTile extends StatefulWidget {
  const _PhotoTile({
    super.key,
    required this.photo,
    required this.controller,
  });

  final AgentOrderPhoto photo;
  final OrderDetailController controller;

  @override
  State<_PhotoTile> createState() => _PhotoTileState();
}

class _PhotoTileState extends State<_PhotoTile> {
  bool _hovered = false;

  static const _imageExts = {'.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp'};

  bool get _isImage {
    final lower = widget.photo.fileName.toLowerCase();
    return _imageExts.any((ext) => lower.endsWith(ext));
  }

  bool get _isPdf => widget.photo.fileName.toLowerCase().endsWith('.pdf');

  String get _resolvedUrl {
    final path = widget.photo.filePath;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final base = ApiClient.instance.dio.options.baseUrl;
    final trimmedBase =
        base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$trimmedBase$normalizedPath';
  }

  Future<Uint8List?> _downloadBytes(BuildContext context) async {
    try {
      final resp = await ApiClient.instance.dio.get<List<int>>(
        _resolvedUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(resp.data!);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al descargar: $e')),
        );
      }
      return null;
    }
  }

  Future<void> _onTap(BuildContext context) async {
    final bytes = await _downloadBytes(context);
    if (bytes == null || !context.mounted) return;

    if (_isImage) {
      await showDialog<void>(
        context: context,
        builder: (_) => _ImageLightbox(
          bytes: bytes,
          fileName: widget.photo.fileName,
        ),
      );
    } else {
      // Save to temp dir and open with OS
      try {
        final tmpPath =
            '${Directory.systemTemp.path}/${widget.photo.fileName}';
        await File(tmpPath).writeAsBytes(bytes);
        if (Platform.isMacOS) {
          await Process.run('open', [tmpPath]);
        } else if (Platform.isWindows) {
          await Process.run('cmd', ['/c', 'start', '', tmpPath]);
        } else if (Platform.isLinux) {
          await Process.run('xdg-open', [tmpPath]);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo abrir el archivo: $e')),
          );
        }
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ct = context.ct;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ct.surfaceElevated,
        title: Text(
          'Eliminar archivo',
          style: TextStyle(color: ct.textPrimary, fontSize: 15),
        ),
        content: Text(
          '¿Eliminar "${widget.photo.fileName}"?',
          style: TextStyle(color: ct.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: TextStyle(color: ct.textSecondary)),
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

  Widget _buildThumbnail(CobaltPalette ct) {
    if (_isImage) {
      return Image.network(
        _resolvedUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Center(
          child: Icon(Icons.broken_image_outlined, color: ct.textHint, size: 36),
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

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    final isPrivileged = widget.controller.isPrivileged;
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    final tile = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => _onTap(context),
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
                  child: _BottomOverlay(photo: widget.photo, ct: ct),
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

    return TweenAnimationBuilder<double>(
      tween: Tween(
        begin: disableAnimations ? 1.0 : 0.0,
        end: 1.0,
      ),
      duration: disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: tile,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.scale(scale: 0.95 + 0.05 * t, child: child),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _BottomOverlay extends StatelessWidget {
  const _BottomOverlay({required this.photo, required this.ct});

  final AgentOrderPhoto photo;
  final CobaltPalette ct;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.67),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(7)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              photo.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: ct.textPrimary, fontSize: 9),
            ),
          ),
          const SizedBox(width: 4),
          _ScopeTag(proyectoId: photo.proyectoId, ct: ct),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ScopeTag extends StatelessWidget {
  const _ScopeTag({required this.proyectoId, required this.ct});

  final int? proyectoId;
  final CobaltPalette ct;

  @override
  Widget build(BuildContext context) {
    final isProject = proyectoId != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: isProject
            ? CobaltColors.cobalt.withValues(alpha: 0.15)
            : ct.border,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        isProject ? 'Proy' : 'Orden',
        style: TextStyle(
          fontSize: 8,
          color: isProject ? CobaltColors.cobaltLight : ct.textHint,
          fontWeight: FontWeight.w600,
        ),
      ),
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

// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------

class _ImageLightbox extends StatelessWidget {
  const _ImageLightbox({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black87,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.memory(bytes, fit: BoxFit.contain),
          ),
          Padding(
            padding: const EdgeInsets.all(4),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white70),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Cerrar',
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const r = 8.0;
    final path = Path()
      ..moveTo(r, 0)
      ..lineTo(size.width - r, 0)
      ..arcToPoint(
        Offset(size.width, r),
        radius: const Radius.circular(r),
      )
      ..lineTo(size.width, size.height - r)
      ..arcToPoint(
        Offset(size.width - r, size.height),
        radius: const Radius.circular(r),
      )
      ..lineTo(r, size.height)
      ..arcToPoint(
        Offset(0, size.height - r),
        radius: const Radius.circular(r),
      )
      ..lineTo(0, r)
      ..arcToPoint(Offset(r, 0), radius: const Radius.circular(r))
      ..close();

    for (final metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        final end = (dist + 6.0).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(dist, end), paint);
        dist += 10.0;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}
