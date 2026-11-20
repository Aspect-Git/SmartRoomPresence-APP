import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'app/room_theme.dart';
import 'features/home/home_screen.dart';
import 'features/insights/insights_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/rooms/rooms_screen.dart';
import 'features/device/ble_setup_screen.dart';
import 'features/device/devices_screen.dart';
import 'features/auth/login_screen.dart';
import 'models/room_data.dart';
import 'room_language.dart';
import 'thingsboard_service.dart';
import 'shared/floating_tab_bar.dart';

class RoomApp extends StatelessWidget {
  const RoomApp({super.key});
  @override
  Widget build(BuildContext context) =>
      const LanguageHost(child: _RoomMaterialApp());
}

class _RoomMaterialApp extends StatelessWidget {
  const _RoomMaterialApp();
  @override
  Widget build(BuildContext context) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Room Presence',
      theme: RoomTheme.light,
      builder: (context, child) => _MobileWebShell(child: child!),
      home: const RoomExperience());
}

/// Keeps the web build phone-shaped on large screens while remaining full
/// width on an actual phone or a narrow browser window.
class _MobileWebShell extends StatelessWidget {
  const _MobileWebShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width > 600;
    if (!isWide) return child;

    return ColoredBox(
      color: RoomColors.raised,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: RoomColors.canvas,
              borderRadius: BorderRadius.circular(RoomShape.panel),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 28,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(RoomShape.panel),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class RoomExperience extends StatefulWidget {
  const RoomExperience({super.key});
  @override
  State<RoomExperience> createState() => _RoomExperienceState();
}

class _RoomExperienceState extends State<RoomExperience> {
  final _rooms = <RoomData>[];
  final _thingsBoard = ThingsBoardService();
  StreamSubscription<User?>? _authSub;
  Timer? _poll, _demoTimer;
  bool _checking = true,
      _workspaceLoading = false,
      _demo = false,
      _deviceConfigured = false,
      _fahrenheit = false,
      _historyLoading = false;
  int _tab = 0, _selected = 0, _tick = 0, _days = 1;
  String _name = 'User', _sensor = 'co2_ppm';
  String? _error;
  Map<String, dynamic> _telemetry = {}, _history = {};
  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      setState(() => _checking = false);
      if (user != null) {
        setState(() {
          _workspaceLoading = true;
          _name = user.displayName ?? user.email?.split('@').first ?? 'User';
          _demo = false;
        });
        _loadWorkspace(user).then((_) {
          if (mounted) setState(() => _workspaceLoading = false);
          if (mounted && FirebaseAuth.instance.currentUser?.uid == user.uid) {
            _startPolling();
          }
        });
      } else {
        _stopPolling();
        if (mounted) {
          setState(() {
            _rooms.clear();
            _deviceConfigured = false;
            _selected = 0;
            _tab = 0;
          });
        }
      }
    }, onError: (_) {
      if (mounted) setState(() => _checking = false);
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _poll?.cancel();
    _demoTimer?.cancel();
    super.dispose();
  }

  bool get _hasData => _telemetry.values.any((v) => v is List && v.isNotEmpty);
  bool get _hasWorkspace => _demo || _rooms.isNotEmpty;

  Future<void> _loadWorkspace(User user) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = snapshot.data() ?? const <String, dynamic>{};
      final savedRooms = data['rooms'];
      if (!mounted || FirebaseAuth.instance.currentUser?.uid != user.uid) {
        return;
      }
      setState(() {
        _deviceConfigured = data['deviceConfigured'] == true;
        _selected = 0;
        _tab = 0;
        _rooms
          ..clear()
          ..addAll(savedRooms is List
              ? savedRooms.whereType<String>().map((name) => RoomData(name))
              : const <RoomData>[]);
      });
    } catch (_) {
      // Keep the empty device state if the private workspace cannot load.
    }
  }

  Future<void> _saveWorkspace() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'deviceConfigured': _deviceConfigured,
        'rooms': _rooms.map((room) => room.name).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      _toast('Could not save workspace changes.');
    }
  }

  bool get _fresh {
    if (_demo) return true;
    int? latest;
    for (final points in _telemetry.values) {
      if (points is List && points.isNotEmpty && points.first is Map) {
        final ts = int.tryParse('${points.first['ts']}');
        if (ts != null && (latest == null || ts > latest)) latest = ts;
      }
    }
    return latest != null &&
        DateTime.now().millisecondsSinceEpoch - latest < 120000;
  }

  void _startPolling() {
    _demo = false;
    _demoTimer?.cancel();
    _poll?.cancel();
    if (!_deviceConfigured) {
      setState(() {
        _telemetry = {};
        _history = {};
        _error = null;
      });
      return;
    }
    _refresh();
    _loadHistory();
    _poll = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  void _stopPolling() {
    _poll?.cancel();
    _poll = null;
    if (mounted) {
      setState(() {
        _telemetry = {};
        _history = {};
      });
    }
  }

  Future<void> _refresh() async {
    if (_demo || FirebaseAuth.instance.currentUser == null) return;
    try {
      final t = await _thingsBoard.latestRoomTelemetry();
      if (mounted) {
        setState(() {
          _telemetry = t;
          _error = null;
          if (_hasData) _deviceConfigured = true;
        });
        if (_hasData) _saveWorkspace();
      }
    } on FirebaseFunctionsException catch (e) {
      // Never expose backend exception codes or internal details in the UI.
      if (mounted) {
        setState(() => _error = e.code == 'unavailable'
            ? 'Room readings are temporarily unavailable.'
            : 'Could not reach the room device. Check its connection.');
      }
    } catch (_) {
      if (mounted) {
        setState(
            () => _error = 'Could not load room readings. Try again later.');
      }
    }
  }

  Future<void> _loadHistory() async {
    if (_demo) {
      if (mounted) setState(() => _history = _demoHistory(_days));
      return;
    }
    if (FirebaseAuth.instance.currentUser == null || _historyLoading) return;
    setState(() => _historyLoading = true);
    try {
      final h = await _thingsBoard.roomHistory(_days);
      if (mounted) setState(() => _history = h);
    } catch (_) {
      _toast('Unable to load sensor history.');
    } finally {
      if (mounted) setState(() => _historyLoading = false);
    }
  }

  void _startDemo() {
    _poll?.cancel();
    _demoTimer?.cancel();
    setState(() {
      _demo = true;
      _deviceConfigured = true;
      _rooms
        ..clear()
        ..add(RoomData('Living room'));
      _tick = 0;
      _tab = 0;
      _selected = 0;
      _telemetry = _demoTelemetry();
      _history = _demoHistory(_days);
      _error = null;
    });
    _demoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_demo) return;
      setState(() {
        _tick++;
        _telemetry = _demoTelemetry();
        _history = _demoHistory(_days);
      });
    });
  }

  Map<String, dynamic> _demoTelemetry() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final occupied = _tick % 6 != 5;
    final n = <String, num>{
      'temperature_c': 23.8 + math.sin(_tick * .5) * .3,
      'humidity_pct': 51 + math.cos(_tick * .25) * 2,
      'co2_ppm': 690 + math.sin(_tick * .2) * 80,
      'lux': 320 + math.cos(_tick * .18) * 55,
      'radar_moving_cm': occupied ? 185 + math.sin(_tick * .4) * 28 : 0,
      'radar_stationary_cm': occupied ? 245 + math.cos(_tick * .2) * 20 : 0,
      'wifi_rssi': -54,
      'uptime_s': _tick * 4
    };
    return {
      for (final e in n.entries)
        e.key: [
          {'ts': now, 'value': e.value}
        ],
      'presence': [
        {'ts': now, 'value': occupied}
      ],
      'radar_out': [
        {'ts': now, 'value': occupied}
      ],
      for (final k in [
        'radar_ok',
        'scd40_ok',
        'hdc2080_ok',
        'veml7700_ok',
        'mqtt_connected'
      ])
        k: [
          {'ts': now, 'value': true}
        ]
    };
  }

  Map<String, dynamic> _demoHistory(int days) {
    final count = days == 1
            ? 24
            : days == 7
                ? 28
                : 30,
        now = DateTime.now().millisecondsSinceEpoch,
        step = days * Duration.millisecondsPerDay ~/ count;
    final all = <String, List<Map<String, Object>>>{};
    for (var i = 0; i < count; i++) {
      final ts = now - (count - i - 1) * step;
      void put(String k, num v) =>
          all.putIfAbsent(k, () => []).add({'ts': ts, 'value': v});
      put('temperature_c', 23.7 + math.sin(i * .8) * .45);
      put('humidity_pct', 51 + math.sin(i * .35) * 3);
      put('co2_ppm', 680 + math.sin(i * .34) * 110);
      put('lux', 300 + math.max(0, math.sin(i * math.pi / (count - 1))) * 400);
      put('presence', i % 7 < 5 ? 1 : 0);
    }
    return all;
  }

  Future<void> _addRoom() async {
    if (!_demo && !_deviceConfigured) {
      _toast('Add a device before creating a room.');
      return;
    }
    final c = TextEditingController();
    final v = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Add room'),
                content: TextField(
                    controller: c,
                    autofocus: true,
                    maxLength: 40,
                    decoration: const InputDecoration(labelText: 'Room name')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, c.text.trim()),
                      child: const Text('Add'))
                ]));
    c.dispose();
    if (v == null || v.isEmpty || !mounted) return;
    setState(() {
      _rooms.add(RoomData(v));
      _selected = _rooms.length - 1;
      _tab = 0;
    });
    _saveWorkspace();
    _toast('Room added.');
  }

  Future<void> _addDevice() async {
    final added = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(builder: (_) => const BleSetupScreen()));
    if (added != true || !mounted) return;
    setState(() {
      _deviceConfigured = true;
      _tab = 0;
    });
    await _saveWorkspace();
    _refresh();
    if (_rooms.isEmpty) await _addRoom();
  }

  void _toast(String value) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value), behavior: SnackBarBehavior.floating));
  Future<void> _editName() async {
    final c = TextEditingController(text: _name);
    final v = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Display name'),
                content: TextField(
                    controller: c,
                    autofocus: true,
                    maxLength: 30,
                    decoration: const InputDecoration(labelText: 'Name')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, c.text.trim()),
                      child: const Text('Save'))
                ]));
    c.dispose();
    if (v == null || v.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await user.updateDisplayName(v);
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
            {'displayName': v, 'updatedAt': FieldValue.serverTimestamp()},
            SetOptions(merge: true));
      } catch (_) {
        _toast('Could not save profile name.');
        return;
      }
    }
    if (mounted) setState(() => _name = v);
  }

  Future<void> _signOut() async {
    if (_demo) {
      _demoTimer?.cancel();
      setState(() {
        _demo = false;
        _tab = 0;
        _telemetry = {};
        _history = {};
      });
      return;
    }
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      _toast('Could not sign out.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final telemetry = _selected == 0 ? _telemetry : <String, dynamic>{};
    final history = _selected == 0 ? _history : <String, dynamic>{};
    final signedIn = FirebaseAuth.instance.currentUser != null;
    final showLogin = !signedIn && !_demo;
    final hasWorkspace = _hasWorkspace;
    final profile = ProfileScreen(
        name: _name,
        email: FirebaseAuth.instance.currentUser?.email ?? '',
        demo: _demo,
        fahrenheit: _fahrenheit,
        onFahrenheit: (v) => setState(() => _fahrenheit = v),
        onEdit: _editName,
        onDevice: _addDevice,
        onSignOut: _signOut);
    final pages = hasWorkspace
        ? <Widget>[
            HomeScreen(
                roomName: _rooms[_selected].name,
                telemetry: telemetry,
                hasData: _selected == 0 && _hasData,
                isFresh: _selected == 0 && _fresh,
                isDemo: _demo,
                fahrenheit: _fahrenheit,
                loading: _workspaceLoading ||
                    (_deviceConfigured &&
                        !_hasData &&
                        _error == null &&
                        !_demo),
                error: _error,
                onAddRoom: _addRoom,
                onAddDevice: _addDevice,
                onOpenRooms: () => setState(() => _tab = 1),
                onOpenInsights: () => setState(() => _tab = 2)),
            RoomsScreen(
                rooms: _rooms,
                selected: _selected,
                telemetry: telemetry,
                hasData: _selected == 0 && _hasData,
                demo: _demo,
                onSelect: (i) => setState(() => _selected = i),
                onAddRoom: _addRoom),
            InsightsScreen(
                history: history,
                sensor: _sensor,
                days: _days,
                loading: _historyLoading,
                demo: _demo,
                onSensor: (v) => setState(() => _sensor = v),
                onDays: (v) {
                  setState(() => _days = v);
                  _loadHistory();
                },
                onRefresh: _loadHistory),
            profile,
          ]
        : <Widget>[
            DevicesScreen(
                configured: _deviceConfigured,
                onAddDevice: _addDevice,
                onCreateRoom: _addRoom,
                error: _error),
            profile,
          ];

    return Scaffold(
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(
            bottom: false,
            child: AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : RoomMotion.quick,
              child: showLogin
                  ? LoginScreen(
                      key: const ValueKey('login'),
                      onEnter: (name) {
                        if (name == null) {
                          _startDemo();
                        } else {
                          setState(() => _name = name);
                          _startPolling();
                        }
                      })
                  : KeyedSubtree(
                      key:
                          ValueKey(hasWorkspace ? 'workspace' : 'empty-device'),
                      child: IndexedStack(
                          index: _tab.clamp(0, pages.length - 1),
                          children: pages)),
            ),
          ),
          if (!showLogin)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FloatingTabBar(
                selectedIndex: _tab.clamp(0, hasWorkspace ? 3 : 1),
                hasDeviceWorkspace: hasWorkspace,
                onSelected: (i) => setState(() => _tab = i),
              ),
            ),
        ],
      ),
    );
  }
}
