/**
 * Global device type catalog — single source of truth for dropdowns and API mapping.
 * Append new entries here to extend supported types.
 */
export const DEVICE_TYPES = Object.freeze([
  Object.freeze({ code: "ps5", label: "PlayStation 5", prefix: "PS5" }),
  Object.freeze({ code: "ps4", label: "PlayStation 4", prefix: "PS4" }),
  Object.freeze({ code: "pc", label: "PC Gaming", prefix: "PC" }),
  Object.freeze({ code: "vr", label: "Virtual Reality", prefix: "VR" }),
  Object.freeze({ code: "xbox", label: "Xbox", prefix: "XBOX" }),
  Object.freeze({ code: "sim", label: "Simulator Racing", prefix: "SIM" }),
]);

/** @type {Record<string, string>} */
export const DEVICE_TYPE_PREFIX = Object.freeze(
  Object.fromEntries(DEVICE_TYPES.map((row) => [row.code, row.prefix])),
);

/** @type {Record<string, string>} */
export const DEVICE_TYPE_LABEL = Object.freeze(
  Object.fromEntries(DEVICE_TYPES.map((row) => [row.code, row.label])),
);

export function getDeviceTypeByCode(code) {
  return DEVICE_TYPES.find((row) => row.code === code) ?? null;
}

export function getDeviceTypePrefix(code) {
  return DEVICE_TYPE_PREFIX[code] ?? null;
}

export function getDeviceTypeLabel(code) {
  return DEVICE_TYPE_LABEL[code] ?? code?.toUpperCase() ?? "—";
}
