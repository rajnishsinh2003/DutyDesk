import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:duty_desk/l10n/app_localizations.dart';
import '../auth_provider.dart';

/// Concept 1: "The Shield Lock" (Security & Verification Focus)
/// High-security animated splash screen featuring:
/// - Layer 1: SVG Path-drawn outline of the shield in radiant cyan/light-blue
/// - Layer 2: Inner 'D' lock core sliding in and snapping with tactile scale-pop & haptic pulse
/// - Layer 3: Typography "DutyDesk" and subtitle sliding up (y: 12px -> 0px) and fading in
/// - Completion: Glowing cyan aura pulse and wave-animated 3-dot session sync indicator
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainAnimCtrl;
  late AnimationController _pulseAnimCtrl;

  // Layer 1: Shield Outline Path Draw (0.0 -> 0.40)
  late Animation<double> _shieldPathAnim;

  // Layer 2: Inner 'D' Lock Snap & Scale Pop (0.35 -> 0.65)
  late Animation<double> _innerDScaleAnim;
  late Animation<double> _innerDOpacityAnim;

  // Layer 3: Typography Slide-up & Fade-in (0.60 -> 0.85)
  late Animation<double> _textSlideAnim;
  late Animation<double> _textFadeAnim;

  // Completion: Aura Pulse & Glow (0.80 -> 1.00)
  late Animation<double> _auraPulseAnim;
  late Animation<double> _auraOpacityAnim;

  bool _hasHapticTriggered = false;

  @override
  void initState() {
    super.initState();

    // Main choreography: 1800ms
    _mainAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Continuous 3-dot micro-pulse loop: 1200ms
    _pulseAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Layer 1: Shield Stroke Drawing (0ms - 700ms)
    _shieldPathAnim = CurvedAnimation(
      parent: _mainAnimCtrl,
      curve: const Interval(0.0, 0.42, curve: Curves.easeInOutCubic),
    );

    // Layer 2: Inner 'D' Lock-in with satisfying elastic pop (630ms - 1150ms)
    _innerDScaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.88, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 65,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 35,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _mainAnimCtrl,
        curve: const Interval(0.35, 0.65),
      ),
    );

    _innerDOpacityAnim = CurvedAnimation(
      parent: _mainAnimCtrl,
      curve: const Interval(0.35, 0.52, curve: Curves.easeIn),
    );

    // Layer 3: Typography Slide Up (1080ms - 1530ms)
    _textSlideAnim = Tween<double>(begin: 14.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainAnimCtrl,
        curve: const Interval(0.60, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _textFadeAnim = CurvedAnimation(
      parent: _mainAnimCtrl,
      curve: const Interval(0.60, 0.82, curve: Curves.easeIn),
    );

    // Completion: Aura Pulse (1440ms - 1800ms)
    _auraPulseAnim = Tween<double>(begin: 1.0, end: 1.45).animate(
      CurvedAnimation(
        parent: _mainAnimCtrl,
        curve: const Interval(0.80, 1.0, curve: Curves.easeOutQuad),
      ),
    );

    _auraOpacityAnim = Tween<double>(begin: 0.7, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainAnimCtrl,
        curve: const Interval(0.80, 1.0, curve: Curves.easeOut),
      ),
    );

    // Trigger haptic feedback exactly when the D locks in
    _mainAnimCtrl.addListener(() {
      if (_mainAnimCtrl.value >= 0.55 && !_hasHapticTriggered) {
        _hasHapticTriggered = true;
        HapticFeedback.mediumImpact();
      }
    });

    _startSessionResolution();
  }

  Future<void> _startSessionResolution() async {
    // Start main animation
    _mainAnimCtrl.forward();

    // Concurrently restore auth session from storage/Firebase
    final authNotifier = ref.read(authProvider.notifier);
    final restoredFuture = authNotifier.restoreSession();

    // Ensure users enjoy the complete 2.0s cinematic lock animation
    await Future.wait([
      restoredFuture,
      Future.delayed(const Duration(milliseconds: 2100)),
    ]);

    if (!mounted) return;

    final authState = ref.read(authProvider);

    // Smooth navigation based on verified role
    if (authState.role == UserRole.admin) {
      context.go('/admin_dashboard');
    } else if (authState.role == UserRole.auditor) {
      context.go('/auditor_dashboard');
    } else if (authState.role == UserRole.finance) {
      context.go('/admin_dashboard/payroll');
    } else if (authState.role == UserRole.invigilator && authState.userId != null) {
      context.go('/invigilator_dashboard');
    } else {
      if (kIsWeb) {
        context.go('/');
      } else {
        context.go('/login');
      }
    }
  }

  @override
  void dispose() {
    _mainAnimCtrl.dispose();
    _pulseAnimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Deep dark navy canvas background (#0B1220)
    const bgColor = Color(0xFF0B1220);
    const cyanAccent = Color(0xFF00F0FF);
    const brandTeal = Color(0xFF007A87);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background ambient radial gradient glow
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.0, -0.15),
                  radius: 0.95,
                  colors: [
                    brandTeal.withValues(alpha: 0.22),
                    const Color(0xFF0B172E).withValues(alpha: 0.5),
                    bgColor,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // Central Animated Brand Assembly
          Center(
            child: AnimatedBuilder(
              animation: _mainAnimCtrl,
              builder: (context, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Shield Lock Emblem Container
                    SizedBox(
                      width: 170,
                      height: 190,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Completion Aura Glow Pulse
                          if (_mainAnimCtrl.value >= 0.80)
                            Transform.scale(
                              scale: _auraPulseAnim.value,
                              child: Opacity(
                                opacity: _auraOpacityAnim.value,
                                child: Container(
                                  width: 140,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: cyanAccent.withValues(alpha: 0.8),
                                        blurRadius: 45,
                                        spreadRadius: 15,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          // Layer 1 & 2: Custom Shield and Inner "D" Lock Core
                          CustomPaint(
                            size: const Size(140, 160),
                            painter: _ShieldLockPainter(
                              pathProgress: _shieldPathAnim.value,
                              innerDScale: _innerDScaleAnim.value,
                              innerDOpacity: _innerDOpacityAnim.value,
                              glowAura: _auraOpacityAnim.value,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Layer 3: Typography "DutyDesk" (Slide Up & Fade In)
                    Transform.translate(
                      offset: Offset(0, _textSlideAnim.value),
                      child: Opacity(
                        opacity: _textFadeAnim.value,
                        child: Column(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Duty',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.0,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: cyanAccent.withValues(alpha: 0.45),
                                        blurRadius: 18,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  'Desk',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.0,
                                    color: cyanAccent,
                                    shadows: [
                                      Shadow(
                                        color: cyanAccent.withValues(alpha: 0.8),
                                        blurRadius: 24,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Subtitle
                            Text(
                              (S.of(context)?.examInvigilationManagement ??
                                      'EXAM INVIGILATION MANAGEMENT')
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.5,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Bottom Session Sync Status Indicator (Concept 2 Hybrid: 3 Micro-Dots Wave Pulse)
          Positioned(
            left: 0,
            right: 0,
            bottom: 54,
            child: AnimatedBuilder(
              animation: _pulseAnimCtrl,
              builder: (context, child) {
                return Opacity(
                  opacity: _textFadeAnim.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 3 Micro-dots wave pulse
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          // Phase shift each dot for wave animation
                          final phase = (_pulseAnimCtrl.value * 2 * math.pi) -
                              (index * 0.9);
                          final wave = (math.sin(phase) + 1.0) / 2.0; // 0.0 to 1.0

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            width: 7 + (wave * 3.5),
                            height: 7 + (wave * 3.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color.lerp(
                                const Color(0xFF334155),
                                cyanAccent,
                                wave,
                              ),
                              boxShadow: [
                                if (wave > 0.4)
                                  BoxShadow(
                                    color: cyanAccent.withValues(alpha: wave * 0.7),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                              ],
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 14),

                      // Minimal security status indicator text
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 13,
                            color: cyanAccent.withValues(alpha: 0.75),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'SECURE ENCLAVE VERIFICATION',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.8,
                              color: const Color(0xFF64748B)
                                  .withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Vector Painter that draws:
/// 1. Sleek Shield outline with progressive path metric stroke animation and glow
/// 2. Inner Stylized "D" shape with lock core geometry and scale pop
class _ShieldLockPainter extends CustomPainter {
  final double pathProgress;
  final double innerDScale;
  final double innerDOpacity;
  final double glowAura;

  _ShieldLockPainter({
    required this.pathProgress,
    required this.innerDScale,
    required this.innerDOpacity,
    required this.glowAura,
  });

  Path _createShieldPath(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    // High-tech angular aerodynamic shield contour
    path.moveTo(w * 0.5, h * 0.04);
    // Top right shoulder
    path.cubicTo(w * 0.76, h * 0.04, w * 0.96, h * 0.08, w * 0.97, h * 0.22);
    // Right flank tapering smoothly to bottom shield apex
    path.cubicTo(w * 0.97, h * 0.58, w * 0.78, h * 0.88, w * 0.5, h * 0.98);
    // Left flank curving up from bottom apex
    path.cubicTo(w * 0.22, h * 0.88, w * 0.03, h * 0.58, w * 0.03, h * 0.22);
    // Top left shoulder back to crown apex
    path.cubicTo(w * 0.04, h * 0.08, w * 0.24, h * 0.04, w * 0.5, h * 0.04);
    path.close();

    return path;
  }

  Path _createInnerDShape(Size size) {
    final w = size.width;
    final h = size.height;

    final left = w * 0.32;
    final right = w * 0.70;
    final top = h * 0.28;
    final bottom = h * 0.74;
    final r = (bottom - top) * 0.5;

    final outerPath = Path();
    outerPath.moveTo(left, top);
    outerPath.lineTo(left + (right - left) * 0.45, top);
    outerPath.arcToPoint(
      Offset(left + (right - left) * 0.45, bottom),
      radius: Radius.circular(r),
      clockwise: true,
    );
    outerPath.lineTo(left, bottom);
    outerPath.close();

    // Inner cutout creating the stylized "D"
    final innerLeft = left + (right - left) * 0.32;
    final innerRight = right - (right - left) * 0.30;
    final innerTop = top + (bottom - top) * 0.25;
    final innerBottom = bottom - (bottom - top) * 0.25;
    final innerR = (innerBottom - innerTop) * 0.5;

    final innerCutout = Path();
    innerCutout.moveTo(innerLeft, innerTop);
    innerCutout.lineTo(innerLeft + (innerRight - innerLeft) * 0.38, innerTop);
    innerCutout.arcToPoint(
      Offset(innerLeft + (innerRight - innerLeft) * 0.38, innerBottom),
      radius: Radius.circular(innerR),
      clockwise: true,
    );
    innerCutout.lineTo(innerLeft, innerBottom);
    innerCutout.close();

    return Path.combine(PathOperation.difference, outerPath, innerCutout);
  }

  @override
  void paint(Canvas canvas, Size size) {
    const cyanAccent = Color(0xFF00F0FF);
    const deepCyan = Color(0xFF007A87);
    const royalBlue = Color(0xFF0284C7);

    final shieldPath = _createShieldPath(size);

    // Subtle background tint once path is closing
    if (pathProgress > 0.6) {
      final fillOpacity = ((pathProgress - 0.6) / 0.4) * 0.16;
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            cyanAccent.withValues(alpha: fillOpacity),
            deepCyan.withValues(alpha: fillOpacity * 0.5),
            Colors.transparent,
          ],
        ).createShader(Offset.zero & size);

      canvas.drawPath(shieldPath, fillPaint);
    }

    // 1. LAYER 1: Shield Outline Stroke Drawing Animation
    if (pathProgress > 0.0) {
      final metrics = shieldPath.computeMetrics();
      for (final metric in metrics) {
        final currentLength = metric.length * pathProgress;
        final animatedPath = metric.extractPath(0.0, currentLength);

        // Ambient outer neon glow
        final glowPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0
          ..strokeCap = StrokeCap.round
          ..color = cyanAccent.withValues(alpha: 0.38)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

        canvas.drawPath(animatedPath, glowPaint);

        // Crisp vector foreground stroke
        final strokePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2
          ..strokeCap = StrokeCap.round
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cyanAccent,
              Color(0xFF38BDF8),
              deepCyan,
            ],
          ).createShader(Offset.zero & size);

        canvas.drawPath(animatedPath, strokePaint);
      }
    }

    // 2. LAYER 2: Inner "D" Shape (Slides & Snaps with Scale Pop)
    if (innerDOpacity > 0.0) {
      canvas.save();

      // Pivot around center of the shield
      final center = Offset(size.width * 0.5, size.height * 0.5);
      canvas.translate(center.dx, center.dy);
      canvas.scale(innerDScale);
      canvas.translate(-center.dx, -center.dy);

      final dShapePath = _createInnerDShape(size);

      // Inner "D" drop shadow / glow
      final dGlowPaint = Paint()
        ..color = cyanAccent.withValues(alpha: innerDOpacity * 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawPath(dShapePath, dGlowPaint);

      // Inner "D" gradient fill
      final dFillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cyanAccent.withValues(alpha: innerDOpacity),
            royalBlue.withValues(alpha: innerDOpacity * 0.95),
            deepCyan.withValues(alpha: innerDOpacity),
          ],
        ).createShader(Offset.zero & size);
      canvas.drawPath(dShapePath, dFillPaint);

      // Keyhole / Lock Pin Highlight: High-security center dot
      final pinPaint = Paint()
        ..color = const Color(0xFF0B1220)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(size.width * 0.505, size.height * 0.51),
        4.0,
        pinPaint,
      );

      final pinGlow = Paint()
        ..color = cyanAccent.withValues(alpha: innerDOpacity * 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(
        Offset(size.width * 0.505, size.height * 0.51),
        4.0,
        pinGlow,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ShieldLockPainter oldDelegate) {
    return oldDelegate.pathProgress != pathProgress ||
        oldDelegate.innerDScale != innerDScale ||
        oldDelegate.innerDOpacity != innerDOpacity ||
        oldDelegate.glowAura != glowAura;
  }
}
