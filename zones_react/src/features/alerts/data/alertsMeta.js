export const NOTIFICATION_TARGET_FORM_OPTIONS = [
  {
    value: "everyone",
    label: "الجميع",
    audiences: ["customer", "reception", "maintenance"],
    channel: "all_channels",
  },
  {
    value: "maintenance_only",
    label: "موظف الصيانة",
    audiences: ["maintenance"],
    channel: "staff_dashboard",
  },
  {
    value: "reception_only",
    label: "موظف الاستقبال",
    audiences: ["reception"],
    channel: "staff_dashboard",
  },
  {
    value: "customers_only",
    label: "الزبون",
    audiences: ["customer"],
    channel: "flutter_app",
  },
];

export const SELECTABLE_TARGET_AUDIENCES = NOTIFICATION_TARGET_FORM_OPTIONS.map((item) => item.value);

/** خيارات العرض للسجلات القديمة + النموذج الحالي */
export const NOTIFICATION_TARGET_AUDIENCES = [
  ...NOTIFICATION_TARGET_FORM_OPTIONS,
  { value: "all_employees", label: "جميع الموظفين", audiences: ["reception", "maintenance"] },
  { value: "reception_maintenance", label: "استقبال + صيانة", audiences: ["reception", "maintenance"] },
  { value: "customers_reception", label: "زبائن + استقبال", audiences: ["customer", "reception"] },
  { value: "customers_maintenance", label: "زبائن + صيانة", audiences: ["customer", "maintenance"] },
];

export const ALERT_TARGET_CATEGORIES = [
  { value: "reception", label: "موظف استقبال", shortLabel: "موظف الاستقبال" },
  { value: "maintenance", label: "موظف صيانة", shortLabel: "موظف الصيانة" },
  { value: "customer", label: "زبون", shortLabel: "الزبون" },
];

export const ALERT_STATUSES = [
  { value: "active", label: "نشط" },
  { value: "stopped", label: "متوقف" },
];

export const ALERT_SEVERITY_LEVELS = [
  { value: "low", label: "منخفض", badgeClass: "bg-sky-500/15 text-sky-600 dark:text-sky-400" },
  { value: "medium", label: "متوسط", badgeClass: "bg-amber-500/15 text-amber-700 dark:text-amber-400" },
  { value: "high", label: "مرتفع", badgeClass: "bg-orange-500/15 text-orange-600 dark:text-orange-400" },
  { value: "critical", label: "حرج", badgeClass: "bg-red-500/15 text-red-600 dark:text-red-400" },
];

export function targetAudienceMeta(value) {
  return NOTIFICATION_TARGET_AUDIENCES.find((item) => item.value === value) ?? null;
}

export function isSelectableTargetAudience(value) {
  return SELECTABLE_TARGET_AUDIENCES.includes(value);
}

const LEGACY_TARGET_AUDIENCE_MAP = {
  customer: "customers_only",
  reception: "reception_only",
  maintenance: "maintenance_only",
  employees: "maintenance_only",
  all: "everyone",
  everyone: "everyone",
};

export function resolveTargetAudience(payload = {}) {
  if (payload.targetAudience && targetAudienceMeta(payload.targetAudience)) {
    return payload.targetAudience;
  }

  const raw = payload.target_audience;
  if (typeof raw === "string" && targetAudienceMeta(raw)) {
    return raw;
  }

  const categories = normalizeTargetCategories(
    payload.targetCategories ?? payload.targetCategory ?? payload.targetAudience,
  );

  if (categories.length === 1 && LEGACY_TARGET_AUDIENCE_MAP[categories[0]]) {
    return LEGACY_TARGET_AUDIENCE_MAP[categories[0]];
  }

  if (categories.length === 1) {
    const map = {
      customer: "customers_only",
      reception: "reception_only",
      maintenance: "maintenance_only",
    };
    if (map[categories[0]]) return map[categories[0]];
  }

  if (
    categories.includes("customer") &&
    categories.includes("reception") &&
    categories.includes("maintenance")
  ) {
    return "everyone";
  }

  return "customers_only";
}

export function validateTargetAudienceForSubmit(value) {
  const normalized = resolveTargetAudience({ targetAudience: value });
  if (!isSelectableTargetAudience(normalized)) {
    return {
      valid: false,
      normalized: null,
      error: "يرجى اختيار المستهدف: الجميع، موظف الصيانة، موظف الاستقبال، أو الزبون.",
    };
  }
  return { valid: true, normalized, error: null };
}

export function targetAudienceRequiresCustomerPush(targetAudience) {
  return targetAudience === "customers_only" || targetAudience === "everyone";
}

export function targetAudienceChannel(targetAudience) {
  const meta =
    NOTIFICATION_TARGET_FORM_OPTIONS.find((item) => item.value === targetAudience) ??
    targetAudienceMeta(targetAudience);
  return meta?.channel ?? "unknown";
}

export function targetAudienceToCategories(targetAudience) {
  const meta = targetAudienceMeta(targetAudience);
  if (meta) return meta.audiences;
  return normalizeTargetCategories(targetAudience);
}

export function normalizeTargetCategories(value) {
  if (Array.isArray(value)) {
    const list = value.filter(Boolean);
    return list.length ? list : ["customer"];
  }
  if (typeof value === "string" && value.trim()) {
    const meta = targetAudienceMeta(value);
    if (meta) return meta.audiences;
    if (value === "employees") return ["reception", "maintenance"];
    if (value === "visitors") return ["customer"];
    if (value === "all" || value === "everyone") return ["customer", "reception", "maintenance"];
    return [value];
  }
  return ["customer"];
}

export function alertTargetLabel(value) {
  if (typeof value === "string") {
    const meta = targetAudienceMeta(value);
    if (meta) return meta.label;
  }
  if (value?.targetAudience) {
    const meta = targetAudienceMeta(value.targetAudience);
    if (meta) return meta.label;
  }
  const categories = normalizeTargetCategories(value?.targetCategories ?? value?.targetCategory ?? value);
  if (categories.length === 3) return "الجميع";
  const labels = categories
    .map((v) => ALERT_TARGET_CATEGORIES.find((c) => c.value === v)?.shortLabel ?? v)
    .filter(Boolean);
  return labels.length ? labels.join("، ") : "—";
}

export function toggleTargetCategorySelection(current, value) {
  const list = normalizeTargetCategories(current);
  const withoutAll = list.filter((v) => v !== "all");
  const next = withoutAll.includes(value)
    ? withoutAll.filter((v) => v !== value)
    : [...withoutAll, value];
  return next.length ? next : ["customer"];
}

export function alertStatusLabel(value) {
  return ALERT_STATUSES.find((s) => s.value === value)?.label ?? "—";
}

export function alertSeverityLabel(value) {
  return ALERT_SEVERITY_LEVELS.find((s) => s.value === value)?.label ?? "—";
}

export function alertSeverityMeta(value) {
  return ALERT_SEVERITY_LEVELS.find((s) => s.value === value) ?? ALERT_SEVERITY_LEVELS[1];
}

export function formatAlertDateTime(date = new Date()) {
  const d = date instanceof Date ? date : new Date(date);
  if (Number.isNaN(d.getTime())) return "—";
  return d.toLocaleString("ar-LY", {
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
  });
}

export function formatAlertRecordCode(id) {
  return `T-${String(id ?? 0).padStart(4, "0")}`;
}
