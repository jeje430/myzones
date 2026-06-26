import { needsStorageSeed } from "../../../shared/storage/storageHelpers";
import { DEFAULT_COMMISSION_RATE } from "./superAdminConstants";
import {
  COMMISSION_PAYMENT,
  isCommissionPaymentOverdue,
  normalizeCommissionPaymentStatus,
} from "./commissionPaymentStatus";
import {
  buildManagerRegistrationUrl,
  createHallManagerInvite,
  getInviteByToken,
  markInviteCompleted,
  syncInvitesCommissionRate,
} from "./hallManagerInvitesStorage";
import { HALL_REQUEST_STATUS, normalizeHallRequestStatus } from "./hallRequestStatus";
import { resolveHallServices } from "./hallServicesData";
import { registerManagerUser, setMockUsersActiveByEmails } from "../../auth/data/mockUsersStorage";
import { normalizeGmailEmail } from "../../../shared/utils/normalizeGmailEmail";

const STORAGE_KEY = "zones-super-admin-data-v11";

const DEFAULT_STATE = {
  requestStats: { rejectedThisMonth: 0, approvedThisMonth: 0 },
  pendingRequests: [],
  activeHalls: [],
  managers: [],
  employees: [],
  archivedHalls: [],
  archivedUsers: [],
  financialAlerts: [],
  systemSettings: {
    platformName: "منصة إدارة الصالات",
    platformLogo: "",
    platformUrl: "https://hall-platform.ly",
    adminEmail: "superadmin@gmail.com",
    globalCommissionRate: DEFAULT_COMMISSION_RATE,
    maintenanceMode: false,
    maintenanceActivatedAt: null,
    maintenanceNotifyCustomers: false,
    maintenanceNotificationsCount: 0,
    currency: "د.ل",
    lastBackupAt: null,
    supportEmail: "support.zones@gmail.com",
    supportPhone: "+218 91 000 0000",
    timezone: "Africa/Tripoli",
    language: "ar",
    allowRegistrations: true,
    emailNotifications: true,
    loyaltyPointsPerSession: 10,
    loyaltyMinimumPointsRequired: 100,
    /** @deprecated use loyaltyMinimumPointsRequired */
    loyaltyRedemptionThreshold: 100,
  },
};

export const MAX_COMMISSION_RATE = 20;

function clampCommissionRate(rate) {
  let v = Number(rate);
  if (Number.isNaN(v)) v = DEFAULT_COMMISSION_RATE;
  if (v < 0) v = 0;
  if (v > MAX_COMMISSION_RATE) v = MAX_COMMISSION_RATE;
  return v;
}

function migrateHallRequests(requests) {
  return (requests || []).map((r) => ({
    ...r,
    status: normalizeHallRequestStatus(r.status),
  }));
}

function migrateCommissionFields(state) {
  const globalRate = clampCommissionRate(state.systemSettings?.globalCommissionRate);

  state.activeHalls = (state.activeHalls || []).map((hall) => ({
    ...hall,
    commissionRate: hall.commissionRate ?? globalRate,
  }));

  state.pendingRequests = (state.pendingRequests || []).map((request) => ({
    ...request,
    commissionRate:
      request.status === HALL_REQUEST_STATUS.pending
        ? (request.commissionRate ?? globalRate)
        : request.commissionRate,
  }));

  return state;
}

/** تطبيق نسبة العمولة العامة على كل الصالات وطلبات الانضمام المعلّقة */
function propagateGlobalCommissionRate(state, rate) {
  const safeRate = clampCommissionRate(rate);

  state.systemSettings.globalCommissionRate = safeRate;
  state.activeHalls = (state.activeHalls || []).map((hall) => ({
    ...hall,
    commissionRate: safeRate,
  }));
  state.pendingRequests = (state.pendingRequests || []).map((request) => {
    if (request.status !== HALL_REQUEST_STATUS.pending) return request;
    return { ...request, commissionRate: safeRate };
  });

  syncInvitesCommissionRate(safeRate);
  return state;
}

function migrateHallCatalog(state) {
  if (!state._hallCatalogV11) {
    state._hallCatalogV11 = true;
  }

  state.activeHalls = (state.activeHalls || []).map((hall) => ({
    ...hall,
    services: resolveHallServices(hall),
    paymentStatus: normalizeCommissionPaymentStatus(hall.paymentStatus),
    commissionPaidAt:
      normalizeCommissionPaymentStatus(hall.paymentStatus) === COMMISSION_PAYMENT.paid
        ? hall.commissionPaidAt || null
        : null,
  }));

  return state;
}

