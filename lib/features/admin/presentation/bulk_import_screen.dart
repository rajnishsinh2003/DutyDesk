import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

import '../services/bulk_import_service.dart';
import '../providers/invigilator_provider.dart';
import '../providers/center_provider.dart';

class BulkImportScreen extends ConsumerStatefulWidget {
  final ImportEntityType initialType;

  const BulkImportScreen({
    super.key,
    this.initialType = ImportEntityType.invigilators,
  });

  static Future<void> showAsDialog(BuildContext context, {ImportEntityType initialType = ImportEntityType.invigilators}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: 880,
            height: 720,
            child: BulkImportScreen(initialType: initialType),
          ),
        ),
      ),
    );
  }

  @override
  ConsumerState<BulkImportScreen> createState() => _BulkImportScreenState();
}

class _BulkImportScreenState extends ConsumerState<BulkImportScreen> {
  late ImportEntityType _selectedType;
  ConflictStrategy _conflictStrategy = ConflictStrategy.skip;

  bool _isParsing = false;
  bool _isExportingTemplate = false;
  bool _isImporting = false;
  double _importProgress = 0.0;
  String _importProgressMessage = '';

  String? _pickedFileName;
  int? _pickedFileSize;
  ImportValidationResult? _validationResult;
  ImportCommitSummary? _commitSummary;

  String _tableFilter = 'all'; // 'all', 'valid', 'conflict', 'error'

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  void _resetImportState() {
    setState(() {
      _pickedFileName = null;
      _pickedFileSize = null;
      _validationResult = null;
      _commitSummary = null;
      _isImporting = false;
      _importProgress = 0.0;
      _importProgressMessage = '';
      _tableFilter = 'all';
    });
  }

