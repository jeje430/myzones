import { useCallback, useEffect, useMemo, useState } from "react";
import { Power, PowerOff } from "lucide-react";
import { zonesToastSuccess } from "../../../shared/utils/zonesAlerts";
import PageHeader from "../../super-admin/components/ui/PageHeader";
import SearchBar from "../../super-admin/components/ui/SearchBar";
import ToggleSwitch from "../../super-admin/components/ui/ToggleSwitch";
import TablePagination from "../../../shared/components/TablePagination";
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
import { loadPackages, PACKAGES_STORAGE_EVENT } from "../../devices-packages/data/packagesStorage";
import { isDeviceBroken, loadSyncedActiveDevices } from "../../devices-packages/utils/deviceFaultSync";
import { MAINTENANCE_FAULTS_EVENT } from "../../maintenance/data/maintenanceFaultsStorage";
import { deviceFaultUiStatus, faultStatusBadgeClass, formatDisplayDate } from "../../maintenance/data/faultMeta";
import {
  isDeviceToggleLocked,
  reportDeviceFault,
  tryEnableDevice,
} from "../../maintenance/utils/maintenanceWorkflow";
import MaintenanceFaultRecordModal from "../components/MaintenanceFaultRecordModal";
import DeviceNameCell from "../components/DeviceNameCell";

const PAGE_SIZE = 8;

function DeviceStatusLabel({ active, locked }) {
  return (
    <span
      className={`inline-flex rounded-full px-2.5 py-0.5 text-[11px] font-bold ${
        locked
          ? "bg-red-500/15 text-red-600 dark:text-red-400"
          : active
            ? "bg-emerald-500/15 text-emerald-600 dark:text-emerald-400"
            : "bg-gray-200 text-gray-500 dark:bg-gray-700 dark:text-gray-400"
      }`}
    >
      {locked ? "معطّل — مقفول" : active ? "مفعّل" : "معطّل"}
    </span>
  );
}

function FaultStateBadge({ device }) {
  const ui = deviceFaultUiStatus(device);
  return (
    <span className={`inline-flex rounded-full px-2.5 py-0.5 text-[11px] font-bold ${faultStatusBadgeClass(ui.tone)}`}>
      {ui.label}
    </span>
  );
}

