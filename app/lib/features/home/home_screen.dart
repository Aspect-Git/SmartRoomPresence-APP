import 'package:flutter/material.dart';
import '../../room_language.dart';

import '../../app/room_theme.dart';
import '../../thingsboard_service.dart';
import '../../shared/room_panel.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.roomName,
    required this.telemetry,
    required this.hasData,
    required this.isFresh,
    required this.isDemo,
    required this.fahrenheit,
    this.loading = false,
    this.error,
    required this.onAddRoom,
    required this.onAddDevice,
    required this.onOpenRooms,
    required this.onOpenInsights,
  });

  final String roomName;
  final Map<String, dynamic> telemetry;
  final bool hasData;
  final bool isFresh;
  final bool isDemo;
  final bool fahrenheit;
  final bool loading;
  final String? error;
  final VoidCallback onAddRoom;
  final VoidCallback onAddDevice;
  final VoidCallback onOpenRooms;
  final VoidCallback onOpenInsights;

  String _value(String key, String unit, {int digits = 0}) {
    final value = telemetryNumber(telemetry, key);
    if (value == null) return '—';
    return '${value.toStringAsFixed(digits)}$unit';
  }

  String _temperature() {
    final celsius = telemetryNumber(telemetry, 'temperature_c');
    if (celsius == null) return '—';
    if (fahrenheit) return '${(celsius * 9 / 5 + 32).toStringAsFixed(1)}°F';
    return '${celsius.toStringAsFixed(1)}°C';
  }

  @override
  Widget build(BuildContext context) {
    final presence = telemetryBool(telemetry, 'presence') ??
        telemetryBool(telemetry, 'radar_out');
    final co2 = telemetryNumber(telemetry, 'co2_ppm');
    final co2Critical = co2 != null && co2 >= 1500;
    final co2Elevated = co2 != null && co2 >= 1000;
    final connectionLabel = isDemo
        ? 'Demo data'
        : isFresh
            ? 'Connected'
            : hasData
                ? 'No recent data'
                : 'Not connected';
    final connectionColor = isDemo
        ? RoomColors.coralInk
        : isFresh
            ? RoomColors.green
            : RoomColors.muted;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const RoomText('Room overview',
                      style: TextStyle(
                          fontSize: 28,
                          height: 1.15,
                          fontWeight: FontWeight.w600,
                          color: RoomColors.ink)),
                  const SizedBox(height: 5),
                  RoomText(roomName,
                      style: const TextStyle(
                          color: RoomColors.secondary, fontSize: 14)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Add room',
              onPressed: onAddRoom,
              icon: const Icon(Icons.add_home_outlined),
            ),
          ],
        ),
        if (isDemo) ...[
          const SizedBox(height: 18),
          const RoomDemoNotice(),
        ],
        const SizedBox(height: 20),
        _MotionIn(
          delay: 0,
          child: loading
              ? const _PresenceSkeleton()
              : RoomPanel(
                  padding: 20,
                  color:
                      presence == true ? RoomColors.peach : RoomColors.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: RoomText('Presence now',
                                style: TextStyle(
                                    color: RoomColors.secondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500)),
                          ),
                          RoomStatusTag(
                            label: connectionLabel,
                            color: connectionColor,
                            background: isDemo
                                ? RoomColors.peach
                                : isFresh
                                    ? RoomColors.greenWash
                                    : RoomColors.raised,
                            icon: isDemo
                                ? Icons.science_outlined
                                : isFresh
                                    ? Icons.check_circle_outline
                                    : Icons.sensors_off_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            presence == null
                                ? Icons.sensors_off_outlined
                                : presence
                                    ? Icons.sensors
                                    : Icons.sensor_door_outlined,
                            color: presence == true
                                ? RoomColors.coralInk
                                : RoomColors.muted,
                            size: 30,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RoomText(
                                  presence == null
                                      ? 'Waiting for radar data'
                                      : presence
                                          ? 'Presence detected'
                                          : 'No presence detected',
                                  style: const TextStyle(
                                      color: RoomColors.ink,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 5),
                                RoomText(
                                  _rangeText(),
                                  style: const TextStyle(
                                      color: RoomColors.muted, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Divider(),
                      const SizedBox(height: 12),
                      const RoomText(
                        'Presence sensing can report a target range. It does not identify or count people.',
                        style: TextStyle(
                            color: RoomColors.secondary,
                            fontSize: 13,
                            height: 1.45),
                      ),
                    ],
                  ),
                ),
        ),
        RoomSectionTitle(
          'Room conditions',
          trailing: TextButton(
            onPressed: onOpenInsights,
            child: const RoomText('History'),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 500 ? 4 : 2;
            const gap = 12.0;
            final width =
                (constraints.maxWidth - (columns - 1) * gap) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                SizedBox(
                    width: width,
                    child: loading
                        ? const _MetricSkeleton()
                        : _MotionIn(
                            delay: 35,
                            child: RoomMetricCard(
                                label: 'Temperature',
                                value: _temperature(),
                                icon: Icons.thermostat_outlined))),
                SizedBox(
                    width: width,
                    child: loading
                        ? const _MetricSkeleton()
                        : _MotionIn(
                            delay: 75,
                            child: RoomMetricCard(
                                label: 'Humidity',
                                value: _value('humidity_pct', '%'),
                                icon: Icons.water_drop_outlined))),
                SizedBox(
                    width: width,
                    child: loading
                        ? const _MetricSkeleton()
                        : _MotionIn(
                            delay: 115,
                            child: RoomMetricCard(
                                label: 'Carbon dioxide',
                                value: _value('co2_ppm', ' ppm'),
                                detail: co2Critical
                                    ? 'Critical · ventilate now'
                                    : co2Elevated
                                        ? 'Elevated · consider ventilation'
                                        : null,
                                icon: Icons.air_outlined))),
                SizedBox(
                    width: width,
                    child: loading
                        ? const _MetricSkeleton()
                        : _MotionIn(
                            delay: 155,
                            child: RoomMetricCard(
                                label: 'Illuminance',
                                value: _value('lux', ' lx'),
                                icon: Icons.light_mode_outlined))),
              ],
            );
          },
        ),
        if (co2Elevated) ...[
          const SizedBox(height: 12),
          RoomStatusTag(
            label: co2Critical
                ? 'CO₂ is critically high · ventilate now'
                : 'CO₂ is elevated · consider ventilation',
            color: co2Critical ? RoomColors.red : RoomColors.amber,
            background: co2Critical ? RoomColors.redWash : RoomColors.amberWash,
            icon: Icons.air,
          ),
        ],
        const RoomSectionTitle('Device connection'),
        _MotionIn(
          delay: 200,
          child: RoomPanel(
            padding: 16,
            child: Column(
              children: [
                _connectionRow(
                  Icons.memory_outlined,
                  'Smart Room Presence board',
                  isDemo
                      ? 'Simulated'
                      : isFresh
                          ? 'Connected'
                          : 'No connection',
                ),
                if (hasData || isDemo) ...[
                  const Divider(height: 24),
                  _connectionRow(
                    Icons.wifi_outlined,
                    'Wi-Fi signal',
                    _value('wifi_rssi', ' dBm'),
                  ),
                  const Divider(height: 24),
                  _connectionRow(
                    Icons.cloud_outlined,
                    'ThingsBoard',
                    isDemo
                        ? 'Simulated'
                        : (telemetryBool(telemetry, 'mqtt_connected') ?? false)
                            ? 'Connected'
                            : 'Disconnected',
                  ),
                ],
                if (!isFresh && !isDemo) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onAddDevice,
                      icon: const Icon(Icons.bluetooth),
                      label: const RoomText('Set up device over BLE'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (error != null && !isDemo) ...[
          const SizedBox(height: 12),
          RoomStatusTag(
              label: 'Could not load readings · $error',
              color: RoomColors.red,
              background: RoomColors.redWash,
              icon: Icons.error_outline),
        ],
        const RoomSectionTitle('Device details'),
        RoomPanel(
          padding: 0,
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory,
            ),
            child: ExpansionTile(
              key: const ValueKey('device-diagnostics'),
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              leading:
                  const Icon(Icons.tune_outlined, color: RoomColors.coralInk),
              title: const RoomText('Hardware diagnostics',
                  style: TextStyle(
                      color: RoomColors.ink, fontWeight: FontWeight.w600)),
              subtitle: RoomText(isDemo
                  ? 'Simulated device checks'
                  : hasData
                      ? 'Reading availability'
                      : 'Waiting for device data'),
              children: [
                _sensorStatusRow(
                    'CO₂ readings', 'Carbon dioxide sensor', 'scd40_ok'),
                const Divider(height: 20),
                _sensorStatusRow('Room climate readings',
                    'Temperature and humidity', 'hdc2080_ok'),
                const Divider(height: 20),
                _sensorStatusRow(
                    'Light readings', 'Ambient light level', 'veml7700_ok'),
                const Divider(height: 20),
                _sensorStatusRow(
                    'Presence detection', 'Radar status', 'radar_ok'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: onOpenRooms,
          icon: const Icon(Icons.meeting_room_outlined),
          label: const RoomText('Manage rooms'),
        ),
      ],
    );
  }

  String _rangeText() {
    if (!(telemetryBool(telemetry, 'presence') ??
        telemetryBool(telemetry, 'radar_out') ??
        false)) {
      return 'Binary presence sensing';
    }
    final distances = [
      telemetryNumber(telemetry, 'radar_moving_cm'),
      telemetryNumber(telemetry, 'radar_stationary_cm'),
    ].whereType<double>().where((value) => value > 0).toList();
    if (distances.isEmpty) return 'Target range is unavailable';
    return 'Nearest reported target · ${(distances.reduce((a, b) => a < b ? a : b) / 100).toStringAsFixed(1)} m';
  }

  Widget _connectionRow(IconData icon, String label, String value) => Row(
        children: [
          Icon(icon, size: 18, color: RoomColors.muted),
          const SizedBox(width: 10),
          Expanded(
              child: RoomText(label,
                  style: const TextStyle(color: RoomColors.secondary))),
          RoomText(value,
              style: const TextStyle(
                  color: RoomColors.ink, fontWeight: FontWeight.w500)),
        ],
      );

  Widget _sensorStatusRow(String name, String detail, String key) {
    final value = telemetryBool(telemetry, key);
    return RoomSensorRow(
      name: name,
      detail: detail,
      available: hasData ? value : null,
      demo: isDemo,
    );
  }
}

class _MotionIn extends StatefulWidget {
  const _MotionIn({required this.child, this.delay = 0});
  final Widget child;
  final int delay;

  @override
  State<_MotionIn> createState() => _MotionInState();
}

class _MetricSkeleton extends StatelessWidget {
  const _MetricSkeleton();
  @override
  Widget build(BuildContext context) => const RoomPanel(
        padding: 16,
        child: SizedBox(
          height: 86,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBlock(width: 120, height: 14),
              Spacer(),
              _SkeletonBlock(width: 90, height: 26),
            ],
          ),
        ),
      );
}

class _PresenceSkeleton extends StatelessWidget {
  const _PresenceSkeleton();
  @override
  Widget build(BuildContext context) => const RoomPanel(
        padding: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SkeletonBlock(width: 110, height: 14),
            SizedBox(height: 24),
            _SkeletonBlock(width: 205, height: 25),
            SizedBox(height: 10),
            _SkeletonBlock(width: 145, height: 13),
            SizedBox(height: 24),
            _SkeletonBlock(width: double.infinity, height: 1),
            SizedBox(height: 16),
            _SkeletonBlock(width: double.infinity, height: 30),
          ],
        ),
      );
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({required this.width, required this.height});
  final double width, height;
  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: RoomColors.raised,
          borderRadius: BorderRadius.circular(RoomShape.compact),
        ),
      );
}

class _MotionInState extends State<_MotionIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: RoomMotion.enter,
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, .035),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    if (widget.delay > 0) {
      await Future<void>.delayed(Duration(milliseconds: widget.delay));
    }
    if (mounted) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _opacity,
        child: SlideTransition(position: _slide, child: widget.child),
      );
}
