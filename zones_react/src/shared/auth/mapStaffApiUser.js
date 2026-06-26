/**
 * يحوّل استجابة المستخدم من Laravel إلى شكل الجلسة المحلية.
 * يدعم station_id / hall_id كمعرّف الصالة (Multi-Tenant).
 */
export function mapStaffApiUser(json, forcedRole = null) {
  if (!json) return null;

  const fullName = json.full_name || json.name || "";
  const roles = json.roles || [];
  let role = forcedRole;

  if (!role) {
    if (roles.includes("manager")) role = "manager";
    else if (roles.includes("reception")) role = "reception";
    else if (roles.includes("maintenance")) role = "maintenance";
    else role = "manager";
  }

  const stationId =
    json.station_id ?? json.hall_id ?? json.hallId ?? null;

  return {
    id: json.id,
    email: json.email || "",
    fullName,
    phone: json.phone || "",
    role,
    hallId: stationId != null && stationId !== "" ? String(stationId) : null,
    stationId: stationId != null ? Number(stationId) : null,
    stationName: json.station_name || json.hall_name || null,
    avatar: json.profile_image || "",
    joinDate: json.created_at
      ? String(json.created_at).slice(0, 10)
      : new Date().toISOString().slice(0, 10),
    active: json.account_status !== "inactive",
    source: "api",
  };
}
