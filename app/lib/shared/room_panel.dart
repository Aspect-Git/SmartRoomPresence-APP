import 'package:flutter/material.dart';

import '../app/room_theme.dart';

const _panelRadius = BorderRadius.all(Radius.circular(RoomShape.panel));

class RoomPanel extends StatelessWidget {
  const RoomPanel({
    super.key,
    required this.child,
    this.padding = 20,
    this.color = RoomColors.surface,
    this.borderColor = RoomColors.line,
  });

  final Widget child;
  final double padding;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: color,
          borderRadius: _panelRadius,
          border: Border.all(color: borderColor),
        ),
        child: child,
      );
}

class RoomSectionTitle extends StatelessWidget {
  const RoomSectionTitle(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 28, bottom: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: RoomColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

class RoomStatusTag extends StatelessWidget {
  const RoomStatusTag({
    super.key,
    required this.label,
    required this.color,
    required this.background,
    this.icon,
  });

  final String label;
  final Color color;
  final Color background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(RoomShape.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}

class RoomMetricCard extends StatelessWidget {
  const RoomMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.detail,
    this.icon,
  });

  final String label;
  final String value;
  final String? detail;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => RoomPanel(
        padding: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: RoomColors.raised,
                      borderRadius: BorderRadius.circular(RoomShape.compact),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 17, color: RoomColors.coralInk),
                  ),
                  const SizedBox(width: 9),
                ],
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: RoomColors.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: RoomColors.ink,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 4),
              Text(
                detail!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: RoomColors.muted,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      );
}

class RoomDemoNotice extends StatelessWidget {
  const RoomDemoNotice({super.key});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: RoomColors.peach,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.science_outlined, color: RoomColors.coralInk, size: 18),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                'Explore Demo · simulated board and sensor data',
                style: TextStyle(
                  color: RoomColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
}

class RoomSensorRow extends StatelessWidget {
  const RoomSensorRow({
    super.key,
    required this.name,
    required this.detail,
    required this.available,
    this.demo = false,
  });

  final String name;
  final String detail;
  final bool? available;
  final bool demo;

  @override
  Widget build(BuildContext context) {
    final color = demo
        ? RoomColors.coralInk
        : available == true
            ? RoomColors.green
            : RoomColors.muted;
    final label = demo
        ? 'Demo'
        : available == null
            ? 'No data'
            : available!
                ? 'Ready'
                : 'Offline';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: RoomColors.ink, fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                Text(detail,
                    style:
                        const TextStyle(color: RoomColors.muted, fontSize: 12)),
              ],
            ),
          ),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
