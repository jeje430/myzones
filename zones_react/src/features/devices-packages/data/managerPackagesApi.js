import { apiClient, mapApiErrorMessage } from "../../../shared/api/apiClient";
import { formatPackageTypeLabel, parsePackagePrice } from "./packageTypes";

function mapApiPackage(row) {
  const type = row.package_type || row.type || "";
  return {
    id: row.id,
    name: row.name || "",
    price: String(row.hourly_price ?? row.price ?? ""),
    deviceLabel: formatPackageTypeLabel(type),
    packageType: type,
    description: row.description || "",
    minimumHours: Number(row.minimum_hours ?? row.minimumHours ?? 1) || 1,
    maximumHours: row.maximum_hours ?? row.maximumHours ?? null,
    isActive: Boolean(row.is_active ?? !row.is_archived),
    isArchived: Boolean(row.is_archived ?? !row.is_active),
    createdAt: row.created_at || "—",
  };
}

export { mapApiPackage };

export async function fetchManagerPackages(params = {}) {
  try {
    const { data } = await apiClient.get("/manager/packages", { params });
    const list = data.packages || [];
    return { ok: true, packages: list.map(mapApiPackage) };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error), packages: [] };
  }
}

export async function createManagerPackage(payload) {
  try {
    const { data } = await apiClient.post("/manager/packages", {
      name: payload.name,
      package_type: payload.packageType || payload.type || "ps5",
      hourly_price: parsePackagePrice(payload.price),
      description: payload.description || "",
      is_active: payload.isActive !== false && !payload.isArchived,
    });
    return { ok: true, package: mapApiPackage(data.package), message: data.message };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}

export async function updateManagerPackage(id, payload) {
  try {
    const body = {
      name: payload.name,
      hourly_price: payload.price != null ? parsePackagePrice(payload.price) : undefined,
      description: payload.description,
      is_active: payload.isArchived ? false : payload.isActive !== false,
    };

    if (payload.packageType || payload.type) {
      body.package_type = payload.packageType || payload.type;
    }

    const { data } = await apiClient.put(`/manager/packages/${id}`, body);
    return { ok: true, package: mapApiPackage(data.package), message: data.message };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}

export async function deleteManagerPackage(id) {
  try {
    const { data } = await apiClient.delete(`/manager/packages/${id}`);
    return { ok: true, message: data.message };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}
