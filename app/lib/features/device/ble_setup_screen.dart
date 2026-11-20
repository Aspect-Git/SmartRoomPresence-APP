import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../app/room_theme.dart';
import '../../room_language.dart';

const _coral = Color(0xFFFF592C);
const _muted = Color(0xFF737373);
const _serviceUuid = '2b8d0001-6b3a-4f7c-9e2d-1a0b5c6d7e80';
const _configUuid = '2b8d0003-6b3a-4f7c-9e2d-1a0b5c6d7e80';
const _statusUuid = '2b8d0004-6b3a-4f7c-9e2d-1a0b5c6d7e80';

class BleSetupScreen extends StatefulWidget {
  const BleSetupScreen({super.key});

  @override
  State<BleSetupScreen> createState() => _BleSetupScreenState();
}

class _BleSetupScreenState extends State<BleSetupScreen> {
  final _ssid = TextEditingController();
  final _password = TextEditingController();
  final Map<String, _NearbyBoard> _foundDevices = {};
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<List<int>>? _statusSubscription;
  BluetoothDevice? _device;
  String? _error;
  String _statusText = 'Your board will appear here after scanning.';
  bool _busy = false;
  bool _showPassword = false;
  bool _done = false;

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _statusSubscription?.cancel();
    final device = _device;
    if (device != null) unawaited(device.disconnect());
    _ssid.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    await _run(() async {
      await FlutterBluePlus.stopScan();
      await _scanSubscription?.cancel();
      _foundDevices.clear();
      _scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
        for (final result in results) {
          final name = result.advertisementData.advName.isNotEmpty
              ? result.advertisementData.advName
              : result.device.platformName;
          final advertisesService = result.advertisementData.serviceUuids
              .any((uuid) => uuid.str.toLowerCase() == _serviceUuid);
          if (advertisesService || name == 'SmartRoom-Setup') {
            _foundDevices[result.device.remoteId.str] = _NearbyBoard(
              device: result.device,
              rssi: result.rssi,
            );
          }
        }
        if (mounted) setState(() {});
      });
      await FlutterBluePlus.adapterState
          .where((state) => state == BluetoothAdapterState.on)
          .first
          .timeout(const Duration(seconds: 15));
      await FlutterBluePlus.startScan(
        withServices: [Guid(_serviceUuid)],
        withNames: ['SmartRoom-Setup'],
        timeout: const Duration(seconds: 12),
      );
      await FlutterBluePlus.isScanning
          .where((isScanning) => !isScanning)
          .first
          .timeout(const Duration(seconds: 15));
      if (_foundDevices.isEmpty) {
        throw StateError('No SmartRoom-Setup device was found.');
      }
      _statusText = 'Select the nearby Smart Room device.';
    });
  }

  Future<void> _connectAndProvision() async {
    final device = _device;
    final ssid = _ssid.text;
    final password = _password.text;
    if (device == null || ssid.trim().isEmpty) {
      setState(
          () => _error = 'Select the device and enter the 2.4 GHz Wi-Fi name.');
      return;
    }
    if (utf8.encode(ssid).length > 32 || utf8.encode(password).length > 63) {
      setState(
          () => _error = 'Wi-Fi name/password exceeds the firmware limit.');
      return;
    }

    await _run(() async {
      _statusText = 'Connecting to the board…';
      await device.connect(
        license: License.nonprofit,
        timeout: const Duration(seconds: 15),
      );
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        try {
          await device.requestMtu(185);
        } catch (_) {
          // Android may keep its default MTU; a GATT long write is used below.
        }
      }

      final services = await device.discoverServices();
      final service = services.firstWhere(
        (item) => item.serviceUuid.str.toLowerCase() == _serviceUuid,
        orElse: () => throw StateError('Firmware BLE service was not found.'),
      );
      final config = service.characteristics.firstWhere(
        (item) => item.characteristicUuid.str.toLowerCase() == _configUuid,
        orElse: () => throw StateError(
            'Wi-Fi provisioning characteristic was not found.'),
      );
      final status = service.characteristics.firstWhere(
        (item) => item.characteristicUuid.str.toLowerCase() == _statusUuid,
        orElse: () =>
            throw StateError('Device status characteristic was not found.'),
      );

      final saved = Completer<void>();
      await status.setNotifyValue(true);
      await _statusSubscription?.cancel();
      _statusSubscription = status.onValueReceived.listen((bytes) {
        final message = utf8.decode(bytes, allowMalformed: true).trim();
        if (!mounted || message.isEmpty) return;
        setState(() => _statusText = 'Device: $message');
        if (message == 'saved' && !saved.isCompleted) saved.complete();
        if (message.startsWith('invalid_') && !saved.isCompleted) {
          saved.completeError(
              StateError('Device rejected Wi-Fi details: $message'));
        }
      });

      final payload = utf8.encode(jsonEncode({
        'cmd': 'provision',
        'ssid': ssid,
        'password': password,
      }));
      if (payload.length > device.mtuNow - 3) {
        await config.write(payload, allowLongWrite: true);
      } else {
        await config.write(payload, withoutResponse: false);
      }
      await saved.future.timeout(const Duration(seconds: 20));
      if (!mounted) return;
      _password.clear();
      setState(() {
        _done = true;
        _error = null;
        _statusText = 'Wi-Fi details received. The board will now connect.';
      });
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.toLowerCase().contains('permission')) {
      return tr(context, 'Bluetooth permission is required.');
    }
    if (message.toLowerCase().contains('timeout') ||
        message.toLowerCase().contains('not found')) {
      return tr(
          context, 'Device not found. Put it in BLE setup mode and try again.');
    }
    return message.replaceFirst('Bad state: ', '');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const RoomText('Add device')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  const RoomText(
                    'Bring your room online',
                    style: TextStyle(
                        fontSize: 27,
                        height: 1.15,
                        fontWeight: FontWeight.w600,
                        color: RoomColors.ink),
                  ),
                  const SizedBox(height: 8),
                  const RoomText(
                    'Pair the board, then send your 2.4 GHz Wi-Fi details securely over Bluetooth.',
                    style: TextStyle(color: RoomColors.secondary, height: 1.45),
                  ),
                  const SizedBox(height: 22),
                  _step(1, 'Prepare the board'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: RoomColors.line)),
                    child: Row(
                      children: [
                        Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                                color: RoomColors.peach,
                                borderRadius: BorderRadius.circular(13)),
                            child: const Icon(Icons.touch_app_outlined,
                                color: RoomColors.coralInk)),
                        const SizedBox(width: 12),
                        const Expanded(
                            child: RoomText(
                                'Hold the side button for 3 seconds until the status LED blinks teal. The board then accepts Wi-Fi setup for two minutes.',
                                style: TextStyle(
                                    color: RoomColors.ink,
                                    fontSize: 13,
                                    height: 1.4))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _step(2, 'Connect to your board'),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _scan,
                      icon: _busy
                          ? const SizedBox.square(
                              dimension: 17,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.bluetooth_searching),
                      label:
                          RoomText(_busy ? 'Scanning…' : 'Scan nearby devices'),
                    ),
                  ),
                  if (_foundDevices.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: RoomColors.line)),
                      child: RadioGroup<String>(
                        groupValue: _device?.remoteId.str,
                        onChanged: (id) {
                          if (_busy) return;
                          setState(() => _device =
                              id == null ? null : _foundDevices[id]?.device);
                        },
                        child: Column(
                          children: _foundDevices.entries.map((entry) {
                            final strength = entry.value.rssi >= -60
                                ? 'Strong signal'
                                : entry.value.rssi >= -75
                                    ? 'Good signal'
                                    : 'Weak signal';
                            final selected = _device?.remoteId.str == entry.key;
                            return RadioListTile<String>(
                              value: entry.key,
                              enabled: !_busy,
                              activeColor: _coral,
                              title: const RoomText('Smart Room board'),
                              subtitle: RoomText(
                                  '$strength · ${entry.value.rssi} dBm'),
                              selected: selected,
                              secondary: const Icon(Icons.sensors_outlined),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _step(3, 'Connect to Wi-Fi'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _ssid,
                    onChanged: (_) => setState(() {}),
                    autocorrect: false,
                    decoration: const InputDecoration(
                        labelText: '2.4 GHz Wi-Fi name (SSID)'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _password,
                    obscureText: !_showPassword,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: 'Wi-Fi password',
                      suffixIcon: IconButton(
                        tooltip: tr(context, 'Show or hide password'),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                        icon: Icon(_showPassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _busy ||
                            _done ||
                            _device == null ||
                            _ssid.text.trim().isEmpty
                        ? null
                        : _connectAndProvision,
                    style: FilledButton.styleFrom(
                      backgroundColor: _coral,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                    ),
                    icon: _busy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send),
                    label: RoomText(_busy ? 'Sending…' : 'Send Wi-Fi details'),
                  ),
                  const SizedBox(height: 12),
                  RoomText(_statusText,
                      style: const TextStyle(color: _muted, height: 1.4)),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    _message(_error!, isError: true),
                  ],
                  if (_done) ...[
                    const SizedBox(height: 12),
                    _message(_statusText, isError: false),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const RoomText('Continue to create a room'),
                    ),
                  ],
                  const SizedBox(height: 18),
                  const RoomText(
                    'The app sends Wi-Fi details directly to the selected board over BLE. It does not store the Wi-Fi password or ThingsBoard device token.',
                    style: TextStyle(fontSize: 12, color: _muted, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _step(int number, String label) => Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: RoomColors.peach,
                borderRadius: BorderRadius.circular(10)),
            child: Text('$number',
                style: const TextStyle(
                    color: _coral, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: RoomText(label,
                  style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      );

  Widget _message(String text, {required bool isError}) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isError ? const Color(0xFFFFEEE8) : const Color(0xFFEAF5EE),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
                color: isError ? _coral : const Color(0xFF21824C)),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: const TextStyle(height: 1.4))),
          ],
        ),
      );
}

class _NearbyBoard {
  const _NearbyBoard({required this.device, required this.rssi});
  final BluetoothDevice device;
  final int rssi;
}
