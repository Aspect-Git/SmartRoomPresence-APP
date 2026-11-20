import 'package:flutter/material.dart';
import '../../room_language.dart';
import '../../app/room_theme.dart';
import '../../models/room_data.dart';
import '../../shared/room_panel.dart';
import '../../thingsboard_service.dart';

class RoomsScreen extends StatelessWidget {
  const RoomsScreen({
    super.key,
    required this.rooms,
    required this.selected,
    required this.telemetry,
    required this.hasData,
    required this.demo,
    required this.onSelect,
    required this.onAddRoom,
  });
  final List<RoomData> rooms;
  final int selected;
  final Map<String, dynamic> telemetry;
  final bool hasData, demo;
  final ValueChanged<int> onSelect;
  final VoidCallback onAddRoom;
  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 120), children: [
        Row(children: [
          const Expanded(
              child: RoomText('Rooms',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: RoomColors.ink))),
          IconButton(
              onPressed: onAddRoom,
              tooltip: 'Add room',
              icon: const Icon(Icons.add))
        ]),
        const SizedBox(height: 4),
        const RoomText(
            'Room names organize your workspace. Live readings currently come from one connected board.',
            style: TextStyle(color: RoomColors.secondary)),
        const SizedBox(height: 20),
        for (var i = 0; i < rooms.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          RoomPanel(
              padding: 16,
              borderColor: i == selected
                  ? RoomColors.coralInk.withValues(alpha: .45)
                  : RoomColors.line,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: RoomText(rooms[i].name,
                              style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: RoomColors.ink))),
                      RoomStatusTag(
                          label: i == selected && hasData
                              ? (demo ? 'DEMO' : 'LIVE')
                              : 'NO DEVICE',
                          color: i == selected && hasData
                              ? RoomColors.green
                              : RoomColors.muted,
                          background: i == selected && hasData
                              ? RoomColors.greenWash
                              : RoomColors.raised,
                          icon: i == selected && hasData
                              ? Icons.check_circle_outline
                              : Icons.sensors_off_outlined)
                    ]),
                    const SizedBox(height: 14),
                    if (i == selected && hasData) ...[
                      _sensor('Presence detection',
                          'Binary detection${_range()}', 'radar_ok'),
                      const Divider(height: 1),
                      _sensor('CO₂', _val('co2_ppm', ' ppm'), 'scd40_ok'),
                      const Divider(height: 1),
                      _sensor(
                          'Temperature & humidity',
                          '${_val('temperature_c', ' °C')} · ${_val('humidity_pct', '%')}',
                          'hdc2080_ok'),
                      const Divider(height: 1),
                      _sensor(
                          'Ambient light', _val('lux', ' lx'), 'veml7700_ok'),
                    ] else
                      const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: RoomText('No device assigned to this room.',
                              style: TextStyle(color: RoomColors.muted))),
                    const SizedBox(height: 12),
                    if (i != selected)
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton(
                            onPressed: () => onSelect(i),
                            child: const RoomText('Select room')),
                      ),
                  ])),
        ],
        const RoomSectionTitle('What this device measures'),
        const RoomPanel(
            child: RoomText(
                'The radar reports presence and, when available, target distance. It does not estimate a room map or count people. The board also reports CO₂, temperature, humidity and ambient light.',
                style: TextStyle(height: 1.5, color: RoomColors.secondary))),
      ]);
  String _val(String k, String u) {
    final v = telemetryNumber(telemetry, k);
    return v == null
        ? '—'
        : '${v.toStringAsFixed(k == 'temperature_c' ? 1 : 0)}$u';
  }

  String _range() {
    final p = telemetryBool(telemetry, 'presence') ??
        telemetryBool(telemetry, 'radar_out');
    if (p != true) return '';
    final values = [
      telemetryNumber(telemetry, 'radar_moving_cm'),
      telemetryNumber(telemetry, 'radar_stationary_cm')
    ].whereType<double>().where((x) => x > 0).toList();
    return values.isEmpty
        ? ''
        : ' · ${(values.reduce((a, b) => a < b ? a : b) / 100).toStringAsFixed(1)} m';
  }

  Widget _sensor(String label, String detail, String statusKey) =>
      RoomSensorRow(
        name: label,
        detail: detail,
        available: hasData ? telemetryBool(telemetry, statusKey) : null,
        demo: demo,
      );
}