function migrateAuthEmails(state) {
  let changed = false;

  if (Array.isArray(state.pendingRequests)) {
    state.pendingRequests = state.pendingRequests.map((row) => {
      if (!row.managerEmail) return row;
      const managerEmail = normalizeGmailEmail(row.managerEmail);
      if (managerEmail === row.managerEmail) return row;
      changed = true;
      return { ...row, managerEmail };
    });
  }

  for (const key of ["managers", "employees"]) {
    if (!Array.isArray(state[key])) continue;
    state[key] = state[key].map((row) => {
      if (!row.email) return row;
      const email = normalizeGmailEmail(row.email);
      if (email === row.email) return row;
      changed = true;
      return { ...row, email };
    });
  }

  return changed;
}

function loadRaw() {
  try {
    let raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) {
      const initial = structuredClone(DEFAULT_STATE);
      migrateCommissionFields(initial);
      migrateHallCatalog(initial);
      return initial;
    }
    const parsed = JSON.parse(raw);
    const merged = { ...structuredClone(DEFAULT_STATE), ...parsed };
    merged.systemSettings = {
      ...DEFAULT_STATE.systemSettings,
      ...(merged.systemSettings || {}),
    };
    merged.pendingRequests = migrateHallRequests(merged.pendingRequests);
    migrateCommissionFields(merged);
    migrateHallCatalog(merged);
    const emailsChanged = migrateAuthEmails(merged);
    if (!parsed?._hallCatalogV11 && merged._hallCatalogV11) {
      save(merged);
    } else if (emailsChanged) {
      save(merged);
    }
    return merged;
  } catch {
    const fallback = structuredClone(DEFAULT_STATE);
    migrateCommissionFields(fallback);
    migrateHallCatalog(fallback);
    return fallback;
  }
}

function save(state) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
  window.dispatchEvent(new CustomEvent("super-admin-data-updated"));
}

export function getSuperAdminState() {
  return loadRaw();
}

export function ensureSuperAdminDataPersisted() {
  if (typeof window === "undefined") return;
  if (!needsStorageSeed(localStorage.getItem(STORAGE_KEY))) return;
  save(loadRaw());
}

export function getPendingRequestsCount() {
  return loadRaw().pendingRequests.filter((r) => r.status === HALL_REQUEST_STATUS.pending).length;
}

export function calcCommission(income, rate) {
  const r = Number(rate) || DEFAULT_COMMISSION_RATE;
  return Math.round((Number(income) || 0) * (r / 100) * 100) / 100;
}

const COMMISSION_PAYMENT_STATUSES = ["paid", "pending", "paid", "pending", "pending", "paid", "pending"];
const COMMISSION_DUE_DATES = [
  "2026/06/10",
  "2026/06/11",
  "2026/06/09",
  "2026/06/14",
  "2026/06/15",
  "2026/06/12",
];

export function getCommissionRows() {
  const { activeHalls, systemSettings } = loadRaw();
  const fallbackRate = systemSettings.globalCommissionRate;
  return activeHalls.map((h, i) => {
    const rate = h.commissionRate ?? fallbackRate;
    const dueDate = h.commissionDueDate || COMMISSION_DUE_DATES[i % COMMISSION_DUE_DATES.length];
    const paymentStatus = normalizeCommissionPaymentStatus(
      h.paymentStatus || COMMISSION_PAYMENT_STATUSES[i % COMMISSION_PAYMENT_STATUSES.length],
    );
    return {
      hallId: h.id,
      hallName: h.name,
      monthlyIncome: h.monthlyIncome,
      rate,
      commission: calcCommission(h.monthlyIncome, rate),
      dueDate,
      paymentStatus,
      commissionPaidAt: h.commissionPaidAt || null,
      isOverdue: isCommissionPaymentOverdue(dueDate, paymentStatus),
    };
  });
}

