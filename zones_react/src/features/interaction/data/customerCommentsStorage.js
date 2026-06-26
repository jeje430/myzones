import { hallScopedKey } from "../../../shared/tenant/hallScopedStorage";

const BASE_KEY = "zones-customer-comments-v2";
const storageKey = () => hallScopedKey(BASE_KEY);
export const CUSTOMER_COMMENTS_EVENT = "zones-customer-comments-updated";

const LEGACY_KEYS = ["zones-customer-comments-v1", "zones-customer-comments-v2"];
const LEGACY_PURGE_FLAG = "zones-customer-comments-legacy-purged-v3";

function purgeLegacyCommentStorage() {
  if (typeof window === "undefined") return;
  if (localStorage.getItem(LEGACY_PURGE_FLAG)) return;
  for (const key of LEGACY_KEYS) {
    localStorage.removeItem(key);
  }
  localStorage.setItem(LEGACY_PURGE_FLAG, "1");
}

purgeLegacyCommentStorage();

function notifyUpdated() {
  if (typeof window === "undefined") return;
  window.dispatchEvent(new CustomEvent(CUSTOMER_COMMENTS_EVENT));
}

function normalizeComment(row) {
  return {
    id: row.id,
    customerName: String(row.customerName || "زبون").trim(),
    text: String(row.text || "").trim(),
    rating: Math.min(5, Math.max(0, Number(row.rating) || 0)),
    createdAt: Number(row.createdAt) || Date.now(),
    source: row.source || "customer_app",
    managerReply: row.managerReply
      ? {
          text: String(row.managerReply.text || "").trim(),
          repliedAt: Number(row.managerReply.repliedAt) || Date.now(),
          managerName: String(row.managerReply.managerName || "مدير الصالة").trim(),
        }
      : null,
  };
}

export function loadComments() {
  try {
    const raw = localStorage.getItem(storageKey());
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed) || !parsed.length) return [];
    return parsed.map(normalizeComment);
  } catch {
    return [];
  }
}

export function saveComments(list) {
  try {
    localStorage.setItem(storageKey(), JSON.stringify(list.map(normalizeComment)));
    notifyUpdated();
  } catch {
    /* ignore */
  }
}

export function nextCommentId(list = loadComments()) {
  return list.reduce((max, c) => Math.max(max, c.id ?? 0), 0) + 1;
}

export function addCustomerComment({ customerName, text, rating = 0 }) {
  const trimmed = String(text || "").trim();
  const name = String(customerName || "زبون").trim();
  if (!trimmed) return null;

  const list = loadComments();
  const comment = normalizeComment({
    id: nextCommentId(list),
    customerName: name || "زبون",
    text: trimmed,
    rating,
    createdAt: Date.now(),
    source: "customer_app",
    managerReply: null,
  });
  saveComments([comment, ...list]);
  return comment;
}

export function replyToComment(commentId, replyText, managerName = "مدير الصالة") {
  const trimmed = String(replyText || "").trim();
  if (!trimmed) return null;

  const list = loadComments();
  let updated = null;
  const next = list.map((c) => {
    if (c.id !== commentId) return c;
    updated = normalizeComment({
      ...c,
      managerReply: {
        text: trimmed,
        repliedAt: Date.now(),
        managerName: managerName.trim() || "مدير الصالة",
      },
    });
    return updated;
  });
  saveComments(next);
  return updated;
}

export function deleteComment(commentId) {
  const list = loadComments();
  const next = list.filter((c) => c.id !== commentId);
  if (next.length === list.length) return false;
  saveComments(next);
  return true;
}

export function getCommentStats(comments = loadComments()) {
  const replied = comments.filter((c) => c.managerReply?.text).length;
  return {
    total: comments.length,
    pending: comments.length - replied,
    replied,
  };
}

export function formatRelativeTime(timestamp) {
  const ts = Number(timestamp);
  if (!ts) return "—";

  const diffMs = Date.now() - ts;
  const minutes = Math.floor(diffMs / 60000);
  if (minutes < 1) return "الآن";
  if (minutes < 60) return `منذ ${minutes} دقيقة`;

  const hours = Math.floor(minutes / 60);
  if (hours < 24) return hours === 1 ? "منذ ساعة" : `منذ ${hours} ساعة`;

  const days = Math.floor(hours / 24);
  if (days < 7) return days === 1 ? "منذ يوم" : `منذ ${days} يوم`;

  const weeks = Math.floor(days / 7);
  if (weeks < 5) return weeks === 1 ? "منذ أسبوع" : `منذ ${weeks} أسبوع`;

  return new Date(ts).toLocaleDateString("ar-LY", {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}

export function customerInitials(name) {
  const parts = String(name || "ز").trim().split(/\s+/).filter(Boolean);
  if (!parts.length) return "ز";
  if (parts.length === 1) return parts[0].slice(0, 2);
  return `${parts[0][0] || ""}${parts[1][0] || ""}`;
}
