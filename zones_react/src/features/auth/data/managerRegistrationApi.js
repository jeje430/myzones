import { apiClient, mapApiErrorMessage } from "../../../shared/api/apiClient";
import { mapStaffApiUser } from "../../../shared/auth/mapStaffApiUser";

export async function getInvitationByToken(token) {
  if (!token) {
    return { ok: false, error: "رابط غير صالح." };
  }

  try {
    const { data } = await apiClient.get(`/invitations/${token}`);
    const inv = data.invitation;

    return {
      ok: true,
      invite: {
        managerName: inv.name,
        email: inv.email,
        hallName: inv.hall_name || inv.station_name,
        expired: Boolean(inv.expired),
        alreadyUsed: Boolean(inv.already_used),
      },
    };
  } catch (error) {
    const status = error?.response?.status;
    if (status === 404) {
      return { ok: false, error: "رابط غير صالح أو منتهي الصلاحية." };
    }
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}

export async function completeManagerRegistrationApi(token, { phone, password }) {
  try {
    const { data } = await apiClient.post("/complete-registration", {
      token,
      phone: String(phone || "").trim(),
      password,
      password_confirmation: password,
    });

    const role = data.role || "manager";
    const user = mapStaffApiUser(data.user, role === "manager" ? "manager" : role);

    return {
      ok: true,
      user,
      token: data.token || null,
      role,
    };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}
