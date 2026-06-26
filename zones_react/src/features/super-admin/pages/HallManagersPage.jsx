import { useCallback, useEffect, useState } from "react";
import PageHeader from "../components/ui/PageHeader";
import UsersTable from "../components/UsersTable";
import {
  archiveStaffMember,
  fetchManagersForTable,
  toggleStaffActive,
} from "../data/staffManagementApi";

export default function HallManagersPage() {
  const [managers, setManagers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const loadManagers = useCallback(async () => {
    setLoading(true);
    setError("");

    const result = await fetchManagersForTable();

    if (!result.ok) {
      setManagers([]);
      setError(result.error || "تعذّر تحميل مدراء الصالات.");
      setLoading(false);
      return;
    }

    setManagers(result.users);
    setLoading(false);
  }, []);

  useEffect(() => {
    loadManagers();
  }, [loadManagers]);

  const handleToggle = async (user) => {
    const result = await toggleStaffActive(user);
    if (!result.ok) {
      return { ok: false, error: result.error };
    }
    await loadManagers();
    return { ok: true, user: result.staff };
  };

  const handleArchive = async (userId) => {
    const result = await archiveStaffMember(userId);
    if (!result.ok) {
      return { ok: false, error: result.error };
    }
    await loadManagers();
    return { ok: true };
  };

  return (
    <div>
      <PageHeader title="مدراء الصالات" />

      {error ? (
        <div className="mb-4 rounded-2xl border border-red-500/25 bg-red-500/10 px-4 py-3 text-sm font-semibold text-red-600 dark:text-red-400">
          {error}
          <button
            type="button"
            onClick={loadManagers}
            className="mr-3 text-xs font-bold text-[#6B5478] underline"
          >
            إعادة المحاولة
          </button>
        </div>
      ) : null}

      <UsersTable
        collection="managers"
        users={managers}
        isManager
        loading={loading}
        searchPlaceholder="ابحث عن مدير صالة..."
        onToggleActive={handleToggle}
        onArchive={handleArchive}
      />
    </div>
  );
}
