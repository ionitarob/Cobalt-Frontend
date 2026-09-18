import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart' as excel_pkg;
import 'package:flutter/material.dart';

import '../../../../core/auth_service.dart';
import '../../../../core/cobalt_theme.dart';
import '../../../../core/colors.dart';
import '../../../../services/serigrafia_service.dart';
import '../order_detail_controller.dart';

class SerigrafiaPanel extends StatefulWidget {
  const SerigrafiaPanel({super.key, required this.controller});

  final OrderDetailController controller;

  @override
  State<SerigrafiaPanel> createState() => _SerigrafiaPanelState();
}

class _SerigrafiaPanelState extends State<SerigrafiaPanel> {
  int _currentStep = 1;

  // Phase 1: Standard
  List<SerigrafiaStandard> _standards = [];
  SerigrafiaStandard? _selectedStandard;

  // Phase 2: Excel
  excel_pkg.Sheet? _firstSheet;
  excel_pkg.Excel? _excel;
  List<String> _excelHeaders = [];
  bool _loadingExcel = false;
  String? _selectedFileName;
  String? _selectedFilePath;

  // Phase 3: Mapping & Filtering
  Map<String, String> _variableToColumnMapping = {};
  int? _startCiFilter;
  int? _endCiFilter;
  final TextEditingController _startCiController = TextEditingController();
  final TextEditingController _endCiController = TextEditingController();

  // Phase 4: Execution
  int _currentRowIndex = 1;
  bool _printing = false;
  List<Map<String, dynamic>> _registries = [];

  // CI Inventory
  bool _requiresCI = false;
  String? _currentCiCode;
  bool _fetchingCI = false;

  bool _isUsingExistingRegistry = false;
  final Map<String, Set<int>> _approvedLengthsByVariable = {};

  final FocusNode _scanFocusNode = FocusNode();
  final TextEditingController _scanController = TextEditingController();

  SerigrafiaService get _svc => SerigrafiaService.instance;

  int? get _idnbr =>
      widget.controller.detail?.agentOrder.idnbr;

  @override
  void initState() {
    super.initState();
    _loadStandards();
  }