  Future<void> _handleDownloadTemplate({required bool asExcel}) async {
    setState(() => _isExportingTemplate = true);
    try {
      await BulkImportService.downloadOrShareTemplate(_selectedType, asExcel: asExcel);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${asExcel ? "Excel (.xlsx)" : "CSV"} template prepared successfully!'),
            backgroundColor: const Color(0xFF047857),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download template: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isExportingTemplate = false);
    }
  }

  Future<void> _handlePickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
      );

      if (result.isEmpty) return;

      final pickedFile = result.first;
      Uint8List? fileBytes;
      int fileSize = 0;

      if (pickedFile.path != null) {
        final f = File(pickedFile.path!);
        if (await f.exists()) {
          fileBytes = await f.readAsBytes();
          fileSize = fileBytes.length;
        }
      }

      if (fileBytes == null || fileBytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not read file data. Please try another file.'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      setState(() {
        _isParsing = true;
        _pickedFileName = pickedFile.name;
        _pickedFileSize = fileSize;
        _validationResult = null;
        _commitSummary = null;
      });

      final invs = ref.read(invigilatorProvider);
      final centers = ref.read(centerProvider);

      final validation = await BulkImportService.parseAndValidate(
        fileBytes: fileBytes,
        fileName: pickedFile.name,
        entityType: _selectedType,
        existingInvs: invs,
        existingCenters: centers,
      );

      if (mounted) {
        setState(() {
          _validationResult = validation;
          _isParsing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isParsing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error parsing file: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleCommitImport() async {
    if (_validationResult == null) return;

    final eligibleRows = _validationResult!.rows.where((r) => r.isValid).toList();
    if (eligibleRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid records available to import.'), backgroundColor: Colors.red),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.cloud_upload_rounded, color: Color(0xFF007A87)),
            const SizedBox(width: 8),
            const Text('Confirm Bulk Import'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ready to import ${eligibleRows.length} records into "${_selectedType.displayName}".'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Total Valid Rows: ${eligibleRows.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('• Existing Conflicts: ${_validationResult!.conflictCount}', style: const TextStyle(fontSize: 13)),
                  Text(
                    '• Conflict Strategy: ${_conflictStrategy == ConflictStrategy.skip ? "Skip existing (preserve current)" : (_conflictStrategy == ConflictStrategy.overwrite ? "Overwrite existing records" : "Insert duplicates")}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF007A87), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Execute Batch Import'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isImporting = true;
      _importProgress = 0.0;
      _importProgressMessage = 'Starting batch commit...';
    });

    try {
      final summary = await BulkImportService.commitBatchImport(
        entityType: _selectedType,
        rowsToImport: eligibleRows,
        strategy: _conflictStrategy,
        onProgress: (progress, status) {
          if (mounted) {
            setState(() {
              _importProgress = progress;
              _importProgressMessage = status;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isImporting = false;
          _commitSummary = summary;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isImporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenBgColor = isDarkMode ? const Color(0xFF0F172A) : Colors.white;
    final cardBgColor = isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final invs = ref.watch(invigilatorProvider);
    final centers = ref.watch(centerProvider);

    return Scaffold(
      backgroundColor: screenBgColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bulk Data Import Hub', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Batch upload via Excel (.xlsx) or CSV format', style: TextStyle(fontSize: 11, color: subtitleColor)),
          ],
        ),
        backgroundColor: screenBgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          if (_validationResult != null && _commitSummary == null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Reset and pick another file',
              onPressed: _resetImportState,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ENTITY TYPE SELECTOR CHIPS
              _buildEntityTypeSelector(isDarkMode),
              const SizedBox(height: 16),

              // DATABASE CONTEXT COUNTER BANNER
              _buildDatabaseSummaryBanner(invs.length, centers.length, isDarkMode),
              const SizedBox(height: 20),

              // SUCCESS SUMMARY RECEIPT (IF COMPLETED)
              if (_commitSummary != null) ...[
                _buildSuccessSummaryCard(cardBgColor, borderColor, textColor, subtitleColor),
                const SizedBox(height: 24),
              ] else ...[
                // STEP 1: OFFICIAL STARTER TEMPLATES
                _buildTemplateCard(cardBgColor, borderColor, textColor, subtitleColor),
                const SizedBox(height: 20),

                // STEP 2: FILE UPLOADER DROPZONE
                _buildUploaderCard(cardBgColor, borderColor, textColor, subtitleColor),
                const SizedBox(height: 20),

                // STEP 3: PRE-COMMIT VALIDATION TABLE & CONTROLS
                if (_validationResult != null) ...[
                  _buildValidationDashboard(cardBgColor, borderColor, textColor, subtitleColor, isDarkMode),
                  const SizedBox(height: 20),
                  _buildPreviewTable(cardBgColor, borderColor, textColor, subtitleColor, isDarkMode),
                  const SizedBox(height: 24),
                  _buildCommitActionSection(),
                  const SizedBox(height: 32),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // UI SECTIONS & BUILDERS
  // ---------------------------------------------------------
  Widget _buildEntityTypeSelector(bool isDarkMode) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: ImportEntityType.values.map((type) {
          final isSelected = _selectedType == type;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getEntityIcon(type),
                    size: 16,
                    color: isSelected ? Colors.white : const Color(0xFF007A87),
                  ),
                  const SizedBox(width: 6),
                  Text(type.displayName),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected && _selectedType != type) {
                  setState(() {
                    _selectedType = type;
                    _resetImportState();
                  });
                }
              },
              selectedColor: const Color(0xFF007A87),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : (isDarkMode ? Colors.white : const Color(0xFF0F172A)),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12.5,
              ),
              backgroundColor: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF007A87) : Colors.transparent,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getEntityIcon(ImportEntityType type) {
    switch (type) {
      case ImportEntityType.invigilators:
        return Icons.people_alt_rounded;
      case ImportEntityType.centers:
        return Icons.location_city_rounded;
      case ImportEntityType.duties:
        return Icons.assignment_turned_in_rounded;
      case ImportEntityType.securityGuards:
        return Icons.security_rounded;
    }
  }

  Widget _buildDatabaseSummaryBanner(int invCount, int centerCount, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF007A87).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF007A87).withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFF007A87), size: 18),
              const SizedBox(width: 8),
              Text(
                'Targeting: ${_selectedType.displayName}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF007A87)),
              ),
            ],
          ),
          Text(
            _selectedType == ImportEntityType.invigilators
                ? 'Current in DB: $invCount Staff'
                : (_selectedType == ImportEntityType.centers ? 'Current in DB: $centerCount Centers' : 'Batch mode enabled'),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(Color cardBg, Color borderColor, Color textColor, Color subtitleColor) {
    final headers = BulkImportService.getExpectedHeaders(_selectedType);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.download_for_offline_rounded, color: Color(0xFF6366F1), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Step 1: Download Standard Template', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                      Text('Ensure header names match expected schema', style: TextStyle(fontSize: 11.5, color: subtitleColor)),
                    ],
                  ),
                ],
              ),
              if (_isExportingTemplate)
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              else
                Row(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.table_chart_rounded, size: 15),
                      label: const Text('Excel (.xlsx)', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF15803D),
                        side: const BorderSide(color: Color(0xFF15803D)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () => _handleDownloadTemplate(asExcel: true),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.description_rounded, size: 15),
                      label: const Text('CSV (.csv)', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0284C7),
                        side: const BorderSide(color: Color(0xFF0284C7)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () => _handleDownloadTemplate(asExcel: false),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Text('Expected Columns:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subtitleColor)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: headers.map((h) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Text(
                  h,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUploaderCard(Color cardBg, Color borderColor, Color textColor, Color subtitleColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF007A87).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.file_upload_outlined, color: Color(0xFF007A87), size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Step 2: Upload File', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                  Text('Select spreadsheet containing your records', style: TextStyle(fontSize: 11.5, color: subtitleColor)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isParsing) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF007A87)),
                  SizedBox(height: 14),
                  Text('Analyzing file headers and validating data rows...', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ] else if (_pickedFileName == null) ...[
            InkWell(
              onTap: _handlePickFile,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF007A87).withValues(alpha: 0.5), width: 1.5, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(14),
                  color: const Color(0xFF007A87).withValues(alpha: 0.04),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_upload_rounded, color: Color(0xFF007A87), size: 44),
                    const SizedBox(height: 10),
                    const Text('Click or Tap to Select File', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF007A87))),
                    const SizedBox(height: 4),
                    Text('Supported: .xlsx, .xls, .csv', style: TextStyle(color: subtitleColor, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF007A87).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF007A87).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file_rounded, color: Color(0xFF007A87), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_pickedFileName ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: textColor)),
                        Text(
                          '${((_pickedFileSize ?? 0) / 1024).toStringAsFixed(1)} KB • ${_pickedFileName?.endsWith(".csv") == true ? "CSV File" : "Excel Workbook"}',
                          style: TextStyle(color: subtitleColor, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                    label: const Text('Change File'),
                    onPressed: _handlePickFile,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildValidationDashboard(Color cardBg, Color borderColor, Color textColor, Color subtitleColor, bool isDarkMode) {
    final v = _validationResult!;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Step 3: Pre-Commit Validation Audit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: v.errorCount == 0 ? Colors.green.withValues(alpha: 0.15) : Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  v.errorCount == 0 ? 'STATUS: READY' : 'STATUS: REVIEW NEEDED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: v.errorCount == 0 ? const Color(0xFF047857) : const Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // KPI TILES
          Row(
            children: [
              Expanded(child: _buildKpiBox('Total Rows', '${v.totalRows}', const Color(0xFF6366F1), isDarkMode)),
              const SizedBox(width: 8),
              Expanded(child: _buildKpiBox('Valid (New)', '${v.validCount}', const Color(0xFF059669), isDarkMode)),
              const SizedBox(width: 8),
              Expanded(child: _buildKpiBox('Conflicts', '${v.conflictCount}', const Color(0xFFD97706), isDarkMode)),
              const SizedBox(width: 8),
              Expanded(child: _buildKpiBox('Errors', '${v.errorCount}', const Color(0xFFDC2626), isDarkMode)),
            ],
          ),
          const SizedBox(height: 18),

          // CONFLICT RESOLUTION STRATEGY
          if (v.conflictCount > 0) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.handshake_rounded, color: Color(0xFFD97706), size: 16),
                      SizedBox(width: 6),
                      Text('Conflict Resolution Strategy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFFD97706))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      ChoiceChip(
                        label: const Text('Skip Existing (Recommended)', style: TextStyle(fontSize: 11.5)),
                        selected: _conflictStrategy == ConflictStrategy.skip,
                        onSelected: (val) => setState(() => _conflictStrategy = ConflictStrategy.skip),
                      ),
                      ChoiceChip(
                        label: const Text('Overwrite / Update Existing', style: TextStyle(fontSize: 11.5)),
                        selected: _conflictStrategy == ConflictStrategy.overwrite,
                        onSelected: (val) => setState(() => _conflictStrategy = ConflictStrategy.overwrite),
                      ),
                      ChoiceChip(
                        label: const Text('Insert Duplicates Anyway', style: TextStyle(fontSize: 11.5)),
                        selected: _conflictStrategy == ConflictStrategy.createDuplicate,
                        onSelected: (val) => setState(() => _conflictStrategy = ConflictStrategy.createDuplicate),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKpiBox(String title, String count, Color color, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDarkMode ? 0.2 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(count, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildPreviewTable(Color cardBg, Color borderColor, Color textColor, Color subtitleColor, bool isDarkMode) {
    final v = _validationResult!;

    List<ImportRowValidation> filteredRows = v.rows;
    if (_tableFilter == 'valid') {
      filteredRows = v.rows.where((r) => r.isValid && !r.isConflict).toList();
    } else if (_tableFilter == 'conflict') {
      filteredRows = v.rows.where((r) => r.isConflict).toList();
    } else if (_tableFilter == 'error') {
      filteredRows = v.rows.where((r) => !r.isValid).toList();
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // FILTER TABS BAR
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Row Preview (${filteredRows.length} of ${v.totalRows})', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                Wrap(
                  spacing: 4,
                  children: [
                    _filterChip('all', 'All (${v.totalRows})'),
                    _filterChip('valid', 'Valid (${v.validCount})'),
                    _filterChip('conflict', 'Conflicts (${v.conflictCount})'),
                    _filterChip('error', 'Errors (${v.errorCount})'),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // LIST OF ROWS
          if (filteredRows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text('No rows match filter "$_tableFilter".', style: TextStyle(color: subtitleColor, fontSize: 12)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredRows.length > 50 ? 50 : filteredRows.length, // Cap preview to 50 for performance
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final row = filteredRows[index];
                return _buildRowItem(row, textColor, subtitleColor, isDarkMode);
              },
            ),

          if (filteredRows.length > 50)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Center(
                child: Text('+ ${filteredRows.length - 50} more records in file (truncated in preview)', style: TextStyle(color: subtitleColor, fontSize: 11)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _filterChip(String filterKey, String label) {
    final isSelected = _tableFilter == filterKey;
    return GestureDetector(
      onTap: () => setState(() => _tableFilter = filterKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF007A87) : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildRowItem(ImportRowValidation row, Color textColor, Color subtitleColor, bool isDarkMode) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (!row.isValid) {
      statusColor = const Color(0xFFDC2626);
      statusLabel = 'INVALID';
      statusIcon = Icons.error_outline_rounded;
    } else if (row.isConflict) {
      statusColor = const Color(0xFFD97706);
      statusLabel = 'CONFLICT';
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusColor = const Color(0xFF059669);
      statusLabel = 'VALID';
      statusIcon = Icons.check_circle_outline_rounded;
    }

    final summary = row.rawData.entries.take(4).map((e) => '${e.key}: ${e.value}').join('  •  ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ROW NUMBER BADGE
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('#${row.rowIndex}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),

          // STATUS BADGE
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 11, color: statusColor),
                const SizedBox(width: 4),
                Text(statusLabel, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: statusColor)),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // SUMMARY & ERRORS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(summary, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: textColor), maxLines: 2, overflow: TextOverflow.ellipsis),
                if (row.errors.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  for (final err in row.errors)
                    Row(
                      children: [
                        const Icon(Icons.close_rounded, size: 12, color: Colors.red),
                        const SizedBox(width: 4),
                        Expanded(child: Text(err, style: const TextStyle(fontSize: 10.5, color: Colors.red, fontWeight: FontWeight.bold))),
                      ],
                    ),
                ],
                if (row.warnings.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  for (final w in row.warnings)
                    Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 12, color: Color(0xFFD97706)),
                        const SizedBox(width: 4),
                        Expanded(child: Text(w, style: const TextStyle(fontSize: 10.5, color: Color(0xFFD97706)))),
                      ],
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommitActionSection() {
    final v = _validationResult!;
    final eligibleCount = v.rows.where((r) => r.isValid).length;

    if (_isImporting) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF007A87).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF007A87)),
        ),
        child: Column(
          children: [
            LinearProgressIndicator(value: _importProgress > 0 ? _importProgress : null, color: const Color(0xFF007A87)),
            const SizedBox(height: 12),
            Text(_importProgressMessage, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF007A87))),
            const SizedBox(height: 4),
            Text('Committing atomic batches into Firestore. Please keep the app open.', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.cloud_upload_rounded),
          label: Text(
            eligibleCount > 0 ? 'Batch Import $eligibleCount Records Now' : 'Cannot Import (0 Valid Rows)',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: eligibleCount > 0 ? const Color(0xFF007A87) : Colors.grey,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: eligibleCount > 0 ? _handleCommitImport : null,
        ),
        if (v.errorCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Note: ${v.errorCount} invalid rows will be skipped automatically.',
              style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildSuccessSummaryCard(Color cardBg, Color borderColor, Color textColor, Color subtitleColor) {
    final s = _commitSummary!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF059669).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Color(0xFF059669), shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 16),
          const Text('Batch Import Completed!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
          const SizedBox(height: 6),
          Text('Successfully processed ${s.totalProcessed} records into ${_selectedType.displayName}.', style: TextStyle(color: subtitleColor, fontSize: 13), textAlign: TextAlign.center),
          const SizedBox(height: 20),

          // SUMMARY NUMBERS
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatBox('Created', '${s.insertedCount}', const Color(0xFF059669)),
              const SizedBox(width: 12),
              _buildStatBox('Updated', '${s.updatedCount}', const Color(0xFF0284C7)),
              const SizedBox(width: 12),
              _buildStatBox('Skipped', '${s.skippedCount}', const Color(0xFF64748B)),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Import Another File'),
                onPressed: _resetImportState,
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Return to Dashboard'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF007A87), foregroundColor: Colors.white),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    context.go('/admin_dashboard');
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
