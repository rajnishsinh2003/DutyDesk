import 'dart:developer';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import '../../auth/auth_provider.dart';
import '../../admin/providers/invigilator_provider.dart';
import '../../../core/services/smtp_email_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/offline_sync_service.dart';
import '../../notifications/providers/notification_provider.dart';

class ExamDuty {
  final String id;
  final String date;
  final String examName;
  final String centerName;
  final String invigilatorId;
  final String status;
  final String payment;
  final String lunch;
  final String role;
  final String shift;
  final String sessionId;
  final String reportingTime;
  final String excellentUntil; // e.g. "06:20 AM"
  final String goodUntil;      // e.g. "06:30 AM"
  final bool isReached;
  final DateTime? reachedAt;
  final String? reachedTime;
  final String? reachedDate;
  final String? reachedPerformance; // 'Excellent', 'Good', 'Needs Improvement'
  final String? reachedMessage;
  final double? reachedLatitude;
  final double? reachedLongitude;
  final String? reachedLocation;
  final String? reachedMapsUrl;
  final double? distanceFromCenter;
  final bool? isGeofenceVerified;
  final String? geofenceStatus; // 'verified', 'outside', 'manual_requested', 'no_coords'
  final String paymentStatus; // 'pending', 'approved', 'paid'
  final DateTime? paidAt;
  final String? paymentReference;
  final String? paymentRemarks;

  ExamDuty({
    required this.id,
    required this.date,
    required this.examName,
    required this.centerName,
    required this.invigilatorId,
    required this.status,
    required this.payment,
    required this.lunch,
    required this.role,
    required this.shift,
    this.sessionId = '',
    this.reportingTime = '05:00 AM',
    this.excellentUntil = '06:20 AM',
    this.goodUntil = '06:30 AM',
    this.isReached = false,
    this.reachedAt,
    this.reachedTime,
    this.reachedDate,
    this.reachedPerformance,
    this.reachedMessage,
    this.reachedLatitude,
    this.reachedLongitude,
    this.reachedLocation,
    this.reachedMapsUrl,
    this.distanceFromCenter,
    this.isGeofenceVerified,
    this.geofenceStatus,
    this.paymentStatus = 'pending',
    this.paidAt,
    this.paymentReference,
    this.paymentRemarks,
  });

  factory ExamDuty.fromFirestore(String id, Map<String, dynamic> data) {
    final Timestamp? reachedTimestamp = data['reachedAt'];
    final Timestamp? paidTimestamp = data['paidAt'];
    return ExamDuty(
      id: id,
      date: data['date'] ?? '',
      examName: data['examName'] ?? '',
      centerName: data['centerName'] ?? '',
      invigilatorId: data['invigilatorId'] ?? '',
      status: data['status'] ?? 'pending',
      payment: data['payment'] ?? getAutoPaymentForShift(data['shift'] ?? '1'),
      lunch: data['lunch'] ?? 'No',
      role: data['role'] ?? 'inv',
      shift: data['shift'] ?? '1',
      sessionId: data['sessionId'] ?? '',
      reportingTime: data['reportingTime'] ?? '05:00 AM',
      excellentUntil: data['excellentUntil'] ?? '06:20 AM',
      goodUntil: data['goodUntil'] ?? '06:30 AM',
      isReached: data['isReached'] ?? false,
      reachedAt: reachedTimestamp?.toDate(),
      reachedTime: data['reachedTime'],
      reachedDate: data['reachedDate'],
      reachedPerformance: data['reachedPerformance'],
      reachedMessage: data['reachedMessage'],
      reachedLatitude: (data['reachedLatitude'] as num?)?.toDouble(),
      reachedLongitude: (data['reachedLongitude'] as num?)?.toDouble(),
      reachedLocation: data['reachedLocation'],
      reachedMapsUrl: data['reachedMapsUrl'],
      distanceFromCenter: (data['distanceFromCenter'] as num?)?.toDouble(),
      isGeofenceVerified: data['isGeofenceVerified'],
      geofenceStatus: data['geofenceStatus'],
      paymentStatus: data['paymentStatus'] ?? 'pending',
      paidAt: paidTimestamp?.toDate(),
      paymentReference: data['paymentReference'],
      paymentRemarks: data['paymentRemarks'],
    );
  }

