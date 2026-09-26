import 'package:flutter_test/flutter_test.dart';
import 'package:configtool_cobalt/screens/xiaomi_serials/serial_change/serial_change_models.dart';
import 'package:configtool_cobalt/screens/xiaomi_serials/serial_change/label_generator.dart';

void main() {
  // ── SCOperator ──────────────────────────────────────────────────────
  group('SCOperator', () {
    test('fromJson maps all fields', () {
      final op = SCOperator.fromJson({'operador': 'Orange', 'tipos': 5, 'activos': 3});
      expect(op.name, 'Orange');
      expect(op.totalTypes, 5);
      expect(op.activeTypes, 3);
    });

    test('fromJson handles nulls', () {
      final op = SCOperator.fromJson({});
      expect(op.name, '');
      expect(op.totalTypes, 0);
    });
  });

  // ── SCLabelType ─────────────────────────────────────────────────────
  group('SCLabelType', () {
    test('fromJson maps all fields', () {
      final t = SCLabelType.fromJson({
        'id': 42, 'operador': 'Vodafone', 'articulo': 'VF-STD',
        'sap_cliente': '1234', 'codigo_letra': 'V', 'activo': true,
      });
      expect(t.id, 42);
      expect(t.operatorName, 'Vodafone');
      expect(t.article, 'VF-STD');
      expect(t.sapClient, '1234');
      expect(t.active, true);
    });

    test('displayName prefers article', () {
      final t = SCLabelType.fromJson({'articulo': 'ART', 'codigo_letra': 'C'});
      expect(t.displayName, 'ART');
    });

    test('displayName falls back to codeLetter', () {
      final t = SCLabelType.fromJson({'codigo_letra': 'C'});
      expect(t.displayName, 'C');
    });
  });

  // ── SCPrinter ───────────────────────────────────────────────────────
  group('SCPrinter', () {
    test('fromJson maps fields', () {
      final p = SCPrinter.fromJson({'id_printer': 7, 'printer_name': 'Zebra', 'ip_address': '10.0.0.1'});
      expect(p.id, 7);
      expect(p.name, 'Zebra');
      expect(p.ip, '10.0.0.1');
    });
  });

  // ── SCMapping ───────────────────────────────────────────────────────
  group('SCMapping', () {
    test('oldSerial is mutable', () {
      final m = SCMapping(oldSerial: 'OLD', newSerial: 'NEW', scannedAt: DateTime.now());
      m.oldSerial = 'EDITED';
      expect(m.oldSerial, 'EDITED');
    });
  });

  // ── SCBoxSession ────────────────────────────────────────────────────
  group('SCBoxSession', () {
    test('tracks scannedCount and isComplete', () {
      final box = SCBoxSession(boxNumber: '1', units: 2, labels: ['L1', 'L2']);
      expect(box.scannedCount, 0);
      expect(box.isComplete, false);
      expect(box.currentLabel, 'L1');

      box.mappings.add(SCMapping(oldSerial: 'O1', newSerial: 'L1', scannedAt: DateTime.now()));
      expect(box.scannedCount, 1);
      expect(box.currentLabel, 'L2');

      box.mappings.add(SCMapping(oldSerial: 'O2', newSerial: 'L2', scannedAt: DateTime.now()));
      expect(box.isComplete, true);
      expect(box.currentLabel, isNull);
    });
  });

  // ── SCResumeData ────────────────────────────────────────────────────
  group('SCResumeData', () {
    test('stores resume fields', () {
      final rd = SCResumeData(
        existingCount: 50, operador: 'Orange', sku: 'SKU1',
        totalUnits: 100, tipoId: 5, ean: '123456789',
        nextSequence: 51, lastBox: '3',
      );
      expect(rd.existingCount, 50);
      expect(rd.nextSequence, 51);
      expect(rd.ean, '123456789');
    });
  });

  // ── LabelGenerator ──────────────────────────────────────────────────
  group('LabelGenerator', () {
    test('Orange generates correct format', () {
      final labels = LabelGenerator.generate(
        operatorName: 'Orange', date: DateTime(2026, 9, 25),
        totalUnits: 3, article: 'OR-STD', sapClient: null,
        codeLetter: 'O', startSequence: 1,
      );
      expect(labels.length, 3);
      expect(labels[0], startsWith('20260925'));
      expect(labels[0], endsWith('00001'));
      expect(labels[2], endsWith('00003'));
    });

    test('Vodafone generates correct format', () {
      final labels = LabelGenerator.generate(
        operatorName: 'Vodafone', date: DateTime(2026, 9, 25),
        totalUnits: 2, article: 'VF', sapClient: '1234',
        codeLetter: null, startSequence: 10,
      );
      expect(labels.length, 2);
      // SAP + yearDigit + monthLetter + day + seq
      expect(labels[0], startsWith('1234'));
      expect(labels[0], contains('6')); // year 2026 → 6
      expect(labels[0], contains('S')); // September → S
      expect(labels[0], endsWith('00010'));
      expect(labels[1], endsWith('00011'));
    });

    test('startSequence offsets correctly', () {
      final labels = LabelGenerator.generate(
        operatorName: 'Orange', date: DateTime(2026, 1, 1),
        totalUnits: 2, article: 'X', sapClient: null,
        codeLetter: null, startSequence: 50,
      );
      expect(labels[0], endsWith('00050'));
      expect(labels[1], endsWith('00051'));
    });

    test('zero units returns empty', () {
      final labels = LabelGenerator.generate(
        operatorName: 'Orange', date: DateTime.now(),
        totalUnits: 0, article: 'X', sapClient: null,
        codeLetter: null, startSequence: 1,
      );
      expect(labels, isEmpty);
    });

    test('generic operator uses date prefix', () {
      final labels = LabelGenerator.generate(
        operatorName: 'CustomOp', date: DateTime(2026, 12, 31),
        totalUnits: 1, article: 'ART', sapClient: '',
        codeLetter: 'C', startSequence: 1,
      );
      expect(labels.length, 1);
      expect(labels[0], startsWith('20261231'));
    });
  });
}