export function markHallCommissionPaid(hallId) {
  const state = loadRaw();
  const hall = state.activeHalls.find((h) => h.id === hallId);
  if (!hall) return { ok: false, error: "الصالة غير موجودة." };

  const rate = hall.commissionRate ?? state.systemSettings.globalCommissionRate;
  const amount = calcCommission(hall.monthlyIncome, rate);
  const paidAt = new Date().toISOString().slice(0, 10);

  hall.paymentStatus = COMMISSION_PAYMENT.paid;
  hall.commissionPaidAt = paidAt;

  state.financialAlerts.unshift({
    id: Date.now(),
    type: "collected",
    hallName: hall.name,
    amount,
    daysLeft: 0,
    dueDate: paidAt.replaceAll("-", "/"),
    read: false,
  });

  save(state);
  return { ok: true, hall };
}

export function revertHallCommissionPayment(hallId) {
  const state = loadRaw();
  const hall = state.activeHalls.find((h) => h.id === hallId);
  if (!hall) return { ok: false, error: "الصالة غير موجودة." };

  hall.paymentStatus = COMMISSION_PAYMENT.pending;
  hall.commissionPaidAt = null;
  save(state);
  return { ok: true, hall };
}

export function acceptHallRequestWithInvitation(id, { commissionRate, subscriptionMonths, adminNotes } = {}) {
  const state = loadRaw();
  const idx = state.pendingRequests.findIndex((r) => r.id === id);
  if (idx < 0) return { ok: false, error: "الطلب غير موجود." };
  const req = state.pendingRequests[idx];
  if (req.status !== HALL_REQUEST_STATUS.pending) {
    return { ok: false, error: "تمت معالجة هذا الطلب مسبقاً." };
  }

  const rate =
    commissionRate !== "" && commissionRate != null
      ? Number(commissionRate)
      : state.systemSettings?.globalCommissionRate ?? DEFAULT_COMMISSION_RATE;
  const months = Number(subscriptionMonths) || 12;
  const newHallId = Date.now();
  const hallImage = req.images?.[0] || "https://images.unsplash.com/photo-1511886929834-cd04b0d64d4b?w=400&h=240&fit=crop";

  state.activeHalls.push({
    id: newHallId,
    name: req.hallName,
    image: hallImage,
    address: req.address,
    commercialPhone: req.commercialPhone,
    managerName: req.managerName,
    managerId: null,
    status: "pending_activation",
    monthlyIncome: 0,
    employeeCount: req.employeeCount,
    commissionRate: rate,
    subscriptionMonths: months,
    city: req.city,
    services: ["drinks_fridge", "free_internet"],
    paymentStatus: COMMISSION_PAYMENT.pending,
  });

  state.pendingRequests[idx] = {
    ...req,
    status: HALL_REQUEST_STATUS.accepted,
    acceptedAt: new Date().toISOString().slice(0, 10),
    commissionRate: rate,
    subscriptionMonths: months,
    adminNotes: adminNotes || "",
    linkedHallId: newHallId,
  };

  if (!state.requestStats) state.requestStats = { rejectedThisMonth: 0, approvedThisMonth: 0 };
  state.requestStats.approvedThisMonth += 1;

  state.financialAlerts.push({
    id: Date.now(),
    hallName: req.hallName,
    amount: 0,
    daysLeft: 30,
    dueDate: new Date(Date.now() + 30 * 86400000).toISOString().slice(0, 10),
    read: false,
    type: "new_hall",
  });

  const invite = createHallManagerInvite({
    requestId: req.id,
    hallId: newHallId,
    email: req.managerEmail,
    managerName: req.managerName,
    hallName: req.hallName,
    commissionRate: rate,
    subscriptionMonths: months,
    adminNotes: adminNotes || "",
  });

  save(state);
  return {
    ok: true,
    invite,
    registrationUrl: buildManagerRegistrationUrl(invite.token),
    request: state.pendingRequests[idx],
  };
}

export function rejectHallRequestWithReason(id, reason) {
  const state = loadRaw();
  const idx = state.pendingRequests.findIndex((r) => r.id === id);
  if (idx < 0) return { ok: false, error: "الطلب غير موجود." };
  const req = state.pendingRequests[idx];
  if (req.status !== HALL_REQUEST_STATUS.pending) {
    return { ok: false, error: "تمت معالجة هذا الطلب مسبقاً." };
  }
  const trimmedReason = String(reason || "").trim();
  if (!trimmedReason) return { ok: false, error: "سبب الرفض مطلوب." };

  state.pendingRequests[idx] = {
    ...req,
    status: HALL_REQUEST_STATUS.rejected,
    rejectedAt: new Date().toISOString().slice(0, 10),
    rejectionReason: trimmedReason,
  };

  if (!state.requestStats) state.requestStats = { rejectedThisMonth: 0, approvedThisMonth: 0 };
  state.requestStats.rejectedThisMonth += 1;
  save(state);
  return { ok: true, request: state.pendingRequests[idx] };
}

