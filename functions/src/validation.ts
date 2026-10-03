const INCIDENT_TYPES = new Set([
  'alive_crossing_road',
  'alive_near_road',
  'injured',
  'dead_roadkill',
]);
const LOCATION_SOURCES = new Set(['device_gps', 'manual_pin', 'unknown']);
const ALLOWED_FIELDS = new Set([
  'requestId',
  'latitude',
  'longitude',
  'locationAccuracyMetres',
  'locationSource',
  'incidentType',
  'directionBearing',
  'note',
  'occurredAt',
]);

export function validateSubmission(data: Record<string, unknown> | null | undefined): string[] {
  const errors: string[] = [];
  if (!data || typeof data !== 'object' || Array.isArray(data)) {
    return ['request data must be an object'];
  }
  for (const key of Object.keys(data)) {
    if (!ALLOWED_FIELDS.has(key)) errors.push(`unsupported field: ${key}`);
  }
  if (typeof data.requestId !== 'string' || !/^[A-Za-z0-9._:-]{1,128}$/.test(data.requestId)) {
    errors.push('requestId must be a short stable identifier');
  }
  validateNumber(data.latitude, 'latitude', -90, 90, errors);
  validateNumber(data.longitude, 'longitude', -180, 180, errors);
  if (data.locationAccuracyMetres !== undefined) {
    validateNumber(data.locationAccuracyMetres, 'locationAccuracyMetres', 0, 10000, errors);
  }
  if (typeof data.locationSource !== 'string' || !LOCATION_SOURCES.has(data.locationSource)) {
    errors.push('locationSource is invalid');
  }
  if (typeof data.incidentType !== 'string' || !INCIDENT_TYPES.has(data.incidentType)) {
    errors.push('incident type is invalid');
  }
  if (data.directionBearing !== undefined) {
    validateNumber(data.directionBearing, 'directionBearing', 0, 359.999999, errors);
  }
  if (data.note !== undefined &&
      (typeof data.note !== 'string' || data.note.length > 500)) {
    errors.push('note must be a string of 500 characters or fewer');
  }
  if (data.occurredAt !== undefined &&
      (typeof data.occurredAt !== 'string' || !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,6})?(?:Z|[+-]\d{2}:\d{2})$/.test(data.occurredAt) || Number.isNaN(Date.parse(data.occurredAt)) || Date.parse(data.occurredAt) > Date.now() + 5 * 60 * 1000)) {
    errors.push('occurredAt must be an ISO date');
  }
  return errors;
}

function validateNumber(
  value: unknown,
  name: string,
  minimum: number,
  maximum: number,
  errors: string[],
): void {
  if (typeof value !== 'number' || !Number.isFinite(value)) {
    errors.push(`${name} must be finite`);
  } else if (value < minimum || value > maximum) {
    errors.push(`${name} must be between ${minimum} and ${maximum}`);
  }
}
