import { useEffect, useState } from "react";
import { Save } from "lucide-react";
import { HALL_SERVICE_OPTIONS, countAvailableHallServices } from "../../super-admin/data/hallServicesData";
import { loadManagerHall, persistManagerHall } from "../data/managerHallStorage";
import { zonesToastError, zonesToastSuccess } from "../../../shared/utils/zonesAlerts";

function ServiceChip({ label, active, onClick, title }) {
  return (
    <button
      type="button"
      onClick={onClick}
      title={title || label}
      aria-pressed={active}
      className={`rounded-full px-4 py-2 text-[11px] font-bold transition focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#6B5478]/50 focus-visible:ring-offset-2 dark:focus-visible:ring-offset-gray-900 ${
        active
          ? "bg-[#6B5478] text-white shadow-md shadow-[#6B5478]/30 ring-2 ring-[#6B5478]/40"
          : "border border-gray-200 bg-gray-100 text-gray-500 hover:border-[#6B5478]/40 hover:bg-[#6B5478]/5 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-400 dark:hover:border-[#6B5478]/50"
      }`}
    >
      {label}
    </button>
  );
}

function loadDraftFromHall() {
  const hall = loadManagerHall();
  return { ...hall.servicesAvailability };
}

export default function HallServicesManagerPicker({ compact = false }) {
  const [draft, setDraft] = useState(loadDraftFromHall);
  const [savedSnapshot, setSavedSnapshot] = useState(loadDraftFromHall);

  useEffect(() => {
    const refresh = () => {
      const next = loadDraftFromHall();
      setDraft(next);
      setSavedSnapshot(next);
    };
    window.addEventListener("manager-hall-updated", refresh);
    return () => window.removeEventListener("manager-hall-updated", refresh);
  }, []);

  const activeCount = countAvailableHallServices(draft);
  const isDirty = JSON.stringify(draft) !== JSON.stringify(savedSnapshot);

  function toggleService(key) {
    setDraft((prev) => ({ ...prev, [key]: !prev[key] }));
  }

  async function handleSave() {
    const result = await persistManagerHall({
      servicesAvailability: draft,
    });

    if (!result.ok) {
      zonesToastError(result.error || "تعذر حفظ الخدمات");
      return;
    }

    setSavedSnapshot({ ...draft });
    zonesToastSuccess(result.message || "تم حفظ خدمات الصالة — ستظهر للزبائن في التطبيق");
  }

  return (
    <section
      className={`rounded-2xl border border-gray-200 bg-white shadow-sm dark:border-gray-800 dark:bg-gray-900 ${
        compact ? "p-4" : "p-5"
      }`}
    >
      <div className={`flex flex-wrap items-start justify-between gap-3 ${compact ? "mb-3" : "mb-4"}`}>
        <div>
          <h2 className="text-sm font-extrabold text-gray-900 dark:text-white">الخدمات المتوفرة</h2>
          <p className="mt-1 text-[11px] text-gray-500 dark:text-gray-400">
            حدّد الخدمات المتوفرة في صالتك.
          </p>
        </div>
        <span className="rounded-full bg-[#6B5478] px-2.5 py-0.5 text-[11px] font-bold text-white shadow-sm shadow-[#6B5478]/20">
          {activeCount} نشطة
        </span>
      </div>

      <div className="flex flex-wrap gap-2">
        {HALL_SERVICE_OPTIONS.map((service) => (
          <ServiceChip
            key={service.key}
            label={service.shortLabel}
            title={service.label}
            active={Boolean(draft[service.key])}
            onClick={() => toggleService(service.key)}
          />
        ))}
      </div>

      <div className="mt-5 flex flex-wrap items-center justify-end gap-3 border-t border-gray-100 pt-4 dark:border-gray-800">
        <button
          type="button"
          onClick={handleSave}
          disabled={!isDirty}
          className="inline-flex items-center gap-2 rounded-xl bg-[#6B5478] px-4 py-2.5 text-xs font-bold text-white transition hover:bg-[#5a4665] disabled:cursor-not-allowed disabled:opacity-45"
        >
          <Save size={14} />
          حفظ التعديلات
        </button>
      </div>
    </section>
  );
}
