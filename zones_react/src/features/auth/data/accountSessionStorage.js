/**
 * جلسات متعددة في نفس المتصفح — كل مدير له مفتاح تخزين خاص حسب user.id.
 * يسمح بفتح لوحة علي حسن (id=2) وجمال عبدالله (id=3) في تبويبات مختلفة.
 */

import { EMPLOYEE_LOGIN_PATH, MANAGER_LOGIN_PATH } from "./authRoutes";

const SESSION_KEY_BASE = "zones-auth-session";
const MANAGER_TOKEN_KEY_BASE = "zones-manager-token";
const LEGACY_SESSION_KEY = "zones-auth-session";

const MANAGER_PATH_RE = /^\/manager\/(\d+)(?:\/|$)/;
const RECEPTION_EMPLOYEE_PATH_RE = /^\/employee\/reception\/(\d+)(?:\/|$)/;
const MAINTENANCE_EMPLOYEE_PATH_RE = /^\/employee\/maintenance\/(\d+)(?:\/|$)/;

export function parseManagerIdFromPath(pathname) {
  const match = String(pathname || "").match(MANAGER_PATH_RE);
  return match ? match[1] : null;
}

export function parseReceptionEmployeeIdFromPath(pathname) {
  const match = String(pathname || "").match(RECEPTION_EMPLOYEE_PATH_RE);
  return match ? match[1] : null;
}

export function parseMaintenanceEmployeeIdFromPath(pathname) {
  const match = String(pathname || "").match(MAINTENANCE_EMPLOYEE_PATH_RE);
  return match ? match[1] : null;
}

/** معرّف الحساب النشط من الرابط (مدير أو موظف). */
export function parseWorkspaceAccountIdFromPath(pathname) {
  return (
    parseManagerIdFromPath(pathname) ||
    parseReceptionEmployeeIdFromPath(pathname) ||
    parseMaintenanceEmployeeIdFromPath(pathname) ||
    null
  );
}

export function getActiveAccountIdFromUrl() {
  if (typeof window === "undefined") return null;
  return parseWorkspaceAccountIdFromPath(window.location.pathname);
}

export function scopedSessionKey(accountId) {
  return `${SESSION_KEY_BASE}::${accountId}`;
}

export function scopedTokenKey(accountId) {
  return `${MANAGER_TOKEN_KEY_BASE}::${accountId}`;
}

export function buildManagerWorkspacePath(managerId, segment = "dashboard") {
  const id = String(managerId ?? "").trim();
  if (!id) return MANAGER_LOGIN_PATH;
  const raw = String(segment || "dashboard").replace(/^\//, "");
  const [path, search] = raw.split("?");
  const normalizedPath = path || "dashboard";
  return `/manager/${id}/${normalizedPath}${search ? `?${search}` : ""}`;
}

export function buildReceptionWorkspacePath(employeeId, segment = "dashboard") {
  const id = String(employeeId ?? "").trim();
  if (!id) return EMPLOYEE_LOGIN_PATH;
  const raw = String(segment || "dashboard").replace(/^\//, "");
  if (!raw || raw === "dashboard") return `/employee/reception/${id}`;
  const [path, search] = raw.split("?");
  return `/employee/reception/${id}/${path}${search ? `?${search}` : ""}`;
}

export function buildMaintenanceWorkspacePath(employeeId, segment = "dashboard") {
  const id = String(employeeId ?? "").trim();
  if (!id) return EMPLOYEE_LOGIN_PATH;
  const raw = String(segment || "dashboard").replace(/^\//, "");
  if (!raw || raw === "dashboard") return `/employee/maintenance/${id}`;
  const [path, search] = raw.split("?");
  return `/employee/maintenance/${id}/${path}${search ? `?${search}` : ""}`;
}

function readJson(key) {
  try {
    const raw = localStorage.getItem(key);
    if (!raw) return null;
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

export function readScopedSession(accountId) {
  if (accountId == null || accountId === "") return null;
  return readJson(scopedSessionKey(accountId));
}

export function writeScopedSession(accountId, session) {
  if (accountId == null || accountId === "") return;
  localStorage.setItem(scopedSessionKey(accountId), JSON.stringify(session));
}

export function removeScopedSession(accountId) {
  if (accountId == null || accountId === "") return;
  localStorage.removeItem(scopedSessionKey(accountId));
}

export function getScopedToken(accountId) {
  if (accountId == null || accountId === "") return null;
  return localStorage.getItem(scopedTokenKey(accountId)) || null;
}

export function setScopedToken(accountId, token) {
  if (accountId == null || accountId === "") return;
  if (token) {
    localStorage.setItem(scopedTokenKey(accountId), token);
  } else {
    localStorage.removeItem(scopedTokenKey(accountId));
  }
}

export function removeScopedToken(accountId) {
  if (accountId == null || accountId === "") return;
  localStorage.removeItem(scopedTokenKey(accountId));
}

export function clearScopedAccount(accountId) {
  removeScopedSession(accountId);
  removeScopedToken(accountId);
}

/** يقرأ الجلسة القديمة (قبل تعدد التبويبات) وينقلها إلى المفتاح المعزول */
export function migrateLegacySessionToScoped(accountId) {
  try {
    const raw = localStorage.getItem(LEGACY_SESSION_KEY);
    if (!raw) return null;
    const parsed = JSON.parse(raw);
    if (!parsed?.id || String(parsed.id) !== String(accountId)) return null;
    writeScopedSession(accountId, parsed);
    localStorage.removeItem(LEGACY_SESSION_KEY);
    const legacyToken = localStorage.getItem(MANAGER_TOKEN_KEY_BASE);
    if (legacyToken) {
      setScopedToken(accountId, legacyToken);
      localStorage.removeItem(MANAGER_TOKEN_KEY_BASE);
    }
    return parsed;
  } catch {
    return null;
  }
}

export function readLegacySession() {
  return readJson(LEGACY_SESSION_KEY);
}

/** أول جلسة مدير محفوظة (للتحويل من المسارات القديمة) */
export function findScopedManagerSession() {
  if (typeof window === "undefined") return null;
  const legacy = readLegacySession();
  if (legacy?.id) return legacy;

  for (let i = 0; i < localStorage.length; i++) {
    const key = localStorage.key(i);
    if (!key?.startsWith(`${SESSION_KEY_BASE}::`)) continue;
    const session = readJson(key);
    if (session?.id && (session.role === "manager" || session.role === "admin")) {
      return session;
    }
  }
  return null;
}