  ExamDuty copyWith({
    String? id,
    String? date,
    String? examName,
    String? centerName,
    String? invigilatorId,
    String? status,
    String? payment,
    String? lunch,
    String? role,
    String? shift,
    String? sessionId,
    String? reportingTime,
    String? excellentUntil,
    String? goodUntil,
    bool? isReached,
    DateTime? reachedAt,
    String? reachedTime,
    String? reachedDate,
    String? reachedPerformance,
    String? reachedMessage,
    double? reachedLatitude,
    double? reachedLongitude,
    String? reachedLocation,
    String? reachedMapsUrl,
    double? distanceFromCenter,
    bool? isGeofenceVerified,
    String? geofenceStatus,
    String? paymentStatus,
    DateTime? paidAt,
    String? paymentReference,
    String? paymentRemarks,
  }) {
    return ExamDuty(
      id: id ?? this.id,
      date: date ?? this.date,
      examName: examName ?? this.examName,
      centerName: centerName ?? this.centerName,
      invigilatorId: invigilatorId ?? this.invigilatorId,
      status: status ?? this.status,
      payment: payment ?? this.payment,
      lunch: lunch ?? this.lunch,
      role: role ?? this.role,
      shift: shift ?? this.shift,
      sessionId: sessionId ?? this.sessionId,
      reportingTime: reportingTime ?? this.reportingTime,
      excellentUntil: excellentUntil ?? this.excellentUntil,
      goodUntil: goodUntil ?? this.goodUntil,
      isReached: isReached ?? this.isReached,
      reachedAt: reachedAt ?? this.reachedAt,
      reachedTime: reachedTime ?? this.reachedTime,
      reachedDate: reachedDate ?? this.reachedDate,
      reachedPerformance: reachedPerformance ?? this.reachedPerformance,
      reachedMessage: reachedMessage ?? this.reachedMessage,
      reachedLatitude: reachedLatitude ?? this.reachedLatitude,
      reachedLongitude: reachedLongitude ?? this.reachedLongitude,
      reachedLocation: reachedLocation ?? this.reachedLocation,
      reachedMapsUrl: reachedMapsUrl ?? this.reachedMapsUrl,
      distanceFromCenter: distanceFromCenter ?? this.distanceFromCenter,
      isGeofenceVerified: isGeofenceVerified ?? this.isGeofenceVerified,
      geofenceStatus: geofenceStatus ?? this.geofenceStatus,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paidAt: paidAt ?? this.paidAt,
      paymentReference: paymentReference ?? this.paymentReference,
      paymentRemarks: paymentRemarks ?? this.paymentRemarks,
    );
  }

  int get parsedPaymentAmount {
    try {
      final clean = payment.replaceAll(RegExp(r'[^0-9]'), '');
      return int.parse(clean);
    } catch (_) {
      return 400;
    }
  }

  String? get resolvedMapsUrl {
    if (reachedMapsUrl != null && reachedMapsUrl!.isNotEmpty) {
      return reachedMapsUrl;
    }
    if (reachedLatitude != null && reachedLongitude != null) {
      return 'https://www.google.com/maps/search/?api=1&query=$reachedLatitude,$reachedLongitude';
    }
    return null;
  }
}

String getAutoPaymentForShift(String shift) {
  final clean = shift.replaceAll(RegExp(r'[^0-9]'), '');
  switch (clean) {
    case '1':
      return '₹400';
    case '2':
      return '₹600';
    case '3':
      return '₹800';
    default:
      return '₹400';
  }
}

class DutyArrivalResult {
  final bool success;
  final String performance;
  final String message;
  final String reachedTime;
  final String reachedDate;
  final double? latitude;
  final double? longitude;
  final String? locationString;
  final String? mapsUrl;
  final double? distanceFromCenter;
  final bool? isGeofenceVerified;
  final String? geofenceStatus;
  final bool isOfflineSaved;
  final String? error;

  DutyArrivalResult({
    required this.success,
    required this.performance,
    required this.message,
    required this.reachedTime,
    required this.reachedDate,
    this.latitude,
    this.longitude,
    this.locationString,
    this.mapsUrl,
    this.distanceFromCenter,
    this.isGeofenceVerified,
    this.geofenceStatus,
    this.isOfflineSaved = false,
    this.error,
  });
}

class DutyNotifier extends Notifier<List<ExamDuty>> {
  StreamSubscription? _subscription;

