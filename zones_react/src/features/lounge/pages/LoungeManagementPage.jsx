import { useEffect, useRef, useState } from "react";
import { Link } from "react-router-dom";
import {
  Building2,
  CalendarDays,
  Clock,
  ExternalLink,
  Gamepad2,
  MapPin,
  Package,
  Pencil,
  Phone,
  Upload,
  Users,
} from "lucide-react";
import { zonesConfirm, zonesToastError, zonesToastSuccess } from "../../../shared/utils/zonesAlerts";
import ManagerLayout from "../../../shared/layouts/ManagerLayout";
import PageHeader from "../../super-admin/components/ui/PageHeader";
import KpiCard from "../../super-admin/components/ui/KpiCard";
import {
  formatHallWorkHours,
  getHallStatusMeta,
  loadManagerHall,
  persistManagerHall,
  refreshManagerHallFromApi,
  clearManagerHall,
} from "../data/managerHallStorage";
import { useHallStats } from "../hooks/useHallStats";
import HallServicesManagerPicker from "../components/HallServicesManagerPicker";
import { useManagerPaths } from "../../../shared/tenant/ManagerWorkspaceProvider";

const STATUS_BADGE = {
  emerald: "bg-emerald-500/15 text-emerald-600 dark:text-emerald-400",
  red: "bg-red-500/15 text-red-600 dark:text-red-400",
  amber: "bg-amber-500/15 text-amber-600 dark:text-amber-400",
};

function InfoRow({ icon: Icon, label, value, ltr, isLink }) {
  return (
    <div className="flex items-start justify-between gap-3 border-b border-gray-100 py-3 text-xs last:border-0 dark:border-gray-800">
      <span className="flex shrink-0 items-center gap-1.5 font-semibold text-gray-500 dark:text-gray-400">
        <Icon size={14} className="text-[#6B5478]" />
        {label}
      </span>
      {isLink && value ? (
        <a
          href={value}
          target="_blank"
          rel="noreferrer"
          className="flex items-center gap-1 font-bold text-[#6B5478]"
          dir="ltr"
        >
          فتح الرابط <ExternalLink size={12} />
        </a>
      ) : (
        <span className="text-left font-bold text-gray-800 dark:text-gray-100" dir={ltr ? "ltr" : undefined}>
          {value || "—"}
        </span>
      )}
    </div>
  );
}

