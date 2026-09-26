import 'package:flutter/material.dart';
import '../../../../core/cobalt_theme.dart';
import '../../../../core/colors.dart';
import '../serial_change_controller.dart';

/// Final screen when all units are scanned.
class FinishStep extends StatefulWidget {
  final SerialChangeController ctrl;
  const FinishStep({super.key, required this.ctrl});
  @override
  State<FinishStep> createState() => _FinishStepState();
}

class _FinishStepState extends State<FinishStep> {
  bool _uploading = false;
  String? _uploadResult;

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    final c = widget.ctrl;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 40),
        const Icon(Icons.celebration_outlined, size: 56, color: CobaltColors.cobaltLight),
        const SizedBox(height: 16),
        Text('Orden completada', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: ct.textPrimary)),
        const SizedBox(height: 8),
        Text('${c.totalScanned} seriales registrados en ${c.completedBoxes.length} cajas',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: ct.textSecondary)),
        const SizedBox(height: 32),
        // Upload to SFTP
        SizedBox(height: 48, child: FilledButton.icon(
          onPressed: _uploading ? null : _upload,
          icon: _uploading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.cloud_upload_outlined),
          label: const Text('Exportar Excel + SFTP', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          style: FilledButton.styleFrom(backgroundColor: CobaltColors.cobalt,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        )),
        if (_uploadResult != null) ...[
          const SizedBox(height: 8),
          Text(_uploadResult!, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: _uploadResult!.contains('Error') ? Colors.redAccent : const Color(0xFF2ECC71))),
        ],
        const SizedBox(height: 16),
        SizedBox(height: 48, child: OutlinedButton(
          onPressed: c.reset,
          style: OutlinedButton.styleFrom(
              side: BorderSide(color: ct.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: Text('Nueva orden', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ct.textPrimary)),
        )),
      ]),
    );
  }

  Future<void> _upload() async {
    setState(() { _uploading = true; _uploadResult = null; });
    final filename = await widget.ctrl.finishAndUpload();
    if (mounted) {
      setState(() {
        _uploading = false;
        _uploadResult = filename != null ? 'Subido: $filename' : 'Error al subir';
      });
    }
  }
}
