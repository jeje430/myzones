/**
 * Multi-tenant client-side isolation.
 *
 * كل بيانات الصالة تُخزَّن في localStorage مع لاحقة hallId المشتقة من جلسة
 * المدير النشط في هذا التبويب (من الرابط /manager/:id/...).
 */

import {
  getActiveAccountIdFromUrl,
  migrateLegacySessionToScoped,
  readLegacySession,
  readScopedSession,
} from "../../features/auth/data/accountSessionStorage";

function readActiveSession() {
  const accountId = getActiveAccountIdFromUrl();
  if (accountId) {
    const scoped = readScopedSession(accountId) ?? migrateLegacySessionToScoped(accountId);
    if (scoped) return scoped;
  }
  return readLegacySession();
}

/**
 * معرّف الصالة النشطة — من station_id في جلسة Laravel (معزول لكل صالة).
 * لا يُشارك بيانات صالة أخرى حتى لو نفس المتصفح.
 */
export function getActiveHallId() {
  if (typeof window === "undefined") return "default";

  const session = readActiveSession();
  if (!session || (session.id == null && !session.email)) return "default";

  if (session.hallId != null && session.hallId !== "") {
    return `station-${String(session.hallId)}`;
  }

  const role = session.role;
  if (role === "manager") {
    return session.id != null ? `mgr-${session.id}` : "default";
  }

  if (session.id != null) {
    return `acct-${session.id}`;
  }

  return "default";
}

/** مفتاح تخزين معزول حسب الصالة النشطة. */
export function hallScopedKey(baseKey) {
  return `${baseKey}::${getActiveHallId()}`;
}
