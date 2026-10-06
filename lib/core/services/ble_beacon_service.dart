import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum BleProximity {
  immediate, // < 1m
  near,      // 1 - 3.5m
  far,       // 3.5 - 10m
  unknown,
}

class ExamRoomBeacon {
  final String uuid;
  final int major;
  final int minor;
  final String roomName;
  final String centerName;
  final int rssi; // Signal strength in dBm (-50 is strong, -95 is weak)
  final double estimatedDistanceMeters;
  final BleProximity proximity;
  final DateTime lastSeen;

  const ExamRoomBeacon({
    required this.uuid,
    required this.major,
    required this.minor,
    required this.roomName,
    required this.centerName,
    required this.rssi,
    required this.estimatedDistanceMeters,
    required this.proximity,
    required this.lastSeen,
  });

  bool get isLockedInRoom =>
      proximity == BleProximity.immediate || proximity == BleProximity.near;
}

class BleBeaconState {
  final bool isScanning;
  final List<ExamRoomBeacon> detectedBeacons;
  final ExamRoomBeacon? activeRoomLock;
  final String? statusMessage;

  const BleBeaconState({
    this.isScanning = false,
    this.detectedBeacons = const [],
    this.activeRoomLock,
    this.statusMessage,
  });

  BleBeaconState copyWith({
    bool? isScanning,
    List<ExamRoomBeacon>? detectedBeacons,
    ExamRoomBeacon? activeRoomLock,
    String? statusMessage,
  }) {
    return BleBeaconState(
      isScanning: isScanning ?? this.isScanning,
      detectedBeacons: detectedBeacons ?? this.detectedBeacons,
      activeRoomLock: activeRoomLock ?? this.activeRoomLock,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

class BleBeaconNotifier extends Notifier<BleBeaconState> {
  Timer? _scanTimer;

  @override
  BleBeaconState build() {
    ref.onDispose(() {
      _scanTimer?.cancel();
    });
    return const BleBeaconState();
  }

  /// Start indoor BLE beacon scan for the specified exam center
  void startBeaconScan({required String centerName, String? expectedRoom}) {
    state = state.copyWith(
      isScanning: true,
      statusMessage: 'Scanning for indoor exam room BLE beacons...',
    );

    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _simulateBeaconTelemetry(centerName: centerName, expectedRoom: expectedRoom);
    });

    // Initial immediate scan
    _simulateBeaconTelemetry(centerName: centerName, expectedRoom: expectedRoom);
  }

  void stopBeaconScan() {
    _scanTimer?.cancel();
    state = state.copyWith(
      isScanning: false,
      statusMessage: 'Beacon scan paused',
    );
  }

  void _simulateBeaconTelemetry({required String centerName, String? expectedRoom}) {
    final rand = math.Random();
    // Simulate realistic indoor RSSI fluctuations between -55 dBm and -72 dBm
    final simulatedRssi = -58 - rand.nextInt(15);
    final distance = _calculateDistance(simulatedRssi, -59);
    final prox = distance < 1.2
        ? BleProximity.immediate
        : (distance < 3.5 ? BleProximity.near : BleProximity.far);

    final room = expectedRoom ?? 'Room 204 (Hall B)';
    final beacon = ExamRoomBeacon(
      uuid: 'FDA50693-A4E2-4FB1-AFCF-C6EB07647825',
      major: 101,
      minor: 204,
      roomName: room,
      centerName: centerName,
      rssi: simulatedRssi,
      estimatedDistanceMeters: double.parse(distance.toStringAsFixed(1)),
      proximity: prox,
      lastSeen: DateTime.now(),
    );

    state = state.copyWith(
      detectedBeacons: [beacon],
      activeRoomLock: beacon.isLockedInRoom ? beacon : null,
      statusMessage: beacon.isLockedInRoom
          ? 'Indoor Locked: $room (${beacon.estimatedDistanceMeters}m • ${beacon.rssi} dBm)'
          : 'Detecting room beacon ($room)...',
    );
  }

  /// Log-distance path loss formula for Bluetooth RSSI to approximate distance in meters
  static double _calculateDistance(int rssi, int txPowerAt1Meter) {
    if (rssi == 0) return -1.0;
    final ratio = rssi * 1.0 / txPowerAt1Meter;
    if (ratio < 1.0) {
      return math.pow(ratio, 10).toDouble();
    } else {
      return (0.89976) * math.pow(ratio, 7.7095) + 0.111;
    }
  }
}

final bleBeaconProvider = NotifierProvider<BleBeaconNotifier, BleBeaconState>(() {
  return BleBeaconNotifier();
});
