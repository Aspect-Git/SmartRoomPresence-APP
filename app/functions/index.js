const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { defineSecret, defineString } = require('firebase-functions/params');
const { HttpsError, onCall } = require('firebase-functions/v2/https');

initializeApp();

const thingsBoardBaseUrl = defineString('TB_BASE_URL', {
  default: 'https://eu.thingsboard.cloud',
});
const thingsBoardUsername = defineSecret('TB_USERNAME');
const thingsBoardPassword = defineSecret('TB_PASSWORD');
const telemetryKeys = [
  'temperature_c',
  'humidity_pct',
  'co2_ppm',
  'lux',
  'presence',
  'radar_out',
  'radar_moving',
  'radar_stationary',
  'radar_moving_cm',
  'radar_stationary_cm',
  'radar_moving_energy',
  'radar_stationary_energy',
  'scd40_ok',
  'hdc2080_ok',
  'veml7700_ok',
  'radar_ok',
  'wifi_rssi',
  'uptime_s',
  'mqtt_connected',
];

let cachedJwt;
let cachedJwtExpiresAt = 0;

async function getThingsBoardJwt(forceRefresh = false) {
  if (!forceRefresh && cachedJwt && Date.now() < cachedJwtExpiresAt) {
    return cachedJwt;
  }

  const response = await fetch(`${thingsBoardBaseUrl.value()}/api/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      username: thingsBoardUsername.value(),
      password: thingsBoardPassword.value(),
    }),
  });
  if (!response.ok) {
    throw new HttpsError('unavailable', 'ThingsBoard authentication failed.');
  }
  const body = await response.json();
  if (typeof body.token !== 'string') {
    throw new HttpsError('unavailable', 'ThingsBoard did not return a session token.');
  }

  cachedJwt = body.token;
  cachedJwtExpiresAt = Date.now() + 30 * 60 * 1000;
  return cachedJwt;
}

async function readTelemetry(deviceId, jwt) {
  const query = new URLSearchParams({ keys: telemetryKeys.join(',') });
  return fetch(
    `${thingsBoardBaseUrl.value()}/api/plugins/telemetry/DEVICE/${encodeURIComponent(deviceId)}/values/timeseries?${query}`,
    { headers: { 'X-Authorization': `Bearer ${jwt}` } },
  );
}

async function readHistory(deviceId, jwt, startTs, endTs, interval, limit) {
  const query = new URLSearchParams({
    keys: telemetryKeys.join(','),
    startTs: String(startTs),
    endTs: String(endTs),
    interval: String(interval),
    limit: String(limit),
    agg: 'AVG',
    orderBy: 'ASC',
  });
  return fetch(
    `${thingsBoardBaseUrl.value()}/api/plugins/telemetry/DEVICE/${encodeURIComponent(deviceId)}/values/timeseries?${query}`,
    { headers: { 'X-Authorization': `Bearer ${jwt}` } },
  );
}

exports.getLatestRoomTelemetry = onCall(
  {
    region: 'europe-west1',
    secrets: [thingsBoardUsername, thingsBoardPassword],
    timeoutSeconds: 30,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Sign in to Room first.');
    }

    const mapping = await getFirestore()
      .collection('userDeviceAccess')
      .doc(request.auth.uid)
      .get();
    const deviceId = mapping.data()?.deviceId;
    if (
      typeof deviceId !== 'string' ||
      !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(deviceId)
    ) {
      throw new HttpsError(
        'failed-precondition',
        'No ThingsBoard device is assigned to this Room account yet.',
      );
    }

    let response = await readTelemetry(deviceId, await getThingsBoardJwt());
    if (response.status === 401) {
      response = await readTelemetry(deviceId, await getThingsBoardJwt(true));
    }
    if (!response.ok) {
      throw new HttpsError('unavailable', 'Could not retrieve Room telemetry.');
    }
    return response.json();
  },
);

exports.getRoomHistory = onCall(
  {
    region: 'europe-west1',
    secrets: [thingsBoardUsername, thingsBoardPassword],
    timeoutSeconds: 30,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Sign in to Room first.');
    }
    const mapping = await getFirestore()
      .collection('userDeviceAccess')
      .doc(request.auth.uid)
      .get();
    const deviceId = mapping.data()?.deviceId;
    if (
      typeof deviceId !== 'string' ||
      !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(deviceId)
    ) {
      throw new HttpsError('failed-precondition', 'No device is assigned to this Room account yet.');
    }
    const now = Date.now();
    const days = [1, 7, 30].includes(Number(request.data?.days))
      ? Number(request.data.days)
      : 1;
    const startTs = now - days * 24 * 60 * 60 * 1000;
    const interval = days === 1 ? 15 * 60 * 1000 : days === 7 ? 60 * 60 * 1000 : 6 * 60 * 60 * 1000;
    let response = await readHistory(deviceId, await getThingsBoardJwt(), startTs, now, interval, 500);
    if (response.status === 401) {
      response = await readHistory(deviceId, await getThingsBoardJwt(true), startTs, now, interval, 500);
    }
    if (!response.ok) {
      throw new HttpsError('unavailable', 'Could not retrieve Room history.');
    }
    return response.json();
  },
);
