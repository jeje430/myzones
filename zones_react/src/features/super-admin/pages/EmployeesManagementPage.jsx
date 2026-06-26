import { useCallback, useEffect, useState } from "react";
import PageHeader from "../components/ui/PageHeader";
import UsersTable from "../components/UsersTable";
import {
  archiveStaffMember,
  fetchEmployeesForTable,
  toggleStaffActive,
} from "../data/staffManagementApi";

const FILTERS = [
  { key: "all", label: "الكل" },
  { key: "reception", label: "الاستقبال" },
  { key: "maintenance", label: "الصيانة" },
];

export default function EmployeesManagementPage() {
  const [employees, setEmployees] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [filter, setFilter] = useState("all");

  const loadEmployees = useCallback(async (roleFilter = filter) => {
    setLoading(true);
    setError("");

    const result = await fetchEmployeesForTable(roleFilter);

    if (!result.ok) {
      setEmployees([]);
      setError(result.error || "تعذّر تحميل الموظفين.");
      setLoading(false);
      return;
    }

    setEmployees(result.users);
    setLoading(false);
  }, [filter]);

  useEffect(() => {
    loadEmployees(filter);
  }, [filter, loadEmployees]);

  const handleToggle = async (user) => {
    const result = await toggleStaffActive(user);
    if (!result.ok) {
      return { ok: false, error: result.error };
    }
    await loadEmployees(filter);
    return { ok: true, user: result.staff };
  };

  const handleArchive = async (userId) => {
    const result = await archiveStaffMember(userId);
    if (!result.ok) {
      return { ok: false, error: result.error };
    }
    await loadEmployees(filter);
    return { ok: true };
  };

  return (
    <div>
      <PageHeader title="الموظفون" />

      {error ? (
        <div className="mb-4 rounded-2xl border border-red-500/25 bg-red-500/10 px-4 py-3 text-sm font-semibold text-red-600 dark:text-red-400">
          {error}
          <button
            type="button"
            onClick={() => loadEmployees(filter)}
            className="mr-3 text-xs font-bold text-[#6B5478] underline"
          >
            إعادة المحاولة
          </button>
        </div>
      ) : null}

      <UsersTable
        collection="employees"
        users={employees}
        loading={loading}
        showWorkingHours
        searchPlaceholder="ابحث عن موظف..."
        onToggleActive={handleToggle}
        onArchive={handleArchive}
      />

      <div className="mt-4 flex flex-wrap justify-center gap-2">
        {FILTERS.map((f) => (
          <button
            key={f.key}
            type="button"
            onClick={() => setFilter(f.key)}
            className={`rounded-xl px-4 py-1.5 text-xs font-bold transition ${
              filter === f.key
                ? "bg-[#6B5478] text-white"
                : "border border-gray-300 text-gray-600 hover:bg-gray-50 dark:border-gray-700 dark:text-gray-300 dark:hover:bg-gray-800"
            }`}
          >
            {f.label}
          </button>
        ))}
      </div>
    </div>
  );
}
