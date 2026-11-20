import 'package:flutter/material.dart';

import '../../app/room_theme.dart';
import '../../room_language.dart';
import '../../shared/room_panel.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({
    super.key,
    required this.configured,
    required this.onAddDevice,
    required this.onCreateRoom,
    this.error,
  });

  final bool configured;
  final VoidCallback onAddDevice;
  final VoidCallback onCreateRoom;
  final String? error;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 128),
        children: [
          Row(children: [
            const Expanded(
              child: RoomText('Devices',
                  style: TextStyle(
                      color: RoomColors.ink,
                      fontSize: 29,
                      fontWeight: FontWeight.w600)),
            ),
            if (configured)
              IconButton(
                  tooltip: 'Add device',
                  onPressed: onAddDevice,
                  icon: const Icon(Icons.add))
          ]),
          const SizedBox(height: 26),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF0EDE6),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(17)),
                  child: const Icon(Icons.sensors,
                      color: RoomColors.coralInk, size: 28),
                ),
                const SizedBox(height: 22),
                RoomText(
                  configured
                      ? 'Your device is set up'
                      : 'Add your first device',
                  style: const TextStyle(
                      color: RoomColors.ink,
                      fontSize: 24,
                      height: 1.12,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 9),
                RoomText(
                  configured
                      ? 'Create a room to organize the readings from your board.'
                      : 'Connect your Smart Room board to bring live room conditions into the app.',
                  style:
                      const TextStyle(color: RoomColors.secondary, height: 1.5),
                ),
                if (error != null) ...[
                  const SizedBox(height: 14),
                  RoomStatusTag(
                      label: error!,
                      color: RoomColors.red,
                      background: RoomColors.redWash,
                      icon: Icons.error_outline)
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: configured ? onCreateRoom : onAddDevice,
                    icon: Icon(configured
                        ? Icons.add_home_outlined
                        : Icons.bluetooth_searching),
                    label:
                        RoomText(configured ? 'Create a room' : 'Add device'),
                    style: FilledButton.styleFrom(
                        backgroundColor: RoomColors.ink,
                        minimumSize: const Size.fromHeight(54)),
                  ),
                ),
              ],
            ),
          ),
          const RoomSectionTitle('How setup works'),
          const RoomPanel(
            padding: 6,
            child: Column(children: [
              _SetupStep(
                  number: '01',
                  title: 'Put the board in setup mode',
                  detail:
                      'Hold the side button for 3 seconds until the status LED blinks teal. The board then accepts Wi-Fi setup for two minutes.'),
              Divider(height: 1),
              _SetupStep(
                  number: '02',
                  title: 'Connect over Bluetooth',
                  detail: 'Choose the nearby Smart Room board.'),
              Divider(height: 1),
              _SetupStep(
                  number: '03',
                  title: 'Provide 2.4 GHz Wi-Fi',
                  detail:
                      'Credentials are sent to the board for provisioning.'),
            ]),
          ),
          const SizedBox(height: 18),
          const RoomText(
              'Once online, readings appear here through your ThingsBoard connection.',
              textAlign: TextAlign.center,
              style: TextStyle(color: RoomColors.muted, fontSize: 12)),
        ],
      );
}

class _SetupStep extends StatelessWidget {
  const _SetupStep(
      {required this.number, required this.title, required this.detail});
  final String number, title, detail;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          RoomText(number,
              style: const TextStyle(
                  color: RoomColors.coralInk,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                RoomText(title,
                    style: const TextStyle(
                        color: RoomColors.ink, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                RoomText(detail,
                    style: const TextStyle(
                        color: RoomColors.secondary,
                        fontSize: 12,
                        height: 1.4)),
              ])),
        ]),
      );
}
