import sharp from 'sharp';
import {HttpsError} from 'firebase-functions/v2/https';

export const maximumPhotoBytes = 2 * 1024 * 1024;
export function photoInput(data: unknown): {incidentId: string; bytes: Buffer} {
  if (!data || typeof data !== 'object' || Array.isArray(data)) throw new HttpsError('invalid-argument', 'Photo data is invalid.');
  const value = data as Record<string, unknown>;
  if (Object.keys(value).some(key => !['incidentId', 'jpegBase64'].includes(key)) || typeof value.incidentId !== 'string' || !/^[a-f0-9]{32}$/.test(value.incidentId)) throw new HttpsError('invalid-argument', 'Incident ID is invalid.');
  const encoded = value.jpegBase64;
  if (typeof encoded !== 'string' || encoded.length > Math.ceil(maximumPhotoBytes / 3) * 4 || !/^[A-Za-z0-9+/]+={0,2}$/.test(encoded)) throw new HttpsError('invalid-argument', 'Photo must be a bounded JPEG.');
  const bytes = Buffer.from(encoded, 'base64');
  if (bytes.length > maximumPhotoBytes || bytes.length < 4 || bytes.toString('base64') !== encoded || bytes[0] !== 0xff || bytes[1] !== 0xd8) throw new HttpsError('invalid-argument', 'Photo must be a bounded JPEG.');
  return {incidentId: value.incidentId, bytes};
}

export async function processPrivateJpeg(bytes: Buffer): Promise<Buffer> {
  try {
    const pipeline = sharp(bytes, {limitInputPixels: 8_000_000, failOn: 'warning'});
    const metadata = await pipeline.metadata();
    if (metadata.format !== 'jpeg') throw new Error('JPEG required');
    // Sharp discards all metadata by default. No withMetadata/keepMetadata call is permitted.
    const processed = await pipeline.rotate().resize({width: 1600, height: 1600, fit: 'inside', withoutEnlargement: true}).jpeg({quality: 82}).toBuffer();
    if (processed.length > maximumPhotoBytes) throw new Error('Photo too large');
    return processed;
  } catch (_) { throw new HttpsError('invalid-argument', 'The JPEG could not be processed safely.'); }
}