  @override
  List<ExamDuty> build() {
    final authState = ref.watch(authProvider);
    final invigilatorId = authState.userId;

    if (invigilatorId == null) {
      return [];
    }

    if (Firebase.apps.isEmpty) {
      return [];
    }

    _subscription?.cancel();
    _subscription = FirebaseFirestore.instance
        .collection('duties')
        .where('invigilatorId', isEqualTo: invigilatorId)
        .snapshots()
        .listen((snapshot) {
      state = snapshot.docs.map((doc) => ExamDuty.fromFirestore(doc.id, doc.data())).toList();
    }, onError: (error) {
      log("Firestore duties subscription error: $error");
    });

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return [];
  }

  String _getRoleDisplayName(String roleCode) {
    switch (roleCode) {
      case 'inv':
        return 'Invigilator';
      case 'ls':
        return 'Lab Staff';
      case 'mtoe':
        return 'MTOE';
      default:
        return roleCode.toUpperCase();
    }
  }

  Future<void> allocateDuty({
    required String date,
    required String examName,
    required String centerName,
    required String invigilatorId,
    required String role,
    required String shift,
    String? payment,
    required String lunch,
    required String sessionId,
    String reportingTime = '05:00 AM',
    String excellentUntil = '06:20 AM',
    String goodUntil = '06:30 AM',
  }) async {
    final invigilators = ref.read(invigilatorProvider);
    final inv = invigilators.firstWhere(
      (i) => i.id == invigilatorId,
      orElse: () => Invigilator(id: '', name: 'Unknown Staff', resourceId: '', mobile: '', mockDutyCount: 0),
    );
    final email = inv.email;

    if (Firebase.apps.isEmpty) {
      throw Exception('Firebase is not initialized');
    }

    // Auto-compute shift remuneration if payment not explicitly overridden
    final calculatedPayment = (payment != null && payment.isNotEmpty && payment != '₹500') 
        ? payment 
        : getAutoPaymentForShift(shift);

    // 1. Add the duty to Firestore
    final dutyRef = await FirebaseFirestore.instance.collection('duties').add({
      'date': date,
      'examName': examName,
      'centerName': centerName,
      'invigilatorId': invigilatorId,
      'status': 'pending',
      'payment': calculatedPayment,
      'lunch': lunch,
      'role': role,
      'shift': shift,
      'sessionId': sessionId,
      'reportingTime': reportingTime,
      'excellentUntil': excellentUntil,
      'goodUntil': goodUntil,
      'isReached': false,
      'reachedAt': null,
      'reachedTime': null,
      'reachedDate': null,
      'reachedPerformance': null,
      'reachedMessage': null,
      'paymentStatus': 'pending',
      'emailStatus': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Dispatch In-App Notification to Invigilator
    try {
      await ref.read(notificationProvider.notifier).sendNotification(
            userId: invigilatorId,
            title: 'New Exam Duty Assigned',
            message: 'You have been assigned to "$examName" at $centerName (Shift $shift) on $date.',
            type: 'duty_assigned',
            dutyId: dutyRef.id,
            sessionId: sessionId,
          );
    } catch (_) {}

    // 3. Dispatch SMTP email directly if the email is provided
    if (email != null && email.isNotEmpty) {
      try {
        final emailBody = 'Hello ${inv.name},\n\n'
            'You have been assigned to invigilate the "$examName" exam.\n\n'
            'Assignment Details:\n'
            '- Date: $date\n'
            '- Center: $centerName\n'
            '- Shift: Shift $shift\n'
            '- Reporting Time: $reportingTime\n'
            '- Excellent Until: $excellentUntil\n'
            '- Good Until: $goodUntil\n'
            '- Lunch Provided: $lunch\n'
            '- Remuneration: $calculatedPayment\n\n'
            'Please log into the DutyDesk application to accept or reject this assignment.';

        await SmtpEmailService.sendEmail(
          toAddress: email,
          subject: 'Exam Duty Assignment: $examName',
          bodyText: emailBody,
        );

        await dutyRef.update({'emailStatus': 'sent'});

        await FirebaseFirestore.instance.collection('email_logs').add({
          'dutyId': dutyRef.id,
          'toAddress': email,
          'subject': 'Exam Duty Assignment: $examName',
          'body': emailBody,
          'status': 'sent',
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (smtpError) {
        await dutyRef.update({
          'emailStatus': 'failed',
          'emailError': smtpError.toString(),
        });
      }
    }
  }

  Future<void> updateDutyStatus(String id, String status) async {
    if (Firebase.apps.isEmpty) return;

    try {
      final docRef = FirebaseFirestore.instance.collection('duties').doc(id);
      final snapshot = await docRef.get();
      if (!snapshot.exists) return;
      
      final data = snapshot.data()!;
      final oldStatus = data['status'] ?? 'pending';
      final examName = data['examName'] ?? '';
      final date = data['date'] ?? '';
      final centerName = data['centerName'] ?? '';
      final invId = data['invigilatorId'] ?? '';

      await docRef.update({'status': status});

      if (oldStatus != status && (status == 'accepted' || status == 'rejected')) {
        final invigilators = ref.read(invigilatorProvider);
        final inv = invigilators.firstWhere(
          (i) => i.id == invId,
          orElse: () => Invigilator(id: '', name: 'Unknown Staff', resourceId: '-', mobile: '', mockDutyCount: 0),
        );

        // Send in-app notification to Admin
        try {
          await ref.read(notificationProvider.notifier).sendNotification(
                userId: 'admin',
                title: '🔔 Duty ${status.toUpperCase()}: ${inv.name}',
                message: '${inv.name} (Res: ${inv.resourceId}) has ${status.toLowerCase()} duty for "$examName" on $date.',
                type: status == 'accepted' ? 'duty_accepted' : 'duty_rejected',
                dutyId: id,
              );
        } catch (_) {}

        final subject = '🔔 Duty Response: ${inv.name} has ${status.toUpperCase()} duty';
        final bodyText = 'Hello Admin,\n\n'
            '${inv.name} (Resource ID: ${inv.resourceId}) has ${status.toLowerCase()} the duty assignment for "$examName".\n\n'
            'Details:\n'
            '- Date: $date\n'
            '- Center: $centerName\n'
            '- Response: ${status.toUpperCase()}\n\n'
            'Thank you,\nDutyDesk Control System';

        try {
          await SmtpEmailService.sendEmail(
            toAddress: 'envirowatch.service@gmail.com',
            subject: subject,
            bodyText: bodyText,
          );
        } catch (mailErr) {
          log('SMTP auto-notify to admin failed: $mailErr');
        }
      }
    } catch (e) {
      log('Error updating duty status: $e');
    }
  }

  /// Parses a time string like "06:20 AM" to minutes-since-midnight.
  int _parseTimeToMinutes(String timeStr) {
    try {
      final parsed = DateFormat('hh:mm a').parse(timeStr.trim());
      return parsed.hour * 60 + parsed.minute;
    } catch (_) {
      return 0;
    }
  }

  /// Evaluates arrival time against duty-level timing thresholds:
  /// At or before excellentUntil => Excellent ("You reached on time.")
  /// After excellentUntil and at or before goodUntil => Good ("You reached slightly late.")
  /// After goodUntil => Needs Improvement ("Reach in proper time.")
  DutyArrivalResult evaluateArrival(
    DateTime now, {
    String excellentUntil = '06:20 AM',
    String goodUntil = '06:30 AM',
  }) {
    final totalMinutes = now.hour * 60 + now.minute;
    final excellentMinutes = _parseTimeToMinutes(excellentUntil);
    final goodMinutes = _parseTimeToMinutes(goodUntil);

    String performance;
    String message;

    if (totalMinutes <= excellentMinutes) {
      performance = 'Excellent';
      message = 'You reached on time.';
    } else if (totalMinutes <= goodMinutes) {
      performance = 'Good';
      message = 'You reached slightly late.';
    } else {
      performance = 'Needs Improvement';
      message = 'Reach in proper time.';
    }

    final reachedTimeStr = DateFormat('hh:mm a').format(now);
    final reachedDateStr = DateFormat('yyyy-MM-dd').format(now);

    return DutyArrivalResult(
      success: true,
      performance: performance,
      message: message,
      reachedTime: reachedTimeStr,
      reachedDate: reachedDateStr,
    );
  }

  Future<DutyArrivalResult> recordDutyReached({
    required String dutyId,
    required String invigilatorId,
    String? reportingTime,
    String excellentUntil = '06:20 AM',
    String goodUntil = '06:30 AM',
    double? centerLat,
    double? centerLng,
    int allowedRadiusMeters = 200,
    bool isManualOverride = false,
  }) async {
    final now = DateTime.now();
    final eval = evaluateArrival(now, excellentUntil: excellentUntil, goodUntil: goodUntil);

    // 1. Capture High Accuracy GPS Location (MANDATORY FOR ALL USERS)
    final loc = await LocationService.getCurrentLocation();
    if (!loc.success || loc.latitude == null || loc.longitude == null) {
      return DutyArrivalResult(
        success: false,
        performance: 'Unknown',
        message: loc.errorMessage ?? 'Location is mandatory to record duty reached. Please enable GPS and allow location access.',
        error: loc.errorMessage ?? 'Location is mandatory to record duty reached.',
        reachedTime: '',
        reachedDate: '',
      );
    }
    
    // 2. Geofence Verification
    final geofence = LocationService.verifyGeofence(
      staffLat: loc.latitude!,
      staffLng: loc.longitude!,
      centerLat: centerLat,
      centerLng: centerLng,
      allowedRadiusMeters: allowedRadiusMeters,
    );

    final isVerified = isManualOverride ? false : geofence.isVerified;
    final geofenceStatus = isManualOverride ? 'manual_requested' : geofence.status;
    final distanceMeters = geofence.distanceMeters;

    if (Firebase.apps.isEmpty) {
      // Offline fallback
      final offlineRecord = OfflineArrivalRecord(
        dutyId: dutyId,
        invigilatorId: invigilatorId,
        reachedDate: eval.reachedDate,
        reachedTime: eval.reachedTime,
        performance: eval.performance,
        message: eval.message,
        latitude: loc.latitude,
        longitude: loc.longitude,
        locationString: loc.locationString,
        mapsUrl: loc.mapsUrl,
        distanceFromCenter: distanceMeters,
        isGeofenceVerified: isVerified,
        geofenceStatus: geofenceStatus,
        timestamp: now.toIso8601String(),
      );
      await OfflineSyncService.saveOfflineArrival(offlineRecord);

      return DutyArrivalResult(
        success: true,
        performance: eval.performance,
        message: 'Arrival Recorded Offline (Waiting for Internet)',
        reachedTime: eval.reachedTime,
        reachedDate: eval.reachedDate,
        latitude: loc.latitude,
        longitude: loc.longitude,
        locationString: loc.locationString,
        mapsUrl: loc.mapsUrl,
        distanceFromCenter: distanceMeters,
        isGeofenceVerified: isVerified,
        geofenceStatus: geofenceStatus,
        isOfflineSaved: true,
      );
    }

    try {
      final docRef = FirebaseFirestore.instance.collection('duties').doc(dutyId);
      final snapshot = await docRef.get();
      if (!snapshot.exists) {
        return DutyArrivalResult(
          success: false,
          performance: 'Unknown',
          message: 'Duty record not found',
          reachedTime: '',
          reachedDate: '',
          error: 'Duty record not found',
        );
      }

      final data = snapshot.data()!;
      // Prevent duplicate submissions
      if (data['isReached'] == true) {
        return DutyArrivalResult(
          success: true,
          performance: data['reachedPerformance'] ?? 'Excellent',
          message: data['reachedMessage'] ?? 'Already reached.',
          reachedTime: data['reachedTime'] ?? '',
          reachedDate: data['reachedDate'] ?? '',
          latitude: (data['reachedLatitude'] as num?)?.toDouble(),
          longitude: (data['reachedLongitude'] as num?)?.toDouble(),
          locationString: data['reachedLocation'],
          mapsUrl: data['reachedMapsUrl'],
          distanceFromCenter: (data['distanceFromCenter'] as num?)?.toDouble(),
          isGeofenceVerified: data['isGeofenceVerified'],
          geofenceStatus: data['geofenceStatus'],
        );
      }

      await docRef.update({
        'isReached': true,
        'reachedAt': FieldValue.serverTimestamp(),
        'reachedTime': eval.reachedTime,
        'reachedDate': eval.reachedDate,
        'reachedPerformance': eval.performance,
        'reachedMessage': eval.message,
        'reachedLatitude': loc.latitude,
        'reachedLongitude': loc.longitude,
        'reachedLocation': loc.locationString ?? 'Location unavailable',
        'reachedMapsUrl': loc.mapsUrl,
        'distanceFromCenter': distanceMeters,
        'isGeofenceVerified': isVerified,
        'geofenceStatus': geofenceStatus,
      });

      // Send alert notification to Admin if staff is late or outside geofence
      if (geofenceStatus == 'outside' || geofenceStatus == 'manual_requested' || eval.performance == 'Needs Improvement') {
        try {
          final inv = ref.read(invigilatorProvider).firstWhere(
            (i) => i.id == invigilatorId,
            orElse: () => Invigilator(id: '', name: 'Staff', resourceId: '-', mobile: '', mockDutyCount: 0),
          );
          final alertMsg = geofenceStatus == 'manual_requested'
              ? '${inv.name} reported arrival outside geofence (${geofence.formattedDistance} away).'
              : '${inv.name} reported arrival late at ${eval.reachedTime}.';
          await ref.read(notificationProvider.notifier).sendNotification(
                userId: 'admin',
                title: '⚠️ Arrival Alert: ${inv.name}',
                message: alertMsg,
                type: 'geofence_alert',
                dutyId: dutyId,
              );
        } catch (_) {}
      }

      return DutyArrivalResult(
        success: true,
        performance: eval.performance,
        message: eval.message,
        reachedTime: eval.reachedTime,
        reachedDate: eval.reachedDate,
        latitude: loc.latitude,
        longitude: loc.longitude,
        locationString: loc.locationString,
        mapsUrl: loc.mapsUrl,
        distanceFromCenter: distanceMeters,
        isGeofenceVerified: isVerified,
        geofenceStatus: geofenceStatus,
      );
    } catch (e) {
      log('Error recording duty reached to Firestore: $e. Caching offline...');
      // Save offline on Firestore failure
      final offlineRecord = OfflineArrivalRecord(
        dutyId: dutyId,
        invigilatorId: invigilatorId,
        reachedDate: eval.reachedDate,
        reachedTime: eval.reachedTime,
        performance: eval.performance,
        message: eval.message,
        latitude: loc.latitude,
        longitude: loc.longitude,
        locationString: loc.locationString,
        mapsUrl: loc.mapsUrl,
        distanceFromCenter: distanceMeters,
        isGeofenceVerified: isVerified,
        geofenceStatus: geofenceStatus,
        timestamp: now.toIso8601String(),
      );
      await OfflineSyncService.saveOfflineArrival(offlineRecord);

      return DutyArrivalResult(
        success: true,
        performance: eval.performance,
        message: 'Arrival Saved Offline (Will sync when online)',
        reachedTime: eval.reachedTime,
        reachedDate: eval.reachedDate,
        latitude: loc.latitude,
        longitude: loc.longitude,
        locationString: loc.locationString,
        mapsUrl: loc.mapsUrl,
        distanceFromCenter: distanceMeters,
        isGeofenceVerified: isVerified,
        geofenceStatus: geofenceStatus,
        isOfflineSaved: true,
      );
    }
  }

  Future<void> updateDutyPaymentStatus(
    String dutyId,
    String paymentStatus, {
    String? paymentReference,
    String? paymentRemarks,
  }) async {
    if (Firebase.apps.isEmpty) return;

    try {
      final docRef = FirebaseFirestore.instance.collection('duties').doc(dutyId);
      final updateData = <String, dynamic>{
        'paymentStatus': paymentStatus,
      };

      if (paymentStatus == 'paid') {
        updateData['paidAt'] = FieldValue.serverTimestamp();
      }
      if (paymentReference != null) {
        updateData['paymentReference'] = paymentReference;
      }
      if (paymentRemarks != null) {
        updateData['paymentRemarks'] = paymentRemarks;
      }

      await docRef.update(updateData);
    } catch (e) {
      log('Error updating payment status: $e');
    }
  }

  Future<void> bulkUpdatePaymentStatus(
    List<String> dutyIds,
    String paymentStatus, {
    String? paymentReference,
    String? paymentRemarks,
  }) async {
    if (Firebase.apps.isEmpty) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final id in dutyIds) {
        final docRef = FirebaseFirestore.instance.collection('duties').doc(id);
        final updateData = <String, dynamic>{
          'paymentStatus': paymentStatus,
        };
        if (paymentStatus == 'paid') {
          updateData['paidAt'] = FieldValue.serverTimestamp();
        }
        if (paymentReference != null) {
          updateData['paymentReference'] = paymentReference;
        }
        if (paymentRemarks != null) {
          updateData['paymentRemarks'] = paymentRemarks;
        }
        batch.update(docRef, updateData);
      }
      await batch.commit();
    } catch (e) {
      log('Error in bulk payment status update: $e');
    }
  }

  Future<void> bulkAllocateDuties({
    required List<String> invigilatorIds,
    required String date,
    required String examName,
    required String centerName,
    required String role,
    required String shift,
    String? payment,
    required String lunch,
    required String sessionId,
    String reportingTime = '05:00 AM',
    String excellentUntil = '06:20 AM',
    String goodUntil = '06:30 AM',
  }) async {
    for (final invId in invigilatorIds) {
      try {
        await allocateDuty(
          date: date,
          examName: examName,
          centerName: centerName,
          invigilatorId: invId,
          role: role,
          shift: shift,
          payment: payment,
          lunch: lunch,
          sessionId: sessionId,
          reportingTime: reportingTime,
          excellentUntil: excellentUntil,
          goodUntil: goodUntil,
        );
      } catch (e) {
        log('Error in bulk allocate for inv $invId: $e');
      }
    }
  }

  Future<void> bulkAllocateMultiDateDuties({
    required List<String> dates,
    required List<String> invigilatorIds,
    required String examName,
    required String centerName,
    required String role,
    required String shift,
    String? payment,
    required String lunch,
    required String sessionId,
    String reportingTime = '05:00 AM',
    String excellentUntil = '06:20 AM',
    String goodUntil = '06:30 AM',
  }) async {
    for (final date in dates) {
      for (final invId in invigilatorIds) {
        try {
          await allocateDuty(
            date: date,
            examName: examName,
            centerName: centerName,
            invigilatorId: invId,
            role: role,
            shift: shift,
            payment: payment,
            lunch: lunch,
            sessionId: sessionId,
            reportingTime: reportingTime,
            excellentUntil: excellentUntil,
            goodUntil: goodUntil,
          );
        } catch (e) {
          log('Error in multi-date allocate for date $date, inv $invId: $e');
        }
      }
    }
  }

  Future<void> bulkAllocateIndividualDuties({
    required String date,
    required String examName,
    required String centerName,
    required String sessionId,
    required Map<String, Map<String, String>> individualSettings,
  }) async {
    for (final entry in individualSettings.entries) {
      final invId = entry.key;
      final settings = entry.value;
      final shiftVal = settings['shift'] ?? '1';
      final payVal = settings['payment'] ?? getAutoPaymentForShift(shiftVal);
      try {
        await allocateDuty(
          date: date,
          examName: examName,
          centerName: centerName,
          invigilatorId: invId,
          role: settings['role'] ?? 'inv',
          shift: shiftVal,
          payment: payVal,
          lunch: settings['lunch'] ?? 'No',
          sessionId: sessionId,
          reportingTime: settings['reportingTime'] ?? '05:00 AM',
          excellentUntil: settings['excellentUntil'] ?? '06:20 AM',
          goodUntil: settings['goodUntil'] ?? '06:30 AM',
        );
      } catch (e) {
        log('Error in bulk individual allocate for inv $invId: $e');
      }
    }
  }

  Future<void> reassignDuty(String dutyId, String newInvigilatorId) async {
    if (Firebase.apps.isEmpty) return;

    try {
      final inv = ref.read(invigilatorProvider).firstWhere(
        (i) => i.id == newInvigilatorId,
        orElse: () => Invigilator(id: '', name: 'Unknown Staff', resourceId: '', mobile: '', mockDutyCount: 0),
      );

      await FirebaseFirestore.instance.collection('duties').doc(dutyId).update({
        'invigilatorId': newInvigilatorId,
        'status': 'pending',
        'isReached': false,
        'reachedAt': null,
        'reachedTime': null,
        'reachedPerformance': null,
      });

      final doc = await FirebaseFirestore.instance.collection('duties').doc(dutyId).get();
      final data = doc.data() ?? {};
      final examName = data['examName'] ?? '';
      final date = data['date'] ?? '';
      final centerName = data['centerName'] ?? '';
      final role = data['role'] ?? 'inv';
      final shift = data['shift'] ?? '1';
      final lunch = data['lunch'] ?? 'No';
      final payment = data['payment'] ?? getAutoPaymentForShift(shift);

      // In-app notification for reassignment
      try {
        await ref.read(notificationProvider.notifier).sendNotification(
              userId: newInvigilatorId,
              title: 'Exam Duty Reassigned to You',
              message: 'You have been reassigned to "$examName" at $centerName (Shift $shift) on $date.',
              type: 'duty_reassigned',
              dutyId: dutyId,
            );
      } catch (_) {}

      if (inv.email != null && inv.email!.isNotEmpty) {
        final reportTime = data['reportingTime'] ?? '05:00 AM';
        final excUntil = data['excellentUntil'] ?? '06:20 AM';
        final gdUntil = data['goodUntil'] ?? '06:30 AM';
        final emailBody = 'Hello ${inv.name},\n\n'
            'You have been reassigned to invigilate the "$examName" exam.\n\n'
            'Assignment Details:\n'
            '- Date: $date\n'
            '- Center: $centerName\n'
            '- Role: ${_getRoleDisplayName(role)}\n'
            '- Shift: Shift $shift\n'
            '- Reporting Time: $reportTime\n'
            '- Excellent Until: $excUntil\n'
            '- Good Until: $gdUntil\n'
            '- Lunch Provided: $lunch\n'
            '- Remuneration: $payment\n\n'
            'Please log into the DutyDesk application to accept or reject this assignment.';

        await SmtpEmailService.sendEmail(
          toAddress: inv.email!,
          subject: 'Reassigned Exam Duty: $examName',
          bodyText: emailBody,
        );
      }
    } catch (e) {
      log('Error reassigning duty: $e');
    }
  }

  Future<void> sendManualReminder(String dutyId) async {
    if (Firebase.apps.isEmpty) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('duties').doc(dutyId).get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final invId = data['invigilatorId'] ?? '';
      final examName = data['examName'] ?? '';
      final date = data['date'] ?? '';
      final centerName = data['centerName'] ?? '';
      final role = data['role'] ?? 'inv';
      final shift = data['shift'] ?? '1';

      final inv = ref.read(invigilatorProvider).firstWhere(
        (i) => i.id == invId,
        orElse: () => Invigilator(id: '', name: 'Unknown Staff', resourceId: '', mobile: '', mockDutyCount: 0),
      );

      // In-app notification for reminder
      try {
        await ref.read(notificationProvider.notifier).sendNotification(
              userId: invId,
              title: '⏰ Duty Reminder: Pending Response',
              message: 'Reminder: Please accept or reject your assignment for "$examName" at $centerName on $date.',
              type: 'duty_reminder',
              dutyId: dutyId,
            );
      } catch (_) {}

      if (inv.email != null && inv.email!.isNotEmpty) {
        final reportTime = data['reportingTime'] ?? '05:00 AM';
        final excUntil = data['excellentUntil'] ?? '06:20 AM';
        final gdUntil = data['goodUntil'] ?? '06:30 AM';
        final emailBody = 'Hello ${inv.name},\n\n'
            'This is a friendly reminder that you have a pending exam duty assignment for "$examName".\n\n'
            'Assignment Details:\n'
            '- Date: $date\n'
            '- Center: $centerName\n'
            '- Role: ${_getRoleDisplayName(role)}\n'
            '- Shift: Shift $shift\n'
            '- Reporting Time: $reportTime\n'
            '- Excellent Until: $excUntil\n'
            '- Good Until: $gdUntil\n\n'
            'Please log into DutyDesk to accept or reject this assignment as soon as possible.';

        await SmtpEmailService.sendEmail(
          toAddress: inv.email!,
          subject: '⚠️ Reminder: Pending Exam Duty Assignment: $examName',
          bodyText: emailBody,
        );
      }
    } catch (e) {
      log('Error sending manual reminder: $e');
    }
  }

  Future<void> deleteDuty(String id) async {
    if (Firebase.apps.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('duties').doc(id).delete();
    } catch (e) {
      log('Error deleting duty: $e');
    }
  }
}

class GlobalDutyNotifier extends Notifier<List<ExamDuty>> {
  StreamSubscription? _subscription;

  @override
  List<ExamDuty> build() {
    if (Firebase.apps.isEmpty) {
      return [];
    }

    _subscription?.cancel();
    _subscription = FirebaseFirestore.instance
        .collection('duties')
        .snapshots()
        .listen((snapshot) {
      state = snapshot.docs.map((doc) => ExamDuty.fromFirestore(doc.id, doc.data())).toList();
    }, onError: (error) {
      log("Firestore global duties subscription error: $error");
    });

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return [];
  }
}

final dutyProvider = NotifierProvider<DutyNotifier, List<ExamDuty>>(() {
  return DutyNotifier();
});

final globalDutyProvider = NotifierProvider<GlobalDutyNotifier, List<ExamDuty>>(() {
  return GlobalDutyNotifier();
});