export default function LoungeManagementPage() {
  const { routes } = useManagerPaths();
  const [hall, setHall] = useState(loadManagerHall);
  const [uploading, setUploading] = useState(false);
  const fileRef = useRef(null);
  const { deviceCount, packageCount, employeeCount } = useHallStats();

  useEffect(() => {
    const refresh = () => setHall(loadManagerHall());
    refreshManagerHallFromApi().finally(refresh);
    window.addEventListener("manager-hall-updated", refresh);
    return () => window.removeEventListener("manager-hall-updated", refresh);
  }, []);

  const statusMeta = getHallStatusMeta(hall.status);
  const isPublished = Boolean(hall.isPublished);

  const onClearAll = async () => {
    const confirmed = await zonesConfirm({
      title: "مسح جميع بيانات الصالة؟",
      text: "ستُفرغ الحقول والصورة وتختفي من تطبيق الزبون حتى تضيف البيانات من جديد.",
      confirmText: "مسح البيانات",
      cancelText: "إلغاء",
      danger: true,
    });
    if (!confirmed) return;

    const result = await clearManagerHall();
    if (!result.ok) {
      zonesToastError(result.error || "تعذر مسح البيانات");
      return;
    }

    setHall(result.hall);
    zonesToastSuccess(result.message || "تم مسح البيانات");
  };

  const onCoverChange = async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;

    if (file.size > 5 * 1024 * 1024) {
      zonesToastError("حجم الصورة يجب أن يكون أقل من 5 ميجابايت");
      return;
    }

    if (!file.type.startsWith("image/")) {
      zonesToastError("يرجى اختيار ملف صورة صالح");
      return;
    }

    const previewUrl = URL.createObjectURL(file);
    setHall((prev) => ({ ...prev, image: previewUrl }));
    setUploading(true);
    const result = await persistManagerHall({ imageFile: file });
    URL.revokeObjectURL(previewUrl);
    setUploading(false);

    if (!result.ok) {
      zonesToastError(result.error || "تعذر رفع صورة الغلاف");
      setHall(loadManagerHall());
      return;
    }

    setHall(loadManagerHall());
    zonesToastSuccess("تم رفع صورة الغلاف — ستظهر في التطبيق بعد نشر الصالة");
    e.target.value = "";
  };

  const onDeleteCover = async () => {
    const confirmed = await zonesConfirm({
      title: "حذف صورة الغلاف؟",
      text: "ستُحذف من قاعدة البيانات والتخزين وستختفي من التطبيق.",
      confirmText: "حذف",
      cancelText: "إلغاء",
      danger: true,
    });
    if (!confirmed) return;

    setUploading(true);
    const result = await persistManagerHall({ removeCoverImage: true, image: "" });
    setUploading(false);

    if (!result.ok) {
      zonesToastError(result.error || "تعذر حذف الصورة");
      return;
    }

    setHall(loadManagerHall());
    zonesToastSuccess("تم حذف صورة الغلاف");
  };

  return (
    <ManagerLayout>
      <PageHeader
        title="بيانات الصالة"
        description="أكمل بيانات الصالة ثم اضغط «حفظ التغييرات» في صفحة التعديل — عندها فقط تظهر في تطبيق الزبون."
      />

      {!isPublished ? (
        <div className="mb-4 rounded-2xl border border-amber-200 bg-amber-50 px-4 py-3 text-xs text-amber-900 dark:border-amber-900/50 dark:bg-amber-950/30 dark:text-amber-200">
          الصالة <strong>غير ظاهرة</strong> في تطبيق الزبون بعد. أكمل الاسم، العنوان، ساعات العمل، الخدمات، ثم اضغط
          <strong> حفظ التغييرات</strong> في صفحة التعديل.
          قبول السوبر أدمن يفتح حسابك فقط — الكارت يظهر بعد إكمال الإعداد وحفظ التغييرات.
        </div>
      ) : (
        <div className="mb-4 rounded-2xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-xs text-emerald-800 dark:border-emerald-900/50 dark:bg-emerald-950/30 dark:text-emerald-200">
          صالتك <strong>ظاهرة الآن</strong> في تطبيق الزبون (كارت + صفحة تفاصيل).
        </div>
      )}

      <div className="mb-6 grid gap-4 sm:grid-cols-3">
        <KpiCard
          label="عدد الأجهزة"
          value={deviceCount}
          hint="يُحدَّث تلقائياً عند الإضافة أو الحذف"
          icon={Gamepad2}
          tone="primary"
        />
        <KpiCard
          label="عدد الباقات"
          value={packageCount}
          hint="يُحدَّث تلقائياً عند الإضافة أو الحذف"
          icon={Package}
          tone="green"
        />
        <KpiCard
          label="عدد الموظفين"
          value={employeeCount}
          hint="يُحدَّث تلقائياً عند الإضافة أو الحذف"
          icon={Users}
          tone="amber"
        />
      </div>

      <div className="grid gap-4 lg:grid-cols-3">
        <section className="lg:col-span-2 rounded-2xl border border-gray-200 bg-white p-5 shadow-sm dark:border-gray-800 dark:bg-gray-900">
          <div className="mb-4 flex items-center justify-between">
            <h2 className="flex items-center gap-2 text-sm font-extrabold text-gray-900 dark:text-white">
              <Building2 size={16} className="text-[#6B5478]" />
              معلومات الصالة
            </h2>
            <Link
              to={routes.loungeEdit}
              className="flex items-center gap-1.5 rounded-xl border border-gray-300 px-3 py-1.5 text-[11px] font-bold text-gray-700 transition hover:bg-gray-50 dark:border-gray-700 dark:text-gray-200 dark:hover:bg-gray-800"
            >
              <Pencil size={13} /> {hall.hallName ? "تعديل" : "إضافة بيانات"}
            </Link>
          </div>

          <div className="rounded-xl border border-gray-100 px-4 py-1 dark:border-gray-800">
            <InfoRow icon={Building2} label="اسم الصالة" value={hall.hallName} />
            <InfoRow icon={MapPin} label="المدينة" value={hall.city} />
            <InfoRow icon={MapPin} label="العنوان" value={hall.address} />
            <InfoRow icon={ExternalLink} label="رابط Google Maps" value={hall.mapLink} isLink />
            <InfoRow
              icon={MapPin}
              label="الإحداثيات (GPS)"
              value={
                hall.latitude && hall.longitude ? `${hall.latitude}, ${hall.longitude}` : "—"
              }
              ltr
            />
            <InfoRow icon={Users} label="عدد الموظفين" value={`${employeeCount} موظف`} />
            <InfoRow
              icon={CalendarDays}
              label="تاريخ الانضمام"
              value={hall.joinDate?.replaceAll("-", "/")}
              ltr
            />
            <div className="flex items-center justify-between gap-3 py-3 text-xs">
              <span className="font-semibold text-gray-500 dark:text-gray-400">حالة الصالة</span>
              <span
                className={`rounded-full px-2.5 py-0.5 text-[11px] font-bold ${STATUS_BADGE[statusMeta.color]}`}
              >
                {statusMeta.label}
              </span>
            </div>
          </div>

          <p className="mt-3 text-[10px] text-gray-400">
            حالة الصالة وتاريخ الانضمام يحدّدهما النظام والإدارة — لا يمكن تعديلهما من هنا.
          </p>
        </section>

        <div className="space-y-4">
          <section className="rounded-2xl border border-gray-200 bg-white p-5 shadow-sm dark:border-gray-800 dark:bg-gray-900">
            <h2 className="mb-4 flex items-center gap-2 text-sm font-extrabold text-gray-900 dark:text-white">
              <Phone size={16} className="text-[#6B5478]" />
              التواصل والتشغيل
            </h2>
            <div className="rounded-xl border border-gray-100 px-4 py-1 dark:border-gray-800">
              <InfoRow icon={Phone} label="الهاتف" value={hall.phone} ltr />
              <InfoRow
                icon={Clock}
                label="ساعات العمل"
                value={formatHallWorkHours(hall.workHoursFrom, hall.workHoursTo)}
                ltr
              />
            </div>
          </section>

          <section className="rounded-2xl border border-gray-200 bg-white p-5 shadow-sm dark:border-gray-800 dark:bg-gray-900">
            <div className="mb-3 flex flex-wrap items-center justify-between gap-2">
              <h2 className="text-sm font-extrabold text-gray-900 dark:text-white">صورة الغلاف</h2>
              <div className="flex flex-wrap gap-2">
                <button
                  type="button"
                  disabled={uploading}
                  onClick={() => fileRef.current?.click()}
                  className="flex items-center gap-1.5 rounded-xl border border-[#6B5478]/40 bg-[#6B5478]/10 px-3 py-1.5 text-[11px] font-bold text-[#6B5478] transition hover:bg-[#6B5478]/15 disabled:opacity-60"
                >
                  <Upload size={13} />
                  {uploading ? "جاري الرفع..." : "رفع صورة"}
                </button>
                {hall.image ? (
                  <button
                    type="button"
                    disabled={uploading}
                    onClick={onDeleteCover}
                    className="rounded-xl border border-red-300 px-3 py-1.5 text-[11px] font-bold text-red-600 transition hover:bg-red-50 disabled:opacity-60 dark:border-red-800 dark:text-red-400"
                  >
                    حذف الصورة
                  </button>
                ) : null}
              </div>
              <input
                ref={fileRef}
                type="file"
                accept="image/jpeg,image/png,image/webp"
                className="hidden"
                onChange={onCoverChange}
              />
            </div>
            {hall.image ? (
              <img
                src={hall.image}
                alt={hall.hallName}
                className="h-44 w-full rounded-2xl object-cover ring-1 ring-gray-200 dark:ring-gray-700"
              />
            ) : (
              <div
                className="flex h-44 w-full items-center justify-center rounded-2xl border border-dashed border-gray-300 bg-gray-50 text-xs text-gray-400 dark:border-gray-700 dark:bg-gray-800/50"
              >
                لا توجد صورة — ارفع صورة الغلاف للتطبيق
              </div>
            )}
            <p className="mt-3 text-center text-xs font-bold text-gray-700 dark:text-gray-200">
              {hall.hallName || "اسم الصالة"}
            </p>
            <p className="mt-1 text-center text-[11px] text-gray-500">{hall.city}</p>
            <p className="mt-2 text-center text-[10px] text-gray-400">
              تُحفظ في Laravel وتظهر كغلاف في صفحة تفاصيل الصالة (Flutter).
            </p>
          </section>
        </div>
      </div>

      <div className="mt-4 flex flex-wrap justify-end gap-2">
        <button
          type="button"
          onClick={onClearAll}
          className="rounded-xl border border-red-300 px-4 py-2 text-[11px] font-bold text-red-600 dark:border-red-800 dark:text-red-400"
        >
          مسح جميع البيانات
        </button>
      </div>

      <div className="mt-4">
        <HallServicesManagerPicker />
      </div>
    </ManagerLayout>
  );
}
