import type { FulfillmentRecord } from './types';

const fulfilled = new Map<string, FulfillmentRecord>();

export function markFulfilled(record: FulfillmentRecord): void {
  fulfilled.set(record.sessionId, record);
}

export function getFulfillment(sessionId: string): FulfillmentRecord | undefined {
  return fulfilled.get(sessionId);
}

/** True if webhook already recorded successful fulfillment for this Checkout Session. */
export function isWebhookFulfilled(sessionId: string): boolean {
  return fulfilled.has(sessionId);
}
