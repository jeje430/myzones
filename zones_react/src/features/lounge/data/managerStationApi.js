import { apiClient, mapApiErrorMessage, postMultipart } from "../../../shared/api/apiClient";
import { createDefaultServicesAvailability } from "../../super-admin/data/hallServicesData";
import { resolveStationMediaUrl } from "../../../shared/utils/resolveStationMediaUrl";

function mapStationToHall(station) {
  if (!station) return null;

  const servicesAvailability = station.servicesAvailability
    ? { ...createDefaultServicesAvailability(), ...station.servicesAvailability }
    : createDefaultServicesAvailability();

  if (Array.isArray(station.available_services)) {
    station.available_services.forEach((key) => {
      if (key in servicesAvailability) servicesAvailability[key] = true;
    });
  }

  const services = Array.isArray(station.services)
    ? Object.values(station.services)
    : [];

  return {
    hallName: station.hallName || station.name || "",
    city: station.city || "",
    address: station.address || "",
    description: station.description || "",
    mapLink: station.mapLink || station.map_link || "",
    latitude: station.latitude != null ? String(station.latitude) : "",
    longitude: station.longitude != null ? String(station.longitude) : "",
    phone: station.phone || "",
    email: station.email || "",
    workHoursFrom: station.workHoursFrom || station.opens_at || "14:00",
    workHoursTo: station.workHoursTo || station.closes_at || "02:00",
    image: resolveStationMediaUrl(station.image || station.image_url || station.cover_image || ""),
    status: station.status || (station.is_published ? "active" : "pending"),
    isPublished: Boolean(station.is_published ?? station.published),
    setupCompleted: Boolean(station.setup_completed ?? station.is_published ?? station.published),
    stationId: station.id ?? station.station_id,
    servicesAvailability,
    servicesFromApi: services,
  };
}

const STATION_SCALAR_FIELDS = [
  "hallName",
  "name",
  "description",
  "city",
  "address",
  "mapLink",
  "map_link",
  "latitude",
  "longitude",
  "phone",
  "workHoursFrom",
  "workHoursTo",
  "opens_at",
  "closes_at",
];

function appendScalarFields(form, patch) {
  STATION_SCALAR_FIELDS.forEach((key) => {
    if (patch[key] === undefined || patch[key] === null) return;
    form.append(key, String(patch[key]));
  });
}

function appendServicesAvailability(form, servicesAvailability) {
  if (!servicesAvailability || typeof servicesAvailability !== "object") return;

  Object.entries(servicesAvailability).forEach(([key, enabled]) => {
    form.append(`servicesAvailability[${key}]`, enabled ? "1" : "0");
  });
}

/** Builds multipart/form-data for station updates (image upload + fields). */
function buildStationFormData(patch) {
  const form = new FormData();

  appendScalarFields(form, patch);
  appendServicesAvailability(form, patch.servicesAvailability);

  if (patch.imageFile instanceof File) {
    form.append("cover_image", patch.imageFile, patch.imageFile.name);
  }

  if (patch.removeCoverImage) {
    form.append("remove_cover_image", "1");
  }

  if (patch.completeSetup) {
    form.append("complete_setup", "1");
  }

  return form;
}

/** Legacy JSON path — base64 data URI only (fallback). */
function sanitizeStationImagePayload(payload) {
  const next = { ...payload };
  const image = next.image;

  if (image && typeof image === "string") {
    const trimmed = image.trim();
    if (trimmed.startsWith("data:image")) {
      next.image = trimmed;
    } else {
      delete next.image;
    }
  }

  delete next.imageFile;
  return next;
}

export async function fetchManagerStation() {
  try {
    const { data } = await apiClient.get("/manager/station");
    const station = mapStationToHall(data.station);
    return { ok: true, station: data.station, hall: station };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}

export async function resetManagerStation() {
  try {
    const { data } = await apiClient.post("/manager/station/reset");
    const hall = mapStationToHall(data.station);
    return { ok: true, station: data.station, hall, message: data.message };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}

export async function updateManagerStation(patch) {
  try {
    if (patch.resetStation) {
      return resetManagerStation();
    }

    const wantsMultipart = patch.imageFile instanceof File || patch.removeCoverImage;

    if (wantsMultipart) {
      const formData = buildStationFormData(patch);
      const { data } = await postMultipart("/manager/station", formData);
      const hall = mapStationToHall(data.station);
      return {
        ok: true,
        station: data.station,
        hall,
        message: data.message,
        published: data.published,
        setupCompleted: data.setup_completed,
      };
    }

    const payload = sanitizeStationImagePayload({ ...patch });

    if (patch.servicesAvailability) {
      payload.servicesAvailability = patch.servicesAvailability;
    }

    if (patch.removeCoverImage) {
      payload.remove_cover_image = true;
      delete payload.removeCoverImage;
      delete payload.image;
    }

    if (patch.completeSetup) {
      payload.complete_setup = true;
      delete payload.completeSetup;
    }

    const { data } = await apiClient.put("/manager/station", payload);
    const hall = mapStationToHall(data.station);
    return {
      ok: true,
      station: data.station,
      hall,
      message: data.message,
      published: data.published,
      setupCompleted: data.setup_completed,
    };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}