/** @deprecated استخدم acceptHallRequestWithInvitation */
export function acceptPendingRequest(id) {
  return acceptHallRequestWithInvitation(id, {});
}

/** @deprecated استخدم rejectHallRequestWithReason */
export function rejectPendingRequest(id, reason = "لم تتم الموافقة على الطلب.") {
  return rejectHallRequestWithReason(id, reason);
}

export function completeManagerRegistration(token, { fullName, password, phone }) {
  const inviteState = getInviteByToken(token);
  if (!inviteState) return { ok: false, error: "رابط غير صالح أو منتهي." };
  if (inviteState.alreadyUsed) return { ok: false, error: "تم استخدام هذا الرابط مسبقاً." };
  if (inviteState.expired) return { ok: false, error: "انتهت صلاحية الرابط (24 ساعة)." };

  const name = String(fullName || "").trim();
  const phoneVal = String(phone || "").trim();
  if (!name || !phoneVal) return { ok: false, error: "الاسم ورقم الهاتف مطلوبان." };
  if (!password || password.length < 4) return { ok: false, error: "كلمة المرور (4 أحرف على الأقل)." };

  const reg = registerManagerUser({
    email: inviteState.email,
    password,
    fullName: name,
    phone: phoneVal,
    hallId: inviteState.hallId,
  });
  if (!reg.ok) return reg;

  const state = loadRaw();
  const hallIdx = state.activeHalls.findIndex((h) => h.id === inviteState.hallId);
  if (hallIdx < 0) return { ok: false, error: "الصالة غير موجودة." };

  const managerId = reg.user.id;
  state.activeHalls[hallIdx] = {
    ...state.activeHalls[hallIdx],
    managerId,
    managerName: name,
    status: "active",
  };

  const nextManagerId =
    state.managers.reduce((max, m) => Math.max(max, m.id ?? 0), 0) + 1;
  state.managers.push({
    id: nextManagerId,
    fullName: name,
    email: inviteState.email,
    phone: phoneVal,
    residence: state.activeHalls[hallIdx].city || state.activeHalls[hallIdx].address || "—",
    joinDate: new Date().toISOString().slice(0, 10),
    assignedHalls: [inviteState.hallName],
    active: true,
    role: "manager",
  });

  save(state);
  markInviteCompleted(token);
  return { ok: true, user: reg.user, hall: state.activeHalls[hallIdx] };
}

export function toggleUserActive(collection, id) {
  const state = loadRaw();
  const list = state[collection];
  const idx = list.findIndex((u) => u.id === id);
  if (idx < 0) return { ok: false };

  const user = list[idx];
  const newActive = !user.active;
  list[idx] = { ...user, active: newActive };

  const emailsToSync = [user.email];

  if (collection === "managers") {
    const hallNames = user.assignedHalls || [];

    state.activeHalls = state.activeHalls.map((hall) => {
      if (!hallNames.includes(hall.name)) return hall;
      return { ...hall, status: newActive ? "active" : "closed" };
    });

    state.employees = state.employees.map((employee) => {
      const belongsToHall = (employee.assignedHalls || []).some((name) => hallNames.includes(name));
      if (!belongsToHall) return employee;
      emailsToSync.push(employee.email);
      return { ...employee, active: newActive };
    });
  }

  save(state);
  setMockUsersActiveByEmails(emailsToSync, newActive);
  return { ok: true, user: list[idx] };
}

export function archiveHall(id, reason = "أرشفة إدارية") {
  const state = loadRaw();
  const idx = state.activeHalls.findIndex((h) => h.id === id);
  if (idx < 0) return { ok: false };
  const hall = state.activeHalls[idx];
  state.archivedHalls.unshift({
    id: hall.id,
    name: hall.name,
    address: hall.address,
    archivedAt: new Date().toISOString().slice(0, 10),
    archiveReason: reason,
    managerName: hall.managerName,
  });
  state.activeHalls.splice(idx, 1);
  save(state);
  return { ok: true };
}

