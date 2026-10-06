import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/invigilator_provider.dart';
import '../providers/center_provider.dart';

enum ImportEntityType {
  invigilators,
  centers,
  duties,
  securityGuards,
}

extension ImportEntityTypeExtension on ImportEntityType {
  String get displayName {
    switch (this) {
      case ImportEntityType.invigilators:
        return 'Invigilators & Teaching Staff';
      case ImportEntityType.centers:
        return 'Exam Centers & Venues';
      case ImportEntityType.duties:
        return 'Exam Duty Allocations';
      case ImportEntityType.securityGuards:
        return 'Security Guard Log';
    }
  }

  String get targetCollection {
    switch (this) {
      case ImportEntityType.invigilators:
        return 'invigilators';
      case ImportEntityType.centers:
        return 'centers';
      case ImportEntityType.duties:
        return 'duties';
      case ImportEntityType.securityGuards:
        return 'daily_records';
    }
  }
}

enum ConflictStrategy {
  skip,
  overwrite,
  createDuplicate,
}

class ImportRowValidation {
  final int rowIndex; // 1-based index (data row)
  final Map<String, String> rawData;
  final bool isValid;
  final bool isConflict;
  final String? conflictEntityId;
  final List<String> errors;
  final List<String> warnings;
  final Map<String, dynamic> parsedPayload;

  ImportRowValidation({
    required this.rowIndex,
    required this.rawData,
    required this.isValid,
    this.isConflict = false,
    this.conflictEntityId,
    required this.errors,
    required this.warnings,
    required this.parsedPayload,
  });
}

class ImportValidationResult {
  final ImportEntityType entityType;
  final String fileName;
  final int totalRows;
  final int validCount;
  final int conflictCount;
  final int errorCount;
  final List<String> detectedHeaders;
  final List<ImportRowValidation> rows;

  ImportValidationResult({
    required this.entityType,
    required this.fileName,
    required this.totalRows,
    required this.validCount,
    required this.conflictCount,
    required this.errorCount,
    required this.detectedHeaders,
    required this.rows,
  });
}

class ImportCommitSummary {
  final int totalProcessed;
  final int insertedCount;
  final int updatedCount;
  final int skippedCount;
  final List<String> errorMessages;

  ImportCommitSummary({
    required this.totalProcessed,
    required this.insertedCount,
    required this.updatedCount,
    required this.skippedCount,
    required this.errorMessages,
  });
}

class BulkImportService {
  // ---------------------------------------------------------
  // TEMPLATE DEFINITIONS
  // ---------------------------------------------------------
  static List<String> getExpectedHeaders(ImportEntityType type) {
    switch (type) {
      case ImportEntityType.invigilators:
        return ['Full Name', 'Mobile Number', 'Resource ID', 'Email', 'Address'];
      case ImportEntityType.centers:
        return ['Center Name', 'Location', 'Capacity', 'Latitude', 'Longitude', 'Radius Meters'];
      case ImportEntityType.duties:
        return ['Exam Name', 'Date (YYYY-MM-DD)', 'Shift (1 or 2)', 'Center Name', 'Staff Identifier (Mobile / ID)', 'Reporting Time', 'Lunch (Yes/No)', 'Remuneration'];
      case ImportEntityType.securityGuards:
        return ['Date (YYYY-MM-DD)', 'Guard Name', 'Center Name', 'Gender', 'Duty Type', 'Total Shifts', 'Payment'];
    }
  }

