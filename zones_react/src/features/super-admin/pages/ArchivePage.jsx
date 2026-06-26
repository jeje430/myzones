import { useEffect, useMemo, useState } from "react";
import { RotateCcw } from "lucide-react";
import { zonesConfirm, zonesToastSuccess } from "../../../shared/utils/zonesAlerts";
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
import PageHeader from "../components/ui/PageHeader";
import { getSuperAdminState, restoreArchivedUser, restoreHall } from "../data/superAdminStorage";

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

  useEffect(() => {
    const refresh = () => setState(getSuperAdminState());
    refresh();
    window.addEventListener("super-admin-data-updated", refresh);
    return () => window.removeEventListener("super-admin-data-updated", refresh);
  }, []);

  const isHalls = type === "halls";

  const items = useMemo(() => {
    if (isHalls) return state.archivedHalls;
    const role = type === "managers" ? "manager" : ["reception", "maintenance"];
    return state.archivedUsers.filter((u) =>
      Array.isArray(role) ? role.includes(u.role) : u.role === role,
    );
  }, [state, type, isHalls]);

  const pageIds = useMemo(() => items.map((item) => item.id), [items]);
  const selection = useTableSelection({ items, pageIds });

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
      if (isHalls) restoreHall(target.id);
      else restoreArchivedUser(target.id);
    }

    selection.clearSelection();
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
  const colCount = isHalls ? 8 : showEmployeeRole ? 10 : 9;

  return (
    <div>
      <PageHeader title={TITLES[type].title} />

      <div className="overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-sm dark:border-gray-800 dark:bg-gray-900">
        <TableBulkActionBar
          count={selection.count}
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
              {isHalls
                ? items.map((h) => (
                    <tr key={h.id} className={selectableRowClass(selection.isSelected(h.id))}>
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
              {items.length === 0 ? (
                <tr>
                  <td colSpan={colCount} className="px-3 py-10 text-center text-gray-400">
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