export function restoreHall(id) {
  const state = loadRaw();
  const idx = state.archivedHalls.findIndex((h) => h.id === id);
  if (idx < 0) return { ok: false };
  const archived = state.archivedHalls[idx];
  state.activeHalls.push({
    id: archived.id,
    name: archived.name,
    image: "https://images.unsplash.com/photo-1542751371-adc38448a05e?w=400&h=240&fit=crop",
    address: archived.address,
    managerName: archived.managerName,
    managerId: null,
    status: "active",
    monthlyIncome: 0,
    employeeCount: 0,
    services: ["drinks_fridge", "free_internet"],
  });
  state.archivedHalls.splice(idx, 1);
  save(state);
  return { ok: true };
}

export function archiveUser(collection, id, reason = "أرشفة إدارية") {
  const state = loadRaw();
  const list = state[collection];
  const idx = list.findIndex((u) => u.id === id);
  if (idx < 0) return { ok: false };
  const user = list[idx];
  state.archivedUsers.unshift({
    id: user.id,
    fullName: user.fullName,
    email: user.email,
    role: user.role,
    roleLabel: user.roleLabel || (user.role === "manager" ? "مدير صالة" : user.role),
    assignedHalls: user.assignedHalls,
    archivedAt: new Date().toISOString().slice(0, 10),
    archiveReason: reason,
  });
  list.splice(idx, 1);
  save(state);
  return { ok: true };
}

export function restoreArchivedUser(id) {
  const state = loadRaw();
  const idx = state.archivedUsers.findIndex((u) => u.id === id);
  if (idx < 0) return { ok: false };
  const user = state.archivedUsers[idx];
  const target = user.role === "manager" ? "managers" : "employees";
  state[target].push({
    id: user.id,
    fullName: user.fullName,
    email: user.email,
    phone: "+218 91 000 0000",
    residence: "—",
    joinDate: new Date().toISOString().slice(0, 10),
    assignedHalls: user.assignedHalls,
    active: true,
    role: user.role,
    roleLabel: user.roleLabel,
  });
  state.archivedUsers.splice(idx, 1);
  save(state);
  return { ok: true };
}

export function updateSystemSettings(patch) {
  const state = loadRaw();
  const prevRate = state.systemSettings.globalCommissionRate;
  state.systemSettings = { ...state.systemSettings, ...patch };

  if (
    patch.globalCommissionRate != null &&
    clampCommissionRate(patch.globalCommissionRate) !== clampCommissionRate(prevRate)
  ) {
    propagateGlobalCommissionRate(state, patch.globalCommissionRate);
  }

  save(state);
  return state.systemSettings;
}

export function runDatabaseBackup() {
  return new Promise((resolve) => {
    setTimeout(() => {
      const state = loadRaw();
      state.systemSettings.lastBackupAt = new Date().toISOString();
      save(state);
      resolve({ ok: true, at: state.systemSettings.lastBackupAt });
    }, 1800);
  });
}

export function markAlertRead(id) {
  const state = loadRaw();
  const alert = state.financialAlerts.find((a) => a.id === id);
  if (alert) alert.read = true;
  save(state);
}

export function markAllAlertsRead() {
  const state = loadRaw();
  state.financialAlerts.forEach((a) => {
    a.read = true;
  });
  save(state);
}

export function deleteFinancialAlert(id) {
  const state = loadRaw();
  state.financialAlerts = state.financialAlerts.filter((a) => a.id !== id);
  save(state);
}

export function deleteFinancialAlerts(ids) {
  const idSet = new Set(ids);
  const state = loadRaw();
  state.financialAlerts = state.financialAlerts.filter((a) => !idSet.has(a.id));
  save(state);
}

export function clearFinancialAlerts() {
  const state = loadRaw();
  state.financialAlerts = [];
  save(state);
}

function formatSubmittedTimeAr(date = new Date()) {
  const h = date.getHours();
  const m = String(date.getMinutes()).padStart(2, "0");
  const hour12 = h % 12 || 12;
  const period = h < 12 ? "ص" : "م";
  return `${hour12}:${m} ${period}`;
}