  @override
  void dispose() {
    _startCiController.dispose();
    _endCiController.dispose();
    _scanFocusNode.dispose();
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _loadStandards() async {
    try {
      final list = await _svc.getStandards();
      if (mounted) setState(() => _standards = list);
    } catch (_) {}
  }

  Future<void> _loadExcel(
    String filePath,
    String fileName,
  ) async {
    setState(() {
      _loadingExcel = true;
      _excel = null;
      _firstSheet = null;
      _excelHeaders = [];
      _approvedLengthsByVariable.clear();
    });
    try {
      final normalizedPath = filePath.replaceAll('\\', '/');
      final doc = await _svc.downloadAndParseExcel(normalizedPath);
      if (doc != null && mounted) {
        final sheet =
            doc.sheets.isNotEmpty ? doc.sheets.values.first : null;
        setState(() {
          _excel = doc;
          _firstSheet = sheet;
          _excelHeaders = doc.sheets.isNotEmpty
              ? _svc.getExcelHeaders(doc)
              : [];
          _selectedFileName = fileName;
          _selectedFilePath = filePath;
          _currentStep = 3;
          _currentCiCode = null;
        });
      } else if (mounted) {
        _showSnack(
          'No se pudo procesar el archivo Excel. Verifica que no esté dañado.',
          color: Colors.orange,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Error al descargar el archivo: $e', color: Colors.red);
      }
    }
    if (mounted) setState(() => _loadingExcel = false);
  }

  List<String> get _allVariables {
    final vars = _selectedStandard?.variables ?? [];
    final upper = vars.map((v) => v.toUpperCase()).toSet();
    final hasCiLike =
        upper.contains('CI') || upper.contains('CI_CODE');
    if (_requiresCI && !hasCiLike) return [...vars, 'CI_CODE'];
    return vars;
  }

  Future<void> _fetchNextCI() async {
    setState(() => _fetchingCI = true);
    try {
      final code = await _svc.getNextInventoryCode();
      if (mounted) {
        setState(() {
          _currentCiCode = code;
          final colName = _variableToColumnMapping['CI_CODE'];
          final colIdx = _excelHeaders.indexOf(colName ?? '');
          if (colIdx != -1 && _currentCiCode != null && _firstSheet != null) {
            _firstSheet!.updateCell(
              excel_pkg.CellIndex.indexByColumnRow(
                  columnIndex: colIdx, rowIndex: _currentRowIndex),
              excel_pkg.TextCellValue(_currentCiCode!),
            );
          }
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _fetchingCI = false);
  }

  void _startExecution() {
    if (_excel == null || _selectedStandard == null) return;
    if (_allVariables.isEmpty) {
      _showSnack(
        'El estándar seleccionado no tiene variables configuradas.',
        color: Colors.orange,
      );
      return;
    }
    for (final v in _allVariables) {
      final colName = _variableToColumnMapping[v];
      if (colName == null ||
          colName.isEmpty ||
          !_excelHeaders.contains(colName)) {
        _showSnack('Falta mapear o es inválida la variable $v');
        return;
      }
    }
    setState(() => _currentStep = 4);
    _syncExcelWithDatabase();
  }

  Future<void> _saveAndUploadToServer({bool silent = false}) async {
    if (_excel == null) return;
    final idnbr = _idnbr;
    if (idnbr == null) return;
    try {
      final bytes = _excel!.encode();
      if (bytes != null) {
        final originalName = _selectedFileName ?? 'serigrafia.xlsx';
        final targetName = 'SERIGRAFIA_CORREGIDO_$originalName';
        final ok = await _svc.uploadExcel(
            idnbr, Uint8List.fromList(bytes), targetName);
        if (!silent && mounted) {
          if (ok) {
            _showSnack('Excel sincronizado y guardado en Archivos',
                color: Colors.green);
            widget.controller.load();
          } else {
            _showSnack('Error al guardar Excel', color: Colors.red);
          }
        }
      }
    } catch (e) {
      if (!silent) debugPrint('_saveAndUploadToServer: $e');
    }
  }

  Future<void> _syncExcelWithDatabase() async {
    if (_excel == null) return;
    final idnbr = _idnbr;
    if (idnbr == null) return;

    final registries = await _svc.getRegistries(
      idnbr,
      labelName: _selectedStandard!.name,
      includeProject: true,
    );
    _registries = registries;

    if (registries.isEmpty) {
      _advanceToNextEmptyRow();
      return;
    }

    setState(() {
      final sheet = _firstSheet;
      if (sheet == null) return;

      for (int i = 1; i < sheet.maxRows; i++) {
        final row = sheet.rows[i];
        Map<String, dynamic>? match;
        const uniqueKeys = ['CI', 'CI_CODE', 'SERIAL'];

        for (final v in _allVariables) {
          if (!uniqueKeys.contains(v.toUpperCase().trim())) continue;
          final targetHeader =
              _variableToColumnMapping[v]?.toUpperCase().trim() ?? '';
          if (targetHeader.isEmpty) continue;

          int colIdx = -1;
          for (int k = 0; k < _excelHeaders.length; k++) {
            if (_excelHeaders[k].toUpperCase().trim() == targetHeader) {
              colIdx = k;
              break;
            }
          }

          if (colIdx != -1) {
            final excelVal = row.length > colIdx
                ? row[colIdx]?.value?.toString().trim() ?? ''
                : '';
            if (excelVal.isNotEmpty &&
                excelVal.toLowerCase() != 'null') {
              match = registries.where((r) {
                final data = r['data'] as Map;
                final regCi =
                    (data['CI'] ?? data['CI_CODE'])?.toString();
                final regSerial = data['SERIAL']?.toString();
                return regCi == excelVal || regSerial == excelVal;
              }).firstOrNull;
              if (match != null) break;
            }
          }
        }

        if (match != null) {
          final data = match['data'] as Map;
          for (final v in _allVariables) {
            final targetHeader =
                _variableToColumnMapping[v]?.toUpperCase().trim() ?? '';
            if (targetHeader.isEmpty) continue;
            int colIdx = -1;
            for (int k = 0; k < _excelHeaders.length; k++) {
              if (_excelHeaders[k].toUpperCase().trim() == targetHeader) {
                colIdx = k;
                break;
              }
            }
            if (colIdx != -1) {
              String? canonicalVal;
              final upperV = v.toUpperCase();
              if (upperV == 'CI' || upperV == 'CI_CODE') {
                canonicalVal =
                    (data['CI'] ?? data['CI_CODE'])?.toString();
              } else if (upperV == 'SERIAL') {
                canonicalVal = data['SERIAL']?.toString();
              } else {
                data.forEach((rk, rv) {
                  if (rk.toString().toUpperCase() == upperV) {
                    canonicalVal = rv?.toString();
                  }
                });
              }
              if (canonicalVal != null) {
                final currentVal = row.length > colIdx
                    ? row[colIdx]?.value?.toString().trim() ?? ''
                    : '';
                if (canonicalVal != currentVal) {
                  sheet.updateCell(
                    excel_pkg.CellIndex.indexByColumnRow(
                        columnIndex: colIdx, rowIndex: i),
                    excel_pkg.TextCellValue(canonicalVal!),
                  );
                }
              }
            }
          }
        }
      }
    });

    _saveAndUploadToServer(silent: true);
    _advanceToNextEmptyRow();
  }

  void _advanceToNextEmptyRow() {
    if (_excel == null || _selectedStandard == null) return;
    final sheet = _firstSheet;
    if (sheet == null) return;

    final rows = sheet.rows;
    final maxRows = sheet.maxRows;

    final colIndices = <String, int>{};
    for (final v in _allVariables) {
      final targetHeader =
          _variableToColumnMapping[v]?.toUpperCase().trim() ?? '';
      int foundIdx = -1;
      if (targetHeader.isNotEmpty) {
        for (int k = 0; k < _excelHeaders.length; k++) {
          if (_excelHeaders[k].toUpperCase().trim() == targetHeader) {
            foundIdx = k;
            break;
          }
        }
      }
      colIndices[v] = foundIdx;
    }

    for (int i = 1; i < maxRows; i++) {
      if (_startCiFilter != null || _endCiFilter != null) {
        int? rowCi;
        for (final v in _allVariables) {
          if (v.toUpperCase() == 'CI' || v.toUpperCase() == 'CI_CODE') {
            final colIdx = colIndices[v] ?? -1;
            if (colIdx != -1) {
              final cell = sheet.cell(
                excel_pkg.CellIndex.indexByColumnRow(
                    columnIndex: colIdx, rowIndex: i),
              );
              final val = cell.value?.toString() ?? '';
              rowCi = int.tryParse(
                  val.replaceAll(RegExp(r'[^0-9]'), ''));
              break;
            }
          }
        }
        if (rowCi != null) {
          if (_startCiFilter != null && rowCi < _startCiFilter!) {
            continue;
          }
          if (_endCiFilter != null && rowCi > _endCiFilter!) continue;
        } else {
          continue;
        }
      }

      if (i >= rows.length) {
        setState(() {
          _currentRowIndex = i;
          _currentCiCode = null;
        });
        if (_requiresCI) _fetchNextCI();
        return;
      }

      final row = rows[i];
      bool allFilled = true;

      for (final variableName in _allVariables) {
        final colIndex = colIndices[variableName] ?? -1;
        if (colIndex != -1) {
          final cell = sheet.cell(
            excel_pkg.CellIndex.indexByColumnRow(
                columnIndex: colIndex, rowIndex: i),
          );
          final cellValue = cell.value?.toString().trim() ?? '';
          if (cellValue.isEmpty ||
              cellValue.toLowerCase() == 'null' ||
              cellValue.toLowerCase() == 'undefined') {
            allFilled = false;
            break;
          }
        }
      }

      if (!allFilled) {
        String? existingCi;
        for (final v in _allVariables) {
          if (v.toUpperCase() == 'CI' || v.toUpperCase() == 'CI_CODE') {
            final cIdx = colIndices[v] ?? -1;
            if (cIdx != -1) {
              existingCi = row.length > cIdx
                  ? row[cIdx]?.value?.toString().trim() ?? ''
                  : '';
            }
          }
        }
        setState(() {
          _currentRowIndex = i;
          _currentCiCode =
              (existingCi?.isNotEmpty == true &&
                      existingCi?.toLowerCase() != 'null')
                  ? existingCi
                  : null;
        });
        if (_requiresCI && _currentCiCode == null) _fetchNextCI();
        return;
      }
    }

    _showSnack('Todas las filas están completas');
  }

  void _jumpToNextGap() {
    if (_excel == null || _firstSheet == null) return;
    final sheet = _firstSheet!;

    int ciIdx = -1;
    int serialIdx = -1;

    for (final v in _allVariables) {
      final target =
          _variableToColumnMapping[v]?.toUpperCase().trim() ?? '';
      if (target.isEmpty) continue;
      for (int k = 0; k < _excelHeaders.length; k++) {
        if (_excelHeaders[k].toUpperCase().trim() == target) {
          if (v.toUpperCase() == 'CI' || v.toUpperCase() == 'CI_CODE') {
            ciIdx = k;
          }
          if (v.toUpperCase() == 'SERIAL') serialIdx = k;
        }
      }
    }

    if (ciIdx == -1 || serialIdx == -1) {
      _showSnack('Falta mapear CI o SERIAL para buscar huecos',
          color: Colors.orange);
      return;
    }

    for (int i = 1; i < sheet.maxRows; i++) {
      if (_startCiFilter != null || _endCiFilter != null) {
        final ciCell = sheet.cell(
          excel_pkg.CellIndex.indexByColumnRow(
              columnIndex: ciIdx, rowIndex: i),
        );
        final val = ciCell.value?.toString() ?? '';
        final numeric = int.tryParse(
            val.replaceAll(RegExp(r'[^0-9]'), ''));
        if (numeric != null) {
          if (_startCiFilter != null && numeric < _startCiFilter!) {
            continue;
          }
          if (_endCiFilter != null && numeric > _endCiFilter!) continue;
        } else {
          continue;
        }
      }

      final ciVal = sheet
              .cell(excel_pkg.CellIndex.indexByColumnRow(
                  columnIndex: ciIdx, rowIndex: i))
              .value
              ?.toString()
              .trim() ??
          '';
      final serialVal = sheet
              .cell(excel_pkg.CellIndex.indexByColumnRow(
                  columnIndex: serialIdx, rowIndex: i))
              .value
              ?.toString()
              .trim() ??
          '';

      if (ciVal.isNotEmpty &&
          ciVal.toLowerCase() != 'null' &&
          (serialVal.isEmpty ||
              serialVal.toLowerCase() == 'null' ||
              serialVal.toLowerCase() == 'undefined')) {
        setState(() => _currentRowIndex = i);
        _showSnack('Saltando al hueco en Fila ${i + 1} (CI: $ciVal)',
            color: Colors.cyan);
        return;
      }
    }

    _showSnack('No se encontraron más huecos en el rango',
        color: Colors.green);
  }

  void _autoDetectCiRange(String colName) {
    if (_excel == null || _firstSheet == null) return;
    final colIdx = _excelHeaders.indexOf(colName);
    if (colIdx == -1) return;

    final sheet = _firstSheet!;
    final List<int> candidates = [];

    for (int i = 1; i < sheet.maxRows; i++) {
      final cell = sheet.cell(
        excel_pkg.CellIndex.indexByColumnRow(
            columnIndex: colIdx, rowIndex: i),
      );
      final val = cell.value?.toString() ?? '';
      final digitsOnly = val.replaceAll(RegExp(r'[^0-9]'), '');
      if (digitsOnly.isEmpty) continue;
      final numeric = int.tryParse(digitsOnly);
      if (numeric != null &&
          digitsOnly.length >= 5 &&
          digitsOnly.length <= 8) {
        candidates.add(numeric);
      }
    }

    if (candidates.isNotEmpty) {
      final Map<String, List<int>> groups = {};
      for (final c in candidates) {
        final prefix = c.toString().substring(0, 2);
        groups.putIfAbsent(prefix, () => []).add(c);
      }
      String? winnerPrefix;
      int maxCount = 0;
      groups.forEach((prefix, list) {
        if (list.length > maxCount) {
          maxCount = list.length;
          winnerPrefix = prefix;
        }
      });
      if (winnerPrefix != null) {
        final winnerList = groups[winnerPrefix]!..sort();
        final minCi = winnerList.first;
        final maxCi = winnerList.last;
        setState(() {
          _startCiFilter = minCi;
          _endCiFilter = maxCi;
          _startCiController.text = minCi.toString();
          _endCiController.text = maxCi.toString();
        });
      }
    } else {
      setState(() {
        _startCiController.clear();
        _endCiController.clear();
        _startCiFilter = null;
        _endCiFilter = null;
      });
    }
  }

  Map<String, int>? _buildCiIntervalSummary() {
    if (_excel == null || _firstSheet == null) return null;
    if (_startCiFilter == null || _endCiFilter == null) return null;
    final start = _startCiFilter!;
    final end = _endCiFilter!;
    if (end < start) return null;

    String? ciVariable;
    for (final candidate in ['CI', 'CI_CODE']) {
      final mapped = _variableToColumnMapping[candidate];
      if (mapped != null && mapped.isNotEmpty) {
        ciVariable = candidate;
        break;
      }
    }
    if (ciVariable == null) return null;
    final colName = _variableToColumnMapping[ciVariable];
    if (colName == null || colName.isEmpty) return null;
    final colIdx = _excelHeaders.indexOf(colName);
    if (colIdx == -1) return null;

    final sheet = _firstSheet!;
    final found = <int>{};
    for (int i = 1; i < sheet.maxRows; i++) {
      final cell = sheet.cell(
        excel_pkg.CellIndex.indexByColumnRow(
            columnIndex: colIdx, rowIndex: i),
      );
      final raw = cell.value?.toString() ?? '';
      final digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');
      final numeric = int.tryParse(digitsOnly);
      if (numeric == null) continue;
      if (numeric < start || numeric > end) continue;
      found.add(numeric);
    }

    final total = end - start + 1;
    final foundCount = found.length;
    final missing = total - foundCount;
    return {
      'total': total,
      'found': foundCount,
      'missing': missing < 0 ? 0 : missing,
    };
  }

  Future<void> _updateCell(String variable, String value) async {
    final sheet = _firstSheet;
    if (sheet == null) return;
    final colName = _variableToColumnMapping[variable];
    if (colName == null) return;
    final colIdx = _excelHeaders.indexOf(colName);
    if (colIdx == -1) return;

    setState(() {
      final currentVal = sheet.rows[_currentRowIndex].length > colIdx
          ? sheet.rows[_currentRowIndex][colIdx]
                  ?.value
                  ?.toString()
                  .trim() ??
              ''
          : '';
      if (currentVal != value) {
        sheet.updateCell(
          excel_pkg.CellIndex.indexByColumnRow(
              columnIndex: colIdx, rowIndex: _currentRowIndex),
          excel_pkg.TextCellValue(value),
        );
      }
    });
    await _checkCompletionAndSubmit();
  }

  Future<void> _checkCompletionAndSubmit() async {
    if (_excel == null || _firstSheet == null) return;
    final sheet = _firstSheet!;
    final row = sheet.rows[_currentRowIndex];
    final values = <String, String>{};
    bool isComplete = true;

    for (final v in _allVariables) {
      final targetHeader =
          _variableToColumnMapping[v]?.toUpperCase().trim() ?? '';
      int colIdx = -1;
      for (int k = 0; k < _excelHeaders.length; k++) {
        if (_excelHeaders[k].toUpperCase().trim() == targetHeader) {
          colIdx = k;
          break;
        }
      }
      if (colIdx != -1) {
        final val = row.length > colIdx
            ? row[colIdx]?.value?.toString().trim() ?? ''
            : '';
        if (val.isEmpty ||
            val.toLowerCase() == 'null' ||
            val.toLowerCase() == 'undefined') {
          isComplete = false;
          break;
        }
        values[v] = val;
      } else {
        isComplete = false;
        break;
      }
    }

    if (isComplete && !_printing) {
      await _printAndSubmit(values);
    }
  }

  Future<void> _printAndSubmit(Map<String, String> values) async {
    if (_selectedStandard == null || _printing) return;
    final idnbr = _idnbr;
    if (idnbr == null) return;

    setState(() => _printing = true);
    try {
      final wasUsingRegistry = _isUsingExistingRegistry;

      if (!wasUsingRegistry) {
        final currentUser =
            AuthService.instance.currentUser?.username ?? 'unknown';
        final ok = await _svc.saveRegistry(
          idnbr,
          _selectedStandard!.name,
          values,
          operator: currentUser,
        );
        if (!ok) {
          if (mounted) {
            _showSnack(
              'ERROR CRÍTICO: No se pudo guardar en base de datos. Impresión cancelada.',
              color: Colors.red,
              duration: const Duration(seconds: 5),
            );
          }
          setState(() => _printing = false);
          return;
        }
      }

      final printOk = await _svc
          .printLabel(_selectedStandard!, values)
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () => false,
          );

      if (printOk && mounted) {
        final sheet = _firstSheet;
        if (sheet != null) {
          values.forEach((varName, value) {
            final colName = _variableToColumnMapping[varName];
            final colIdx = _excelHeaders.indexOf(colName ?? '');
            if (colIdx != -1) {
              final currentVal =
                  sheet.rows[_currentRowIndex].length > colIdx
                      ? sheet.rows[_currentRowIndex][colIdx]
                              ?.value
                              ?.toString()
                              .trim() ??
                          ''
                      : '';
              if (currentVal != value) {
                sheet.updateCell(
                  excel_pkg.CellIndex.indexByColumnRow(
                      columnIndex: colIdx, rowIndex: _currentRowIndex),
                  excel_pkg.TextCellValue(value),
                );
              }
            }
          });
        }
        _isUsingExistingRegistry = false;
        _advanceToNextEmptyRow();
        _saveAndUpload(silent: true);
        _saveAndUploadToServer(silent: true);
        if (mounted) {
          _showSnack(
              'Registro guardado e impresión enviada exitosamente',
              color: Colors.green);
        }
      } else if (mounted) {
        if (wasUsingRegistry) {
          _showSnack(
            'ERROR DE IMPRESIÓN. Pulsa REIMPRIMIR si es necesario.',
            color: Colors.redAccent,
            duration: const Duration(seconds: 8),
          );
        } else {
          _showSnack(
            'Registro guardado, pero ERROR DE IMPRESIÓN. Pulsa REIMPRIMIR si es necesario.',
            color: Colors.orange,
            duration: const Duration(seconds: 8),
          );
          _isUsingExistingRegistry = false;
          _advanceToNextEmptyRow();
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Error inesperado: $e',
            color: Colors.red,
            duration: const Duration(seconds: 4));
      }
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  Uint8List? _safeEncode() {
    if (_excel == null) return null;
    try {
      final newExcel = excel_pkg.Excel.createExcel();
      final defaultSheetName = newExcel.sheets.keys.first;
      for (final sheetName in _excel!.sheets.keys) {
        final oldSheet = _excel!.sheets[sheetName]!;
        excel_pkg.Sheet newSheet;
        if (sheetName == _excel!.sheets.keys.first) {
          newExcel.rename(defaultSheetName, sheetName);
          newSheet = newExcel[sheetName];
        } else {
          newSheet = newExcel[sheetName];
        }
        for (int r = 0; r < oldSheet.maxRows; r++) {
          final row = oldSheet.rows[r];
          newSheet.appendRow(row.map((c) => c?.value).toList());
        }
        final widths = oldSheet.getColumnWidths;
        for (final colIdx in widths.keys) {
          newSheet.setColumnWidth(colIdx, widths[colIdx]!);
        }
      }
      final encoded = newExcel.encode();
      return encoded != null ? Uint8List.fromList(encoded) : null;
    } catch (e) {
      debugPrint('_safeEncode fallback: $e');
      final encoded = _excel!.encode();
      return encoded != null ? Uint8List.fromList(encoded) : null;
    }
  }

  Future<void> _saveAndUpload({bool silent = false}) async {
    if (_excel == null || _selectedFilePath == null) return;
    final idnbr = _idnbr;
    if (idnbr == null) return;

    if (!silent) setState(() => _printing = true);
    try {
      final bytes = _safeEncode();
      if (bytes != null) {
        String fileName = _selectedFileName ?? 'serigrafia.xlsx';
        if (fileName.toLowerCase().endsWith('.xls')) {
          fileName =
              '${fileName.substring(0, fileName.length - 4)}.xlsx';
        }
        final ok = await _svc.uploadExcel(idnbr, bytes, fileName);
        if (ok && !silent && mounted) {
          _showSnack('Excel actualizado y subido exitosamente',
              color: Colors.green);
          widget.controller.load();
        }
      }
    } catch (_) {}
    if (!silent && mounted) setState(() => _printing = false);
  }

  Future<void> _createExcelFromRegistries() async {
    if (_selectedStandard == null) return;
    final idnbr = _idnbr;
    if (idnbr == null) return;

    setState(() => _loadingExcel = true);
    try {
      final registries = await _svc.getRegistries(
        idnbr,
        labelName: _selectedStandard?.name,
        includeProject: true,
      );
      if (registries.isEmpty) {
        if (mounted) {
          _showSnack(
            'No hay coincidencias registradas en la base de datos para esta orden/estándar.',
            color: Colors.orange,
          );
        }
        setState(() => _loadingExcel = false);
        return;
      }

      final headers = _allVariables;
      if (headers.isEmpty) {
        if (mounted) {
          _showSnack(
            'El estándar seleccionado no tiene variables.',
            color: Colors.orange,
          );
        }
        setState(() => _loadingExcel = false);
        return;
      }

      final newExcel = excel_pkg.Excel.createExcel();
      final sheetName = newExcel.sheets.keys.first;
      final sheet = newExcel[sheetName];

      sheet.appendRow(
          headers.map((h) => excel_pkg.TextCellValue(h)).toList());

      for (final r in registries) {
        final data = r['data'] as Map?;
        final List<excel_pkg.CellValue?> rowValues = [];
        for (final h in headers) {
          String? val;
          if (data != null) {
            data.forEach((k, v) {
              if (k.toString().toUpperCase() == h.toUpperCase()) {
                val = v.toString();
              }
            });
            if (val == null) {
              if (h.toUpperCase() == 'CI' ||
                  h.toUpperCase() == 'CI_CODE') {
                val = r['ci']?.toString();
              } else if (h.toUpperCase() == 'SERIAL') {
                val = r['serial']?.toString();
              }
            }
          }
          rowValues.add(excel_pkg.TextCellValue(val ?? ''));
        }
        sheet.appendRow(rowValues);
      }

      final bytes = newExcel.encode();
      if (bytes == null) throw Exception('Error al codificar el Excel.');

      final detail = widget.controller.detail;
      final orderNbr = detail?.agentOrder.orderNbr
              .replaceAll(RegExp(r'[^\w\-]'), '_') ??
          idnbr.toString();
      final fileName = 'Serigrafia_Manual_$orderNbr.xlsx';

      final ok = await _svc.uploadExcel(
          idnbr, Uint8List.fromList(bytes), fileName);
      if (ok && mounted) {
        _showSnack(
            'Archivo Excel creado y guardado en archivos.',
            color: Colors.green);
        widget.controller.load();
        setState(() {
          _excel = newExcel;
          _firstSheet =
              newExcel.sheets.isNotEmpty ? newExcel.sheets.values.first : null;
          _excelHeaders = headers;
          if (_currentStep < 4) _currentStep = 3;
          _currentCiCode = null;
        });
      } else if (mounted) {
        throw Exception('Error desconocido al subir el archivo.');
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Error al crear Excel: $e', color: Colors.red);
      }
    }
    if (mounted) setState(() => _loadingExcel = false);
  }

  bool _checkForDuplicate(String variable, String value) {
    if (_excel == null || _firstSheet == null) return false;
    final sheet = _firstSheet!;
    final targetHeader =
        _variableToColumnMapping[variable]?.toUpperCase().trim() ?? '';
    int colIdx = -1;
    for (int k = 0; k < _excelHeaders.length; k++) {
      if (_excelHeaders[k].toUpperCase().trim() == targetHeader) {
        colIdx = k;
        break;
      }
    }
    if (colIdx != -1) {
      for (int i = 1; i < sheet.maxRows; i++) {
        if (i == _currentRowIndex) continue;
        final row = sheet.rows[i];
        if (row.length > colIdx) {
          final cellVal = row[colIdx]?.value?.toString().trim();
          if (cellVal != null &&
              cellVal.isNotEmpty &&
              cellVal.toLowerCase() != 'null' &&
              cellVal == value) return true;
        }
      }
    }
    for (final r in _registries) {
      final data =
          r['data'] is Map ? r['data'] as Map : <dynamic, dynamic>{};
      for (final entry in data.entries) {
        final rk = entry.key.toString().toUpperCase().trim();
        final rv = entry.value?.toString().trim();
        if (rk == variable.toUpperCase().trim()) {
          if (rv != null && rv.isNotEmpty && rv == value) return true;
        }
      }
    }
    return false;
  }

  int? _getExpectedLength(String variable) {
    if (_excel == null || _firstSheet == null) return null;
    final sheet = _firstSheet!;
    final colName = _variableToColumnMapping[variable];
    final colIdx = _excelHeaders.indexOf(colName ?? '');
    if (colIdx == -1) return null;
    for (int i = 1; i < sheet.maxRows; i++) {
      final row = sheet.rows[i];
      if (row.length > colIdx) {
        final val =
            row[colIdx]?.value?.toString().trim() ?? '';
        if (val.isNotEmpty) return val.length;
      }
    }
    return null;
  }

  String _lengthKey(String variable) => variable.toUpperCase().trim();

  bool _isApprovedLength(String variable, int length) =>
      _approvedLengthsByVariable[_lengthKey(variable)]
          ?.contains(length) ??
      false;

  void _approveLength(String variable, int length) {
    _approvedLengthsByVariable
        .putIfAbsent(_lengthKey(variable), () => <int>{})
        .add(length);
  }

  Future<bool> _showValidationWarning(
      String title, String message) async {
    final ct = context.ct;
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: ct.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.orange, size: 28),
                const SizedBox(width: 12),
                Text(title,
                    style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            ),
            content: Text(message,
                style:
                    TextStyle(color: ct.textPrimary, fontSize: 14)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('CANCELAR',
                    style: TextStyle(color: ct.textHint)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.black,
                  textStyle:
                      const TextStyle(fontWeight: FontWeight.bold),
                ),
                child: const Text('CONFIRMAR REGISTRO'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _showRegistryManager({String? initialQuery}) async {
    final idnbr = _idnbr;
    if (idnbr == null) return;
    final registries = await _svc.getRegistries(
      idnbr,
      labelName: _selectedStandard!.name,
      includeProject: true,
    );

    final searchCtrl =
        TextEditingController(text: initialQuery ?? '');
    String searchQuery = initialQuery ?? '';

    if (!mounted) return;
    final ct = context.ct;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final filtered = registries.where((r) {
            final dataStr =
                (r['data'] ?? {}).toString().toLowerCase();
            final ci = (r['ci'] ?? '').toString().toLowerCase();
            final serial =
                (r['serial'] ?? '').toString().toLowerCase();
            final op =
                (r['operator'] ?? '').toString().toLowerCase();
            final q = searchQuery.toLowerCase();
            return dataStr.contains(q) ||
                ci.contains(q) ||
                serial.contains(q) ||
                op.contains(q);
          }).toList();

          return AlertDialog(
            backgroundColor: ct.surface,
            title: Row(
              children: [
                Icon(Icons.history_rounded,
                    color: CobaltColors.cobaltLight),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Historial de Registros',
                      style: TextStyle(
                          color: CobaltColors.cobaltLight)),
                ),
                SizedBox(
                  width: 250,
                  child: TextField(
                    controller: searchCtrl,
                    style: TextStyle(color: ct.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Buscar CI, Serial...',
                      hintStyle:
                          TextStyle(color: ct.textHint),
                      prefixIcon: const Icon(Icons.search,
                          size: 16),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,
                                  size: 16),
                              onPressed: () {
                                searchCtrl.clear();
                                setDialogState(
                                    () => searchQuery = '');
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (v) =>
                        setDialogState(() => searchQuery = v),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 700,
              height: 500,
              child: filtered.isEmpty
                  ? Center(
                      child: Text('No hay registros aún',
                          style: TextStyle(
                              color: ct.textHint)))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final r = filtered[index];
                        final data = r['data'] as Map;
                        final time = r['created_at']
                            .toString()
                            .split('T')
                            .first;
                        return Card(
                          color: ct.surfaceElevated,
                          margin:
                              const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(8)),
                          child: ListTile(
                            leading: Icon(
                                Icons.inventory_2_outlined,
                                color: CobaltColors.cobaltLight,
                                size: 24),
                            title: Text(
                              data['CI'] ??
                                  data['CI_CODE'] ??
                                  'Sin CI',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: ct.textPrimary),
                            ),
                            subtitle: Text(
                              '${data['MAC'] ?? ''} | ${data['SERIAL'] ?? data['Serial'] ?? ''}\n$time - ${r['operator']}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: ct.textHint),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                      Icons.edit_note_rounded,
                                      color: CobaltColors
                                          .cobaltLight,
                                      size: 22),
                                  tooltip: 'Editar Registro',
                                  onPressed: () =>
                                      _showEditRegistryDialog(r)
                                          .then((updated) async {
                                    if (updated != null) {
                                      final refreshed =
                                          await _svc.getRegistries(
                                              idnbr);
                                      setDialogState(() {
                                        registries.clear();
                                        registries
                                            .addAll(refreshed);
                                      });
                                    }
                                  }),
                                ),
                                IconButton(
                                  icon: const Icon(
                                      Icons.delete_sweep_rounded,
                                      color: Colors.redAccent,
                                      size: 22),
                                  tooltip: 'Eliminar Registro',
                                  onPressed: () async {
                                    final ok =
                                        await _showConfirmDelete(
                                            r['id'] as int);
                                    if (ok) {
                                      final refreshed =
                                          await _svc.getRegistries(
                                              idnbr);
                                      setDialogState(() {
                                        registries.clear();
                                        registries
                                            .addAll(refreshed);
                                      });
                                    }
                                  },
                                ),
                                const VerticalDivider(
                                    width: 20,
                                    indent: 10,
                                    endIndent: 10),
                                ElevatedButton(
                                  onPressed: () {
                                    _applyRegistryToExcel(r);
                                    Navigator.pop(ctx);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        CobaltColors.cobaltLight
                                            .withValues(alpha: 0.12),
                                    foregroundColor:
                                        CobaltColors.cobaltLight,
                                    elevation: 0,
                                  ),
                                  child: const Text('USAR EN EXCEL'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('CERRAR')),
            ],
          );
        },
      ),
    );
  }

  Future<Map<String, String>?> _showEditRegistryDialog(
      Map<String, dynamic> registry) async {
    final ct = context.ct;
    final rawData = registry['data'] as Map;
    final controllers = <String, TextEditingController>{};
    rawData.forEach((k, v) {
      controllers[k.toString()] =
          TextEditingController(text: v.toString());
    });

    final res = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ct.surface,
        title: Text('Editar Datos del Registro',
            style:
                TextStyle(color: CobaltColors.cobaltLight)),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    'Modifica los valores escaneados para este registro:',
                    style: TextStyle(
                        fontSize: 12, color: ct.textHint)),
                const SizedBox(height: 16),
                ...controllers.entries.map((e) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: e.value,
                        style: TextStyle(color: ct.textPrimary),
                        decoration: InputDecoration(
                          labelText: e.key,
                          border: const OutlineInputBorder(),
                          contentPadding:
                              const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCELAR')),
          FilledButton(
            onPressed: () async {
              final nav = Navigator.of(ctx);
              final newData = <String, String>{};
              controllers.forEach(
                  (k, v) => newData[k] = v.text.trim());
              final ok = await _svc.updateRegistry(
                  registry['id'] as int, {
                'data': newData,
                'ci': newData['CI'] ?? newData['CI_CODE'],
                'serial':
                    newData['SERIAL'] ?? newData['Serial'],
              });
              if (ok) {
                if (mounted) nav.pop(newData);
              } else {
                if (mounted) {
                  _showSnack('Error al actualizar registro',
                      color: Colors.red);
                }
              }
            },
            child: const Text('GUARDAR CAMBIOS'),
          ),
        ],
      ),
    );
    controllers.forEach((k, v) => v.dispose());
    return res;
  }

  Future<bool> _showConfirmDelete(int id) async {
    final ct = context.ct;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ct.surface,
        title: Text('Eliminar Registro Histórico',
            style: TextStyle(color: ct.textPrimary)),
        content: Text('¿Estás seguro de que deseas eliminar este registro?',
            style: TextStyle(color: ct.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCELAR')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ELIMINAR',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok == true) {
      return await _svc.deleteRegistry(id);
    }
    return false;
  }

  void _applyRegistryToExcel(Map<String, dynamic> registry) {
    setState(() {
      final data = registry['data'] as Map;
      final sheet = _firstSheet;
      if (sheet == null) return;
      _isUsingExistingRegistry = true;

      for (final variable in _allVariables) {
        String? value;
        data.forEach((k, v) {
          if (k.toString().toUpperCase() == variable.toUpperCase()) {
            value = v.toString();
          }
        });
        if (value != null) {
          final colIdx = _excelHeaders
              .indexOf(_variableToColumnMapping[variable] ?? '');
          if (colIdx != -1) {
            final currentVal =
                sheet.rows[_currentRowIndex].length > colIdx
                    ? sheet.rows[_currentRowIndex][colIdx]
                            ?.value
                            ?.toString()
                            .trim() ??
                        ''
                    : '';
            if (currentVal != value) {
              sheet.updateCell(
                excel_pkg.CellIndex.indexByColumnRow(
                    columnIndex: colIdx,
                    rowIndex: _currentRowIndex),
                excel_pkg.TextCellValue(value!),
              );
            }
          }
        }
      }
    });
    _checkCompletionAndSubmit();
  }

  Future<void> _showReprintDialog() async {
    if (_selectedStandard == null) {
      _showSnack('Selecciona primero un estándar de etiqueta');
      return;
    }
    final idnbr = _idnbr;
    if (idnbr == null) return;

    final ct = context.ct;
    showDialog(
      context: context,
      builder: (ctx) {
        String searchQuery = '';
        List<Map<String, dynamic>>? registries;
        bool loading = true;
        String? errorMessage;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (loading &&
                registries == null &&
                errorMessage == null) {
              _svc
                  .getRegistries(
                idnbr,
                labelName: _selectedStandard?.name,
                includeProject: true,
              )
                  .then((results) {
                setDialogState(() {
                  registries = results;
                  loading = false;
                });
              }).catchError((err) {
                setDialogState(() {
                  errorMessage = err.toString();
                  loading = false;
                });
              });
            }

            final filtered = registries
                    ?.where((r) {
                      final dataStr =
                          jsonEncode(r['data']).toLowerCase();
                      return dataStr
                          .contains(searchQuery.toLowerCase());
                    })
                    .toList() ??
                [];

            return AlertDialog(
              backgroundColor: ct.surface,
              title: Row(
                children: [
                  Text('Reimpresión de Etiquetas',
                      style: TextStyle(
                          color: CobaltColors.cobaltLight)),
                  const Spacer(),
                  if (registries != null)
                    Text('${registries!.length} registros',
                        style: TextStyle(
                            fontSize: 10, color: ct.textHint)),
                ],
              ),
              content: SizedBox(
                width: 600,
                height: 500,
                child: Column(
                  children: [
                    Text('Orden ID: $idnbr',
                        style: TextStyle(
                            fontSize: 9, color: ct.textHint)),
                    const SizedBox(height: 8),
                    TextField(
                      autofocus: true,
                      style: TextStyle(color: ct.textPrimary),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search_rounded),
                        hintText:
                            'Buscar por CI, Serial o MAC...',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => setDialogState(
                          () => searchQuery = val),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: loading
                          ? Center(
                              child: CircularProgressIndicator(
                                  color: CobaltColors.cobaltLight))
                          : errorMessage != null
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                          Icons.error_outline,
                                          color: Colors.red,
                                          size: 48),
                                      const SizedBox(height: 16),
                                      Text('Error: $errorMessage',
                                          textAlign:
                                              TextAlign.center,
                                          style: const TextStyle(
                                              color: Colors.red)),
                                    ],
                                  ),
                                )
                              : filtered.isEmpty
                                  ? Center(
                                      child: Text(
                                          'No se encontraron registros',
                                          style: TextStyle(
                                              color: ct.textHint)))
                                  : ListView.builder(
                                      itemCount: filtered.length,
                                      itemBuilder:
                                          (context, index) {
                                        final r =
                                            filtered[index];
                                        final data =
                                            r['data'] as Map;
                                        final time = r[
                                                'created_at']
                                            .toString()
                                            .split('T')
                                            .first;
                                        final vars = data.entries
                                            .map((e) =>
                                                '${e.key}: ${e.value}')
                                            .join(' | ');
                                        return ListTile(
                                          title: Text(
                                            data['CI'] ??
                                                data['CI_CODE'] ??
                                                'Unidad #${r['id']}',
                                            style: TextStyle(
                                                fontWeight:
                                                    FontWeight
                                                        .bold,
                                                color:
                                                    ct.textPrimary),
                                          ),
                                          subtitle: Text(
                                            '$vars\n$time - ${r['operator']}',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color:
                                                    ct.textHint),
                                          ),
                                          isThreeLine: true,
                                          trailing: ElevatedButton
                                              .icon(
                                            onPressed: () {
                                              _handleReprint(r);
                                              Navigator.pop(ctx);
                                            },
                                            icon: const Icon(
                                                Icons.print_rounded,
                                                size: 16),
                                            label: const Text(
                                                'REIMPRIMIR'),
                                            style: ElevatedButton
                                                .styleFrom(
                                              backgroundColor:
                                                  CobaltColors
                                                      .cobalt,
                                              foregroundColor:
                                                  Colors.white,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleReprint(
      Map<String, dynamic> registry) async {
    if (_selectedStandard == null) return;
    final data = Map<String, String>.from(
      (registry['data'] as Map)
          .map((k, v) => MapEntry(k.toString(), v.toString())),
    );
    setState(() => _printing = true);
    try {
      final ok =
          await _svc.printLabel(_selectedStandard!, data);
      if (mounted) {
        if (ok) {
          _showSnack('Reimpresión enviada correctamente',
              color: Colors.green);
        } else {
          _showSnack('Error al enviar reimpresión',
              color: Colors.red);
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _printing = false);
  }

  void _showManualStandardDialog() {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final varCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Configurar Etiqueta Manual'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Nombre (ej: Xiaomi High)')),
            TextField(
                controller: urlCtrl,
                decoration:
                    const InputDecoration(labelText: 'URL de Impresión')),
            TextField(
                controller: varCtrl,
                decoration: const InputDecoration(
                    labelText:
                        'Variables (separadas por coma, ej: DSN,MAC)')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCELAR')),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty &&
                  urlCtrl.text.isNotEmpty) {
                final s = SerigrafiaStandard(
                  name: nameCtrl.text,
                  url: urlCtrl.text,
                  variables: varCtrl.text
                      .split(',')
                      .map((e) => e.trim().toUpperCase())
                      .where((e) => e.isNotEmpty)
                      .toList(),
                );
                setState(() {
                  _selectedStandard = s;
                  _currentStep = 2;
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('ACEPTAR'),
          ),
        ],
      ),
    );
  }

  void _showSnack(
    String msg, {
    Color? color,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      duration: duration,
    ));
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ct = context.ct;
    return Container(
      decoration: BoxDecoration(
        color: ct.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ct.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 650;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(ct, isCompact),
              Divider(height: 1, color: ct.border),
              Padding(
                padding:
                    EdgeInsets.all(isCompact ? 12 : 24),
                child: _buildStepContent(ct, isCompact),
              ),
              if (_currentStep > 1)
                _buildFooterActions(ct, isCompact),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(dynamic ct, bool isCompact) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 24, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.print_outlined,
              color: CobaltColors.cobaltLight, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isCompact ? 'SERIGRAFIADO' : 'FLUJO DE SERIGRAFIADO',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      fontSize: 13,
                      color: ct.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isCompact)
                  Text(
                    'Automatización Excel-Print-Scan',
                    style: TextStyle(
                        fontSize: 10, color: ct.textHint),
                  ),
              ],
            ),
          ),
          if (isCompact) ...[
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded,
                  color: CobaltColors.cobaltLight),
              onSelected: (value) {
                if (value == 'reprint') _showReprintDialog();
                if (value == 'repository') {
                  Navigator.pushNamed(
                          context, '/serigrafia/repository')
                      .then((_) => _loadStandards());
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                    value: 'reprint',
                    child: Row(children: [
                      Icon(Icons.history_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Reimprimir'),
                    ])),
                const PopupMenuItem(
                    value: 'repository',
                    child: Row(children: [
                      Icon(Icons.settings_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Configurar Repositorio'),
                    ])),
              ],
            ),
          ] else ...[
            TextButton.icon(
              onPressed: _showReprintDialog,
              icon: const Icon(Icons.history_rounded, size: 18),
              label: const Text('REIMPRIMIR',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                  foregroundColor: CobaltColors.cobaltLight,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16)),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.settings_outlined,
                  color: CobaltColors.cobaltLight, size: 22),
              tooltip: 'Gestionar Repositorio',
              onPressed: () =>
                  Navigator.pushNamed(
                          context, '/serigrafia/repository')
                      .then((_) => _loadStandards()),
            ),
          ],
          const SizedBox(width: 8),
          _buildStepIndicator(ct, isCompact),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(dynamic ct, bool isCompact) {
    if (isCompact) {
      return Text(
        '$_currentStep/4',
        style: TextStyle(
          color: CobaltColors.cobaltLight,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        final stepNum = index + 1;
        final isActive = stepNum == _currentStep;
        final isDone = stepNum < _currentStep;
        final color = isActive
            ? CobaltColors.cobaltLight
            : isDone
                ? CobaltColors.cobaltLight.withValues(alpha: 0.5)
                : ct.border;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (index > 0)
              Container(
                width: 20,
                height: 2,
                color: isDone
                    ? CobaltColors.cobaltLight.withValues(alpha: 0.5)
                    : ct.border,
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isActive ? 28 : 22,
              height: isActive ? 28 : 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? CobaltColors.cobalt
                    : isDone
                        ? CobaltColors.cobalt.withValues(alpha: 0.4)
                        : ct.surfaceElevated,
                border: Border.all(color: color, width: 2),
              ),
              child: Center(
                child: Text(
                  '$stepNum',
                  style: TextStyle(
                    fontSize: isActive ? 11 : 9,
                    fontWeight: FontWeight.bold,
                    color: isActive || isDone
                        ? Colors.white
                        : ct.textHint,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStepContent(dynamic ct, bool isCompact) {
    switch (_currentStep) {
      case 1:
        return _buildPhase1(ct, isCompact);
      case 2:
        return _buildPhase2(ct, isCompact);
      case 3:
        return _buildPhase3(ct, isCompact);
      case 4:
        return _buildPhase4(ct, isCompact);
      default:
        return const SizedBox();
    }
  }

  Widget _buildPhase1(dynamic ct, bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(isCompact ? 10 : 16),
          decoration: BoxDecoration(
            color:
                CobaltColors.cobaltLight.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color:
                    CobaltColors.cobaltLight.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CONFIGURACIÓN DEL FLUJO',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: CobaltColors.cobaltLight,
                    fontSize: 10,
                    letterSpacing: 1),
              ),
              SwitchListTile(
                contentPadding: isCompact
                    ? EdgeInsets.zero
                    : const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                title: Text(
                  '¿Requiere etiqueta de inventariado CI?',
                  style: TextStyle(
                      fontSize: isCompact ? 12 : 14,
                      fontWeight: FontWeight.bold,
                      color: ct.textPrimary),
                ),
                subtitle: Text(
                  'Genera y vincula automáticamente códigos de inventario de la base de datos',
                  style: TextStyle(
                      fontSize: isCompact ? 9 : 11,
                      color: ct.textHint),
                ),
                value: _requiresCI,
                activeThumbColor: CobaltColors.cobaltLight,
                onChanged: (val) =>
                    setState(() => _requiresCI = val),
              ),
            ],
          ),
        ),
        SizedBox(height: isCompact ? 16 : 24),
        Text(
          'SELECCIONA EL ESTÁNDAR DE ETIQUETA',
          style: TextStyle(
              fontWeight: FontWeight.w900,
              color: ct.textSecondary,
              fontSize: 10,
              letterSpacing: 1),
        ),
        const SizedBox(height: 12),
        ..._standards.map((s) => _buildStandardTile(ct, s, isCompact)),
        const SizedBox(height: 8),
        _buildManualStandardTile(ct, isCompact),
      ],
    );
  }

  Widget _buildStandardTile(
      dynamic ct, SerigrafiaStandard s, bool isCompact) {
    final isSelected = _selectedStandard == s;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedStandard = s;
        _currentStep = 2;
      }),
      child: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          decoration: BoxDecoration(
            color: isSelected
                ? CobaltColors.cobaltLight.withValues(alpha: 0.1)
                : ct.surfaceElevated,
            border: Border.all(
                color: isSelected
                    ? CobaltColors.cobaltLight
                    : ct.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.label_important_outline_rounded,
                  color: CobaltColors.cobaltLight, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isCompact ? 13 : 14,
                            color: ct.textPrimary)),
                    Text(s.variables.join(', '),
                        style: TextStyle(
                            fontSize: isCompact ? 10 : 12,
                            color: CobaltColors.cobaltLight)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: ct.textHint, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManualStandardTile(dynamic ct, bool isCompact) {
    return GestureDetector(
      onTap: _showManualStandardDialog,
      child: Container(
        padding: EdgeInsets.all(isCompact ? 12 : 16),
        decoration: BoxDecoration(
          color: ct.surfaceElevated,
          border: Border.all(color: ct.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.add_link_rounded,
                color: ct.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
                child: Text('Configurar Estándar Manual',
                    style: TextStyle(
                        color: ct.textSecondary,
                        fontSize: isCompact ? 12 : 14))),
            Icon(Icons.edit_note_rounded,
                color: ct.textHint, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPhase2(dynamic ct, bool isCompact) {
    final photos =
        widget.controller.detail?.photos ?? [];
    final excels = photos.where((p) =>
        p.fileName.toLowerCase().endsWith('.xlsx') ||
        p.fileName.toLowerCase().endsWith('.xls'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PASO 2: SELECCIONA EL EXCEL DE ARCHIVOS',
          style: TextStyle(
              fontWeight: FontWeight.w900,
              color: ct.textSecondary,
              fontSize: isCompact ? 10 : 11),
        ),
        const SizedBox(height: 16),
        if (_loadingExcel)
          Center(
              child: CircularProgressIndicator(
                  color: CobaltColors.cobaltLight)),
        if (!_loadingExcel && excels.isEmpty)
          Center(
              child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'No hay archivos Excel adjuntos en esta orden',
              textAlign: TextAlign.center,
              style: TextStyle(color: ct.textHint),
            ),
          )),
        if (!_loadingExcel)
          ...excels.map((p) => _buildExcelTile(ct, p)),
      ],
    );
  }

  Widget _buildExcelTile(dynamic ct, dynamic p) {
    final orderIdnbr =
        widget.controller.detail?.agentOrder.idnbr;
    final isProjectFile = p.idnbr != orderIdnbr;
    return ListTile(
      onTap: () =>
          _loadExcel(p.filePath, p.fileName),
      leading: Stack(
        alignment: Alignment.bottomRight,
        children: [
          const Icon(Icons.table_view_rounded,
              color: Colors.green, size: 32),
          if (isProjectFile)
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                  color: CobaltColors.cobalt,
                  shape: BoxShape.circle),
              child: const Icon(
                  Icons.folder_shared_rounded,
                  size: 10,
                  color: Colors.white),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
              child: Text(p.fileName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: ct.textPrimary))),
          if (isProjectFile)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: CobaltColors.cobalt.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: CobaltColors.cobalt.withValues(alpha: 0.3)),
              ),
              child: Text(
                'PROYECTO',
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: CobaltColors.cobaltLight),
              ),
            ),
        ],
      ),
      subtitle: Text(
        'Subido el ${p.uploadedAt}',
        style: TextStyle(color: ct.textSecondary, fontSize: 11),
      ),
      trailing: Icon(Icons.download_rounded,
          size: 16, color: ct.textHint),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildPhase3(dynamic ct, bool isCompact) {
    if (_selectedStandard == null) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PASO 3: MAPEO Y FILTRO DE RANGO',
          style: TextStyle(
              fontWeight: FontWeight.w900,
              color: ct.textSecondary,
              fontSize: isCompact ? 10 : 11),
        ),
        const SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(isCompact ? 10 : 16),
          decoration: BoxDecoration(
            color:
                CobaltColors.cobaltLight.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color:
                    CobaltColors.cobaltLight.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.filter_alt_rounded,
                      size: 16,
                      color: CobaltColors.cobaltLight),
                  const SizedBox(width: 8),
                  Text(
                    'FILTRAR POR RANGO DE CI (OPCIONAL)',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: CobaltColors.cobaltLight,
                        fontSize: isCompact ? 10 : 11),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              isCompact
                  ? Column(
                      children: [
                        TextField(
                          controller: _startCiController,
                          keyboardType:
                              TextInputType.number,
                          style: TextStyle(
                              color: ct.textPrimary),
                          decoration:
                              const InputDecoration(
                                  labelText:
                                      'CI Inicial (ej: 816735)',
                                  border:
                                      OutlineInputBorder()),
                          onChanged: (val) => setState(
                              () => _startCiFilter =
                                  int.tryParse(val)),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _endCiController,
                          keyboardType:
                              TextInputType.number,
                          style: TextStyle(
                              color: ct.textPrimary),
                          decoration:
                              const InputDecoration(
                                  labelText:
                                      'CI Final (ej: 816800)',
                                  border:
                                      OutlineInputBorder()),
                          onChanged: (val) => setState(
                              () => _endCiFilter =
                                  int.tryParse(val)),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _startCiController,
                            keyboardType:
                                TextInputType.number,
                            style: TextStyle(
                                color: ct.textPrimary),
                            decoration: const InputDecoration(
                                labelText:
                                    'CI Inicial (ej: 816735)',
                                border:
                                    OutlineInputBorder()),
                            onChanged: (val) => setState(
                                () => _startCiFilter =
                                    int.tryParse(val)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _endCiController,
                            keyboardType:
                                TextInputType.number,
                            style: TextStyle(
                                color: ct.textPrimary),
                            decoration: const InputDecoration(
                                labelText:
                                    'CI Final (ej: 816800)',
                                border:
                                    OutlineInputBorder()),
                            onChanged: (val) => setState(
                                () => _endCiFilter =
                                    int.tryParse(val)),
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 8),
              Text(
                'Si se define un rango, la app solo mostrará las filas con CI dentro de estos números.',
                style: TextStyle(
                    fontSize: isCompact ? 9 : 10,
                    color: ct.textHint),
              ),
            ],
          ),
        ),
        SizedBox(height: isCompact ? 20 : 32),
        Text(
          'MAPEO DE VARIABLES A COLUMNAS',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: ct.textSecondary,
              fontSize: isCompact ? 9 : 10),
        ),
        const SizedBox(height: 12),
        ..._allVariables.map(
            (v) => _buildMappingRow(ct, v, isCompact)),
        SizedBox(height: isCompact ? 20 : 32),
        Center(
          child: FilledButton.icon(
            onPressed: _startExecution,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Comenzar Procesamiento'),
            style: FilledButton.styleFrom(
              backgroundColor: CobaltColors.cobalt,
              padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 24 : 32,
                  vertical: isCompact ? 12 : 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMappingRow(
      dynamic ct, String variableName, bool isCompact) {
    final currentMapping =
        _variableToColumnMapping[variableName];
    if (isCompact) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: CobaltColors.cobaltLight
                          .withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(8)),
                  child: Text(variableName,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: CobaltColors.cobaltLight)),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_downward_rounded,
                    size: 14, color: ct.textHint),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _excelHeaders.contains(currentMapping)
                  ? currentMapping
                  : null,
              decoration: const InputDecoration(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(),
              ),
              hint: const Text('Seleccionar Columna',
                  style: TextStyle(fontSize: 12)),
              items: _excelHeaders
                  .map((h) => DropdownMenuItem(
                      value: h,
                      child: Text(h,
                          overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() =>
                      _variableToColumnMapping[variableName] =
                          val);
                  if (variableName.toUpperCase() == 'CI' ||
                      variableName.toUpperCase() ==
                          'CI_CODE') {
                    _autoDetectCiRange(val);
                  }
                }
              },
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 120,
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color:
                    CobaltColors.cobaltLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Text(variableName,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: CobaltColors.cobaltLight)),
          ),
          const SizedBox(width: 12),
          Icon(Icons.arrow_forward_rounded,
              size: 16, color: ct.textHint),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _excelHeaders.contains(currentMapping)
                  ? currentMapping
                  : null,
              decoration: const InputDecoration(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(),
              ),
              hint: const Text('Seleccionar Columna',
                  style: TextStyle(fontSize: 12)),
              items: _excelHeaders
                  .map((h) => DropdownMenuItem(
                      value: h,
                      child: Text(h,
                          overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() =>
                      _variableToColumnMapping[variableName] =
                          val);
                  if (variableName.toUpperCase() == 'CI' ||
                      variableName.toUpperCase() ==
                          'CI_CODE') {
                    _autoDetectCiRange(val);
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhase4(dynamic ct, bool isCompact) {
    if (_excel == null) return const SizedBox();
    final sheet = _firstSheet;
    if (sheet == null) {
      return Center(
          child: Text('No se pudo encontrar la hoja de cálculo',
              style: TextStyle(color: ct.textSecondary)));
    }
    final rowData = sheet.rows[_currentRowIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isCompact) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PASO 4: ESCANEO Y REGISTRO',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: ct.textSecondary,
                    fontSize: 10),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded,
                    color: CobaltColors.cobaltLight),
                onSelected: (value) {
                  switch (value) {
                    case 'history':
                      _showRegistryManager();
                      break;
                    case 'sync':
                      _syncExcelWithDatabase();
                      break;
                    case 'export':
                      if (!_loadingExcel) {
                        _createExcelFromRegistries();
                      }
                      break;
                    case 'current':
                      _advanceToNextEmptyRow();
                      break;
                    case 'gap':
                      _jumpToNextGap();
                      break;
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                      value: 'history',
                      child: Row(children: [
                        Icon(Icons.history_toggle_off_rounded,
                            size: 18,
                            color: CobaltColors.cobaltLight),
                        const SizedBox(width: 8),
                        const Text('Ver Historial',
                            style: TextStyle(fontSize: 12)),
                      ])),
                  const PopupMenuItem(
                      value: 'sync',
                      child: Row(children: [
                        Icon(Icons.sync_rounded,
                            size: 18, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Forzar Sincronización',
                            style: TextStyle(fontSize: 12)),
                      ])),
                  const PopupMenuItem(
                      value: 'export',
                      child: Row(children: [
                        Icon(
                            Icons.download_for_offline_outlined,
                            size: 18,
                            color: Colors.green),
                        SizedBox(width: 8),
                        Text('Exportar Relación',
                            style: TextStyle(fontSize: 12)),
                      ])),
                  PopupMenuItem(
                      value: 'current',
                      child: Row(children: [
                        Icon(Icons.fast_forward_rounded,
                            size: 18,
                            color: CobaltColors.cobaltLight),
                        const SizedBox(width: 8),
                        const Text('Volver al Actual',
                            style: TextStyle(fontSize: 12)),
                      ])),
                  PopupMenuItem(
                      value: 'gap',
                      child: Row(children: [
                        Icon(Icons.search_rounded,
                            size: 18,
                            color: CobaltColors.cobaltLight),
                        const SizedBox(width: 8),
                        const Text('Buscar Hueco',
                            style: TextStyle(fontSize: 12)),
                      ])),
                ],
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left_rounded,
                        size: 20,
                        color: CobaltColors.cobaltLight),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _currentRowIndex > 1
                        ? () => setState(
                            () => _currentRowIndex--)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Fila ${_currentRowIndex + 1} de ${sheet.maxRows}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: CobaltColors.cobaltLight),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.chevron_right_rounded,
                        size: 20,
                        color: CobaltColors.cobaltLight),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed:
                        _currentRowIndex < sheet.maxRows - 1
                            ? () => setState(
                                () => _currentRowIndex++)
                            : null,
                  ),
                ],
              ),
              if (_startCiFilter != null ||
                  _endCiFilter != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: const Text('FILTRADO',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange)),
                ),
            ],
          ),
        ] else ...[
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PASO 4: ESCANEO Y REGISTRO',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: ct.textSecondary,
                    fontSize: 11),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                        Icons.history_toggle_off_rounded,
                        size: 22,
                        color: CobaltColors.cobaltLight),
                    tooltip: 'Ver Historial de Registros',
                    onPressed: _showRegistryManager,
                  ),
                  const SizedBox(width: 4),
                  _toolbarButton(
                    onPressed: _syncExcelWithDatabase,
                    icon: Icons.sync_rounded,
                    label: 'FORZAR SINCRONIZACIÓN',
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  _toolbarButton(
                    onPressed: _loadingExcel
                        ? null
                        : _createExcelFromRegistries,
                    icon: Icons.download_for_offline_outlined,
                    label: 'EXPORTAR RELACIÓN A EXCEL',
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _toolbarButton(
                    onPressed: _advanceToNextEmptyRow,
                    icon: Icons.fast_forward_rounded,
                    label: 'VOLVER AL ACTUAL',
                    color: CobaltColors.cobaltLight,
                  ),
                  const SizedBox(width: 8),
                  _toolbarButton(
                    onPressed: _jumpToNextGap,
                    icon: Icons.search_rounded,
                    label: 'BUSCAR HUECO',
                    color: CobaltColors.cobaltLight,
                  ),
                  const SizedBox(width: 8),
                  Container(
                      width: 1,
                      height: 20,
                      color: ct.border),
                  const SizedBox(width: 8),
                  if (_startCiFilter != null ||
                      _endCiFilter != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(4),
                        border: Border.all(
                            color:
                                Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: const Text('FILTRADO',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange)),
                    ),
                  IconButton(
                    icon: Icon(Icons.chevron_left_rounded,
                        size: 20,
                        color: CobaltColors.cobaltLight),
                    tooltip: 'Fila Anterior',
                    onPressed: _currentRowIndex > 1
                        ? () => setState(
                            () => _currentRowIndex--)
                        : null,
                  ),
                  Text(
                    'Fila ${_currentRowIndex + 1} de ${sheet.maxRows}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: CobaltColors.cobaltLight),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right_rounded,
                        size: 20,
                        color: CobaltColors.cobaltLight),
                    tooltip: 'Siguiente Fila',
                    onPressed:
                        _currentRowIndex < sheet.maxRows - 1
                            ? () => setState(
                                () => _currentRowIndex++)
                            : null,
                  ),
                ],
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        _buildCiIntervalSummaryCard(ct),
        const SizedBox(height: 16),
        _buildCurrentRowPreview(ct, rowData, isCompact),
        const SizedBox(height: 32),
        _buildScanningUI(ct),
      ],
    );
  }

  Widget _toolbarButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color)),
      style: TextButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.05),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildCiIntervalSummaryCard(dynamic ct) {
    final summary = _buildCiIntervalSummary();
    if (summary == null) return const SizedBox.shrink();
    final total = summary['total'] ?? 0;
    final found = summary['found'] ?? 0;
    final missing = summary['missing'] ?? 0;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ct.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ct.border),
      ),
      child: Row(
        children: [
          Icon(Icons.analytics_rounded,
              color: CobaltColors.cobaltLight, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Intervalo CI: $total esperados | Encontrados: $found | Faltan: $missing',
              style:
                  TextStyle(fontSize: 12, color: ct.textSecondary),
            ),
          ),
          if (missing == 0)
            const Text('COMPLETO',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.green))
          else
            Text('PENDIENTES: $missing',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange)),
        ],
      ),
    );
  }

  Widget _buildCurrentRowPreview(
      dynamic ct, List<excel_pkg.Data?> row, bool isCompact) {
    final mappedValues = <String, String>{};
    String? ciValue;

    for (final v in _allVariables) {
      final targetHeader =
          _variableToColumnMapping[v]?.toUpperCase().trim() ?? '';
      int colIdx = -1;
      for (int k = 0; k < _excelHeaders.length; k++) {
        if (_excelHeaders[k].toUpperCase().trim() == targetHeader) {
          colIdx = k;
          break;
        }
      }
      if (colIdx != -1 && _firstSheet != null) {
        final cell = _firstSheet!.cell(
          excel_pkg.CellIndex.indexByColumnRow(
              columnIndex: colIdx, rowIndex: _currentRowIndex),
        );
        final val = cell.value?.toString().trim() ?? '';
        mappedValues[v] = val;
        if (v.toUpperCase() == 'CI' ||
            v.toUpperCase() == 'CI_CODE') {
          if (val.isNotEmpty && val.toLowerCase() != 'null') {
            ciValue = val;
          }
        }
      }
    }

    if (ciValue != null && ciValue.toUpperCase().contains('UK')) {
      final serialVal = mappedValues['SERIAL'];
      if (serialVal != null &&
          RegExp(r'^\d+$').hasMatch(serialVal)) {
        final temp = ciValue;
        ciValue = serialVal;
        mappedValues['SERIAL'] = temp;
      }
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 12 : 24),
      decoration: BoxDecoration(
        color: ct.surfaceElevated,
        borderRadius: BorderRadius.circular(isCompact ? 16 : 24),
        border: Border.all(color: ct.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (ciValue != null) ...[
            Text(
              'CÓDIGO DE INVENTARIO (CI)',
              style: TextStyle(
                  fontSize: isCompact ? 9 : 10,
                  fontWeight: FontWeight.w900,
                  color: CobaltColors.cobaltLight,
                  letterSpacing: isCompact ? 1.5 : 2),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () =>
                  _showRegistryManager(initialQuery: ciValue),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Text(
                  ciValue,
                  style: TextStyle(
                      fontSize: isCompact ? 32 : 48,
                      fontWeight: FontWeight.w900,
                      color: ct.textPrimary,
                      letterSpacing: -1),
                ),
              ),
            ),
            SizedBox(height: isCompact ? 12 : 24),
            Divider(
                color: ct.border,
                indent: isCompact ? 10 : 40,
                endIndent: isCompact ? 10 : 40),
            SizedBox(height: isCompact ? 12 : 24),
          ],
          Text(
            'DATOS DE LA ETIQUETA',
            style: TextStyle(
                fontSize: isCompact ? 8 : 9,
                fontWeight: FontWeight.bold,
                color: ct.textHint,
                letterSpacing: 1.5),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: isCompact ? 8 : 12,
            runSpacing: isCompact ? 8 : 12,
            alignment: WrapAlignment.center,
            children: mappedValues.entries
                .where((e) =>
                    e.key.toUpperCase() != 'CI' &&
                    e.key.toUpperCase() != 'CI_CODE')
                .map((e) {
              final isMissing = e.value.isEmpty;
              return Container(
                padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 10 : 16,
                    vertical: isCompact ? 6 : 10),
                decoration: BoxDecoration(
                  color: isMissing
                      ? Colors.orange.withValues(alpha: 0.1)
                      : ct.surface,
                  borderRadius:
                      BorderRadius.circular(isCompact ? 8 : 12),
                  border: Border.all(
                      color: isMissing
                          ? Colors.orange.withValues(alpha: 0.3)
                          : ct.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${e.key}${!isMissing ? " (${_variableToColumnMapping[e.key]})" : ""}: ',
                      style: TextStyle(
                          fontSize: isCompact ? 9 : 10,
                          fontWeight: FontWeight.bold,
                          color: isMissing
                              ? Colors.orange
                              : ct.textHint),
                    ),
                    Text(
                      isMissing ? 'ESPERANDO...' : e.value,
                      style: TextStyle(
                        fontSize: isCompact ? 11 : 13,
                        fontWeight: FontWeight.w900,
                        color: isMissing
                            ? Colors.orange
                            : CobaltColors.cobaltLight,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          if (mappedValues.entries.length <= 1 &&
              ciValue != null)
            Text('Listo para imprimir',
                style: TextStyle(
                    fontSize: isCompact ? 11 : 12,
                    color: Colors.green,
                    fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildScanningUI(dynamic ct) {
    final sheet = _firstSheet;
    if (sheet == null) return const SizedBox();

    String? fieldToScan;
    for (final v in _allVariables) {
      final targetHeader =
          _variableToColumnMapping[v]?.toUpperCase().trim() ?? '';
      int colIdx = -1;
      for (int k = 0; k < _excelHeaders.length; k++) {
        if (_excelHeaders[k].toUpperCase().trim() == targetHeader) {
          colIdx = k;
          break;
        }
      }
      final val = (colIdx != -1 &&
              sheet.rows[_currentRowIndex].length > colIdx)
          ? sheet.rows[_currentRowIndex][colIdx]
                  ?.value
                  ?.toString()
                  .trim() ??
              ''
          : '';
      if (val.isEmpty ||
          val.toLowerCase() == 'null' ||
          val.toLowerCase() == 'undefined') {
        fieldToScan = v;
        break;
      }
    }

    if (fieldToScan == 'CI') {
      return Center(
        child: Column(
          children: [
            Icon(Icons.inventory_rounded,
                size: 48, color: CobaltColors.cobaltLight),
            const SizedBox(height: 16),
            Text('Variable CI Detectada',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: CobaltColors.cobaltLight)),
            Text(
                'Puedes escanear el CI o seleccionarlo de un registro previo',
                style: TextStyle(
                    fontSize: 12, color: ct.textSecondary)),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildScanField(fieldToScan!),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('O',
                      style: TextStyle(color: ct.textHint)),
                ),
                _buildBrowseRegistryButton(ct),
              ],
            ),
          ],
        ),
      );
    }

    if (fieldToScan == 'CI_CODE' &&
        _currentCiCode == null &&
        !_fetchingCI) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.auto_fix_high_rounded,
                size: 48, color: CobaltColors.cobaltLight),
            const SizedBox(height: 16),
            Text('Generando Código de Inventario...',
                style: TextStyle(
                    color: CobaltColors.cobaltLight)),
            const SizedBox(height: 24),
            _fetchingCI
                ? CircularProgressIndicator(
                    color: CobaltColors.cobaltLight)
                : ElevatedButton(
                    onPressed: _fetchNextCI,
                    child:
                        const Text('Generar Manualmente')),
          ],
        ),
      );
    }

    if (fieldToScan == null && _requiresCI) {
      return Center(
        child: Column(
          children: [
            const Icon(Icons.warning_amber_rounded,
                size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            Text('Fila Detectada como "Completada"',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: ct.textPrimary)),
            Text(
                'Si los datos son incorrectos, usa estos controles:',
                style: TextStyle(
                    fontSize: 10, color: ct.textHint)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentCiCode = null;
                      _updateCell('CI', '');
                      _updateCell('CI_CODE', '');
                    });
                    _fetchNextCI();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('REGENERAR CI (NUEVO)'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _updateCell('SERIAL', ''));
                  },
                  icon:
                      const Icon(Icons.qr_code_scanner),
                  label:
                      const Text('RE-ESCANEAR SERIAL'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (fieldToScan == null) {
      if (_printing) {
        return Center(
          child: Column(
            children: [
              const Icon(Icons.print_rounded,
                  color: Colors.green, size: 64),
              const SizedBox(height: 16),
              Text('Imprimiendo...',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: ct.textPrimary)),
              const SizedBox(height: 8),
              CircularProgressIndicator(
                  color: CobaltColors.cobaltLight),
            ],
          ),
        );
      }
      return Center(
        child: Column(
          children: [
            const Icon(Icons.verified_rounded,
                color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text('Fila Completada',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.green)),
            Text('Esta fila ya tiene todos los datos registrados.',
                style: TextStyle(
                    fontSize: 13, color: ct.textSecondary)),
            const SizedBox(height: 32),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    final values = <String, String>{};
                    final s = _firstSheet;
                    if (s == null) return;
                    final row = s.rows[_currentRowIndex];
                    for (final v in _allVariables) {
                      final colName =
                          _variableToColumnMapping[v];
                      final colIdx = _excelHeaders
                          .indexOf(colName ?? '');
                      if (colIdx != -1) {
                        values[v] = row[colIdx]
                                ?.value
                                ?.toString() ??
                            '';
                      }
                    }
                    _printAndSubmit(values);
                  },
                  icon: const Icon(Icons.print_rounded),
                  label:
                      const Text('REIMPRIMIR ETIQUETA'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CobaltColors.cobalt,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12)),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      final s = _firstSheet;
                      if (s == null) return;
                      for (final v in _allVariables) {
                        final colName =
                            _variableToColumnMapping[v];
                        final colIdx = _excelHeaders
                            .indexOf(colName ?? '');
                        if (colIdx != -1) {
                          s.updateCell(
                            excel_pkg.CellIndex
                                .indexByColumnRow(
                                    columnIndex: colIdx,
                                    rowIndex:
                                        _currentRowIndex),
                            excel_pkg.TextCellValue(''),
                          );
                        }
                      }
                      _currentCiCode = null;
                      _isUsingExistingRegistry = false;
                    });
                  },
                  icon:
                      const Icon(Icons.edit_note_rounded),
                  label:
                      const Text('BORRAR Y RE-ESCANEAR'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(
                        color: Colors.orange),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Icon(Icons.qr_code_scanner_rounded,
            size: 48, color: CobaltColors.cobaltLight),
        const SizedBox(height: 16),
        Text(
          'ESCANEANDO: $fieldToScan',
          style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: CobaltColors.cobaltLight),
        ),
        const SizedBox(height: 24),
        TextField(
          key: ValueKey(
              'main_scan_${_currentRowIndex}_$fieldToScan'),
          controller: _scanController,
          focusNode: _scanFocusNode,
          autofocus: true,
          textAlign: TextAlign.center,
          style: TextStyle(color: ct.textPrimary),
          decoration: const InputDecoration(
            labelText: 'EN ESPERA DE ESCANEO...',
            border: OutlineInputBorder(),
            hintText: 'Escanea un código para continuar',
          ),
          onSubmitted: (val) async {
            final scanValue = val.trim();
            if (scanValue.isEmpty) return;
            _scanController.clear();
            final capturedField = fieldToScan;
            if (capturedField == null) return;

            final isDuplicate =
                _checkForDuplicate(capturedField, scanValue);
            if (isDuplicate) {
              final proceed = await _showValidationWarning(
                'VALOR DUPLICADO',
                'El valor "$scanValue" ya ha sido registrado en otra fila. ¿Deseas registrarlo de todos modos?',
              );
              if (!proceed) {
                _scanFocusNode.requestFocus();
                return;
              }
            }

            final expectedLength =
                _getExpectedLength(capturedField);
            final scannedLength = scanValue.length;
            if (expectedLength != null &&
                scannedLength != expectedLength &&
                !_isApprovedLength(capturedField, scannedLength)) {
              final proceed = await _showValidationWarning(
                'ANOMALÍA DE LONGITUD',
                'La longitud de este escaneo ($scannedLength) es diferente a la del primer registro ($expectedLength).\n¿Deseas permitir también esta longitud para el resto de la orden?',
              );
              if (!proceed) {
                _scanFocusNode.requestFocus();
                return;
              }
              _approveLength(capturedField, scannedLength);
            }

            setState(() {
              final s = _firstSheet;
              if (s == null) return;
              final colName =
                  _variableToColumnMapping[capturedField];
              if (colName == null) return;
              final colIdx =
                  _excelHeaders.indexOf(colName);
              final currentVal =
                  s.rows[_currentRowIndex].length > colIdx
                      ? s.rows[_currentRowIndex][colIdx]
                              ?.value
                              ?.toString()
                              .trim() ??
                          ''
                      : '';
              if (currentVal != scanValue) {
                s.updateCell(
                  excel_pkg.CellIndex.indexByColumnRow(
                      columnIndex: colIdx,
                      rowIndex: _currentRowIndex),
                  excel_pkg.TextCellValue(scanValue),
                );
              }
              if (capturedField == 'CI' ||
                  capturedField == 'CI_CODE') {
                _currentCiCode = scanValue;
              }
            });

            await _checkCompletionAndSubmit();
            WidgetsBinding.instance
                .addPostFrameCallback((_) {
              if (mounted) _scanFocusNode.requestFocus();
            });
          },
        ),
      ],
    );
  }

  Widget _buildScanField(String field) {
    return SizedBox(
      width: 300,
      child: TextField(
        key: ValueKey(
            'scan_field_${_currentRowIndex}_$field'),
        controller: _scanController,
        focusNode: _scanFocusNode,
        autofocus: true,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          labelText: 'ESCANEAR $field',
          border: const OutlineInputBorder(),
          hintText: 'Esperando escaneo...',
        ),
        onSubmitted: (val) async {
          final scanValue = val.trim();
          if (scanValue.isNotEmpty) {
            _scanController.clear();
            await _updateCell(field, scanValue);
            WidgetsBinding.instance
                .addPostFrameCallback((_) {
              if (mounted) _scanFocusNode.requestFocus();
            });
          }
        },
      ),
    );
  }

  Widget _buildBrowseRegistryButton(dynamic ct) {
    return ElevatedButton.icon(
      onPressed: _showRegistryManager,
      icon: const Icon(Icons.history_rounded),
      label: const Text('HISTORIAL / BUSCAR'),
      style: ElevatedButton.styleFrom(
        backgroundColor: ct.surfaceElevated,
        foregroundColor: CobaltColors.cobaltLight,
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildFooterActions(dynamic ct, bool isCompact) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: ct.background,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: () => setState(() {
              if (_currentStep == 4) {
                _currentStep = 3;
              } else if (_currentStep > 1) {
                _currentStep--;
              }
            }),
            icon: const Icon(Icons.arrow_back_rounded,
                size: 16),
            label: const Text('VOLVER'),
          ),
          if (_currentStep == 4)
            TextButton.icon(
              onPressed: _saveAndUpload,
              icon: const Icon(Icons.cloud_upload_outlined,
                  size: 16),
              label: const Text('GUARDAR EXCEL'),
            ),
        ],
      ),
    );
  }
}
