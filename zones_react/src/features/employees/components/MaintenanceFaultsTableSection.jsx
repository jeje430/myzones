import { useCallback, useEffect, useMemo, useState } from "react";
import { CheckCircle2, Plus } from "lucide-react";
import { zonesToastSuccess } from "../../../shared/utils/zonesAlerts";
import Button from "../../super-admin/components/ui/Button";
import SearchBar from "../../super-admin/components/ui/SearchBar";
import TablePagination from "../../../shared/components/TablePagination";
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
import { useDevicesStorageSync } from "../../devices-packages/hooks/useDevicesStorageSync";
import {
  DEVICES_STORAGE_EVENT,
  loadDevices,
} from "../../devices-packages/data/devicesStorage";
import {
  getArchivedFaults,
  getCurrentFaults,
  MAINTENANCE_FAULTS_EVENT,
} from "../../maintenance/data/maintenanceFaultsStorage";
import {
  reportDeviceFault,
  completeDeviceRepair,
  reconcileDisabledDevicesWithoutFaults,
} from "../../maintenance/utils/maintenanceWorkflow";
import {
  faultRowDisplayStatus,
  faultStatusBadgeClass,
  faultTypeLabel,
  formatFaultCost,
  formatDisplayDate,
} from "../../maintenance/data/faultMeta";
import MaintenanceFaultRecordModal from "./MaintenanceFaultRecordModal";
import MaintenanceCompleteRepairModal from "./MaintenanceCompleteRepairModal";
import DeviceNameCell from "./DeviceNameCell";

const PAGE_SIZE = 8;

function FaultRowStatusBadge({ row }) {
  const device = loadDevices().find((d) => d.id === row.deviceId);
  const ui = faultRowDisplayStatus(row, device);
  return (
    <span className={`inline-flex rounded-full px-2.5 py-0.5 text-[11px] font-bold ${faultStatusBadgeClass(ui.tone)}`}>
      {ui.label}
    </span>
  );
}