  static List<List<String>> getSampleRows(ImportEntityType type) {
    switch (type) {
      case ImportEntityType.invigilators:
        return [
          ['Dr. Rajesh Kumar', '9876543210', 'INV-101', 'rajesh.k@univ.edu.in', 'Block A, Faculty Quarters'],
          ['Prof. Priya Sharma', '9823456781', 'INV-102', 'priya.s@univ.edu.in', 'Civil Lines, Campus North'],
          ['Dr. Amit Patel', '9712345672', 'INV-103', 'amit.p@univ.edu.in', 'Sector 4, University Enclave'],
        ];
      case ImportEntityType.centers:
        return [
          ['Main Examination Hall', 'Central Academic Block, 2nd Floor', '250', '28.6139', '77.2090', '200'],
          ['Science Complex Auditorium', 'Faculty of Science, Ground Floor', '180', '28.6145', '77.2105', '250'],
          ['Engineering Wing Seminar Hall', 'Tech Campus, Block C', '120', '28.6120', '77.2080', '150'],
        ];
      case ImportEntityType.duties:
        return [
          ['B.Tech End Semester Exam', DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 1))), '1', 'Main Examination Hall', 'INV-101', '08:30 AM', 'Yes', '₹850'],
          ['MBA Quantitative Analysis', DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 1))), '2', 'Science Complex Auditorium', '9823456781', '01:30 PM', 'No', '₹850'],
        ];
      case ImportEntityType.securityGuards:
        return [
          [DateFormat('yyyy-MM-dd').format(DateTime.now()), 'Ramesh Singh', 'Main Examination Hall', 'Male', 'Main Gate Frisking', '2', '₹550'],
          [DateFormat('yyyy-MM-dd').format(DateTime.now()), 'Sunita Devi', 'Science Complex Auditorium', 'Female', 'Female Screening Booth', '2', '₹550'],
        ];
    }
  }

  // ---------------------------------------------------------
  // TEMPLATE GENERATOR & EXPORT
  // ---------------------------------------------------------
  static Uint8List generateExcelTemplate(ImportEntityType type) {
    final excel = Excel.createExcel();
    final sheetName = excel.getDefaultSheet() ?? 'Template';
    final sheet = excel[sheetName];

    final headers = getExpectedHeaders(type);
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    final samples = getSampleRows(type);
    for (final row in samples) {
      sheet.appendRow(row.map((cell) => TextCellValue(cell)).toList());
    }

    final bytes = excel.encode();
    return Uint8List.fromList(bytes ?? []);
  }

  static String generateCsvTemplate(ImportEntityType type) {
    final buffer = StringBuffer();
    final headers = getExpectedHeaders(type);
    buffer.writeln(headers.map((h) => '"$h"').join(','));

    final samples = getSampleRows(type);
    for (final row in samples) {
      buffer.writeln(row.map((cell) => '"$cell"').join(','));
    }

    return buffer.toString();
  }

  static Future<void> downloadOrShareTemplate(
    ImportEntityType type, {
    bool asExcel = true,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final ext = asExcel ? 'xlsx' : 'csv';
      final fileName = 'DutyDesk_Template_${type.name}_${DateFormat('yyyyMMdd').format(DateTime.now())}.$ext';
      final file = File('${dir.path}/$fileName');

      if (asExcel) {
        final bytes = generateExcelTemplate(type);
        await file.writeAsBytes(bytes);
      } else {
        final csv = generateCsvTemplate(type);
        await file.writeAsString(csv);
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: asExcel ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' : 'text/csv')],
          subject: 'DutyDesk ${type.displayName} Bulk Import Template',
          text: 'Use this official template to prepare batch records for import into DutyDesk.',
        ),
      );
    } catch (e) {
      log('Failed to export template: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------
  // PARSING & VALIDATION ENGINE
  // ---------------------------------------------------------
  static Future<ImportValidationResult> parseAndValidate({
    required Uint8List fileBytes,
    required String fileName,
    required ImportEntityType entityType,
    required List<Invigilator> existingInvs,
    required List<ExamCenter> existingCenters,
  }) async {
    final isCsv = fileName.toLowerCase().endsWith('.csv');
    List<List<String>> rawTable;

    if (isCsv) {
      final csvString = utf8.decode(fileBytes, allowMalformed: true);
      rawTable = _parseCsv(csvString);
    } else {
      rawTable = _parseExcel(fileBytes);
    }

    if (rawTable.isEmpty) {
      throw Exception('The uploaded file contains no readable records.');
    }

    final headerRow = rawTable.first.map((c) => c.trim()).toList();
    final dataRows = rawTable.sublist(1);

    if (dataRows.isEmpty) {
      throw Exception('The file contains a header row but no data entries.');
    }

    final headerMap = _mapHeaderColumns(headerRow, entityType);

    final List<ImportRowValidation> validatedRows = [];
    final seenMobiles = <String>{};
    final seenResourceIds = <String>{};
    final seenCenterNames = <String>{};

    for (int i = 0; i < dataRows.length; i++) {
      final row = dataRows[i];
      if (row.every((cell) => cell.trim().isEmpty)) {
        continue; // skip completely blank lines
      }

      final rawDataMap = <String, String>{};
      for (int c = 0; c < row.length; c++) {
        final headerKey = c < headerRow.length ? headerRow[c] : 'Col_$c';
        rawDataMap[headerKey] = row[c].trim();
      }

      final validation = _validateRow(
        rowIndex: i + 1,
        rowCells: row,
        headerMap: headerMap,
        rawDataMap: rawDataMap,
        entityType: entityType,
        existingInvs: existingInvs,
        existingCenters: existingCenters,
        seenMobiles: seenMobiles,
        seenResourceIds: seenResourceIds,
        seenCenterNames: seenCenterNames,
      );

      validatedRows.add(validation);
    }

    final validCount = validatedRows.where((r) => r.isValid && !r.isConflict).length;
    final conflictCount = validatedRows.where((r) => r.isValid && r.isConflict).length;
    final errorCount = validatedRows.where((r) => !r.isValid).length;

    return ImportValidationResult(
      entityType: entityType,
      fileName: fileName,
      totalRows: validatedRows.length,
      validCount: validCount,
      conflictCount: conflictCount,
      errorCount: errorCount,
      detectedHeaders: headerRow,
      rows: validatedRows,
    );
  }

  // ---------------------------------------------------------
  // ROW VALIDATOR HELPER
  // ---------------------------------------------------------
  static ImportRowValidation _validateRow({
    required int rowIndex,
    required List<String> rowCells,
    required Map<String, int> headerMap,
    required Map<String, String> rawDataMap,
    required ImportEntityType entityType,
    required List<Invigilator> existingInvs,
    required List<ExamCenter> existingCenters,
    required Set<String> seenMobiles,
    required Set<String> seenResourceIds,
    required Set<String> seenCenterNames,
  }) {
    final errors = <String>[];
    final warnings = <String>[];
    final payload = <String, dynamic>{};
    bool isConflict = false;
    String? conflictEntityId;

    String getVal(String key) {
      final colIdx = headerMap[key];
      if (colIdx != null && colIdx < rowCells.length) {
        return rowCells[colIdx].trim();
      }
      return '';
    }

    switch (entityType) {
      case ImportEntityType.invigilators:
        final name = getVal('name');
        final mobile = getVal('mobile').replaceAll(RegExp(r'[^0-9]'), '');
        var resId = getVal('resourceId');
        final email = getVal('email');
        final address = getVal('address');

        if (name.isEmpty) {
          errors.add('Full Name is required.');
        } else if (name.length < 2) {
          warnings.add('Name seems unusually short.');
        }

        if (mobile.isEmpty) {
          errors.add('Mobile Number is required.');
        } else {
          // Normalize Indian 10-digit mobile
          final cleanMobile = mobile.length > 10 ? mobile.substring(mobile.length - 10) : mobile;
          if (cleanMobile.length != 10) {
            errors.add('Mobile must contain exactly 10 digits.');
          } else {
            if (seenMobiles.contains(cleanMobile)) {
              errors.add('Duplicate mobile ($cleanMobile) in this file.');
            }
            seenMobiles.add(cleanMobile);

            // Check against Firestore existing invigilators
            final existingMatch = existingInvs.firstWhere(
              (i) => i.mobile.replaceAll(RegExp(r'[^0-9]'), '').endsWith(cleanMobile),
              orElse: () => Invigilator(id: '', name: '', resourceId: '', mobile: '', mockDutyCount: 0),
            );
            if (existingMatch.id.isNotEmpty) {
              isConflict = true;
              conflictEntityId = existingMatch.id;
              warnings.add('Staff already registered: ${existingMatch.name} (${existingMatch.resourceId})');
            }
          }
        }

        if (resId.isEmpty) {
          resId = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}-$rowIndex';
          warnings.add('No Resource ID given; generated $resId');
        } else {
          if (seenResourceIds.contains(resId.toUpperCase())) {
            errors.add('Duplicate Resource ID ($resId) in this file.');
          }
          seenResourceIds.add(resId.toUpperCase());

          final existingMatch = existingInvs.firstWhere(
            (i) => i.resourceId.trim().toUpperCase() == resId.toUpperCase(),
            orElse: () => Invigilator(id: '', name: '', resourceId: '', mobile: '', mockDutyCount: 0),
          );
          if (existingMatch.id.isNotEmpty) {
            isConflict = true;
            conflictEntityId = existingMatch.id;
            warnings.add('Resource ID exists for ${existingMatch.name}');
          }
        }

        if (email.isNotEmpty && !email.contains('@')) {
          warnings.add('Email address appears invalid ($email).');
        }

        payload['name'] = name;
        payload['mobile'] = mobile.length > 10 ? mobile.substring(mobile.length - 10) : mobile;
        payload['resourceId'] = resId;
        payload['email'] = email.isEmpty ? null : email;
        payload['address'] = address.isEmpty ? null : address;
        payload['mockDutyCount'] = 0;
        payload['lastMockAssignedDate'] = null;
        payload['isActive'] = true;
        payload['unavailableDates'] = <String>[];
        payload['photoUrl'] = null;
        payload['isStandby'] = false;
        break;

      case ImportEntityType.centers:
        final name = getVal('name');
        final location = getVal('location');
        final capacityStr = getVal('capacity');
        final latStr = getVal('latitude');
        final lngStr = getVal('longitude');
        final radiusStr = getVal('radius');

        if (name.isEmpty) {
          errors.add('Center Name is required.');
        } else {
          final normName = name.toLowerCase().trim();
          if (seenCenterNames.contains(normName)) {
            errors.add('Duplicate center name in file: $name');
          }
          seenCenterNames.add(normName);

          final existing = existingCenters.firstWhere(
            (c) => c.name.toLowerCase().trim() == normName,
            orElse: () => ExamCenter(id: '', name: '', location: '', capacity: 0),
          );
          if (existing.id.isNotEmpty) {
            isConflict = true;
            conflictEntityId = existing.id;
            warnings.add('Center already exists in database: ${existing.name}');
          }
        }

        if (location.isEmpty) {
          errors.add('Location address is required.');
        }

        int capacity = int.tryParse(capacityStr) ?? 0;
        if (capacity <= 0) {
          capacity = 100;
          warnings.add('Capacity missing or 0; defaulted to 100.');
        }

        double? lat;
        double? lng;
        if (latStr.isNotEmpty) {
          lat = double.tryParse(latStr);
          if (lat == null || lat < -90 || lat > 90) {
            warnings.add('Invalid latitude value ($latStr).');
            lat = null;
          }
        }
        if (lngStr.isNotEmpty) {
          lng = double.tryParse(lngStr);
          if (lng == null || lng < -180 || lng > 180) {
            warnings.add('Invalid longitude value ($lngStr).');
            lng = null;
          }
        }

        int radius = int.tryParse(radiusStr) ?? 200;
        if (radius < 50 || radius > 5000) radius = 200;

        payload['name'] = name;
        payload['location'] = location;
        payload['capacity'] = capacity;
        payload['latitude'] = lat;
        payload['longitude'] = lng;
        payload['allowedRadiusMeters'] = radius;
        break;

      case ImportEntityType.duties:
        final examName = getVal('examName');
        final dateStr = getVal('date');
        final shiftRaw = getVal('shift');
        final centerName = getVal('centerName');
        final staffId = getVal('staffIdentifier');
        final reportingTime = getVal('reportingTime');
        final lunch = getVal('lunch');
        final payment = getVal('payment');

        if (examName.isEmpty) errors.add('Exam Name is required.');

        String normalizedDate = '';
        if (dateStr.isEmpty) {
          errors.add('Duty Date is required.');
        } else {
          try {
            if (dateStr.contains('-')) {
              final parts = dateStr.split('-');
              if (parts[0].length == 4) {
                normalizedDate = dateStr;
              } else if (parts[2].length == 4) {
                normalizedDate = '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
              }
            } else if (dateStr.contains('/')) {
              final parts = dateStr.split('/');
              if (parts[0].length == 4) {
                normalizedDate = '${parts[0]}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}';
              } else if (parts[2].length == 4) {
                normalizedDate = '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
              }
            }
            if (normalizedDate.isEmpty) normalizedDate = dateStr;
          } catch (_) {
            errors.add('Invalid date format. Expected YYYY-MM-DD.');
          }
        }

        String shift = '1';
        if (shiftRaw.contains('2') || shiftRaw.toLowerCase().contains('afternoon') || shiftRaw.toLowerCase().contains('evening')) {
          shift = '2';
        }

        if (centerName.isEmpty) {
          errors.add('Center Name is required.');
        } else {
          final centerMatch = existingCenters.any((c) => c.name.toLowerCase().contains(centerName.toLowerCase()));
          if (!centerMatch) {
            warnings.add('Center "$centerName" is not recognized in Centers registry.');
          }
        }

        String resolvedInvId = '';
        if (staffId.isEmpty) {
          errors.add('Staff Identifier (ID or Mobile) is required.');
        } else {
          final cleanStaffId = staffId.replaceAll(RegExp(r'[^0-9]'), '');
          final matchedInv = existingInvs.firstWhere(
            (i) =>
                i.resourceId.toLowerCase() == staffId.toLowerCase() ||
                (cleanStaffId.length >= 10 && i.mobile.contains(cleanStaffId)) ||
                i.name.toLowerCase() == staffId.toLowerCase(),
            orElse: () => Invigilator(id: '', name: '', resourceId: '', mobile: '', mockDutyCount: 0),
          );

          if (matchedInv.id.isEmpty) {
            warnings.add('Staff "$staffId" not found in registry. Will mark as unallocated staff.');
            resolvedInvId = staffId; // Fallback to provided raw ID
          } else {
            resolvedInvId = matchedInv.id;
          }
        }

        final calcPayment = payment.isNotEmpty ? (payment.startsWith('₹') ? payment : '₹$payment') : (shift == '2' ? '₹900' : '₹550');

        payload['examName'] = examName;
        payload['date'] = normalizedDate;
        payload['shift'] = shift;
        payload['centerName'] = centerName;
        payload['invigilatorId'] = resolvedInvId;
        payload['reportingTime'] = reportingTime.isNotEmpty ? reportingTime : (shift == '1' ? '07:30 AM' : '01:00 PM');
        payload['excellentUntil'] = shift == '1' ? '07:45 AM' : '01:15 PM';
        payload['goodUntil'] = shift == '1' ? '08:00 AM' : '01:30 PM';
        payload['lunch'] = lunch.toLowerCase().contains('y') ? 'Yes' : 'No';
        payload['payment'] = calcPayment;
        payload['role'] = 'Invigilator';
        payload['status'] = 'pending';
        payload['paymentStatus'] = 'pending';
        payload['isReached'] = false;
        payload['isClockedOut'] = false;
        payload['sessionId'] = '';
        break;

      case ImportEntityType.securityGuards:
        final dateStr = getVal('date');
        final guardName = getVal('name');
        final center = getVal('center');
        final gender = getVal('gender');
        final duty = getVal('duty');
        final shifts = getVal('shifts');
        final payment = getVal('payment');

        if (guardName.isEmpty) errors.add('Guard Name is required.');
        if (center.isEmpty) errors.add('Center is required.');

        payload['recordType'] = 'security_guard';
        payload['date'] = dateStr.isNotEmpty ? dateStr : DateFormat('yyyy-MM-dd').format(DateTime.now());
        payload['name'] = guardName;
        payload['center'] = center;
        payload['gender'] = gender.isNotEmpty ? gender : 'Male';
        payload['duty'] = duty.isNotEmpty ? duty : 'Main Gate Screening';
        payload['totalShifts'] = shifts.isNotEmpty ? shifts : '1';
        payload['payment'] = payment.isNotEmpty ? (payment.startsWith('₹') ? payment : '₹$payment') : '₹550';
        break;
    }

    return ImportRowValidation(
      rowIndex: rowIndex,
      rawData: rawDataMap,
      isValid: errors.isEmpty,
      isConflict: isConflict,
      conflictEntityId: conflictEntityId,
      errors: errors,
      warnings: warnings,
      parsedPayload: payload,
    );
  }

  // ---------------------------------------------------------
  // COLUMN MAPPING HELPER
  // ---------------------------------------------------------
  static Map<String, int> _mapHeaderColumns(List<String> headers, ImportEntityType entityType) {
    final map = <String, int>{};

    for (int i = 0; i < headers.length; i++) {
      final h = headers[i].toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

      switch (entityType) {
        case ImportEntityType.invigilators:
          if (h.contains('name') || h.contains('staff') || h.contains('fullname') || h.contains('teacher')) {
            map.putIfAbsent('name', () => i);
          } else if (h.contains('mobile') || h.contains('phone') || h.contains('contact') || h.contains('cell')) {
            map.putIfAbsent('mobile', () => i);
          } else if (h.contains('resource') || h.contains('empid') || h.contains('staffid') || h.contains('code') || h.contains('id')) {
            map.putIfAbsent('resourceId', () => i);
          } else if (h.contains('mail')) {
            map.putIfAbsent('email', () => i);
          } else if (h.contains('address') || h.contains('city') || h.contains('location')) {
            map.putIfAbsent('address', () => i);
          }
          break;

        case ImportEntityType.centers:
          if (h.contains('center') || h.contains('hall') || h.contains('name') || h.contains('venue')) {
            map.putIfAbsent('name', () => i);
          } else if (h.contains('loc') || h.contains('address') || h.contains('place')) {
            map.putIfAbsent('location', () => i);
          } else if (h.contains('cap') || h.contains('seat') || h.contains('room')) {
            map.putIfAbsent('capacity', () => i);
          } else if (h.contains('lat')) {
            map.putIfAbsent('latitude', () => i);
          } else if (h.contains('lon') || h.contains('lng')) {
            map.putIfAbsent('longitude', () => i);
          } else if (h.contains('rad') || h.contains('fence')) {
            map.putIfAbsent('radius', () => i);
          }
          break;

        case ImportEntityType.duties:
          if (h.contains('exam') || h.contains('paper') || h.contains('course')) {
            map.putIfAbsent('examName', () => i);
          } else if (h.contains('date') || h.contains('day')) {
            map.putIfAbsent('date', () => i);
          } else if (h.contains('shift') || h.contains('slot') || h.contains('session')) {
            map.putIfAbsent('shift', () => i);
          } else if (h.contains('center') || h.contains('hall') || h.contains('venue')) {
            map.putIfAbsent('centerName', () => i);
          } else if (h.contains('staff') || h.contains('invig') || h.contains('resource') || h.contains('mobile') || h.contains('faculty')) {
            map.putIfAbsent('staffIdentifier', () => i);
          } else if (h.contains('time') || h.contains('report')) {
            map.putIfAbsent('reportingTime', () => i);
          } else if (h.contains('lunch') || h.contains('meal')) {
            map.putIfAbsent('lunch', () => i);
          } else if (h.contains('pay') || h.contains('amount') || h.contains('fee')) {
            map.putIfAbsent('payment', () => i);
          }
          break;

        case ImportEntityType.securityGuards:
          if (h.contains('date')) {
            map.putIfAbsent('date', () => i);
          } else if (h.contains('guard') || h.contains('name')) {
            map.putIfAbsent('name', () => i);
          } else if (h.contains('center')) {
            map.putIfAbsent('center', () => i);
          } else if (h.contains('gender') || h.contains('sex')) {
            map.putIfAbsent('gender', () => i);
          } else if (h.contains('duty') || h.contains('post')) {
            map.putIfAbsent('duty', () => i);
          } else if (h.contains('shift') || h.contains('count')) {
            map.putIfAbsent('shifts', () => i);
          } else if (h.contains('pay') || h.contains('wage')) {
            map.putIfAbsent('payment', () => i);
          }
          break;
      }
    }

    return map;
  }

  // ---------------------------------------------------------
  // EXCEL PARSER
  // ---------------------------------------------------------
  static List<List<String>> _parseExcel(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);
    final List<List<String>> result = [];

    for (final tableName in excel.tables.keys) {
      final sheet = excel.tables[tableName];
      if (sheet == null) continue;

      for (final row in sheet.rows) {
        final List<String> rowCells = [];
        for (final cell in row) {
          rowCells.add(_cellValueToString(cell?.value));
        }
        if (rowCells.any((c) => c.isNotEmpty)) {
          result.add(rowCells);
        }
      }
      if (result.isNotEmpty) break; // Read first populated sheet
    }

    return result;
  }

  static String _cellValueToString(dynamic val) {
    if (val == null) return '';
    if (val is TextCellValue) return (val.value.text ?? val.value.toString()).trim();
    if (val is IntCellValue) return val.value.toString();
    if (val is DoubleCellValue) return val.value.toString();
    if (val is DateCellValue) {
      return '${val.year}-${val.month.toString().padLeft(2, '0')}-${val.day.toString().padLeft(2, '0')}';
    }
    if (val is DateTimeCellValue) {
      return '${val.year}-${val.month.toString().padLeft(2, '0')}-${val.day.toString().padLeft(2, '0')}';
    }
    if (val is BoolCellValue) return val.value ? 'true' : 'false';
    return val.toString().trim();
  }

  // ---------------------------------------------------------
  // CSV PARSER
  // ---------------------------------------------------------
  static List<List<String>> _parseCsv(String csvString) {
    final List<List<String>> rows = [];
    final lines = csvString.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final List<String> cells = [];
      final StringBuffer current = StringBuffer();
      bool insideQuotes = false;

      for (int i = 0; i < line.length; i++) {
        final char = line[i];
        if (char == '"') {
          if (insideQuotes && i + 1 < line.length && line[i + 1] == '"') {
            current.write('"');
            i++;
          } else {
            insideQuotes = !insideQuotes;
          }
        } else if (char == ',' && !insideQuotes) {
          cells.add(current.toString().trim());
          current.clear();
        } else {
          current.write(char);
        }
      }
      cells.add(current.toString().trim());

      if (cells.any((c) => c.isNotEmpty)) {
        rows.add(cells);
      }
    }

    return rows;
  }

  // ---------------------------------------------------------
  // BATCH FIRESTORE COMMIT EXECUTION
  // ---------------------------------------------------------
  static Future<ImportCommitSummary> commitBatchImport({
    required ImportEntityType entityType,
    required List<ImportRowValidation> rowsToImport,
    required ConflictStrategy strategy,
    void Function(double progress, String status)? onProgress,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final collectionName = entityType.targetCollection;
    final collectionRef = firestore.collection(collectionName);

    int insertedCount = 0;
    int updatedCount = 0;
    int skippedCount = 0;
    final List<String> errorMessages = [];

    final eligibleRows = rowsToImport.where((r) => r.isValid).toList();
    final total = eligibleRows.length;

    WriteBatch batch = firestore.batch();
    int batchOpCount = 0;

    for (int i = 0; i < eligibleRows.length; i++) {
      final item = eligibleRows[i];

      if (onProgress != null && (i % 25 == 0 || i == total - 1)) {
        final progress = total == 0 ? 1.0 : (i + 1) / total;
        onProgress(progress, 'Committing record ${i + 1} of $total...');
      }

      try {
        if (item.isConflict && item.conflictEntityId != null) {
          if (strategy == ConflictStrategy.skip) {
            skippedCount++;
            continue;
          } else if (strategy == ConflictStrategy.overwrite) {
            final docRef = collectionRef.doc(item.conflictEntityId);
            batch.set(docRef, {
              ...item.parsedPayload,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
            updatedCount++;
            batchOpCount++;
          } else {
            // createDuplicate
            final newDoc = collectionRef.doc();
            batch.set(newDoc, {
              ...item.parsedPayload,
              'createdAt': FieldValue.serverTimestamp(),
            });
            insertedCount++;
            batchOpCount++;
          }
        } else {
          // Brand new record
          final newDoc = collectionRef.doc();
          batch.set(newDoc, {
            ...item.parsedPayload,
            'createdAt': FieldValue.serverTimestamp(),
          });
          insertedCount++;
          batchOpCount++;
        }

        // Firestore batch max is 500; flush at 400 safely
        if (batchOpCount >= 400) {
          await batch.commit();
          batch = firestore.batch();
          batchOpCount = 0;
        }
      } catch (e) {
        errorMessages.add('Row ${item.rowIndex}: $e');
      }
    }

    if (batchOpCount > 0) {
      await batch.commit();
    }

    return ImportCommitSummary(
      totalProcessed: eligibleRows.length,
      insertedCount: insertedCount,
      updatedCount: updatedCount,
      skippedCount: skippedCount,
      errorMessages: errorMessages,
    );
  }
}
