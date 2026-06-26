import { apiClient, mapApiErrorMessage } from "../../../shared/api/apiClient";

export const MANAGER_BROADCASTS_ARCHIVED_EVENT = "zones-manager-broadcasts-archived";

function mapBroadcast(row) {
  const isArchived = row.isArchived ?? row.is_archived ?? row.status === "stopped";
  return {
    id: row.id,
    name: row.name,
    situationDescription: row.situationDescription ?? row.body ?? "",
    targetAudience: row.targetAudience ?? row.target_audience ?? "customers_only",
    targetCategories: row.targetCategories,
    severity: row.severity ?? "medium",
    status: row.status ?? (isArchived ? "stopped" : "active"),
    isArchived,
    alternativeInstructions: row.alternativeInstructions ?? row.alternative_instructions ?? "",
    startDate: row.startDate ?? row.createdAt ?? "",
    endDate: row.endDate ?? "",
    source: "api",
  };
}

export function emitBroadcastsArchived(archivedBroadcasts = []) {
  if (typeof window === "undefined") return;
  window.dispatchEvent(
    new CustomEvent(MANAGER_BROADCASTS_ARCHIVED_EVENT, {
      detail: { broadcasts: archivedBroadcasts },
    }),
  );
}

export async function fetchManagerBroadcasts({ status = "active" } = {}) {
  try {
    const { data } = await apiClient.get("/manager/broadcasts", { params: { status } });
    return { ok: true, broadcasts: (data.broadcasts || []).map(mapBroadcast) };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error), broadcasts: [] };
  }
}

export async function fetchArchivedManagerBroadcasts() {
  return fetchManagerBroadcasts({ status: "stopped" });
}

export async function createManagerBroadcast(payload) {
  try {
    const { data } = await apiClient.post("/manager/broadcasts", {
      name: payload.name,
      situation_description: payload.situationDescription || payload.message || "",
      target_audience: payload.targetAudience || "customers_only",
      severity: payload.severity || "medium",
      alternative_instructions: payload.alternativeInstructions || null,
    });
    return {
      ok: true,
      broadcast: mapBroadcast(data.broadcast),
      delivery: data.delivery,
      message: data.message,
    };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}

export async function archiveManagerBroadcast(broadcastId) {
  try {
    const { data } = await apiClient.patch(`/manager/broadcasts/${broadcastId}/archive`);
    const broadcast = mapBroadcast(data.broadcast);
    return { ok: true, broadcast, message: data.message };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}

/** @deprecated استخدم archiveManagerBroadcast */
export async function stopManagerBroadcast(broadcastId) {
  return archiveManagerBroadcast(broadcastId);
}

export { mapBroadcast };