export default function MaintenanceFaultsTableSection({
  mode = "active",
  readOnly = false,
  showEmployeeColumn = false,
  sectionTitle,
}) {
  const isArchived = mode === "archived";

  const loadRows = useCallback(
    () => (isArchived ? getArchivedFaults() : getCurrentFaults()),
    [isArchived],
  );

  const [faults, setFaults] = useState(loadRows);
  const [devicesTick, setDevicesTick] = useState(0);
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);
  const [modalOpen, setModalOpen] = useState(false);
  const [repairModalOpen, setRepairModalOpen] = useState(false);
  const [repairRow, setRepairRow] = useState(null);
  const [repairTargetIds, setRepairTargetIds] = useState([]);

  const refreshFaults = useCallback(() => setFaults(loadRows()), [loadRows]);
  const refreshDevices = useCallback(() => setDevicesTick((t) => t + 1), []);

  const refreshAll = useCallback(() => {
    reconcileDisabledDevicesWithoutFaults();
    refreshFaults();
    refreshDevices();
  }, [refreshFaults, refreshDevices]);

  useEffect(() => {
    refreshAll();
    window.addEventListener(MAINTENANCE_FAULTS_EVENT, refreshAll);
    window.addEventListener(DEVICES_STORAGE_EVENT, refreshAll);
    window.addEventListener("focus", refreshAll);
    return () => {
      window.removeEventListener(MAINTENANCE_FAULTS_EVENT, refreshAll);
      window.removeEventListener(DEVICES_STORAGE_EVENT, refreshAll);
      window.removeEventListener("focus", refreshAll);
    };
  }, [refreshAll]);

  useDevicesStorageSync(refreshAll);

  useEffect(() => {
    setPage(1);
  }, [search, mode]);

  const filtered = useMemo(() => {
    void devicesTick;
    const q = search.trim().toLowerCase();
    if (!q) return faults;
    return faults.filter(
      (f) =>
        (f.deviceName || "").toLowerCase().includes(q) ||
        (f.maintenanceEmployeeName || "").toLowerCase().includes(q) ||
        faultTypeLabel(f.faultType, f.faultTypeCustom).toLowerCase().includes(q),
    );
  }, [faults, search, devicesTick]);

  const totalPages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE));
  const paged = filtered.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE);
  const pageIds = useMemo(() => paged.map((row) => row.id), [paged]);
  const selection = useTableSelection({ items: faults, pageIds });
  const colSpan =
    1 +
    (isArchived ? 6 : 7) +
    (showEmployeeColumn ? 1 : 0) +
    (!readOnly && !isArchived ? 1 : 0);

  useEffect(() => {
    if (page > totalPages) setPage(totalPages);
  }, [page, totalPages]);

  const handleSave = async (payload) => {
    const ok = await reportDeviceFault(payload);
    if (!ok) return;
    refreshAll();
    setModalOpen(false);
    zonesToastSuccess(`تم تسجيل العطل — الجهاز في الصيانة`, `«${payload.deviceName}»`);
  };

  const openCompleteRepair = (row, e) => {
    e?.stopPropagation?.();
    const targetIds = resolveBulkActionIds(row.id, selection.selectedIds);
    const targets = filterItemsByIds(faults, targetIds);
    setRepairTargetIds(targetIds);
    setRepairRow(targets[0] || row);
    setRepairModalOpen(true);
  };

  const handleBulkCompleteRepair = () => {
    const targets = filterItemsByIds(faults, selection.selectedIds);
    if (!targets.length) return;
    setRepairTargetIds(selection.selectedIds);
    setRepairRow(targets[0]);
    setRepairModalOpen(true);
  };

  const handleCompleteRepair = async (cost) => {
    const ids = repairTargetIds.length ? repairTargetIds : repairRow ? [repairRow.id] : [];
    const targets = filterItemsByIds(faults, ids);
    if (!targets.length) return;

    for (const row of targets) {
      const ok = await completeDeviceRepair(row.deviceId, cost);
      if (!ok) return;
    }

    setRepairModalOpen(false);
    setRepairRow(null);
    setRepairTargetIds([]);
    selection.clearSelection();
    refreshAll();
    const isBulk = targets.length > 1;
    zonesToastSuccess(
      isBulk
        ? `تم إصلاح ${targets.length} أعطال — السجلات في الأرشيف والأجهزة متاحة للحجز`
        : "تم الإصلاح — السجل في الأرشيف والجهاز متاح للحجز",
    );
  };

  return (
    <>
      <section className="overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-sm dark:border-gray-800 dark:bg-gray-900">
        <div className="flex flex-wrap items-center justify-between gap-3 border-b border-gray-100 px-5 py-4 dark:border-gray-800">
          <h2 className="text-sm font-extrabold text-gray-900 dark:text-white">{sectionTitle}</h2>
          <span className="rounded-full bg-[#6B5478]/12 px-2.5 py-0.5 text-[11px] font-bold text-[#6B5478]">
            {filtered.length} سجل
          </span>
        </div>

        <div
          className={`flex flex-wrap items-center gap-3 border-b border-gray-100 px-5 py-3 dark:border-gray-800 ${
            readOnly ? "" : "justify-between"
          }`}
        >
          <SearchBar
            containerClassName={readOnly ? "max-w-md flex-1" : "min-w-[220px] flex-1 max-w-none"}
            value={search}
            onChange={setSearch}
            placeholder={
              showEmployeeColumn
                ? "بحث عن جهاز أو موظف صيانة أو نوع عطل..."
                : "بحث عن جهاز أو نوع عطل..."
            }
          />
          {!readOnly && !isArchived ? (
            <Button size="sm" onClick={() => setModalOpen(true)}>
              <Plus className="h-4 w-4" />
              تسجيل عطل جديد
            </Button>
          ) : null}
        </div>

        {!readOnly && !isArchived ? (
          <TableBulkActionBar
            count={selection.count}
            onClear={selection.clearSelection}
            actions={[{ label: "تم الإصلاح للمحدد", icon: CheckCircle2, onClick: handleBulkCompleteRepair }]}
          />
        ) : null}

        <div className="overflow-x-auto">
          <table className="w-full min-w-[1000px] text-right text-xs">
            <thead>
              <tr className="border-b border-gray-100 text-gray-500 dark:border-gray-800 dark:text-gray-400">
                <TableSelectHeaderCell {...selection} />
                <th className="px-3 py-2.5 font-bold">الجهاز</th>
                <th className="px-3 py-2.5 font-bold">نوع العطل</th>
                {showEmployeeColumn ? (
                  <th className="px-3 py-2.5 font-bold">موظف الصيانة</th>
                ) : null}
                {isArchived ? (
                  <>
                    <th className="px-3 py-2.5 font-bold">تاريخ العطل</th>
                    <th className="px-3 py-2.5 font-bold">تاريخ الإصلاح</th>
                    <th className="px-3 py-2.5 font-bold">تكلفة الإصلاح</th>
                  </>
                ) : (
                  <>
                    <th className="px-3 py-2.5 font-bold">تاريخ العطل</th>
                    <th className="px-3 py-2.5 font-bold">الحالة</th>
                  </>
                )}
                {!readOnly && !isArchived ? <th className={TABLE_ACTIONS_TH}>الإجراءات</th> : null}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
              {paged.length === 0 ? (
                <tr>
                  <td colSpan={colSpan} className="px-3 py-10 text-center text-gray-400">
                    {isArchived ? "لا توجد أعطال مؤرشفة." : "لا توجد أعطال حالية."}
                  </td>
                </tr>
              ) : (
                paged.map((row) => {
                  const device = loadDevices().find((d) => d.id === row.deviceId);
                  return (
                    <tr key={row.id} className={selectableRowClass(selection.isSelected(row.id))}>
                      <TableSelectRowCell
                        id={row.id}
                        ariaLabel={`تحديد عطل ${row.deviceName}`}
                        {...selection}
                      />
                      <td className="px-3 py-3">
                        <DeviceNameCell
                          deviceName={row.deviceName}
                          deviceTypeLabel={row.deviceTypeLabel}
                          deviceId={row.deviceId}
                        />
                      </td>
                      <td className="px-3 py-3 text-gray-600 dark:text-gray-300">
                        {faultTypeLabel(row.faultType, row.faultTypeCustom)}
                      </td>
                      {showEmployeeColumn ? (
                        <td className="px-3 py-3 font-semibold text-gray-700 dark:text-gray-200">
                          {row.maintenanceEmployeeName || "—"}
                        </td>
                      ) : null}
                      {isArchived ? (
                        <>
                          <td className="px-3 py-3 whitespace-nowrap text-gray-500" dir="ltr">
                            {formatDisplayDate(row.createdAt)}
                          </td>
                          <td className="px-3 py-3 whitespace-nowrap text-gray-500" dir="ltr">
                            {formatDisplayDate(row.resolvedAt)}
                          </td>
                          <td className="px-3 py-3 font-bold text-[#6B5478]">
                            {formatFaultCost(row.maintenanceCost)}
                          </td>
                        </>
                      ) : (
                        <>
                          <td className="px-3 py-3 whitespace-nowrap text-gray-500" dir="ltr">
                            {formatDisplayDate(row.createdAt)}
                          </td>
                          <td className="px-3 py-3">
                            <FaultRowStatusBadge row={row} />
                          </td>
                        </>
                      )}
                      {!readOnly && !isArchived ? (
                        <td className={TABLE_ACTIONS_TD}>
                          <TableActionsGroup>
                            <IconButton
                              icon={CheckCircle2}
                              label={
                                selection.isSelected(row.id) && selection.count > 1
                                  ? `تم الإصلاح (${selection.count})`
                                  : "تم الإصلاح"
                              }
                              tone="success"
                              onClick={(e) => openCompleteRepair(row, e)}
                            />
                          </TableActionsGroup>
                        </td>
                      ) : null}
                    </tr>
                  );
                })
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
      </section>

      {!readOnly && !isArchived ? (
        <>
          <MaintenanceFaultRecordModal
            open={modalOpen}
            onClose={() => setModalOpen(false)}
            onSave={handleSave}
          />
          <MaintenanceCompleteRepairModal
            open={repairModalOpen}
            device={
              repairRow
                ? loadDevices().find((d) => d.id === repairRow.deviceId) || {
                    name: repairRow.deviceName,
                    typeLabel: repairRow.deviceTypeLabel,
                    id: repairRow.deviceId,
                  }
                : null
            }
            onClose={() => {
              setRepairModalOpen(false);
              setRepairRow(null);
              setRepairTargetIds([]);
            }}
            onConfirm={handleCompleteRepair}
          />
        </>
      ) : null}
    </>
  );
}
