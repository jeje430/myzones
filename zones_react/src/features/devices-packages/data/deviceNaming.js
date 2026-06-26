import {
  DEVICE_TYPE_LABEL,
  DEVICE_TYPE_PREFIX,
  getDeviceTypeLabel,
  getDeviceTypePrefix,
} from "./deviceTypesConfig";

export { DEVICE_TYPE_LABEL, DEVICE_TYPE_PREFIX, getDeviceTypeLabel, getDeviceTypePrefix };

const LEGACY_CODE_PATTERN = /^(PS5|PS4|XBOX|PC|VR|SIM)-(\d{1,4})$/i;

export function typeLabelFromType(type) {
  return getDeviceTypeLabel(type);
}

/** @deprecated Legacy helper — prefer free-form identifiers. */
export function isCodeDeviceName(name) {
  return LEGACY_CODE_PATTERN.test(String(name || "").trim());
}

/**
 * يحوّل الأسماء العربية القديمة إلى PS5-01, XBOX-01 … حسب النوع وترتيب id
 * @returns {{ devices: object[], idToName: Map<number,string>, changed: boolean }}
 */
export function migrateDevicesToCodeNames(list) {
  const devices = Array.isArray(list) ? [...list] : [];
  const needsMigration = devices.some((d) => !isCodeDeviceName(d.name));
  if (!needsMigration) {
    return { devices, idToName: new Map(), changed: false };
  }

  const sorted = [...devices].sort((a, b) => (a.id ?? 0) - (b.id ?? 0));
  const counters = Object.fromEntries(Object.keys(DEVICE_TYPE_PREFIX).map((key) => [key, 0]));
  const idToName = new Map();

  const migrated = sorted.map((d) => {
    const type = d.type && DEVICE_TYPE_PREFIX[d.type] ? d.type : "ps5";
    counters[type] = (counters[type] || 0) + 1;
    const prefix = DEVICE_TYPE_PREFIX[type] || "DEV";
    const newName = `${prefix}-${String(counters[type]).padStart(2, "0")}`;
    idToName.set(d.id, newName);
    return {
      ...d,
      name: newName,
      type,
      typeLabel: typeLabelFromType(type),
    };
  });

  return { devices: migrated, idToName, changed: true };
}

/** يولّد اقتراحاً افتراضياً عند الحقل الفارغ فقط */
export function suggestDeviceName(type, devices) {
  const prefix = getDeviceTypePrefix(type) || "DEV";
  const list = Array.isArray(devices) ? devices : [];
  const sameType = list.filter((d) => d.type === type);
  const used = sameType
    .map((d) => {
      const m = String(d.name || "").match(new RegExp(`^${prefix}-(\\d+)$`, "i"));
      return m ? parseInt(m[1], 10) : 0;
    })
    .filter((n) => n > 0);
  const next = (used.length ? Math.max(...used) : 0) + 1;
  const padWidth = sameType.reduce((width, d) => {
    const m = String(d.name || "").match(new RegExp(`^${prefix}-(\\d+)$`, "i"));
    return m ? Math.max(width, m[1].length) : width;
  }, 2);
  return `${prefix}-${String(next).padStart(padWidth, "0")}`;
}

/** يحلّ نوع الجهاز من نص مكتوب أو مختار */
export function resolveDeviceTypeInput(input, deviceTypeGroups = []) {
  const text = String(input || "").trim();
  if (!text) return { type: "ps5", typeLabel: DEVICE_TYPE_LABEL.ps5 };

  const flat = deviceTypeGroups.flatMap((g) => g.options || []);
  const byLabel = flat.find((o) => o.label.toLowerCase() === text.toLowerCase());
  if (byLabel) return { type: byLabel.value, typeLabel: byLabel.label };
  const byValue = flat.find((o) => o.value.toLowerCase() === text.toLowerCase());
  if (byValue) return { type: byValue.value, typeLabel: byValue.label };

  const slug = text.toLowerCase().replace(/\s+/g, "_").replace(/[^\w\u0600-\u06FF-]/g, "") || "custom";
  return { type: slug, typeLabel: text };
}

/** @deprecated No longer used for validation — kept for optional suggestions. */
export function deviceNameMatchesType(name, type) {
  const prefix = DEVICE_TYPE_PREFIX[type];
  const trimmed = String(name || "").trim();
  if (!trimmed || !prefix) return false;
  return new RegExp(`^${prefix}-\\d+$`, "i").test(trimmed);
}