function extractCityFromAddress(address) {
  const text = String(address || "").trim();
  if (!text) return "غير محددة";
  if (text.includes("—")) return text.split("—")[0].trim();
  if (text.includes("-")) return text.split("-")[0].trim();
  const parts = text.split(/[,،]/).map((p) => p.trim()).filter(Boolean);
  return parts.length > 1 ? parts[parts.length - 1] : parts[0];
}

function deriveManagerNameFromEmail(email, hallName) {
  const local = String(email || "").split("@")[0]?.trim();
  if (!local) return `مدير ${hallName}`;
  return local.replace(/[._-]/g, " ").replace(/\b\w/g, (c) => c.toUpperCase());
}

function slugifyHallName(name) {
  return String(name || "hall")
    .trim()
    .toLowerCase()
    .replace(/\s+/g, "-")
    .replace(/[^\w\u0600-\u06FF-]/g, "")
    .slice(0, 24) || "hall";
}

/** إضافة طلب انضمام جديد من نموذج مدير الصالة العام */
export function submitHallJoinRequest({
  hallName,
  address,
  mapLink,
  email,
  commercialPhone,
  images = [],
}) {
  const trimmedName = String(hallName || "").trim();
  const trimmedAddress = String(address || "").trim();
  const trimmedEmail = normalizeGmailEmail(String(email || "").trim().toLowerCase());
  const trimmedPhone = String(commercialPhone || "").trim();
  const trimmedMap = String(mapLink || "").trim();

  if (!trimmedName || !trimmedAddress || !trimmedEmail || !trimmedPhone || !trimmedMap) {
    return { ok: false, error: "يرجى تعبئة جميع الحقول المطلوبة." };
  }
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(trimmedEmail)) {
    return { ok: false, error: "البريد الإلكتروني غير صالح." };
  }
  try {
    const parsed = new URL(trimmedMap);
    if (!["http:", "https:"].includes(parsed.protocol)) {
      return { ok: false, error: "رابط الخريطة يجب أن يبدأ بـ http أو https." };
    }
  } catch {
    return { ok: false, error: "رابط الخريطة غير صالح." };
  }

  const state = loadRaw();
  const nextId = state.pendingRequests.reduce((max, r) => Math.max(max, Number(r.id) || 0), 0) + 1;
  const now = new Date();
  const slug = slugifyHallName(trimmedName);
  const commissionRate = clampCommissionRate(state.systemSettings?.globalCommissionRate);

  const newRequest = {
    id: nextId,
    hallName: trimmedName,
    city: extractCityFromAddress(trimmedAddress),
    address: trimmedAddress,
    commercialPhone: trimmedPhone,
    employeeCount: 0,
    managerName: deriveManagerNameFromEmail(trimmedEmail, trimmedName),
    managerEmail: trimmedEmail,
    registrationLink: `https://gamezones.ly/register/${slug}`,
    status: HALL_REQUEST_STATUS.pending,
    submittedAt: now.toISOString().slice(0, 10),
    submittedTime: formatSubmittedTimeAr(now),
    mapLink: trimmedMap,
    images: images.length ? images.slice(0, 5) : [],
    source: "hall_join_form",
    commissionRate,
  };

  state.pendingRequests.unshift(newRequest);
  save(state);
  return { ok: true, request: newRequest };
}

export function getDashboardStats() {
  const state = loadRaw();
  const active = state.activeHalls.filter((h) => h.status === "active").length;
  const closed = state.activeHalls.filter((h) => h.status === "closed").length;
  const totalIncome = state.activeHalls.reduce((s, h) => s + h.monthlyIncome, 0);
  const totalCommission = calcCommission(totalIncome, state.systemSettings.globalCommissionRate);
  return {
    activeHalls: active,
    closedHalls: closed,
    pendingRequests: state.pendingRequests.filter((r) => r.status === HALL_REQUEST_STATUS.pending).length,
    totalManagers: state.managers.length,
    totalEmployees: state.employees.length,
    totalIncome,
    totalCommission,
    unreadAlerts: state.financialAlerts.filter((a) => !a.read).length,
  };
}

export function useSuperAdminSync(callback) {
  const handler = () => callback(getSuperAdminState());
  window.addEventListener("super-admin-data-updated", handler);
  return () => window.removeEventListener("super-admin-data-updated", handler);
}
