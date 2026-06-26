import { useCallback, useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { zonesSwal, zonesToastError, zonesToastSuccess } from "../../../shared/utils/zonesAlerts";
import {
  clearAuthSession,
  deleteUserAccount,
  getAuthSession,
  updateUserProfile,
} from "../../auth/data/mockUsersStorage";
import { EMPLOYEE_LOGIN_PATH } from "../../auth/data/authRoutes";
import {
  fetchStaffProfile,
  isApiStaffSession,
  updateStaffProfile,
} from "../../auth/data/staffProfileApi";
import { useRequireAccountUser } from "../../../shared/hooks/useAccountUser";
import { formatDateTimeAr } from "../data/employeeMeta";

export function useEmployeeProfileAccount({ getEmployeeRecord, getHallName }) {
  const navigate = useNavigate();
  const user = useRequireAccountUser();
  const apiSession = isApiStaffSession(user);

  const [fullName, setFullName] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
  const [avatar, setAvatar] = useState("");
  const [editing, setEditing] = useState(false);
  const [deleteOpen, setDeleteOpen] = useState(false);
  const [loading, setLoading] = useState(apiSession);

  const employee = user ? getEmployeeRecord(user) : null;
  const hallName = getHallName();

  const applyUserFields = useCallback((sessionUser) => {
    if (!sessionUser) return;
    setFullName(sessionUser.fullName || "");
    setEmail(sessionUser.email || "");
    setPhone(sessionUser.phone || "");
    setAvatar(sessionUser.avatar || "");
  }, []);

  useEffect(() => {
    if (!user) return;
    applyUserFields(user);
  }, [user, applyUserFields]);

  useEffect(() => {
    if (!apiSession) {
      setLoading(false);
      return;
    }
    let cancelled = false;
    fetchStaffProfile().then((res) => {
      if (cancelled) return;
      setLoading(false);
      if (!res.ok) {
        zonesToastError(res.error || "تعذر تحميل الملف الشخصي");
        return;
      }
      const session = getAuthSession();
      if (session) applyUserFields(session);
    });
    return () => {
      cancelled = true;
    };
  }, [apiSession, applyUserFields]);

  const joinDate = employee?.joinDate || employee?.workStartDate || user?.joinDate || "—";
  const lastLogin = employee?.lastLogin
    ? formatDateTimeAr(employee.lastLogin)
    : getAuthSession()?.loggedInAt
      ? formatDateTimeAr(getAuthSession().loggedInAt)
      : "—";

  const save = async () => {
    if (!user?.id) return;
    const trimmedName = fullName.trim();
    if (!trimmedName) {
      zonesToastError("الاسم الكامل مطلوب.");
      return;
    }

    if (apiSession) {
      const res = await updateStaffProfile({
        fullName: trimmedName,
        phone: phone.trim(),
      });
      if (!res.ok) {
        zonesToastError(res.error);
        return;
      }
      setEditing(false);
      zonesToastSuccess("تم حفظ التعديلات");
      return;
    }

    const res = updateUserProfile(user.id, {
      fullName: trimmedName,
      email,
      phone,
      avatar,
    });
    if (!res.ok) {
      zonesToastError(res.error);
      return;
    }
    setEditing(false);
    zonesToastSuccess("تم حفظ التعديلات");
  };

  const deleteAccount = async () => {
    if (!user?.id) return;
    setDeleteOpen(false);

    if (apiSession) {
      zonesToastError("تواصل مع مدير الصالة لإدارة حسابك أو تعطيله.");
      return;
    }

    const { value: password, isConfirmed } = await zonesSwal({
      title: "تأكيد الحذف",
      text: "أدخل كلمة المرور الحالية لحذف الحساب نهائياً",
      input: "password",
      inputPlaceholder: "كلمة المرور",
      inputAttributes: { autocomplete: "current-password", dir: "ltr" },
      icon: "warning",
      showCancelButton: true,
      confirmButtonText: "حذف نهائياً",
      cancelButtonText: "إلغاء",
      confirmButtonColor: "#dc2626",
      inputValidator: (v) => (!v ? "أدخل كلمة المرور" : undefined),
    });
    if (!isConfirmed || !password) return;

    const res = deleteUserAccount(user.id, password);
    if (!res.ok) {
      zonesToastError(res.error || "تعذر حذف الحساب.");
      return;
    }
    clearAuthSession();
    navigate(EMPLOYEE_LOGIN_PATH, { replace: true, state: { message: "تم حذف حسابك." } });
  };

  return {
    user,
    employee,
    hallName,
    fullName,
    setFullName,
    email,
    phone,
    setPhone,
    avatar,
    setAvatar,
    editing,
    setEditing,
    deleteOpen,
    setDeleteOpen,
    loading,
    apiSession,
    joinDate,
    lastLogin,
    save,
    deleteAccount,
  };
}
