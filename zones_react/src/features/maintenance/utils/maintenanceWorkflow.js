import { zonesToastError, zonesToastWarning, zonesToastSuccess } from "../../../shared/utils/zonesAlerts";
import { isApiStaffSession, getActiveStaffSession } from "../../devices-packages/data/hallCatalogSync";
import { loadDevices, endDeviceMaintenance, setMaintenanceDeviceStatus, startDeviceMaintenance } from "../../devices-packages/data/devicesStorage";
import { reconcileDevicesWithFaults } from "../../devices-packages/utils/deviceFaultSync";
import { invalidateFinanceCache } from "../../finance/data/financeApiCache";
import {
  addFault,
  getLatestBlockingFaultForDevice,
  getLatestPendingFaultForDevice,
  resolveAndArchiveFaultForDevice,
} from "../data/maintenanceFaultsStorage";
import {
  createMaintenanceFault,
  resolveMaintenanceFault,
  startMaintenanceFault,
} from "../data/maintenanceFaultsApi";
import { applyApiDevicePatch, syncMaintenanceStateFromApi } from "../data/maintenanceFaultsSync";
import { formatFaultDateTime } from "../data/faultMeta";

function useApiMaintenance() {
  const session = getActiveStaffSession();
  return isApiStaffSession(session);
}

/** هل يُقفَل مفتاح التفعيل (عطل معلّق أو صيانة جارية) */
export function isDeviceToggleLocked(device) {
  if (!device) return true;
  return Boolean(getLatestBlockingFaultForDevice(device.id)) || Boolean(device.maintenanceInProgress);
}

/** تسجيل عطل + وضع الجهاز في الصيانة */
export async function reportDeviceFault(payload) {
  if (useApiMaintenance()) {
    const result = await createMaintenanceFault(payload);
    if (!result.ok) {
      zonesToastError(result.error || "تعذّر تسجيل العطل", "خطأ");
      return false;
    }
    applyApiDevicePatch(result.device);
    await syncMaintenanceStateFromApi();
    if (payload.applyMaintenanceNow === false) {
      zonesToastSuccess(result.message || "تم جدولة العطل — الجهاز يبقى متاحاً", "عطل مجدول");
    }
    return true;
  }

  addFault(payload);
  if (payload.applyMaintenanceNow !== false) {
    setMaintenanceDeviceStatus(payload.deviceId, false, { hasPendingFault: true });
  }
  reconcileDevicesWithFaults();
  return true;
}

function registerManagerFault(device, managerName, faultTypeCustom) {
  if (!device?.id) return false;
  if (getLatestPendingFaultForDevice(device.id)) {
    zonesToastWarning("الجهاز مسجّل في الصيانة بالفعل.");
    return false;
  }
  addFault({
    deviceId: device.id,
    deviceName: device.name,
    deviceType: device.type,
    deviceTypeLabel: device.typeLabel,
    faultType: "other",
    faultTypeCustom,
    status: "pending",
    createdAt: formatFaultDateTime(),
    maintenanceCost: 0,
    maintenanceEmployeeName: managerName,
    details: "",
    resolvedAt: "",
  });
  setMaintenanceDeviceStatus(device.id, false, { hasPendingFault: true });
  reconcileDevicesWithFaults();
  return true;
}

/** المدير يعطّل الجهاز من الإجراءات — يُنشئ عطلاً نشطاً لموظف الصيانة */
export function disableDeviceFromManager(device, managerName = "مدير الصالة") {
  return registerManagerFault(device, managerName, "تعطيل من المدير");
}

/** المدير يضع الجهاز في الصيانة — يظهر عند موظف الصيانة */
export function markDeviceMaintenanceFromManager(device, managerName = "مدير الصالة") {
  return registerManagerFault(device, managerName, "طلب صيانة من المدير");
}

/** أجهزة معطّلة بلا سجل عطل — مزامنة تلقائية بين المدير والصيانة */
export function reconcileDisabledDevicesWithoutFaults(managerName = "مدير الصالة") {
  const orphans = loadDevices().filter(
    (d) => !d.isArchived && d.isActive === false && !getLatestPendingFaultForDevice(d.id),
  );
  if (!orphans.length) return 0;

  for (const device of orphans) {
    registerManagerFault(device, managerName, "تعطيل من المدير");
  }
  return orphans.length;
}

/** بدء الإصلاح */
export async function startDeviceMaintenanceWorkflow(deviceId) {
  const fault = getLatestPendingFaultForDevice(deviceId);
  if (useApiMaintenance() && fault?.id) {
    const result = await startMaintenanceFault(fault.id);
    if (!result.ok) {
      zonesToastError(result.error || "تعذّر بدء الإصلاح", "خطأ");
      return false;
    }
    applyApiDevicePatch(result.device);
    await syncMaintenanceStateFromApi();
    return true;
  }

  startDeviceMaintenance(deviceId);
  reconcileDevicesWithFaults();
  return true;
}

/** إتمام الإصلاح — أرشفة العطل + إعادة الجهاز للمتاح */
export async function completeDeviceRepair(deviceId, maintenanceCost = 0) {
  const fault = getLatestPendingFaultForDevice(deviceId);
  if (useApiMaintenance() && fault?.id) {
    const result = await resolveMaintenanceFault(fault.id, maintenanceCost);
    if (!result.ok) {
      zonesToastError(result.error || "تعذّر إتمام الإصلاح", "خطأ");
      return false;
    }
    applyApiDevicePatch(result.device);
    await syncMaintenanceStateFromApi();
    invalidateFinanceCache();
    return true;
  }

  resolveAndArchiveFaultForDevice(deviceId, maintenanceCost);
  endDeviceMaintenance(deviceId);
  reconcileDevicesWithFaults();
  return true;
}

/** إعادة تفعيل — مسموح فقط بعد إتمام الإصلاح من جدول الأعطال */
export function tryEnableDevice(deviceId) {
  if (getLatestPendingFaultForDevice(deviceId)) {
    zonesToastError("أكمل الإصلاح من لوحة موظف الصيانة — يُفعَّل الجهاز تلقائياً بعد «تم الإصلاح».");
    return false;
  }
  setMaintenanceDeviceStatus(deviceId, true);
  reconcileDevicesWithFaults();
  return true;
}
