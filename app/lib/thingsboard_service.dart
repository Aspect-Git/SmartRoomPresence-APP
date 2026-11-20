import 'package:cloud_functions/cloud_functions.dart';

/// Authenticated client for Firebase callable functions that proxy ThingsBoard.
class ThingsBoardService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'europe-west1',
  );

  Future<Map<String, dynamic>> latestRoomTelemetry() async {
    final result = await _functions.httpsCallable('getLatestRoomTelemetry').call();
    return _normalize(result.data);
  }

  Future<Map<String, dynamic>> roomHistory(int days) async {
    final result = await _functions.httpsCallable('getRoomHistory').call({'days': days});
    return _normalize(result.data);
  }

  Map<String, dynamic> _normalize(dynamic raw) {
    if (raw is! Map) return <String, dynamic>{};
    return raw.map((key, value) {
      final points = value is List
          ? value.whereType<Map>().map((point) => <String, dynamic>{
                'ts': point['ts'] ?? point['timestamp'],
                'value': point['value'],
              }).toList()
          : <Map<String, dynamic>>[];
      return MapEntry('$key', points);
    });
  }
}

double? telemetryNumber(Map<String, dynamic> telemetry, String key) {
  final value = _latestValue(telemetry[key]);
  if (value is num) return value.toDouble();
  return double.tryParse('$value');
}

bool? telemetryBool(Map<String, dynamic> telemetry, String key) {
  final value = _latestValue(telemetry[key]);
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = '$value'.toLowerCase();
  if (text == 'true' || text == '1') return true;
  if (text == 'false' || text == '0') return false;
  return null;
}

dynamic _latestValue(dynamic raw) {
  if (raw is List && raw.isNotEmpty) {
    final point = raw.last;
    if (point is Map && point.containsKey('value')) return point['value'];
    return point;
  }
  return raw;
}
