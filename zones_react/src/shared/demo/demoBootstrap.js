import { loadMockUsers } from "../../features/auth/data/mockUsersStorage";
import { loadManagerHall } from "../../features/lounge/data/managerHallStorage";
import { ensureSuperAdminDataPersisted } from "../../features/super-admin/data/superAdminStorage";
import { TOURNAMENTS_LIST_KEY } from "../../features/tournaments/tournamentsListStorage";

export const DEMO_BOOTSTRAP_VERSION = "2026.06.20";
const VERSION_KEY = "zones-demo-bootstrap-v2";
const LEGACY_TOURNAMENTS_SESSION_KEY = "zones-tournaments-list-v1";

function migrateTournamentsFromSessionStorage() {
  if (typeof window === "undefined") return;
  if (localStorage.getItem(TOURNAMENTS_LIST_KEY)) return;
  const legacy = sessionStorage.getItem(LEGACY_TOURNAMENTS_SESSION_KEY);
  if (legacy) {
    sessionStorage.removeItem(LEGACY_TOURNAMENTS_SESSION_KEY);
  }
}

/**
 * تهيئة التطبيق — لا تزرع أي بيانات تجريبية.
 * كل صالة/مدير يبدأ من الصفر ويضيف بياناته ديناميكياً.
 */
export function runDemoBootstrap() {
  if (typeof window === "undefined") return;

  loadManagerHall();
  loadMockUsers();
  migrateTournamentsFromSessionStorage();

  ensureSuperAdminDataPersisted();

  localStorage.setItem(VERSION_KEY, DEMO_BOOTSTRAP_VERSION);
}
