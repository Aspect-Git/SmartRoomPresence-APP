import 'package:flutter/material.dart';
import '../../room_language.dart';
import '../../app/room_theme.dart';
import '../../shared/room_panel.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen(
      {super.key,
      required this.name,
      required this.email,
      required this.demo,
      required this.fahrenheit,
      required this.onFahrenheit,
      required this.onEdit,
      required this.onDevice,
      required this.onSignOut});
  final String name, email;
  final bool demo, fahrenheit;
  final ValueChanged<bool> onFahrenheit;
  final VoidCallback onEdit, onDevice, onSignOut;
  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 120), children: [
        const RoomText('Profile',
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: RoomColors.ink)),
        const SizedBox(height: 18),
        RoomPanel(
            child: Row(children: [
          const CircleAvatar(
              backgroundColor: RoomColors.peach,
              child: Icon(Icons.person_outline, color: RoomColors.coralInk)),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                RoomText(name,
                    style: const TextStyle(
                        color: RoomColors.ink, fontWeight: FontWeight.w600)),
                RoomText(demo ? 'Explore Demo' : email,
                    style:
                        const TextStyle(color: RoomColors.muted, fontSize: 12))
              ])),
          IconButton(
              onPressed: onEdit,
              tooltip: 'Edit profile',
              icon: const Icon(Icons.edit_outlined))
        ])),
        const RoomSectionTitle('Preferences'),
        RoomPanel(
            padding: 8,
            child: Column(children: [
              const LanguagePicker(),
              const Divider(height: 1),
              SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  secondary: const Icon(Icons.thermostat_outlined),
                  title: const RoomText('Use Fahrenheit'),
                  subtitle: const RoomText('Temperature display unit'),
                  value: fahrenheit,
                  onChanged: onFahrenheit),
            ])),
        const RoomSectionTitle('Device'),
        RoomPanel(
            padding: 0,
            child: ListTile(
                leading: const Icon(Icons.bluetooth),
                title: const RoomText('Set up Smart Room device'),
                subtitle:
                    const RoomText('Connect over Bluetooth and provide Wi-Fi'),
                trailing: const Icon(Icons.chevron_right),
                onTap: onDevice)),
        const RoomSectionTitle('About this device'),
        const RoomPanel(
            child: RoomText(
                'Presence is reported as detected or clear, with a target range when available. The board measures CO₂, temperature, humidity and light. It does not identify or count people. Readings sync through a secure cloud connection.',
                style: TextStyle(color: RoomColors.secondary, height: 1.5))),
        const SizedBox(height: 24),
        OutlinedButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout),
            label: RoomText(demo ? 'Exit demo' : 'Sign out')),
      ]);
}
