import { apiClient, mapApiErrorMessage } from "../../../shared/api/apiClient";

export async function getEmployeeInvitationByToken(token) {
  if (!token) {
    return { ok: false, error: "رابط غير صالح." };
  }

  try {
    const { data } = await apiClient.get(`/invitations/${token}`);
    const inv = data.invitation;

    return {
      ok: true,
      invite: {
        name: inv.name,
        email: inv.email,
        hallName: inv.hall_name || inv.station_name,
        role: inv.role,
        roleLabel: inv.role_label,
        shift: inv.shift,
        shiftLabel: inv.shift_label,
        expired: Boolean(inv.expired),
        alreadyUsed: Boolean(inv.already_used),
        isEmployee: Boolean(inv.is_employee),
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

export async function sendEmployeeInvitation(payload) {
  try {
    const { data } = await apiClient.post("/send-invitation", {
      name: payload.name,
      email: payload.email,
      role: payload.role,
      shift: payload.shift,
    });

    return {
      ok: true,
      message: data.message,
      mailSent: Boolean(data.mail_sent),
      registerLink: data.register_link,
    };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}

export async function completeEmployeeRegistrationApi(token, { phone, password }) {
  try {
    const { data } = await apiClient.post("/complete-registration", {
      token,
      phone: String(phone || "").trim(),
      password,
      password_confirmation: password,
    });

    return {
      ok: true,
      message: data.message,
      redirectToLogin: Boolean(data.redirect_to_login),
      role: data.role,
    };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}
