import 'dart:ui';

import 'package:flutter/material.dart';

import '../app/room_theme.dart';
import '../room_language.dart';

class FloatingTabBar extends StatelessWidget {
  const FloatingTabBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.hasDeviceWorkspace,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool hasDeviceWorkspace;

  @override
  Widget build(BuildContext context) {
    final items = hasDeviceWorkspace
        ? const [
            (Icons.home_outlined, Icons.home_rounded, 'Home'),
            (Icons.meeting_room_outlined, Icons.meeting_room, 'Rooms'),
            (Icons.show_chart, Icons.show_chart, 'Insights'),
            (Icons.person_outline, Icons.person, 'Profile'),
          ]
        : const [
            (Icons.sensors_outlined, Icons.sensors, 'Devices'),
            (Icons.person_outline, Icons.person, 'Profile'),
          ];
    return SizedBox(
      height: 104,
      width: double.infinity,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    height: 68,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: RoomColors.ink.withValues(alpha: .88),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: .12)),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x260B0908),
                            blurRadius: 24,
                            offset: Offset(0, 8))
                      ],
                    ),
                    child: Row(
                      children: [
                        for (var i = 0; i < items.length; i++)
                          Expanded(
                            child: _TabItem(
                              icon: items[i].$1,
                              selectedIcon: items[i].$2,
                              label: items[i].$3,
                              selected: selectedIndex == i,
                              onTap: () => onSelected(i),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon, selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: tr(context, label),
        child: Material(
          color: selected ? const Color(0xFF34312F) : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            key: ValueKey('tab-${label.toLowerCase()}'),
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: SizedBox.expand(
              child: AnimatedContainer(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : RoomMotion.quick,
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color:
                      selected ? const Color(0xFF34312F) : Colors.transparent,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(selected ? selectedIcon : icon,
                        size: 21,
                        color: selected ? RoomColors.coral : Colors.white70),
                    const SizedBox(height: 3),
                    RoomText(label,
                        style: TextStyle(
                            color: selected ? RoomColors.coral : Colors.white70,
                            fontSize: 10,
                            height: 1.1,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
