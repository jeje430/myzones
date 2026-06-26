import { useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { ArrowRight, Building2, Clock, MapPin, Phone, Star } from "lucide-react";
import { fetchLoungeById } from "../data/loungeCatalogApi";
import HallServicesCustomerCircles from "../../lounge/components/HallServicesCustomerCircles";

function DetailRow({ icon: Icon, label, value, ltr }) {
  if (!value) return null;
  return (
    <div className="flex items-start justify-between gap-3 border-b border-gray-100 py-2.5 text-xs last:border-0 dark:border-gray-800">
      <span className="flex shrink-0 items-center gap-1.5 font-semibold text-gray-500 dark:text-gray-400">
        <Icon size={13} className="text-[#6B5478]" />
        {label}
      </span>
      <span className="text-left font-bold text-gray-800 dark:text-gray-100" dir={ltr ? "ltr" : undefined}>
        {value}
      </span>
    </div>
  );
}

export default function CustomerHallDetailsPage() {
  const { stationId } = useParams();
  const [lounge, setLounge] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    let active = true;
    setLoading(true);
    fetchLoungeById(stationId).then((result) => {
      if (!active) return;
      setLoading(false);
      if (!result.ok) {
        setError(result.error || "تعذر تحميل الصالة");
        return;
      }
      setLounge(result.lounge);
    });
    return () => {
      active = false;
    };
  }, [stationId]);

  return (
    <div
      className="min-h-screen bg-gradient-to-b from-[#f8f6fa] to-white px-4 py-8 dark:from-[#0c0a12] dark:to-[#110c1a]"
      dir="rtl"
    >
      <div className="mx-auto max-w-lg">
        <Link
          to="/app/halls"
          className="mb-6 inline-flex items-center gap-1 text-xs font-bold text-[#6B5478]"
        >
          <ArrowRight size={14} />
          كل الصالات
        </Link>

        {loading ? (
          <p className="text-center text-xs text-gray-500">جاري التحميل...</p>
        ) : error ? (
          <p className="rounded-xl border border-red-200 bg-red-50 p-4 text-xs text-red-600">{error}</p>
        ) : !lounge ? null : (
          <div className="overflow-hidden rounded-3xl border border-gray-200 bg-white shadow-xl dark:border-gray-800 dark:bg-gray-900">
            {lounge.image ? (
              <img src={lounge.image} alt={lounge.name} className="h-48 w-full object-cover" />
            ) : (
              <div className="flex h-48 items-center justify-center bg-gray-100 text-xs text-gray-400 dark:bg-gray-800">
                لا توجد صورة غلاف
              </div>
            )}
            <div className="p-5">
              <p className="mb-1 flex items-center gap-1.5 text-[11px] font-bold text-[#6B5478]">
                <Building2 size={14} />
                تفاصيل الصالة
              </p>
              <h1 className="text-lg font-extrabold text-gray-900 dark:text-white">{lounge.name}</h1>
              <div className="mt-2 flex items-center gap-3 text-xs">
                <span className="flex items-center gap-1 font-bold text-amber-600">
                  <Star size={14} fill="currentColor" />
                  {lounge.averageRating.toFixed(1)} ({lounge.reviewsCount})
                </span>
                <span className={lounge.isOpen ? "text-emerald-600" : "text-gray-500"}>
                  {lounge.isOpen ? "مفتوحة الآن" : "مغلقة"}
                </span>
              </div>

              {lounge.description ? (
                <p className="mt-3 text-xs text-gray-600 dark:text-gray-300">{lounge.description}</p>
              ) : null}

              <div className="mt-4 rounded-2xl border border-gray-100 bg-gray-50/80 px-4 py-2 dark:border-gray-800 dark:bg-gray-950/40">
                <DetailRow icon={MapPin} label="المدينة" value={lounge.city} />
                <DetailRow icon={MapPin} label="العنوان" value={lounge.address} />
                <DetailRow icon={Phone} label="الهاتف" value={lounge.phone} ltr />
                <DetailRow
                  icon={Clock}
                  label="ساعات العمل"
                  value={
                    lounge.opensAt && lounge.closesAt ? `${lounge.opensAt} – ${lounge.closesAt}` : null
                  }
                  ltr
                />
              </div>

              {lounge.services?.length ? (
                <div className="mt-6 rounded-2xl border border-gray-100 bg-gray-50/80 p-5 dark:border-gray-800 dark:bg-gray-950/40">
                  <HallServicesCustomerCircles services={lounge.services} />
                </div>
              ) : null}

              {lounge.devices?.length ? (
                <div className="mt-4 space-y-2">
                  <h2 className="text-xs font-extrabold text-gray-800 dark:text-gray-200">الأجهزة والأسعار</h2>
                  {lounge.devices.map((d) => (
                    <div
                      key={`${d.type}-${d.name_ar}`}
                      className="flex justify-between rounded-xl border border-gray-100 px-3 py-2 text-xs dark:border-gray-800"
                    >
                      <span className="font-bold">{d.name_ar}</span>
                      <span className="text-[#6B5478]">{d.hourly_rate} د.ل/ساعة</span>
                    </div>
                  ))}
                </div>
              ) : null}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
