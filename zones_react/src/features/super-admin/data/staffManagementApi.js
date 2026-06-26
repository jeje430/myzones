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
    role: row.role || "",
    roleLabel: row.role_label || "",
    status: row.status || (row.account_status === "active" ? "active" : "inactive"),
    accountStatus: row.account_status || row.status || "inactive",
    createdAt: row.created_at || "",
    hallName: row.hall_name || "",
  };
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
