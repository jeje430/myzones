import { useCallback, useEffect, useState } from "react";
import PageHeader from "../components/ui/PageHeader";
import UsersTable from "../components/UsersTable";
import StaffFilterSearchToolbar from "../../../shared/components/StaffFilterSearchToolbar";
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
  const [search, setSearch] = useState("");

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
        search={search}
        onSearchChange={setSearch}
        hideSearch
        toolbar={
          <StaffFilterSearchToolbar
            embedded
            filters={FILTERS}
            activeFilter={filter}
            onFilterChange={(key) => {
              setFilter(key);
              setSearch("");
            }}
            search={search}
            onSearchChange={setSearch}
            searchPlaceholder="ابحث عن موظف..."
            filterAriaLabel="تصفية الموظفين"
          />
        }
        onToggleActive={handleToggle}
        onArchive={handleArchive}
      />
    </div>
  );
}
