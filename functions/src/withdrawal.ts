export interface OwnerReceipt {
  id: string;
  incidentType: string;
  moderationStatus: string;
  createdAt: string | null;
}

export interface OwnerReceiptPage {
  reports: OwnerReceipt[];
  hasMore: boolean;
}

export function isIncidentId(value: unknown): value is string {
  return typeof value === 'string' && /^[a-f0-9]{32}$/.test(value);
}

export function ownerReceipt(
  id: string,
  data: Record<string, unknown>,
): OwnerReceipt {
  const createdAt = data.createdAt as {toDate?: () => Date} | undefined;
  return {
    id,
    incidentType: typeof data.incidentType === 'string' ? data.incidentType : 'unknown',
    moderationStatus: typeof data.moderationStatus === 'string' ? data.moderationStatus : 'pending',
    createdAt: createdAt?.toDate ? createdAt.toDate().toISOString() : null,
  };
}

/**
 * Converts an already ordered Firestore page into the public callable shape.
 * The caller deliberately reads one extra document so `hasMore` is truthful.
 */
export function ownerReceiptPage(
  documents: Array<{id: string; data: () => Record<string, unknown>}>,
  pageSize = 500,
): OwnerReceiptPage {
  const hasMore = documents.length > pageSize;
  return {
    reports: documents
      .slice(0, pageSize)
      .map(document => ownerReceipt(document.id, document.data())),
    hasMore,
  };
}
