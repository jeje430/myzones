import { Navigate } from "react-router-dom";
import { buildManagerWorkspacePath } from "../../auth/data/accountSessionStorage";
import { loadMockUsers, setAuthSession } from "../../auth/data/mockUsersStorage";

/** دخول تجريبي للمدير — للعرض بدون صفحة login */
export default function ManagerDemoPage() {
  const manager = loadMockUsers().find((u) => u.role === "manager");
  if (manager) setAuthSession(manager);
  return (
    <Navigate
      to={manager?.id != null ? buildManagerWorkspacePath(manager.id, "dashboard") : "/manager/login"}
      replace
    />
  );
}
