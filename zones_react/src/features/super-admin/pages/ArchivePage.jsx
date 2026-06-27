import { useCallback, useEffect, useMemo, useState } from "react";
import { RotateCcw } from "lucide-react";
import { zonesConfirm, zonesToastError, zonesToastSuccess } from "../../../shared/utils/zonesAlerts";
import {
  TableSelectionModeBar,
  TableSelectHeaderCell,
  TableSelectRowCell,
  selectableRowClass,
} from "../../../shared/components/ui/TableSelection";
import {
  filterItemsByIds,
  resolveBulkActionIds,
  tableSelectColSpan,
} from "../../../shared/hooks/useTableSelection";
import { useTableSelectionMode } from "../../../shared/hooks/useTableSelectionMode";
import PageHeader from "../components/ui/PageHeader";
import { getSuperAdminState, restoreHall } from "../data/superAdminStorage";
import { fetchArchivedStaff, restoreStaffMember } from "../data/staffManagementApi";

const TITLES = {
  halls: { title: "أرشيف الصالات" },
  managers: { title: "أرشيف المدراء" },
  employees: { title: "أرشيف الموظفين" },
};

function initials(name = "") {
  return name.trim().split(/\s+/).slice(0, 2).map((p) => p[0]).join(" ");
}

export default function ArchivePage({ type = "halls" }) {
  const [state, setState] = useState(getSuperAdminState());
  const [archivedUsers, setArchivedUsers] = useState([]);
  const [loadingUsers, setLoadingUsers] = useState(false);
  const [usersError, setUsersError] = useState("");

  const isHalls = type === "halls";

  const loadArchivedUsers = useCallback(async () => {
    if (isHalls) return;

    setLoadingUsers(true);
    setUsersError("");

    const role = type === "managers" ? "manager" : "employee";
    const result = await fetchArchivedStaff({ role });

    if (!result.ok) {
      setArchivedUsers([]);
      setUsersError(result.error || "تعذّر تحميل الأرشيف.");
      setLoadingUsers(false);
      return;
    }

    setArchivedUsers(
      result.users.map((user) => ({
        ...user,
        archiveReason: "أرشفة إدارية",
      })),
    );
    setLoadingUsers(false);
  }, [isHalls, type]);

  useEffect(() => {
    const refreshHalls = () => setState(getSuperAdminState());
    refreshHalls();
    window.addEventListener("super-admin-data-updated", refreshHalls);
    return () => window.removeEventListener("super-admin-data-updated", refreshHalls);
  }, []);

  useEffect(() => {
    loadArchivedUsers();
  }, [loadArchivedUsers]);

  const items = useMemo(() => {
    if (isHalls) return state.archivedHalls;
    return archivedUsers;
  }, [state, isHalls, archivedUsers]);

  const pageIds = useMemo(() => items.map((item) => item.id), [items]);
  const allIds = pageIds;
  const selection = useTableSelectionMode({ items, pageIds, allIds });

  const runRestore = async (targetIds) => {
    const targets = filterItemsByIds(items, targetIds);
    if (!targets.length) return;

    const isBulk = targets.length > 1;
    const ok = await zonesConfirm({
      title: isBulk ? `استرجاع ${targets.length} عناصر؟` : "استرجاع العنصر؟",
      text: isBulk ? "سيتم استرجاع جميع العناصر المحددة من الأرشيف." : undefined,
      confirmText: "استرجاع",
    });
    if (!ok) return;

    for (const target of targets) {
      if (isHalls) {
        restoreHall(target.id);
      } else {
        const result = await restoreStaffMember(target.id);
        if (!result.ok) {
          zonesToastError(result.error || "تعذّر استرجاع الحساب.");
          return;
        }
      }
    }

    if (!isHalls) {
      await loadArchivedUsers();
    }

    selection.exitSelectionMode();
    zonesToastSuccess(isBulk ? `تم استرجاع ${targets.length} عناصر` : "تمت الاستعادة");
  };

  const onRestoreHall = (hall) => runRestore(resolveBulkActionIds(hall.id, selection.selectedIds));
  const onRestoreUser = (user) => runRestore(resolveBulkActionIds(user.id, selection.selectedIds));

  const handleBulkRestore = () => {
    if (!selection.selectedIds.length) return;
    runRestore(selection.selectedIds);
  };

  const ArchivedBadge = () => (
    <span className="rounded-full bg-[#6B5478]/12 px-2.5 py-0.5 text-[11px] font-bold text-[#6B5478]">مؤرشف</span>
  );

  const RestoreBtn = ({ onClick, bulkCount }) => (
    <button
      onClick={onClick}
      className="flex items-center gap-1 whitespace-nowrap rounded-lg bg-[#6B5478] px-3 py-1 text-[11px] font-bold text-white hover:bg-[#5a4665]"
    >
      <RotateCcw size={13} /> {bulkCount > 1 ? `استرجاع ${bulkCount}` : "استرجاع"}
    </button>
  );

  const showEmployeeRole = type === "employees";
  const baseColCount = isHalls ? 7 : showEmployeeRole ? 9 : 8;

  return (
    <div>
      <PageHeader title={TITLES[type].title} />

      {!isHalls && usersError ? (
        <div className="mb-4 rounded-2xl border border-red-500/25 bg-red-500/10 px-4 py-3 text-sm font-semibold text-red-600 dark:text-red-400">
          {usersError}
        </div>
      ) : null}

      <div className="overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-sm dark:border-gray-800 dark:bg-gray-900">
        <TableSelectionModeBar
          selectionMode={selection.selectionMode}
          onEnter={selection.enterSelectionMode}
          onExit={selection.exitSelectionMode}
          count={selection.count}
          totalCount={items.length}
          onClear={selection.clearSelection}
          actions={[{ label: "استرجاع المحدد", icon: RotateCcw, onClick: handleBulkRestore }]}
        />

        <div className="overflow-x-auto">
          <table className="w-full min-w-[760px] text-right text-xs">
            <thead>
              <tr className="border-b border-gray-100 text-gray-500 dark:border-gray-800 dark:text-gray-400">
                <TableSelectHeaderCell {...selection} />
                {isHalls ? (
                  <>
                    <th className="px-3 py-3 font-bold">اسم الصالة</th>
                    <th className="px-3 py-3 font-bold">العنوان</th>
                    <th className="px-3 py-3 font-bold">المدير</th>
                    <th className="px-3 py-3 font-bold">تاريخ الأرشفة</th>
                    <th className="px-3 py-3 font-bold">سبب الأرشفة</th>
                    <th className="px-3 py-3 font-bold">الحالة</th>
                    <th className="px-3 py-3 font-bold">الإجراء</th>
                  </>
                ) : (
                  <>
                    <th className="px-3 py-3 font-bold">الاسم</th>
                    {showEmployeeRole ? <th className="px-3 py-3 font-bold">الوظيفة</th> : null}
                    <th className="px-3 py-3 font-bold">البريد الإلكتروني</th>
                    <th className="px-3 py-3 font-bold">الهاتف</th>
                    <th className="px-3 py-3 font-bold">تاريخ الانضمام</th>
                    <th className="px-3 py-3 font-bold">اسم الصالة</th>
                    <th className="px-3 py-3 font-bold">تاريخ الأرشفة</th>
                    <th className="px-3 py-3 font-bold">سبب الأرشفة</th>
                    <th className="px-3 py-3 font-bold">الإجراء</th>
                  </>
                )}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
              {!isHalls && loadingUsers ? (
                <tr>
                  <td colSpan={tableSelectColSpan(baseColCount, selection.selectionMode)} className="px-3 py-10 text-center text-gray-400">
                    جاري تحميل الأرشيف...
                  </td>
                </tr>
              ) : null}
              {isHalls
                ? items.map((h) => (
                    <tr key={h.id} className={selection.selectionMode ? selectableRowClass(selection.isSelected(h.id)) : undefined}>
                      <TableSelectRowCell id={h.id} ariaLabel={`تحديد ${h.name}`} {...selection} />
                      <td className="px-3 py-3 font-bold text-gray-800 dark:text-gray-100">{h.name}</td>
                      <td className="px-3 py-3 text-gray-600 dark:text-gray-300">{h.address}</td>
                      <td className="px-3 py-3 text-gray-600 dark:text-gray-300">{h.managerName}</td>
                      <td className="px-3 py-3 text-gray-600 dark:text-gray-300" dir="ltr">
                        {h.archivedAt}
                      </td>
                      <td className="px-3 py-3 text-gray-600 dark:text-gray-300">{h.archiveReason}</td>
                      <td className="px-3 py-3">
                        <ArchivedBadge />
                      </td>
                      <td className="px-3 py-3">
                        <RestoreBtn
                          onClick={() => onRestoreHall(h)}
                          bulkCount={
                            selection.isSelected(h.id) && selection.count > 1 ? selection.count : 1
                          }
                        />
                      </td>
                    </tr>
                  ))
                : items.map((u) => (
                    <tr key={u.id} className={selection.selectionMode ? selectableRowClass(selection.isSelected(u.id)) : undefined}>
                      <TableSelectRowCell id={u.id} ariaLabel={`تحديد ${u.fullName}`} {...selection} />
                      <td className="px-3 py-3">
                        <div className="flex items-center gap-2">
                          <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-[#6B5478]/12 text-[10px] font-extrabold text-[#6B5478]">
                            {initials(u.fullName)}
                          </span>
                          <span className="font-bold text-gray-800 dark:text-gray-100">{u.fullName}</span>
                        </div>
                      </td>
                      {showEmployeeRole ? (
                        <td className="px-3 py-3 text-gray-600 dark:text-gray-300">{u.roleLabel}</td>
                      ) : null}
                      <td className="px-3 py-3 text-gray-600 dark:text-gray-300" dir="ltr">
                        {u.email}
                      </td>
                      <td className="px-3 py-3 text-gray-600 dark:text-gray-300" dir="ltr">
                        {u.phone}
                      </td>
                      <td className="px-3 py-3 text-gray-600 dark:text-gray-300" dir="ltr">
                        {u.joinDate}
                      </td>
                      <td className="px-3 py-3 text-gray-600 dark:text-gray-300">
                        {(u.assignedHalls || [])[0] || "—"}
                      </td>
                      <td className="px-3 py-3 text-gray-600 dark:text-gray-300" dir="ltr">
                        {u.archivedAt}
                      </td>
                      <td className="px-3 py-3 text-gray-600 dark:text-gray-300">{u.archiveReason}</td>
                      <td className="px-3 py-3">
                        <RestoreBtn
                          onClick={() => onRestoreUser(u)}
                          bulkCount={
                            selection.isSelected(u.id) && selection.count > 1 ? selection.count : 1
                          }
                        />
                      </td>
                    </tr>
                  ))}
              {!loadingUsers && items.length === 0 ? (
                <tr>
                  <td colSpan={tableSelectColSpan(baseColCount, selection.selectionMode)} className="px-3 py-10 text-center text-gray-400">
                    لا توجد عناصر مؤرشفة.
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
