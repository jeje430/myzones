import { useMemo, useState } from "react";
import { Pencil, ShieldOff, Trash2 } from "lucide-react";
import { cn } from "@/lib/utils";
import IconButton from "../../../shared/components/ui/IconButton";
import TableActionsGroup from "../../../shared/components/ui/TableActionsGroup";
import { TABLE_ACTIONS_TD, TABLE_ACTIONS_TH } from "../../../shared/components/ui/tableActionStyles";
import SearchBar from "./ui/SearchBar";
import AssociatedHallBadge from "./AssociatedHallBadge";
import WorkingHoursBadge from "./WorkingHoursBadge";

const ROLE_BADGE = {
  manager: "bg-violet-500/15 text-violet-700 dark:bg-violet-500/20 dark:text-violet-300",
  reception: "bg-teal-500/15 text-teal-700 dark:bg-teal-500/20 dark:text-teal-300",
  maintenance: "bg-sky-500/15 text-sky-700 dark:bg-sky-500/20 dark:text-sky-300",
  default: "bg-gray-500/15 text-gray-700 dark:bg-gray-500/20 dark:text-gray-300",
};

function roleBadgeClass(role) {
  return ROLE_BADGE[role] ?? ROLE_BADGE.default;
}

function statusBadge(status) {
  const isActive = status === "active";
  return {
    label: isActive ? "نشط" : "غير نشط",
    className: isActive
      ? "bg-emerald-500/15 text-emerald-600 dark:text-emerald-400"
      : "bg-red-500/15 text-red-600 dark:text-red-400",
  };
}

function initials(name = "") {
  const parts = name.trim().split(/\s+/).slice(0, 2);
  return parts.map((part) => part[0]).join("") || "—";
}

export default function StaffTable({ staff = [], loading = false, onEdit, onSuspend, onDelete }) {
  const [search, setSearch] = useState("");

  const filtered = useMemo(() => {
    const query = search.trim().toLowerCase();
    if (!query) return staff;

    return staff.filter(
      (member) =>
        member.name.toLowerCase().includes(query) ||
        member.email.toLowerCase().includes(query) ||
        member.roleLabel.toLowerCase().includes(query) ||
        member.hallName.toLowerCase().includes(query) ||
        (member.hallLabel || "").toLowerCase().includes(query) ||
        (member.workingHours || "").toLowerCase().includes(query),
    );
  }, [search, staff]);

  return (
    <div>
      <div className="mb-4">
        <SearchBar value={search} onChange={setSearch} placeholder="ابحث عن موظف أو مدير..." />
      </div>

      <div className="overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-sm dark:border-gray-800 dark:bg-gray-900">
        <div className="overflow-x-auto">
          <table className="w-full min-w-[1180px] text-right" dir="rtl">
            <thead>
              <tr className="border-b border-gray-200 bg-gray-50 text-gray-500 dark:border-gray-800 dark:bg-gray-800/60 dark:text-gray-400">
                <th className="px-6 py-4 text-sm font-bold">معرف/اسم الموظف</th>
                <th className="px-6 py-4 text-sm font-bold">البريد الإلكتروني</th>
                <th className="px-6 py-4 text-sm font-bold">الدور / الوظيفة</th>
                <th className="px-6 py-4 text-sm font-bold">الصالة المرتبطة</th>
                <th className="px-6 py-4 text-sm font-bold">ساعات الدوام</th>
                <th className="px-6 py-4 text-sm font-bold">تاريخ التسجيل</th>
                <th className="px-6 py-4 text-sm font-bold">حالة الحساب</th>
                <th className={cn(TABLE_ACTIONS_TH, "px-6 py-4 text-sm font-bold")}>الإجراءات</th>
              </tr>
            </thead>

            <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
              {loading ? (
                <tr>
                  <td colSpan={8} className="px-6 py-14 text-center text-sm text-gray-400 dark:text-gray-500">
                    جاري تحميل بيانات الموظفين والإدارة...
                  </td>
                </tr>
              ) : null}

              {!loading
                ? filtered.map((member) => {
                    const status = statusBadge(member.status);

                    return (
                      <tr
                        key={member.id}
                        className="transition-colors hover:bg-gray-50 dark:hover:bg-zinc-800/50"
                      >
                        <td className="px-6 py-4">
                          <div className="flex items-center gap-3">
                            <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-[#6B5478]/12 text-xs font-extrabold text-[#6B5478] dark:text-[#c4b5d0]">
                              {initials(member.name)}
                            </span>
                            <div className="min-w-0">
                              <p className="truncate text-sm font-bold text-gray-900 dark:text-gray-100">
                                {member.name}
                              </p>
                            </div>
                          </div>
                        </td>

                        <td className="px-6 py-4 text-sm text-gray-600 dark:text-gray-300" dir="ltr">
                          {member.email || "—"}
                        </td>

                        <td className="px-6 py-4">
                          <span
                            className={cn(
                              "inline-flex rounded-full px-3 py-1 text-xs font-bold",
                              roleBadgeClass(member.role),
                            )}
                          >
                            {member.roleLabel || member.role || "—"}
                          </span>
                        </td>

                        <td className="px-6 py-4">
                          <AssociatedHallBadge
                            hallName={member.hallName}
                            hallScope={member.hallScope}
                            hallLabel={member.hallLabel}
                          />
                        </td>

                        <td className="px-6 py-4">
                          {member.role === "manager" ? (
                            <span className="text-xs text-gray-400 dark:text-gray-500">—</span>
                          ) : (
                            <WorkingHoursBadge hours={member.workingHours} />
                          )}
                        </td>

                        <td className="px-6 py-4 text-sm font-medium text-gray-600 dark:text-gray-300" dir="ltr">
                          {member.createdAt || "—"}
                        </td>

                        <td className="px-6 py-4">
                          <div className="flex flex-col gap-1">
                            <span
                              className={cn(
                                "inline-flex w-fit rounded-full px-3 py-1 text-xs font-bold",
                                status.className,
                              )}
                            >
                              {status.label}
                            </span>
                            {member.statusNote ? (
                              <span className="text-[10px] font-medium text-red-500 dark:text-red-400">
                                {member.statusNote}
                              </span>
                            ) : null}
                          </div>
                        </td>

                        <td className={cn(TABLE_ACTIONS_TD, "px-6 py-4")}>
                          <TableActionsGroup>
                            <IconButton
                              icon={Pencil}
                              label="تعديل الصلاحيات"
                              tone="default"
                              onClick={() => onEdit?.(member)}
                            />
                            <IconButton
                              icon={ShieldOff}
                              label="تعليق الحساب"
                              tone="warning"
                              onClick={() => onSuspend?.(member)}
                            />
                            <IconButton
                              icon={Trash2}
                              label="حذف / إيقاف"
                              tone="danger"
                              onClick={() => onDelete?.(member)}
                            />
                          </TableActionsGroup>
                        </td>
                      </tr>
                    );
                  })
                : null}

              {!loading && filtered.length === 0 ? (
                <tr>
                  <td colSpan={8} className="px-6 py-14 text-center text-sm text-gray-400 dark:text-gray-500">
                    لا توجد حسابات موظفين أو إدارة مطابقة.
                  </td>
                </tr>
              ) : null}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
