import { useEffect, useMemo, useState } from "react";
import { Archive, ArchiveRestore, Eye } from "lucide-react";
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
import { useNavigate } from "react-router-dom";
import ManagerLayout from "../../../shared/layouts/ManagerLayout";
import TablePagination from "../../../shared/components/TablePagination";
import PageHeader from "../../super-admin/components/ui/PageHeader";
import SearchBar from "../../super-admin/components/ui/SearchBar";
import KpiCard from "../../super-admin/components/ui/KpiCard";
import ReceptionStaffDetailsModal from "../components/ReceptionStaffDetailsModal";
import { formatDateAr, formatDateTimeAr, roleLabel, statusLabel } from "../data/employeeMeta";
import {
  EMPLOYEES_STORAGE_EVENT,
  filterArchivedEmployees,
  loadEmployees,
  restoreEmployee,
  saveEmployees,
} from "../data/employeesStorage";
import { confirmAction, toastSuccess } from "../utils/employeeConfirm";

const PAGE_SIZE = 5;

export default function EmployeesArchivePage() {
  const navigate = useNavigate();
  const [rows, setRows] = useState(loadEmployees);
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);
  const [detailEmployee, setDetailEmployee] = useState(null);

  useEffect(() => {
    const sync = () => setRows(loadEmployees());
    window.addEventListener(EMPLOYEES_STORAGE_EVENT, sync);
    return () => window.removeEventListener(EMPLOYEES_STORAGE_EVENT, sync);
  }, []);

  useEffect(() => {
    saveEmployees(rows);
  }, [rows]);

  const archived = useMemo(() => filterArchivedEmployees(rows), [rows]);

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    if (!q) return archived;
    return archived.filter(
      (e) =>
        e.fullName?.toLowerCase().includes(q) ||
        e.email?.toLowerCase().includes(q) ||
        e.phone?.includes(q),
    );
  }, [archived, search]);

  const totalPages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE));
  const paged = filtered.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE);
  const pageIds = useMemo(() => paged.map((row) => row.id), [paged]);
  const selection = useTableSelection({ items: archived, pageIds });

  useEffect(() => {
    if (page > totalPages) setPage(totalPages);
  }, [page, totalPages]);

  const runRestore = async (targetIds) => {
    const targets = filterItemsByIds(archived, targetIds);
    if (!targets.length) return;

    const isBulk = targets.length > 1;
    const ok = await confirmAction({
      title: isBulk ? `استعادة ${targets.length} موظفين؟` : "استعادة الموظف؟",
      text: isBulk
        ? `سيتم إعادة ${targets.length} موظفين إلى قائمة الموظفين النشطة.`
        : `سيتم إعادة «${targets[0].fullName}» إلى قائمة الموظفين النشطة.`,
      confirmText: "نعم، استعد",
    });
    if (!ok) return;

    let next = rows;
    for (const id of targetIds) {
      next = restoreEmployee(next, id);
    }
    setRows(next);
    selection.clearSelection();
    await toastSuccess("تمت الاستعادة", isBulk ? `عاد ${targets.length} موظفين إلى القائمة النشطة.` : "عاد الموظف إلى القائمة النشطة.");

    if (!isBulk && targets[0]) {
      if (targets[0].role === "reception") navigate("/employees/reception");
      else navigate("/employees");
    }
  };

  const handleRestore = (row) => runRestore(resolveBulkActionIds(row.id, selection.selectedIds));

  const handleBulkRestore = () => {
    if (!selection.selectedIds.length) return;
    runRestore(selection.selectedIds);
  };

  return (
    <ManagerLayout title="أرشفة الموظفين">
      <div className="space-y-4" dir="rtl">
        <PageHeader title="أرشفة" />

        <KpiCard label="إجمالي المؤرشفين" value={archived.length} tone="amber" icon={Archive} />

        <SearchBar
          value={search}
          onChange={(v) => {
            setSearch(v);
            setPage(1);
          }}
          placeholder="بحث بالاسم أو البريد أو الهاتف..."
        />

        <div className="overflow-hidden rounded-2xl border border-gray-200 bg-white dark:border-gray-800 dark:bg-gray-900">
          <TableBulkActionBar
            count={selection.count}
            onClear={selection.clearSelection}
            actions={[{ label: "استعادة المحدد", icon: ArchiveRestore, onClick: handleBulkRestore }]}
          />
          <div className="overflow-x-auto">
            <table className="w-full min-w-[900px] text-right text-xs">
              <thead className="border-b border-gray-100 bg-gray-50 text-[11px] font-extrabold text-gray-500 dark:border-gray-800 dark:bg-gray-800/60 dark:text-gray-400">
                <tr>
                  <TableSelectHeaderCell {...selection} />
                  <th className="px-4 py-3">اسم الموظف</th>
                  <th className="px-4 py-3">نوع الموظف</th>
                  <th className="px-4 py-3">البريد الإلكتروني</th>
                  <th className="px-4 py-3">تاريخ الأرشفة</th>
                  <th className="px-4 py-3">آخر تسجيل دخول</th>
                  <th className="px-4 py-3">الحالة السابقة</th>
                  <th className={TABLE_ACTIONS_TH}>الإجراءات</th>
                </tr>
              </thead>
              <tbody>
                {paged.length === 0 ? (
                  <tr>
                    <td colSpan={8} className="px-4 py-10 text-center text-gray-500">
                      لا يوجد موظفون مؤرشفون.
                    </td>
                  </tr>
                ) : (
                  paged.map((row) => (
                    <tr
                      key={row.id}
                      className={selectableRowClass(
                        selection.isSelected(row.id),
                        "border-b border-gray-50 transition hover:bg-amber-500/5 dark:border-gray-800/80",
                      )}
                    >
                      <TableSelectRowCell id={row.id} ariaLabel={`تحديد ${row.fullName}`} {...selection} />
                      <td className="px-4 py-3 font-bold text-gray-800 dark:text-gray-100">{row.fullName}</td>
                      <td className="px-4 py-3 text-gray-600 dark:text-gray-300">{roleLabel(row.role)}</td>
                      <td className="px-4 py-3 text-gray-600 dark:text-gray-300" dir="ltr">
                        {row.email}
                      </td>
                      <td className="px-4 py-3 text-gray-600 dark:text-gray-300">{formatDateTimeAr(row.archivedAt)}</td>
                      <td className="px-4 py-3 text-gray-600 dark:text-gray-300">{formatDateTimeAr(row.lastLogin)}</td>
                      <td className="px-4 py-3 text-gray-600 dark:text-gray-300">{statusLabel(row.status)}</td>
                      <td className={TABLE_ACTIONS_TD}>
                        <TableActionsGroup>
                          <IconButton
                            icon={Eye}
                            label="عرض التفاصيل"
                            tone="brand"
                            onClick={() => setDetailEmployee(row)}
                          />
                          <IconButton
                            icon={ArchiveRestore}
                            label={
                              selection.isSelected(row.id) && selection.count > 1
                                ? `استعادة ${selection.count} موظفين`
                                : "استعادة"
                            }
                            tone="success"
                            onClick={() => handleRestore(row)}
                          />
                        </TableActionsGroup>
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

      <ReceptionStaffDetailsModal
        open={Boolean(detailEmployee)}
        employee={detailEmployee}
        onClose={() => setDetailEmployee(null)}
      />
    </ManagerLayout>
  );
}
