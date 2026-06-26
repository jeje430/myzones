import { useMemo, useState } from "react";
import { Archive, Power } from "lucide-react";
import { zonesSwal, zonesToastSuccess } from "../../../shared/utils/zonesAlerts";
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
import { archiveUser, toggleUserActive } from "../data/superAdminStorage";

function initials(name = "") {
  const parts = name.trim().split(/\s+/).slice(0, 2);
  return parts.map((p) => p[0]).join(" ");
}

export default function UsersTable({ collection, users, searchPlaceholder, isManager }) {
  const [search, setSearch] = useState("");

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    if (!q) return users;
    return users.filter(
      (u) =>
        u.fullName.toLowerCase().includes(q) ||
        u.email.toLowerCase().includes(q) ||
        (u.assignedHalls || []).join(" ").toLowerCase().includes(q),
    );
  }, [users, search]);

  const pageIds = useMemo(() => filtered.map((u) => u.id), [filtered]);
  const selection = useTableSelection({ items: users, pageIds });

  const onToggle = (user) => {
    const targetIds = resolveBulkActionIds(user.id, selection.selectedIds);
    const targets = filterItemsByIds(users, targetIds);
    let toggled = 0;

    for (const target of targets) {
      const result = toggleUserActive(collection, target.id);
      if (result.ok) toggled += 1;
    }

    if (!toggled) return;

    const last = targets[targets.length - 1];
    const isBulk = targetIds.length > 1;

    if (isBulk) {
      zonesToastSuccess(`تم تحديث حالة ${toggled} حسابات.`);
    } else if (collection === "managers" && last?.active === false) {
      zonesToastSuccess("تم تعطيل المدير والصالة وجميع موظفيها.");
    } else if (collection === "managers" && last?.active === true) {
      zonesToastSuccess("تم تفعيل المدير والصالة وموظفيها.");
    } else if (collection === "employees" && last?.active === false) {
      zonesToastSuccess("تم تعطيل حساب الموظف.");
    } else if (collection === "employees") {
      zonesToastSuccess("تم تفعيل حساب الموظف.");
    }

    selection.clearSelection();
  };

  const onArchive = async (user) => {
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

    for (const target of targets) {
      archiveUser(collection, target.id, res.value);
    }

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
    onArchive(targets[0]);
  };

  const colSpan = isManager ? 8 : 9;

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
                <th className="px-3 py-3 font-bold">تاريخ الانضمام</th>
                <th className="px-3 py-3 font-bold">الصالات المرتبطة</th>
                <th className="px-3 py-3 font-bold">الحالة</th>
                <th className={TABLE_ACTIONS_TH}>الإجراءات</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
              {filtered.map((u) => (
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
                  <td className="px-3 py-3 text-gray-600 dark:text-gray-300" dir="ltr">
                    {u.joinDate}
                  </td>
                  <td className="px-3 py-3 text-gray-600 dark:text-gray-300">
                    {(u.assignedHalls || []).join("، ")}
                  </td>
                  <td className="px-3 py-3">
                    <span
                      className={`rounded-full px-2.5 py-0.5 text-[11px] font-bold ${
                        u.active
                          ? "bg-emerald-500/15 text-emerald-600 dark:text-emerald-400"
                          : "bg-red-500/15 text-red-600 dark:text-red-400"
                      }`}
                    >
                      {u.active ? "نشط" : "معطّل"}
                    </span>
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
                      />
                      <IconButton
                        icon={Archive}
                        label={
                          selection.isSelected(u.id) && selection.count > 1
                            ? `أرشفة ${selection.count}`
                            : "أرشفة"
                        }
                        tone="danger"
                        onClick={() => onArchive(u)}
                      />
                    </TableActionsGroup>
                  </td>
                </tr>
              ))}
              {filtered.length === 0 ? (
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
