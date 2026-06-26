/**
 * Device identifier validation — exact duplicate check only (no format regex).
 */

function normalizeIdentifier(value) {
  return String(value ?? "").trim().toLowerCase();
}

export function deviceIdentifierValue(device) {
  return String(device?.name ?? device?.deviceCode ?? "").trim();
}

/**
 * Returns the conflicting device when identifier already exists (case-insensitive).
 */
export function findDuplicateDevice(identifier, devices = [], excludeDeviceId = null) {
  const candidate = normalizeIdentifier(identifier);
  if (!candidate) return null;

  return (
    (Array.isArray(devices) ? devices : []).find((device) => {
      if (excludeDeviceId != null && device.id === excludeDeviceId) return false;
      return normalizeIdentifier(deviceIdentifierValue(device)) === candidate;
    }) ?? null
  );
}

export function isDuplicateDeviceIdentifier(identifier, devices = [], excludeDeviceId = null) {
  return Boolean(findDuplicateDevice(identifier, devices, excludeDeviceId));
}

export function sanitizeDeviceIdentifierInput(value) {
  return String(value ?? "");
}
