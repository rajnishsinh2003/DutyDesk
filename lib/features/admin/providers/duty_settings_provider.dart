import 'dart:async';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class DutySettings {
  final bool allowDutySwap;
  final bool allowLunch;
  final bool allowRole;
  final int shift1Amount;
  final int shift2Amount;
  final int shift3Amount;
  final String reportingStartTime; // e.g. "05:00 AM"
  final String reportingExcellentEndTime; // e.g. "06:20 AM"
  final String reportingGoodEndTime; // e.g. "06:30 AM"
  final bool voiceFeedbackEnabled;
  final bool requireFaceVerification;
  final bool enableTravelAllowance;
  final int travelAllowancePerKm;
  final String smsGatewayUrl;
  final String smsApiKey;
  final String smsProvider; // 'fast2sms', 'msg91', 'textlocal', 'twilio', 'generic'
  final String whatsappGatewayUrl;
  final String whatsappApiKey;
  final int dataRetentionDays;

  const DutySettings({
    this.allowDutySwap = false,
    this.allowLunch = false,
    this.allowRole = false,
    this.shift1Amount = 400,
    this.shift2Amount = 600,
    this.shift3Amount = 800,
    this.reportingStartTime = '05:00 AM',
    this.reportingExcellentEndTime = '06:20 AM',
    this.reportingGoodEndTime = '06:30 AM',
    this.voiceFeedbackEnabled = true,
    this.requireFaceVerification = false,
    this.enableTravelAllowance = true,
    this.travelAllowancePerKm = 10,
    this.smsGatewayUrl = '',
    this.smsApiKey = '',
    this.smsProvider = 'generic',
    this.whatsappGatewayUrl = '',
    this.whatsappApiKey = '',
    this.dataRetentionDays = 90,
  });

  factory DutySettings.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const DutySettings();
    return DutySettings(
      allowDutySwap: data['allowDutySwap'] ?? false,
      allowLunch: data['allowLunch'] ?? false,
      allowRole: data['allowRole'] ?? false,
      shift1Amount: data['shift1Amount'] ?? 400,
      shift2Amount: data['shift2Amount'] ?? 600,
      shift3Amount: data['shift3Amount'] ?? 800,
      reportingStartTime: data['reportingStartTime'] ?? '05:00 AM',
      reportingExcellentEndTime: data['reportingExcellentEndTime'] ?? '06:20 AM',
      reportingGoodEndTime: data['reportingGoodEndTime'] ?? '06:30 AM',
      voiceFeedbackEnabled: data['voiceFeedbackEnabled'] ?? true,
      requireFaceVerification: data['requireFaceVerification'] ?? false,
      enableTravelAllowance: data['enableTravelAllowance'] ?? true,
      travelAllowancePerKm: data['travelAllowancePerKm'] ?? 10,
      smsGatewayUrl: data['smsGatewayUrl'] ?? '',
      smsApiKey: data['smsApiKey'] ?? '',
      smsProvider: data['smsProvider'] ?? 'generic',
      whatsappGatewayUrl: data['whatsappGatewayUrl'] ?? '',
      whatsappApiKey: data['whatsappApiKey'] ?? '',
      dataRetentionDays: data['dataRetentionDays'] ?? 90,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'allowDutySwap': allowDutySwap,
      'allowLunch': allowLunch,
      'allowRole': allowRole,
      'shift1Amount': shift1Amount,
      'shift2Amount': shift2Amount,
      'shift3Amount': shift3Amount,
      'reportingStartTime': reportingStartTime,
      'reportingExcellentEndTime': reportingExcellentEndTime,
      'reportingGoodEndTime': reportingGoodEndTime,
      'voiceFeedbackEnabled': voiceFeedbackEnabled,
      'requireFaceVerification': requireFaceVerification,
      'enableTravelAllowance': enableTravelAllowance,
      'travelAllowancePerKm': travelAllowancePerKm,
      'smsGatewayUrl': smsGatewayUrl,
      'smsApiKey': smsApiKey,
      'smsProvider': smsProvider,
      'whatsappGatewayUrl': whatsappGatewayUrl,
      'whatsappApiKey': whatsappApiKey,
      'dataRetentionDays': dataRetentionDays,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  DutySettings copyWith({
    bool? allowDutySwap,
    bool? allowLunch,
    bool? allowRole,
    int? shift1Amount,
    int? shift2Amount,
    int? shift3Amount,
    String? reportingStartTime,
    String? reportingExcellentEndTime,
    String? reportingGoodEndTime,
    bool? voiceFeedbackEnabled,
    bool? requireFaceVerification,
    bool? enableTravelAllowance,
    int? travelAllowancePerKm,
    String? smsGatewayUrl,
    String? smsApiKey,
    String? smsProvider,
    String? whatsappGatewayUrl,
    String? whatsappApiKey,
    int? dataRetentionDays,
  }) {
    return DutySettings(
      allowDutySwap: allowDutySwap ?? this.allowDutySwap,
      allowLunch: allowLunch ?? this.allowLunch,
      allowRole: allowRole ?? this.allowRole,
      shift1Amount: shift1Amount ?? this.shift1Amount,
      shift2Amount: shift2Amount ?? this.shift2Amount,
      shift3Amount: shift3Amount ?? this.shift3Amount,
      reportingStartTime: reportingStartTime ?? this.reportingStartTime,
      reportingExcellentEndTime: reportingExcellentEndTime ?? this.reportingExcellentEndTime,
      reportingGoodEndTime: reportingGoodEndTime ?? this.reportingGoodEndTime,
      voiceFeedbackEnabled: voiceFeedbackEnabled ?? this.voiceFeedbackEnabled,
      requireFaceVerification: requireFaceVerification ?? this.requireFaceVerification,
      enableTravelAllowance: enableTravelAllowance ?? this.enableTravelAllowance,
      travelAllowancePerKm: travelAllowancePerKm ?? this.travelAllowancePerKm,
      smsGatewayUrl: smsGatewayUrl ?? this.smsGatewayUrl,
      smsApiKey: smsApiKey ?? this.smsApiKey,
      smsProvider: smsProvider ?? this.smsProvider,
      whatsappGatewayUrl: whatsappGatewayUrl ?? this.whatsappGatewayUrl,
      whatsappApiKey: whatsappApiKey ?? this.whatsappApiKey,
      dataRetentionDays: dataRetentionDays ?? this.dataRetentionDays,
    );
  }

  int getAmountForShift(String shift) {
    final cleanShift = shift.replaceAll(RegExp(r'[^0-9]'), '');
    switch (cleanShift) {
      case '1':
        return shift1Amount;
      case '2':
        return shift2Amount;
      case '3':
        return shift3Amount;
      default:
        return shift1Amount;
    }
  }

  String getAmountFormattedForShift(String shift) {
    return '₹${getAmountForShift(shift)}';
  }
}

class DutySettingsNotifier extends Notifier<DutySettings> {
  StreamSubscription? _subscription;

  @override
  DutySettings build() {
    if (Firebase.apps.isEmpty) {
      return const DutySettings();
    }

    _subscription?.cancel();
    _subscription = FirebaseFirestore.instance
        .collection('settings')
        .doc('duty_settings')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        state = DutySettings.fromMap(snapshot.data());
      } else {
        // Create initial default document if not present
        FirebaseFirestore.instance
            .collection('settings')
            .doc('duty_settings')
            .set(const DutySettings().toMap(), SetOptions(merge: true))
            .catchError((err) => log('Initial duty settings write: $err'));
      }
    }, onError: (error) {
      log('DutySettings subscription error: $error');
    });

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return const DutySettings();
  }

  Future<void> updateSettings(DutySettings newSettings) async {
    state = newSettings;
    if (Firebase.apps.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('duty_settings')
          .set(newSettings.toMap(), SetOptions(merge: true));
    } catch (e) {
      log('Error updating duty settings: $e');
    }
  }

  Future<void> toggleDutySwap(bool allow) async {
    await updateSettings(state.copyWith(allowDutySwap: allow));
  }

  Future<void> toggleLunch(bool allow) async {
    await updateSettings(state.copyWith(allowLunch: allow));
  }

  Future<void> toggleRole(bool allow) async {
    await updateSettings(state.copyWith(allowRole: allow));
  }

  Future<void> toggleVoiceFeedback(bool enabled) async {
    await updateSettings(state.copyWith(voiceFeedbackEnabled: enabled));
  }

  Future<void> toggleRequireFaceVerification(bool enabled) async {
    await updateSettings(state.copyWith(requireFaceVerification: enabled));
  }

  Future<void> toggleEnableTravelAllowance(bool enabled) async {
    await updateSettings(state.copyWith(enableTravelAllowance: enabled));
  }

  Future<void> updateTravelAllowanceRate(int ratePerKm) async {
    await updateSettings(state.copyWith(travelAllowancePerKm: ratePerKm));
  }

  Future<void> updateSmsGatewayUrl(String url) async {
    await updateSettings(state.copyWith(smsGatewayUrl: url));
  }
}

final dutySettingsProvider =
    NotifierProvider<DutySettingsNotifier, DutySettings>(() {
  return DutySettingsNotifier();
});
