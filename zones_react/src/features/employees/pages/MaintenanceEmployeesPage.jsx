import { useEffect, useMemo, useState } from "react";
import { Archive, Wrench } from "lucide-react";
import ManagerLayout from "../../../shared/layouts/ManagerLayout";
import TablePagination from "../../../shared/components/TablePagination";
import PageHeader from "../../super-admin/components/ui/PageHeader";
import KpiCard from "../../super-admin/components/ui/KpiCard";
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
import {
  StaffRowActions,
  StaffSearchToolbar,
  StaffStatusBadge,
} from "../components/EmployeeStaffTableHelpers";
import ReceptionStaffDetailsModal from "../components/ReceptionStaffDetailsModal";
import ReceptionStaffEditModal from "../components/ReceptionStaffEditModal";
import SendEmployeeInviteModal from "../components/SendEmployeeInviteModal";
import { formatDateAr, formatDateTimeAr, normalizeStatus } from "../data/employeeMeta";
import {
  EMPLOYEES_STORAGE_EVENT,
  archiveEmployee,
  filterEmployeesByRole,
  loadEmployees,
  saveEmployees,
} from "../data/employeesStorage";
import { confirmAction, toastSuccess } from "../utils/employeeConfirm";

const PAGE_SIZE = 5;

export default function MaintenanceEmployeesPage() {
  const [rows, setRows] = useState(loadEmployees);
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);
  const [addModalOpen, setAddModalOpen] = useState(false);
  const [detailEmployee, setDetailEmployee] = useState(null);
  const [editEmployee, setEditEmployee] = useState(null);

  useEffect(() => {
    const sync = () => setRows(loadEmployees());
    window.addEventListener(EMPLOYEES_STORAGE_EVENT, sync);
    return () => window.removeEventListener(EMPLOYEES_STORAGE_EVENT, sync);
  }, []);

  useEffect(() => {
    saveEmployees(rows);
  }, [rows]);

  const maintenanceStaff = useMemo(
    () => filterEmployeesByRole(rows, "maintenance", { archived: false }),
    [rows],
  );

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    if (!q) return maintenanceStaff;
    return maintenanceStaff.filter(
      (e) =>
        e.fullName?.toLowerCase().includes(q) ||
        e.email?.toLowerCase().includes(q) ||
        e.phone?.includes(q),
    );
  }, [maintenanceStaff, search]);

  const totalPages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE));
  const paged = filtered.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE);
  const pageIds = useMemo(() => paged.map((row) => row.id), [paged]);
  const selection = useTableSelection({ items: maintenanceStaff, pageIds });

  useEffect(() => {
    if (page > totalPages) setPage(totalPages);
  }, [page, totalPages]);

  const runArchive = async (targetIds) => {
    const targets = filterItemsByIds(maintenanceStaff, targetIds);
    if (!targets.length) return;

    const isBulk = targets.length > 1;
    const ok = await confirmAction({
      title: isBulk ? `أرشفة ${targets.length} موظفين؟` : "أرشفة الموظف؟",
      text: isBulk
        ? `سيتم نقل ${targets.length} موظفين إلى واجهة الأرشفة.`
        : `سيتم نقل «${targets[0].fullName}» إلى واجهة الأرشفة.`,
      confirmText: "نعم، أرشف",
      danger: true,
    });
    if (!ok) return;

    let next = rows;
    for (const id of targetIds) {
      next = archiveEmployee(next, id);
    }
    setRows(next);
    selection.clearSelection();
    await toastSuccess("تمت الأرشفة", isBulk ? `تم نقل ${targets.length} موظفين إلى الأرشفة.` : "تم نقل الموظف إلى واجهة الأرشفة.");
  };

  const handleArchive = (row) => runArchive(resolveBulkActionIds(row.id, selection.selectedIds));

  const handleBulkArchive = () => {
    if (!selection.selectedIds.length) return;
    runArchive(selection.selectedIds);
  };

  return (
    <ManagerLayout title="موظفو الصيانة">
      <div className="space-y-4" dir="rtl">
        <PageHeader title="صيانة" description="إدارة موظفي الصيانة المرتبطين بالصالة" />

        <div className="grid gap-3 sm:grid-cols-3">
          <KpiCard label="إجمالي موظفي الصيانة" value={maintenanceStaff.length} icon={Wrench} />
          <KpiCard
            label="يعملون حالياً"
            value={maintenanceStaff.filter((e) => normalizeStatus(e.status) === "working").length}
            tone="green"
          />
          <KpiCard
            label="في إجازة"
            value={maintenanceStaff.filter((e) => normalizeStatus(e.status) === "leave").length}
            tone="amber"
          />
        </div>

        <StaffSearchToolbar
          search={search}
          onSearchChange={(v) => {
            setSearch(v);
            setPage(1);
          }}
          onAddClick={() => setAddModalOpen(true)}
        />

        <div className="overflow-hidden rounded-2xl border border-gray-200 bg-white dark:border-gray-800 dark:bg-gray-900">
          <TableBulkActionBar
            count={selection.count}
            onClear={selection.clearSelection}
            actions={[{ label: "أرشفة المحدد", icon: Archive, onClick: handleBulkArchive, variant: "dangerOutline" }]}
          />
          <div className="overflow-x-auto">
            <table className="w-full min-w-[920px] text-right text-xs">
              <thead className="border-b border-gray-100 bg-gray-50 text-[11px] font-extrabold text-gray-500 dark:border-gray-800 dark:bg-gray-800/60 dark:text-gray-400">
                <tr>
                  <TableSelectHeaderCell {...selection} />
                  <th className="px-4 py-3">اسم الموظف</th>
                  <th className="px-4 py-3">البريد الإلكتروني</th>
                  <th className="px-4 py-3">رقم الهاتف</th>
                  <th className="px-4 py-3">تاريخ الانضمام</th>
                  <th className="px-4 py-3">آخر تسجيل دخول</th>
                  <th className="px-4 py-3">الحالة</th>
                  <th className={TABLE_ACTIONS_TH}>الإجراءات</th>
                </tr>
              </thead>
              <tbody>
                {paged.length === 0 ? (
                  <tr>
                    <td colSpan={8} className="px-4 py-10 text-center text-gray-500">
                      لا يوجد موظفو صيانة مطابقون للبحث.
                    </td>
                  </tr>
                ) : (
                  paged.map((row) => (
                    <tr
                      key={row.id}
                      className={selectableRowClass(
                        selection.isSelected(row.id),
                        "border-b border-gray-50 transition hover:bg-[#6B5478]/5 dark:border-gray-800/80",
                      )}
                    >
                      <TableSelectRowCell id={row.id} ariaLabel={`تحديد ${row.fullName}`} {...selection} />
                      <td className="px-4 py-3 font-bold text-gray-800 dark:text-gray-100">{row.fullName}</td>
                      <td className="px-4 py-3 text-gray-600 dark:text-gray-300" dir="ltr">
                        {row.email}
                      </td>
                      <td className="px-4 py-3 text-gray-600 dark:text-gray-300" dir="ltr">
                        {row.phone}
                      </td>
                      <td className="px-4 py-3 text-gray-600 dark:text-gray-300">{formatDateAr(row.joinDate)}</td>
                      <td className="px-4 py-3 text-gray-600 dark:text-gray-300">{formatDateTimeAr(row.lastLogin)}</td>
                      <td className="px-4 py-3">
                        <StaffStatusBadge status={row.status} />
                      </td>
                      <td className={TABLE_ACTIONS_TD}>
                        <StaffRowActions
                          onDetails={() => setDetailEmployee(row)}
                          onEdit={() => setEditEmployee(row)}
                          onArchive={() => handleArchive(row)}
                        />
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
          <TablePagination
            page={page}
            totalPages={totalPages}
            totalItems={filtered.length}
            pageSize={PAGE_SIZE}
            onPageChange={setPage}
          />
        </div>
      </div>

      <SendEmployeeInviteModal
        open={addModalOpen}
        onClose={() => setAddModalOpen(false)}
        defaultRole="maintenance"
      />
      <ReceptionStaffDetailsModal
        open={Boolean(detailEmployee)}
        employee={detailEmployee}
        onClose={() => setDetailEmployee(null)}
      />
      <ReceptionStaffEditModal
        open={Boolean(editEmployee)}
        employee={editEmployee}
        employees={rows}
        onClose={() => setEditEmployee(null)}
        onSaved={setRows}
      />
    </ManagerLayout>
  );
}
