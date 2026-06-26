import { useCallback, useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import {
  AUTH_SESSION_EVENT,
  findUserByEmail,
  getAuthSession,
  getUserById,
  PROFILE_UPDATED_EVENT,
} from "../../features/auth/data/mockUsersStorage";

/** حساب المستخدم الحالي فقط — مستقل عن جدول الموظفين */
export function useAccountUser() {
  const read = useCallback(() => {
    const session = getAuthSession();
    if (!session?.id && !session?.email) return null;

    const mock = session.id
      ? getUserById(session.id) ?? findUserByEmail(session.email)
      : findUserByEmail(session.email);
    if (mock) return mock;

    if (session.source === "api" && session.id != null) {
      return {
        id: session.id,
        email: session.email || "",
        fullName: session.fullName || "",
        role: session.role,
        phone: session.phone || "",
        avatar: session.avatar || "",
        joinDate: session.joinDate || "",
        hallId: session.hallId ?? null,
        source: "api",
      };
    }

    return null;
  }, []);

  const [user, setUser] = useState(read);

  useEffect(() => {
    setUser(read());
  }, [read]);

  useEffect(() => {
    const refresh = () => setUser(read());
    window.addEventListener(PROFILE_UPDATED_EVENT, refresh);
    window.addEventListener(AUTH_SESSION_EVENT, refresh);
    window.addEventListener("focus", refresh);
    return () => {
      window.removeEventListener(PROFILE_UPDATED_EVENT, refresh);
      window.removeEventListener(AUTH_SESSION_EVENT, refresh);
      window.removeEventListener("focus", refresh);
    };
  }, [read]);

  return user;
}

/** يوجّه تلقائياً لصفحة الدخول إذا لم يُعثر على حساب المستخدم */
export function useRequireAccountUser() {
  const navigate = useNavigate();
  const user = useAccountUser();

  useEffect(() => {
    if (user) return;
    navigate("/manager/login", {
      replace: true,
      state: { from: window.location.pathname },
    });
  }, [user, navigate]);

  return user;
}
