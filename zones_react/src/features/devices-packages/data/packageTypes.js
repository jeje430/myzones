export const PACKAGE_TYPE_OPTIONS = [
  { value: "ps5", label: "PlayStation 5" },
  { value: "xbox", label: "Xbox" },
  { value: "pc", label: "PC Gaming" },
  { value: "vr", label: "VR" },
  { value: "simulator", label: "Simulator" },
  { value: "vip", label: "VIP" },
];

export function formatPackageTypeLabel(type) {
  const key = String(type ?? "").trim().toLowerCase();
  const match = PACKAGE_TYPE_OPTIONS.find((o) => o.value === key);
  return match?.label || type || "—";
}

export function parsePackagePrice(value) {
  const n = Number(String(value ?? "").replace(/[^\d.]/g, ""));
  return Number.isFinite(n) ? n : 0;
}
