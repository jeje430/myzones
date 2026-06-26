import { useCallback, useEffect, useMemo, useState } from "react";
import { zonesToastInfo } from "../../../shared/utils/zonesAlerts";
import PageHeader from "../components/ui/PageHeader";
import StaffTable from "../components/StaffTable";
import { fetchDashboardStaff } from "../data/staffManagementApi";

const FILTERS = [
  { key: "all", label: "الكل", param: undefined },
  { key: "manager", label: "المدراء", param: "manager" },
  { key: "employee", label: "الموظفون", param: "employee" },
  { key: "reception", label: "الاستقبال", param: "reception" },
  { key: "maintenance", label: "الصيانة", param: "maintenance" },
];

export default function StaffManagementPage() {
  const [staff, setStaff] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [filter, setFilter] = useState("all");

  const loadStaff = useCallback(async (roleParam) => {
    setLoading(true);
    setError("");

    const result = await fetchDashboardStaff(roleParam ? { role: roleParam } : {});

    if (!result.ok) {
      setStaff([]);
      setError(result.error || "تعذّر تحميل بيانات الموظفين والإدارة.");
      setLoading(false);
      return;
    }

    setStaff(result.staff);
    setLoading(false);
  }, []);

  useEffect(() => {
    const activeFilter = FILTERS.find((item) => item.key === filter);
    loadStaff(activeFilter?.param);
  }, [filter, loadStaff]);

  const stats = useMemo(() => {
    const managers = staff.filter((member) => member.role === "manager").length;
    const employees = staff.filter((member) => member.role !== "manager").length;
    const active = staff.filter((member) => member.status === "active").length;

    return { managers, employees, active, total: staff.length };
  }, [staff]);

  const placeholderAction = (label) => () => zonesToastInfo(`سيتم تفعيل ${label} قريباً.`);

  return (
    <div>
      <PageHeader
        title="الموظفون والإدارة"
        description="عرض حصري لحسابات لوحة التحكم — المدراء والموظفون فقط، دون زبائن التطبيق."
      />

      <div className="mb-5 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        {[
          { label: "إجمالي الحسابات", value: stats.total },
          { label: "مدراء الصالات", value: stats.managers },
          { label: "الموظفون", value: stats.employees },
          { label: "حسابات نشطة", value: stats.active },
        ].map((card) => (
          <div
            key={card.label}
            className="rounded-2xl border border-gray-200 bg-white px-5 py-4 shadow-sm dark:border-gray-800 dark:bg-gray-900"
          >
            <p className="text-xs font-semibold text-gray-500 dark:text-gray-400">{card.label}</p>
            <p className="mt-1 text-2xl font-extrabold text-gray-900 dark:text-gray-100">{card.value}</p>
          </div>
        ))}
      </div>

      {error ? (
        <div className="mb-4 rounded-2xl border border-red-500/25 bg-red-500/10 px-4 py-3 text-sm font-semibold text-red-600 dark:text-red-400">
          {error}
        </div>
      ) : null}

      <StaffTable
        staff={staff}
        loading={loading}
        onEdit={placeholderAction("تعديل الصلاحيات")}
        onSuspend={placeholderAction("تعليق الحساب")}
        onDelete={placeholderAction("حذف الحساب")}
      />

      <div className="mt-4 flex flex-wrap justify-center gap-2">
        {FILTERS.map((item) => (
          <button
            key={item.key}
            type="button"
            onClick={() => setFilter(item.key)}
            className={`rounded-xl px-4 py-2 text-xs font-bold transition ${
              filter === item.key
                ? "bg-[#6B5478] text-white shadow-sm shadow-[#6B5478]/30"
                : "border border-gray-300 text-gray-600 hover:bg-gray-50 dark:border-gray-700 dark:text-gray-300 dark:hover:bg-gray-800"
            }`}
          >
            {item.label}
          </button>
        ))}
      </div>
    </div>
  );
}