export default function MaintenanceDevicesPage() {
  const [devices, setDevices] = useState(() => loadSyncedActiveDevices());
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);
  const [faultModalOpen, setFaultModalOpen] = useState(false);
  const [prefilledDeviceId, setPrefilledDeviceId] = useState(null);

  const refresh = useCallback(() => setDevices(loadSyncedActiveDevices()), []);

  useDevicesStorageSync(refresh);

  useEffect(() => {
    refresh();
    window.addEventListener(MAINTENANCE_FAULTS_EVENT, refresh);
    window.addEventListener(PACKAGES_STORAGE_EVENT, refresh);
    return () => {
      window.removeEventListener(MAINTENANCE_FAULTS_EVENT, refresh);
      window.removeEventListener(PACKAGES_STORAGE_EVENT, refresh);
    };
  }, [refresh]);

  useEffect(() => {
    setPage(1);
  }, [search]);

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    if (!q) return devices;
    return devices.filter(
      (d) =>
        d.name.toLowerCase().includes(q) ||
        (d.typeLabel || "").toLowerCase().includes(q),
    );
  }, [devices, search]);

  const totalPages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE));
  const paged = filtered.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE);
  const pageIds = useMemo(() => paged.map((row) => row.id), [paged]);
  const selection = useTableSelection({ items: devices, pageIds });
  const brokenCount = useMemo(() => devices.filter(isDeviceBroken).length, [devices]);

  useEffect(() => {
    if (page > totalPages) setPage(totalPages);
  }, [page, totalPages]);

  const openReportFault = (deviceId) => {
    setPrefilledDeviceId(deviceId);
    setFaultModalOpen(true);
  };

  const closeFaultModal = () => {
    setFaultModalOpen(false);
    setPrefilledDeviceId(null);
  };

  const handleToggle = (row, nextActive) => {
    const targetIds = resolveBulkActionIds(row.id, selection.selectedIds);
    const targets = filterItemsByIds(devices, targetIds);

    if (nextActive) {
      let success = 0;
      for (const target of targets) {
        if (tryEnableDevice(target.id)) success += 1;
      }
      if (success > 0) {
        selection.clearSelection();
        refresh();
      }
      return;
    }

    if (targetIds.length > 1) {
      const unlocked = targets.filter((target) => !isDeviceToggleLocked(target));
      if (!unlocked.length) return;
      openReportFault(unlocked[0].id);
      return;
    }

    openReportFault(row.id);
  };

  const handleBulkEnable = () => {
    const targets = filterItemsByIds(devices, selection.selectedIds).filter(
      (row) => row.isActive === false && !isDeviceToggleLocked(row),
    );
    if (!targets.length) return;
    let success = 0;
    for (const row of targets) {
      if (tryEnableDevice(row.id)) success += 1;
    }
    if (success > 0) {
      selection.clearSelection();
      refresh();
      zonesToastSuccess(`تم تفعيل ${success} من ${targets.length} أجهزة`);
    }
  };

  const handleBulkReportFault = () => {
    const targets = filterItemsByIds(devices, selection.selectedIds).filter(
      (row) => !isDeviceToggleLocked(row) && row.isActive !== false,
    );
    if (!targets.length) return;
    openReportFault(targets[0].id);
  };

  const handleAddFault = (payload) => {
    reportDeviceFault(payload);
    closeFaultModal();
    refresh();
    zonesToastSuccess(
      "تم تسجيل العطل — الجهاز في «الأعطال الحالية» والمفتاح مقفول.",
      `«${payload.deviceName}»`,
    );
  };

  return (
    <div className="space-y-4" dir="rtl">
      <PageHeader
        title="جميع الأجهزة"
        description="مرتبط بجدول المدير — أجهزة جديدة تظهر فوراً. لإبلاغ عطل: أطفئ المفتاح (معطّل) → يُسجَّل في «الأعطال الحالية». بعد «تم الإصلاح» يعود سليم والمفتاح يشتغل."
      />

      <section className="overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-sm dark:border-gray-800 dark:bg-gray-900">
        <div className="flex flex-wrap items-center justify-between gap-3 border-b border-gray-100 px-5 py-4 dark:border-gray-800">
          <h2 className="text-sm font-extrabold text-gray-900 dark:text-white">جميع الأجهزة</h2>
          <div className="flex flex-wrap items-center gap-2">
            <span className="rounded-full bg-[#6B5478]/12 px-2.5 py-0.5 text-[11px] font-bold text-[#6B5478]">
              {filtered.length} جهاز
            </span>
            {brokenCount > 0 ? (
              <span className="rounded-full bg-red-500/12 px-2.5 py-0.5 text-[11px] font-bold text-red-600 dark:text-red-400">
                {brokenCount} معطّل
              </span>
            ) : null}
          </div>
        </div>

        <div className="flex flex-wrap items-center gap-3 border-b border-gray-100 px-5 py-3 dark:border-gray-800">
          <SearchBar
            containerClassName="min-w-[220px] flex-1 max-w-md"
            value={search}
            onChange={setSearch}
            placeholder="بحث عن جهاز..."
          />
        </div>

        <TableBulkActionBar
          count={selection.count}
          onClear={selection.clearSelection}
          actions={[
            { label: "تفعيل المحدد", icon: Power, onClick: handleBulkEnable },
            { label: "تعطيل المحدد", icon: PowerOff, onClick: handleBulkReportFault },
          ]}
        />

        <div className="overflow-x-auto">
          <table className="w-full min-w-[680px] text-right text-xs">
            <thead>
              <tr className="border-b border-gray-100 text-gray-500 dark:border-gray-800 dark:text-gray-400">
                <TableSelectHeaderCell {...selection} />
                <th className="px-3 py-2.5 font-bold">الجهاز</th>
                <th className="px-3 py-2.5 font-bold">تاريخ الإضافة</th>
                <th className="px-3 py-2.5 font-bold">حالة العطل</th>
                <th className="px-3 py-2.5 font-bold">التفعيل</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
              {paged.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-3 py-10 text-center text-gray-400">
                    لا توجد أجهزة — أضف من لوحة المدير (/devices).
                  </td>
                </tr>
              ) : (
                paged.map((row) => {
                  const broken = isDeviceBroken(row);
                  const locked = isDeviceToggleLocked(row);
                  return (
                    <tr
                      key={row.id}
                      className={`${selectableRowClass(selection.isSelected(row.id))} ${
                        broken ? "bg-red-50/25 dark:bg-red-950/10" : ""
                      }`}
                    >
                      <TableSelectRowCell id={row.id} ariaLabel={`تحديد ${row.name}`} {...selection} />
                      <td className="px-3 py-3">
                        <DeviceNameCell device={row} />
                      </td>
                      <td className="px-3 py-3 text-gray-600 dark:text-gray-300" dir="ltr">
                        {formatDisplayDate(row.createdAt)}
                      </td>
                      <td className="px-3 py-3">
                        <FaultStateBadge device={row} />
                      </td>
                      <td className="px-3 py-3">
                        <div className="flex flex-wrap items-center gap-2">
                          <DeviceStatusLabel active={row.isActive} locked={locked} />
                          <ToggleSwitch
                            id={`device-active-${row.id}`}
                            checked={row.isActive !== false && !locked}
                            disabled={locked}
                            onChange={(v) => handleToggle(row, v)}
                          />
                        </div>
                        {!locked ? (
                          <p className="mt-1 text-[10px] text-gray-400">أطفئ المفتاح لتسجيل عطل</p>
                        ) : (
                          <p className="mt-1 text-[10px] text-amber-600 dark:text-amber-400">
                            أكمل الإصلاح من «الأعطال الحالية»
                          </p>
                        )}
                      </td>
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

      <MaintenanceFaultRecordModal
        open={faultModalOpen}
        onClose={closeFaultModal}
        onSave={handleAddFault}
        prefilledDeviceId={prefilledDeviceId}
      />
    </div>
  );
}
