import { DEVICE_TYPES } from "./deviceTypesConfig";
import { CarFront, Gamepad2, Glasses, Monitor } from "lucide-react";

const ICONS = {
  ps5: Gamepad2,
  ps4: Gamepad2,
  xbox: Gamepad2,
  vr: Glasses,
  pc: Monitor,
  sim: CarFront,
};

/** @deprecated Use DEVICE_TYPES from deviceTypesConfig */
export const DEVICE_TYPE_SELECT_OPTIONS = DEVICE_TYPES.map((row) => ({
  value: row.code,
  label: row.label,
  prefix: row.prefix,
  Icon: ICONS[row.code] ?? Gamepad2,
}));

export function buildDeviceTypeOptions() {
  return DEVICE_TYPE_SELECT_OPTIONS;
}

/** توحيد التسميات القديمة (PlayStation → PlayStation 5) */
const LEGACY_LABEL_TO_CODE = Object.freeze({
  playstation: "ps5",
  "play station": "ps5",
  "playstation 5": "ps5",
  "playstation 4": "ps4",
  "gaming pc": "pc",
  "pc gaming": "pc",
  "vr headset": "vr",
  "virtual reality": "vr",
  xbox: "xbox",
  "simulator racing": "sim",
});

export function resolveCanonicalDeviceType(type, typeLabel) {
  const normalizedType = String(type || "").trim().toLowerCase();
  if (DEVICE_TYPES.some((row) => row.code === normalizedType)) {
    const row = DEVICE_TYPES.find((r) => r.code === normalizedType);
    return { type: row.code, typeLabel: row.label };
  }

  const fromLabel = LEGACY_LABEL_TO_CODE[String(typeLabel || "").trim().toLowerCase()];
  if (fromLabel) {
    const row = DEVICE_TYPES.find((r) => r.code === fromLabel);
    return { type: row.code, typeLabel: row.label };
  }

  return {
    type: normalizedType || "ps5",
    typeLabel: String(typeLabel || "").trim() || DEVICE_TYPES[0].label,
  };
}
