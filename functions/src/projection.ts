export interface PublicProjectionInput {
  id: string;
  incidentType: string;
  latitude: number;
  longitude: number;
  occurredAt?: Date;
  random?: () => number;
  minimumMetres?: number;
  maximumMetres?: number;
}

export interface PublicProjection {
  id: string;
  incidentType: string;
  displayLatitude: number;
  displayLongitude: number;
  date: string;
}

export function projectionForModeration(
  status: 'accepted' | 'rejected' | 'duplicate',
  existing: PublicProjection | null | undefined,
  create: () => PublicProjection,
): PublicProjection | null {
  if (status === 'accepted') return existing ?? create();
  return existing ?? null;
}

export function createPublicProjection(input: PublicProjectionInput): PublicProjection {
  const random = input.random ?? Math.random;
  const minimumMetres = input.minimumMetres ?? 20;
  const maximumMetres = input.maximumMetres ?? 50;
  if (!Number.isFinite(minimumMetres) || !Number.isFinite(maximumMetres) || minimumMetres <= 0 || maximumMetres < minimumMetres || maximumMetres > 1000) {
    throw new Error('Invalid public coordinate privacy radius.');
  }
  const distance = minimumMetres + random() * (maximumMetres - minimumMetres);
  const bearing = random() * Math.PI * 2;
  const earthRadiusMetres = 6371000;
  const angularDistance = distance / earthRadiusMetres;
  const latitudeRadians = input.latitude * Math.PI / 180;
  const longitudeRadians = input.longitude * Math.PI / 180;
  const displayLatitudeRadians = Math.asin(
    Math.sin(latitudeRadians) * Math.cos(angularDistance) +
    Math.cos(latitudeRadians) * Math.sin(angularDistance) * Math.cos(bearing),
  );
  const displayLongitudeRadians = longitudeRadians + Math.atan2(
    Math.sin(bearing) * Math.sin(angularDistance) * Math.cos(latitudeRadians),
    Math.cos(angularDistance) - Math.sin(latitudeRadians) * Math.sin(displayLatitudeRadians),
  );
  const wrappedLongitude = (displayLongitudeRadians + 3 * Math.PI) % (2 * Math.PI) - Math.PI;
  return {
    id: input.id,
    incidentType: input.incidentType,
    displayLatitude: displayLatitudeRadians * 180 / Math.PI,
    displayLongitude: wrappedLongitude * 180 / Math.PI,
    date: (input.occurredAt ?? new Date()).toISOString().slice(0, 10),
  };
}

export function haversineMetres(
  latitude1: number,
  longitude1: number,
  latitude2: number,
  longitude2: number,
): number {
  const radians = Math.PI / 180;
  const phi1 = latitude1 * radians;
  const phi2 = latitude2 * radians;
  const deltaPhi = (latitude2 - latitude1) * radians;
  const deltaLambda = (longitude2 - longitude1) * radians;
  const a = Math.sin(deltaPhi / 2) ** 2 +
      Math.cos(phi1) * Math.cos(phi2) * Math.sin(deltaLambda / 2) ** 2;
  return 6371000 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}
