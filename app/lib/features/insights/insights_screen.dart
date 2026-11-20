import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../room_language.dart';
import '../../app/room_theme.dart';
import '../../shared/room_panel.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen(
      {super.key,
      required this.history,
      required this.sensor,
      required this.days,
      required this.loading,
      required this.demo,
      required this.onSensor,
      required this.onDays,
      required this.onRefresh});
  final Map<String, dynamic> history;
  final String sensor;
  final int days;
  final bool loading, demo;
  final ValueChanged<String> onSensor;
  final ValueChanged<int> onDays;
  final VoidCallback onRefresh;
  static const sensors = {
    'co2_ppm': 'CO₂',
    'temperature_c': 'Temperature',
    'humidity_pct': 'Humidity',
    'lux': 'Illuminance',
    'presence': 'Presence'
  };
  static const units = {
    'co2_ppm': 'ppm',
    'temperature_c': '°C',
    'humidity_pct': '%',
    'lux': 'lx',
    'presence': ''
  };
  @override
  Widget build(BuildContext context) {
    final points = _points();
    final values = points
        .map((p) => double.tryParse('${p['value']}'))
        .whereType<double>()
        .toList();
    return ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        children: [
          Row(children: [
            const Expanded(
                child: RoomText('Insights',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: RoomColors.ink))),
            IconButton(
                onPressed: onRefresh,
                tooltip: 'Refresh history',
                icon: const Icon(Icons.refresh))
          ]),
          RoomText(
              demo
                  ? 'Simulated sensor history'
                  : 'History reported by the device',
              style: const TextStyle(color: RoomColors.secondary)),
          const SizedBox(height: 18),
          DropdownMenu<String>(
              key: const ValueKey('history-reading-picker'),
              initialSelection: sensor,
              expandedInsets: EdgeInsets.zero,
              label: const RoomText('Reading'),
              dropdownMenuEntries: sensors.entries
                  .map((e) => DropdownMenuEntry(
                      value: e.key, label: tr(context, e.value)))
                  .toList(),
              onSelected: (v) {
                if (v != null) onSensor(v);
              }),
          const SizedBox(height: 12),
          SegmentedButton<int>(segments: const [
            ButtonSegment(value: 1, label: RoomText('24 h')),
            ButtonSegment(value: 7, label: RoomText('7 days')),
            ButtonSegment(value: 30, label: RoomText('30 days'))
          ], selected: {
            days
          }, onSelectionChanged: (v) => onDays(v.first)),
          const RoomSectionTitle('Trend'),
          RoomPanel(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Expanded(
                      child: RoomText(
                          '${sensors[sensor] ?? sensor}${units[sensor]!.isEmpty ? '' : ' · ${units[sensor]}'}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: RoomColors.ink))),
                  if (loading)
                    const SizedBox.square(
                        dimension: 17,
                        child: CircularProgressIndicator(strokeWidth: 2))
                ]),
                const SizedBox(height: 10),
                SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: points.isEmpty
                        ? const Center(
                            child: RoomText('No readings yet',
                                style: TextStyle(color: RoomColors.muted)))
                        : Semantics(
                            container: true,
                            label:
                                '${tr(context, 'History chart')}: ${tr(context, sensors[sensor] ?? sensor)}. ${tr(context, 'Horizontal axis is time. Vertical axis is the reading.')}. ${tr(context, _summary(values))}',
                            child: CustomPaint(
                                painter: _HistoryPainter(
                                    points,
                                    sensor,
                                    tr(context, 'Detected'),
                                    tr(context, 'Clear'))))),
                const SizedBox(height: 10),
                RoomText(_summary(values),
                    style: const TextStyle(
                        fontSize: 12, color: RoomColors.secondary))
              ])),
          const RoomSectionTitle('Latest readings'),
          RoomPanel(
              child: Column(children: [
            for (final entry in sensors.entries) ...[
              _row(entry.value, entry.key),
              if (entry.key != sensors.keys.last) const Divider(height: 1)
            ]
          ])),
          const RoomSectionTitle('Recent records'),
          RoomPanel(
              child: points.isEmpty
                  ? const RoomText('No records for this sensor yet.',
                      style: TextStyle(color: RoomColors.muted))
                  : Column(children: [
                      for (final p in points.reversed.take(8))
                        ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: RoomText(_format(p['value']),
                                style: const TextStyle(
                                    color: RoomColors.ink,
                                    fontWeight: FontWeight.w500)),
                            subtitle: RoomText(_time(p['ts']),
                                style: const TextStyle(
                                    fontSize: 12, color: RoomColors.muted)))
                    ])),
        ]);
  }

  List<Map> _points() {
    final raw = history[sensor];
    if (raw is! List) return const [];
    final points = raw.whereType<Map>().toList();
    points.sort((a, b) => _timestamp(a['ts']).compareTo(_timestamp(b['ts'])));
    return points;
  }

  int _timestamp(dynamic raw) {
    final value = int.tryParse('$raw') ?? 0;
    return value < 1000000000000 ? value * 1000 : value;
  }

  String _format(dynamic v) {
    if (sensor == 'presence') {
      return v == true || v == 1 ? 'Presence detected' : 'No presence';
    }
    final n = v is num ? v : num.tryParse('$v');
    return n == null
        ? '—'
        : '${n.toStringAsFixed(sensor == 'temperature_c' ? 1 : 0)} ${units[sensor]}';
  }

  String _summary(List<double> v) {
    if (v.isEmpty) return 'Waiting for sensor history.';
    if (sensor == 'presence') {
      final active = v.where((x) => x >= .5).length;
      return 'Presence detected in $active of ${v.length} samples.';
    }
    return 'Min ${v.reduce(math.min).toStringAsFixed(1)} · Average ${(v.reduce((a, b) => a + b) / v.length).toStringAsFixed(1)} · Max ${v.reduce(math.max).toStringAsFixed(1)} ${units[sensor]}';
  }

  Widget _row(String label, String key) {
    final list = history[key];
    dynamic val;
    if (list is List && list.isNotEmpty && list.last is Map) {
      val = (list.last as Map)['value'];
    }
    final n = val is num ? val : num.tryParse('$val');
    final text = key == 'presence'
        ? (val == true || val == 1 ? 'Detected' : 'Clear')
        : n == null
            ? '—'
            : '${n.toStringAsFixed(key == 'temperature_c' ? 1 : 0)} ${units[key]}';
    return ListTile(
        contentPadding: EdgeInsets.zero,
        title: RoomText(label),
        trailing: RoomText(text,
            style: const TextStyle(
                color: RoomColors.ink, fontWeight: FontWeight.w600)));
  }

  String _time(dynamic raw) {
    final n = int.tryParse('$raw');
    if (n == null) return 'Time unavailable';
    final d =
        DateTime.fromMillisecondsSinceEpoch(n < 1000000000000 ? n * 1000 : n)
            .toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

class _HistoryPainter extends CustomPainter {
  _HistoryPainter(
      this.points, this.sensor, this.detectedLabel, this.clearLabel);
  final List<Map> points;
  final String sensor;
  final String detectedLabel, clearLabel;
  @override
  void paint(Canvas c, Size s) {
    final entries = points
        .map((point) => (
              timestamp: _timestamp(point['ts']),
              value: double.tryParse('${point['value']}'),
            ))
        .where((point) => point.value != null)
        .toList();
    if (entries.isEmpty) return;

    var min = sensor == 'presence'
        ? 0.0
        : entries.map((point) => point.value!).reduce(math.min);
    var max = sensor == 'presence'
        ? 1.0
        : entries.map((point) => point.value!).reduce(math.max);
    if (max - min < .001) {
      final padding = math.max(max.abs() * .08, 1.0);
      min -= padding;
      max += padding;
    } else if (sensor != 'presence') {
      final padding = (max - min) * .08;
      min -= padding;
      max += padding;
    }

    const left = 58.0, right = 8.0, top = 12.0, bottom = 30.0;
    final rect = Rect.fromLTRB(left, top, s.width - right, s.height - bottom);
    final grid = Paint()
      ..color = RoomColors.line
      ..strokeWidth = 1;
    final label = TextPainter(
        textDirection: TextDirection.ltr, maxLines: 1, ellipsis: '…');
    for (var i = 0; i < 4; i++) {
      final y = top + (rect.height * i / 3);
      c.drawLine(Offset(left, y), Offset(s.width - right, y), grid);
      final v = max - (max - min) * i / 3;
      final yLabel = sensor == 'presence'
          ? (i == 0
              ? detectedLabel
              : i == 3
                  ? clearLabel
                  : '')
          : v.toStringAsFixed(sensor == 'temperature_c' ? 1 : 0);
      label.text = TextSpan(
          text: yLabel,
          style: const TextStyle(
              color: RoomColors.secondary,
              fontSize: 11,
              fontWeight: FontWeight.w500));
      label.layout(maxWidth: left - 6);
      label.paint(c, Offset(left - label.width - 6, y - label.height / 2));
    }

    final firstTs = entries.first.timestamp;
    final lastTs = entries.last.timestamp;
    final span = math.max(1, lastTs - firstTs);
    final path = Path();
    for (var i = 0; i < entries.length; i++) {
      final point = entries[i];
      final x = left + rect.width * (point.timestamp - firstTs) / span;
      final y = top + rect.height * (1 - (point.value! - min) / (max - min));
      if (i == 0) {
        path.moveTo(x, y);
      } else if (sensor == 'presence') {
        final prior = entries[i - 1];
        final priorY =
            top + rect.height * (1 - (prior.value! - min) / (max - min));
        path.lineTo(x, priorY);
        path.lineTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final line = Paint()
      ..color = RoomColors.coralInk
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    c.drawPath(path, line);

    final last = entries.last;
    final lastY = top + rect.height * (1 - (last.value! - min) / (max - min));
    c.drawCircle(Offset(s.width - right, lastY), 4,
        Paint()..color = RoomColors.coralInk);

    final tick = TextPainter(textDirection: TextDirection.ltr, maxLines: 1);
    for (var i = 0; i < 3; i++) {
      final timestamp = firstTs + (span * i ~/ 2);
      tick.text = TextSpan(
          text: _timeLabel(timestamp, span),
          style: const TextStyle(color: RoomColors.secondary, fontSize: 11));
      tick.layout(maxWidth: rect.width / 3);
      final center = left + rect.width * i / 2;
      final x =
          (center - tick.width / 2).clamp(left, s.width - right - tick.width);
      tick.paint(c, Offset(x, s.height - tick.height));
    }
  }

  int _timestamp(dynamic raw) {
    final value = int.tryParse('$raw') ?? 0;
    return value < 1000000000000 ? value * 1000 : value;
  }

  String _timeLabel(int timestamp, int span) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp).toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    if (span <= const Duration(days: 1).inMilliseconds) {
      return '${two(date.hour)}:${two(date.minute)}';
    }
    return '${two(date.day)}/${two(date.month)}';
  }

  @override
  bool shouldRepaint(covariant _HistoryPainter old) =>
      old.points != points ||
      old.sensor != sensor ||
      old.detectedLabel != detectedLabel ||
      old.clearLabel != clearLabel;
}
