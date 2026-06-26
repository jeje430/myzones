import { apiClient, mapApiErrorMessage } from "../../../shared/api/apiClient";
import { getSuperAdminToken } from "./superAdminAuth";

function authHeaders() {
  const token = getSuperAdminToken();
  return token ? { Authorization: `Bearer ${token}` } : {};
}

function mapStaffMember(row) {
  return {
    id: row.id,
    name: row.name || row.full_name || "",
    email: row.email || "",
    phone: row.phone || "",
    role: row.role || "",
    roleLabel: row.role_label || "",
    workShift: row.work_shift || null,
    shiftLabel: row.shift_label || null,
    workingHours: row.working_hours || row.shift_label || null,
    status: row.status || (row.account_status === "active" ? "active" : "inactive"),
    accountStatus: row.account_status || row.status || "inactive",
    createdAt: row.created_at || "",
    hallName: row.hall_name || "",
    hallScope: row.hall_scope || (row.hall_name ? "assigned" : "unassigned"),
    hallLabel: row.hall_label || row.hall_name || "غير مرتبطة",
    assignedHalls: Array.isArray(row.assigned_halls)
      ? row.assigned_halls
      : row.hall_name
        ? [row.hall_name]
        : [],
    archivedAt: row.archived_at || null,
    statusNote: row.status_note || null,
  };
}

/** Shape expected by UsersTable (managers / employees pages). */
export function mapStaffToUsersTableRow(member) {
  return {
    id: member.id,
    fullName: member.name,
    email: member.email,
    phone: member.phone || "—",
    joinDate: member.createdAt,
    assignedHalls: member.assignedHalls,
    active: member.status === "active",
    role: member.role,
    roleLabel: member.roleLabel,
    workShift: member.workShift,
    shiftLabel: member.shiftLabel || "—",
    workingHours: member.workingHours || member.shiftLabel || "غير محدد",
    archivedAt: member.archivedAt,
    statusNote: member.statusNote || null,
  };
}

export function mapUsersTableRow(row) {
  return mapStaffToUsersTableRow(mapStaffMember(row));
}

export async function fetchDashboardStaff(params = {}) {
  try {
    const { data } = await apiClient.get("/super-admin/staff", {
      headers: authHeaders(),
      params,
    });

    const staff = (data.staff || []).map(mapStaffMember);

    return {
      ok: true,
      staff,
      total: data.meta?.total ?? staff.length,
    };
  } catch (error) {
    return {
      ok: false,
      error: mapApiErrorMessage(error),
      staff: [],
      total: 0,
    };
  }
}

export async function fetchManagersForTable() {
  const result = await fetchDashboardStaff({ role: "manager" });
  if (!result.ok) return result;

  return {
    ...result,
    users: result.staff.map((row) => mapStaffToUsersTableRow(row)),
  };
}

export async function fetchEmployeesForTable(role) {
  const params =
    role && role !== "all"
      ? { role }
      : { role: "employee" };

  const result = await fetchDashboardStaff(params);
  if (!result.ok) return result;

  return {
    ...result,
    users: result.staff.map((row) => mapStaffToUsersTableRow(row)),
  };
}

export async function fetchArchivedStaff({ role } = {}) {
  const params = { archived: 1 };
  if (role === "manager") params.role = "manager";
  if (role === "employee") params.role = "employee";

  const result = await fetchDashboardStaff(params);
  if (!result.ok) return result;

  return {
    ...result,
    users: result.staff.map((row) => mapStaffToUsersTableRow(row)),
  };
}

export async function updateStaffAccountStatus(userId, accountStatus) {
  try {
    const { data } = await apiClient.patch(
      `/super-admin/staff/${userId}`,
      { account_status: accountStatus },
      { headers: authHeaders() },
    );

    return {
      ok: true,
      staff: mapStaffToUsersTableRow(mapStaffMember(data.staff)),
      message: data.message,
    };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}

export async function toggleStaffActive(user) {
  const nextStatus = user.active ? "inactive" : "active";
  return updateStaffAccountStatus(user.id, nextStatus);
}

export async function archiveStaffMember(userId) {
  try {
    const { data } = await apiClient.delete(`/super-admin/staff/${userId}`, {
      headers: authHeaders(),
    });

    return { ok: true, message: data.message };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}

export async function restoreStaffMember(userId) {
  try {
    const { data } = await apiClient.post(
      `/super-admin/staff/${userId}/restore`,
      null,
      { headers: authHeaders() },
    );

    return {
      ok: true,
      staff: mapStaffToUsersTableRow(mapStaffMember(data.staff)),
      message: data.message,
    };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}
