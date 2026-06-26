import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { Building2, Search } from "lucide-react";
import SearchBar from "../../super-admin/components/ui/SearchBar";
import { fetchLoungesCatalog } from "../data/loungeCatalogApi";
import HallCard from "../components/HallCard";
import { HALL_SERVICE_OPTIONS } from "../../super-admin/data/hallServicesData";

export default function CustomerHallsListingPage() {
  const [lounges, setLounges] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [search, setSearch] = useState("");
  const [city, setCity] = useState("");
  const [service, setService] = useState("");
  const [openOnly, setOpenOnly] = useState(false);

  const loadLounges = async () => {
    setLoading(true);
    setError("");
    const params = {};
    if (search.trim()) params.q = search.trim();
    if (city.trim()) params.city = city.trim();
    if (service) params.service = service;
    if (openOnly) params.is_open = 1;

    const result = await fetchLoungesCatalog(params);
    setLoading(false);

    if (!result.ok) {
      setError(result.error || "تعذر تحميل الصالات");
      setLounges([]);
      return;
    }

    setLounges(result.lounges);
  };

  useEffect(() => {
    loadLounges();
  }, []);

  const cities = useMemo(() => {
    const set = new Set(lounges.map((l) => l.city).filter(Boolean));
    return Array.from(set).sort();
  }, [lounges]);

  return (
    <div
      className="min-h-screen bg-gradient-to-b from-[#f8f6fa] to-white px-4 py-8 dark:from-[#0c0a12] dark:to-[#110c1a]"
      dir="rtl"
    >
      <div className="mx-auto max-w-5xl">
        <div className="mb-6 flex flex-wrap items-center justify-between gap-3">
          <div>
            <p className="flex items-center gap-2 text-sm font-extrabold text-gray-900 dark:text-white">
              <Building2 size={18} className="text-[#6B5478]" />
              اكتشف الصالات
            </p>
            <p className="mt-1 text-xs text-gray-500">كل الصالات من قاعدة البيانات — بدون بيانات وهمية</p>
          </div>
          <Link to="/manager/login" className="text-xs font-bold text-[#6B5478]">تسجيل الدخول</Link>
        </div>

        <div className="mb-4 space-y-3 rounded-2xl border border-gray-200 bg-white p-4 shadow-sm dark:border-gray-800 dark:bg-gray-900">
          <SearchBar value={search} onChange={setSearch} placeholder="ابحث عن صالة، مدينة، عنوان..." />
          <div className="flex flex-wrap gap-2">
            <select
              value={city}
              onChange={(e) => setCity(e.target.value)}
              className="rounded-xl border border-gray-200 bg-white px-3 py-2 text-xs dark:border-gray-700 dark:bg-gray-800"
            >
              <option value="">كل المدن</option>
              {cities.map((c) => (
                <option key={c} value={c}>{c}</option>
              ))}
            </select>
            <select
              value={service}
              onChange={(e) => setService(e.target.value)}
              className="rounded-xl border border-gray-200 bg-white px-3 py-2 text-xs dark:border-gray-700 dark:bg-gray-800"
            >
              <option value="">كل الخدمات</option>
              {HALL_SERVICE_OPTIONS.map((s) => (
                <option key={s.key} value={s.key}>{s.label}</option>
              ))}
            </select>
            <label className="flex items-center gap-2 rounded-xl border border-gray-200 px-3 py-2 text-xs dark:border-gray-700">
              <input type="checkbox" checked={openOnly} onChange={(e) => setOpenOnly(e.target.checked)} />
              مفتوحة الآن
            </label>
            <button
              type="button"
              onClick={loadLounges}
              className="flex items-center gap-1 rounded-xl bg-[#6B5478] px-4 py-2 text-xs font-bold text-white"
            >
              <Search size={14} />
              بحث
            </button>
          </div>
        </div>

        {error ? (
          <p className="rounded-xl border border-red-200 bg-red-50 p-4 text-xs text-red-600">{error}</p>
        ) : null}

        {loading ? (
          <p className="text-center text-xs text-gray-500">جاري تحميل الصالات...</p>
        ) : lounges.length === 0 ? (
          <p className="text-center text-xs text-gray-500">لا توجد صالات مطابقة</p>
        ) : (
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {lounges.map((lounge) => (
              <HallCard key={lounge.id} lounge={lounge} />
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
