import { useMemo, useState } from "react";
import { Archive, Power } from "lucide-react";
import { zonesSwal, zonesToastError, zonesToastSuccess } from "../../../shared/utils/zonesAlerts";
import IconButton from "../../../shared/components/ui/IconButton";
import TableActionsGroup from "../../../shared/components/ui/TableActionsGroup";
import { TABLE_ACTIONS_TD, TABLE_ACTIONS_TH } from "../../../shared/components/ui/tableActionStyles";
import {
  TableBulkActionBar,
  TableSelectHeaderCell,
  TableSelectRowCell,
  selectableRowClass,
} from "../../../shared/components/ui/TableSelection";
import {
  filterItemsByIds,
  resolveBulkActionIds,
  useTableSelection,
} from "../../../shared/hooks/useTableSelection";
import SearchBar from "./ui/SearchBar";
import WorkingHoursBadge from "./WorkingHoursBadge";

function initials(name = "") {
  const parts = name.trim().split(/\s+/).slice(0, 2);
  return parts.map((p) => p[0]).join("");
}

export default function UsersTable({
  collection,
  users,
  searchPlaceholder,
  isManager,
  showWorkingHours = false,
  loading = false,
  onToggleActive,
  onArchive,
}) {
  const [search, setSearch] = useState("");
  const [actionLoading, setActionLoading] = useState(false);

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    if (!q) return users;
    return users.filter(
      (u) =>
        u.fullName.toLowerCase().includes(q) ||
        u.email.toLowerCase().includes(q) ||
        (u.assignedHalls || []).join(" ").toLowerCase().includes(q) ||
        (u.roleLabel || "").toLowerCase().includes(q) ||
        (u.workingHours || "").toLowerCase().includes(q),
    );
  }, [users, search]);

  const pageIds = useMemo(() => filtered.map((u) => u.id), [filtered]);
  const selection = useTableSelection({ items: users, pageIds });

  const onToggle = async (user) => {
    if (!onToggleActive || actionLoading) return;

    const targetIds = resolveBulkActionIds(user.id, selection.selectedIds);
    const targets = filterItemsByIds(users, targetIds);
    const disablingManagers =
      collection === "managers" && targets.some((target) => target.active);

    if (disablingManagers) {
      const isBulk = targets.length > 1;
      const res = await zonesSwal({
        title: isBulk
          ? `تعطيل ${targets.length} مديرين وصلاحيات صالاتهم؟`
          : "تعطيل المدير وكل صلاحيات الصالة؟",
        text: "سيتم تعطيل المدير والصالة وجميع موظفيها ولن تظهر في التطبيق.",
        showCancelButton: true,
        confirmButtonText: "تعطيل",
        cancelButtonText: "إلغاء",
      });
      if (!res.isConfirmed) return;
    }

    setActionLoading(true);

    let toggled = 0;
    let lastActive = user.active;

    for (const target of targets) {
      const result = await onToggleActive(target);
      if (!result.ok) {
        zonesToastError(result.error || "تعذّر تحديث حالة الحساب.");
        setActionLoading(false);
        return;
      }
      toggled += 1;
      if (result.user) {
        lastActive = result.user.active;
      }
    }

    setActionLoading(false);

    if (!toggled) return;

    const isBulk = targetIds.length > 1;

    if (isBulk) {
      zonesToastSuccess(`تم تحديث حالة ${toggled} حسابات.`);
    } else if (collection === "managers" && lastActive === false) {
      zonesToastSuccess("تم تعطيل المدير والصالة وجميع موظفيها.");
    } else if (collection === "managers") {
      zonesToastSuccess("تم تفعيل المدير والصالة وموظفيها.");
    } else if (collection === "employees" && lastActive === false) {
      zonesToastSuccess("تم تعطيل حساب الموظف.");
    } else if (collection === "employees") {
      zonesToastSuccess("تم تفعيل حساب الموظف.");
    }

    selection.clearSelection();
  };

  const onArchiveUser = async (user) => {
    if (!onArchive || actionLoading) return;

    const targetIds = resolveBulkActionIds(user.id, selection.selectedIds);
    const targets = filterItemsByIds(users, targetIds);
    const isBulk = targetIds.length > 1;

    const res = await zonesSwal({
      title: isBulk ? `أرشفة ${targetIds.length} حسابات؟` : `أرشفة ${user.fullName}؟`,
      input: "text",
      inputLabel: "سبب الأرشفة",
      inputValue: "أرشفة إدارية",
      showCancelButton: true,
      confirmButtonText: "أرشفة",
      cancelButtonText: "إلغاء",
    });
    if (!res.isConfirmed) return;

    setActionLoading(true);

    for (const target of targets) {
      const result = await onArchive(target.id);
      if (!result.ok) {
        zonesToastError(result.error || "تعذّر أرشفة الحساب.");
        setActionLoading(false);
        return;
      }
    }

    setActionLoading(false);
    selection.clearSelection();
    zonesToastSuccess(isBulk ? `تمت أرشفة ${targets.length} حسابات` : "تمت الأرشفة");
  };

  const handleBulkToggle = () => {
    const targets = filterItemsByIds(users, selection.selectedIds);
    if (!targets.length) return;
    onToggle(targets[0]);
  };

  const handleBulkArchive = () => {
    const targets = filterItemsByIds(users, selection.selectedIds);
    if (!targets.length) return;
    onArchiveUser(targets[0]);
  };

  const colSpan = isManager ? 8 : showWorkingHours ? 10 : 9;

  return (
    <div>
      <div className="mb-4">
        <SearchBar value={search} onChange={setSearch} placeholder={searchPlaceholder} />
      </div>

      <div className="overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-sm dark:border-gray-800 dark:bg-gray-900">
        <TableBulkActionBar
          count={selection.count}
          onClear={selection.clearSelection}
          actions={[
            { label: "تعطيل/تفعيل المحدد", icon: Power, onClick: handleBulkToggle, variant: "outline" },
            { label: "أرشفة المحدد", icon: Archive, onClick: handleBulkArchive, variant: "danger" },
          ]}
        />

        <div className="overflow-x-auto">
          <table className="w-full min-w-[1000px] text-right text-xs">
            <thead>
              <tr className="border-b border-gray-100 text-gray-500 dark:border-gray-800 dark:text-gray-400">
                <TableSelectHeaderCell {...selection} />
                <th className="px-3 py-3 font-bold">الاسم</th>
                {!isManager ? <th className="px-3 py-3 font-bold">الوظيفة</th> : null}
                <th className="px-3 py-3 font-bold">البريد الإلكتروني</th>
                <th className="px-3 py-3 font-bold">الهاتف</th>
                {showWorkingHours ? <th className="px-3 py-3 font-bold">ساعات الدوام</th> : null}
                <th className="px-3 py-3 font-bold">تاريخ الانضمام</th>
                <th className="px-3 py-3 font-bold">الصالات المرتبطة</th>
                <th className="px-3 py-3 font-bold">الحالة</th>
                <th className={TABLE_ACTIONS_TH}>الإجراءات</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
              {loading ? (
                <tr>
                  <td colSpan={colSpan} className="px-3 py-10 text-center text-gray-400">
                    جاري تحميل البيانات...
                  </td>
                </tr>
              ) : (
                filtered.map((u) => (
                  <tr key={u.id} className={selectableRowClass(selection.isSelected(u.id))}>
                    <TableSelectRowCell id={u.id} ariaLabel={`تحديد ${u.fullName}`} {...selection} />
                    <td className="px-3 py-3">
                      <div className="flex items-center gap-2">
                        <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-[#6B5478]/12 text-[10px] font-extrabold text-[#6B5478]">
                          {initials(u.fullName)}
                        </span>
                        <span className="font-bold text-gray-800 dark:text-gray-100">{u.fullName}</span>
                      </div>
                    </td>
                    {!isManager ? (
                      <td className="px-3 py-3 text-gray-600 dark:text-gray-300">{u.roleLabel}</td>
                    ) : null}
                    <td className="px-3 py-3 text-gray-600 dark:text-gray-300" dir="ltr">
                      {u.email}
                    </td>
                    <td className="px-3 py-3 text-gray-600 dark:text-gray-300" dir="ltr">
                      {u.phone}
                    </td>
                    {showWorkingHours ? (
                      <td className="px-3 py-3">
                        <WorkingHoursBadge hours={u.workingHours} />
                      </td>
                    ) : null}
                    <td className="px-3 py-3 text-gray-600 dark:text-gray-300" dir="ltr">
                      {u.joinDate}
                    </td>
                    <td className="px-3 py-3 text-gray-600 dark:text-gray-300">
                      {(u.assignedHalls || []).join("، ")}
                    </td>
                    <td className="px-3 py-3">
                      <div className="flex flex-col gap-1">
                        <span
                          className={`inline-flex w-fit rounded-full px-2.5 py-0.5 text-[11px] font-bold ${
                            u.active
                              ? "bg-emerald-500/15 text-emerald-600 dark:text-emerald-400"
                              : "bg-red-500/15 text-red-600 dark:text-red-400"
                          }`}
                        >
                          {u.active ? "نشط" : "معطّل"}
                        </span>
                        {u.statusNote ? (
                          <span className="text-[10px] font-medium text-red-500 dark:text-red-400">
                            {u.statusNote}
                          </span>
                        ) : null}
                      </div>
                    </td>
                    <td className={TABLE_ACTIONS_TD}>
                      <TableActionsGroup>
                        <IconButton
                          icon={Power}
                          label={
                            selection.isSelected(u.id) && selection.count > 1
                              ? `تعطيل/تفعيل ${selection.count}`
                              : u.active
                                ? "تعطيل"
                                : "تفعيل"
                          }
                          tone={u.active ? "warning" : "success"}
                          onClick={() => onToggle(u)}
                          disabled={actionLoading}
                        />
                        <IconButton
                          icon={Archive}
                          label={
                            selection.isSelected(u.id) && selection.count > 1
                              ? `أرشفة ${selection.count}`
                              : "أرشفة"
                          }
                          tone="danger"
                          onClick={() => onArchiveUser(u)}
                          disabled={actionLoading}
                        />
                      </TableActionsGroup>
                    </td>
                  </tr>
                ))
              )}
              {!loading && filtered.length === 0 ? (
                <tr>
                  <td colSpan={colSpan} className="px-3 py-10 text-center text-gray-400">
                    لا توجد نتائج مطابقة.
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
