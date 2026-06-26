import { useCallback, useEffect, useMemo, useState } from "react";
import { Archive, Building2, Eye, MapPin, Phone, SlidersHorizontal, User, Users } from "lucide-react";
import { zonesSwal, zonesToastError, zonesToastSuccess } from "../../../shared/utils/zonesAlerts";
import SearchBar from "../components/ui/SearchBar";
import PageHeader from "../components/ui/PageHeader";
import { archiveHall, getSuperAdminState } from "../data/superAdminStorage";
import { formatHallServicesHtml } from "../data/hallServicesData";
import { fetchHallJoinRequests } from "../data/hallJoinRequestsApi";
import { HALL_REQUEST_STATUS } from "../data/hallRequestStatus";

/** يحوّل طلب انضمام مقبول إلى بطاقة صالة نشطة */
function mapAcceptedRequestToHall(req, fallbackCommission) {
  return {
    id: `req-${req.id}`,
    sortKey: Number(req.id) || 0,
    source: "api",
    name: req.hallName || "—",
    address: req.address || "—",
    city: req.city || "—",
    commercialPhone: req.commercialPhone || "—",
    managerName: req.managerName || "—",
    managerEmail: req.managerEmail || "—",
    employeeCount: req.employeeCount ?? 0,
    monthlyIncome: req.monthlyIncome ?? 0,
    commissionRate: req.commissionRate ?? fallbackCommission,
    status: "active",
    mapLink: req.mapLink || "",
    acceptedAt: req.acceptedAt || req.submittedAt || "",
  };
}

function InfoRow({ icon: Icon, label, value, ltr }) {
  return (
    <div className="flex items-center justify-between gap-2 text-xs">
      <span className="font-bold text-gray-800 dark:text-gray-100" dir={ltr ? "ltr" : undefined}>
        {value}
      </span>
      <span className="flex items-center gap-1.5 text-gray-400">
        {label}
        <Icon size={13} />
      </span>
    </div>
  );
}

export default function HallsManagementPage() {
  const [state, setState] = useState(getSuperAdminState());
  const [acceptedHalls, setAcceptedHalls] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [sort, setSort] = useState("newest");

  const loadAcceptedHalls = useCallback(async () => {
    const fallback = getSuperAdminState().systemSettings?.globalCommissionRate ?? 3;
    const result = await fetchHallJoinRequests();
    if (!result.ok) {
      zonesToastError(result.error || "تعذر تحميل الصالات");
      setAcceptedHalls([]);
      setLoading(false);
      return;
    }
    const halls = result.requests
      .filter((r) => r.status === HALL_REQUEST_STATUS.accepted)
      .map((r) => mapAcceptedRequestToHall(r, fallback));
    setAcceptedHalls(halls);
    setLoading(false);
  }, []);

  useEffect(() => {
    const refresh = () => setState(getSuperAdminState());
    refresh();
    loadAcceptedHalls();
    const onRequests = () => loadAcceptedHalls();
    window.addEventListener("super-admin-data-updated", refresh);
    window.addEventListener("hall-join-requests-updated", onRequests);
    return () => {
      window.removeEventListener("super-admin-data-updated", refresh);
      window.removeEventListener("hall-join-requests-updated", onRequests);
    };
  }, [loadAcceptedHalls]);

  /** الصالات المقبولة من الـ API + أي صالات محلية (دون تكرار حسب البريد) */
  const allHalls = useMemo(() => {
    const apiEmails = new Set(
      acceptedHalls.map((h) => String(h.managerEmail || "").toLowerCase()),
    );
    const localHalls = (state.activeHalls || [])
      .filter((h) => !apiEmails.has(String(h.managerEmail || "").toLowerCase()))
      .map((h) => ({ ...h, sortKey: Number(h.id) || 0, source: "local" }));
    return [...acceptedHalls, ...localHalls];
  }, [acceptedHalls, state.activeHalls]);

  const filteredHalls = useMemo(() => {
    const q = search.trim().toLowerCase();
    let list = allHalls;
    if (q) {
      list = list.filter(
        (h) =>
          String(h.name).toLowerCase().includes(q) ||
          String(h.address).toLowerCase().includes(q) ||
          String(h.managerName).toLowerCase().includes(q),
      );
    }
    const sorted = [...list];
    if (sort === "newest") sorted.sort((a, b) => b.sortKey - a.sortKey);
    else if (sort === "oldest") sorted.sort((a, b) => a.sortKey - b.sortKey);
    else if (sort === "name") sorted.sort((a, b) => String(a.name).localeCompare(String(b.name), "ar"));
    return sorted;
  }, [allHalls, search, sort]);

  const showHallDetails = (hall) => {
    zonesSwal({
      title: hall.name,
      html: `<div style="text-align:right;font-size:13px;line-height:1.9">
        <p><strong>العنوان:</strong> ${hall.address}</p>
        <p><strong>الهاتف التجاري:</strong> ${hall.commercialPhone ?? "—"}</p>
        <p><strong>المدير:</strong> ${hall.managerName}</p>
        <p><strong>الموظفون:</strong> ${hall.employeeCount ?? "—"}</p>
        <p><strong>الدخل الشهري:</strong> ${(hall.monthlyIncome ?? 0).toLocaleString("ar-LY")} د.ل</p>
        <p><strong>نسبة العمولة:</strong> ${hall.commissionRate ?? state.systemSettings.globalCommissionRate}%</p>
        <p><strong>الحالة:</strong> ${hall.status === "active" ? "نشطة" : "معطّلة"}</p>
        <div style="margin-top:12px">
          <p style="margin-bottom:8px"><strong>الخدمات المتوفرة:</strong></p>
          <div style="line-height:1.8">${formatHallServicesHtml(hall)}</div>
        </div>
      </div>`,
    });
  };

  const onArchive = async (hall) => {
    if (hall.source === "api") {
      zonesToastError("أرشفة الصالات المقبولة عبر الخادم غير متاحة من هنا.");
      return;
    }
    const res = await zonesSwal({
      title: "أرشفة الصالة؟",
      input: "text",
      inputLabel: "سبب الأرشفة",
      inputValue: "أرشفة إدارية",
      showCancelButton: true,
      confirmButtonText: "أرشفة",
      cancelButtonText: "إلغاء",
    });
    if (!res.isConfirmed) return;
    archiveHall(hall.id, res.value || "أرشفة إدارية");
    zonesToastSuccess("تمت الأرشفة");
  };

  return (
    <div>
      <PageHeader title="إدارة الصالات" />

      <div className="mt-2 flex flex-wrap items-center justify-between gap-3">
        <SearchBar value={search} onChange={setSearch} placeholder="بحث عن صالة بالاسم أو العنوان..." />
        <div className="flex items-center gap-2 rounded-xl border border-gray-200 bg-white px-3 py-2 dark:border-gray-700 dark:bg-gray-900">
          <SlidersHorizontal size={15} className="text-gray-400" />
          <select
            value={sort}
            onChange={(e) => setSort(e.target.value)}
            className="bg-transparent text-xs font-bold text-gray-700 outline-none dark:text-gray-200"
          >
            <option value="newest">الأحدث أولاً</option>
            <option value="oldest">الأقدم أولاً</option>
            <option value="name">حسب الاسم</option>
          </select>
        </div>
      </div>

      <div className="mt-4 grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
        {filteredHalls.length === 0 ? (
          <p className="col-span-full rounded-2xl border border-dashed border-gray-300 py-10 text-center text-xs text-gray-400 dark:border-gray-700">
            {loading ? "جاري تحميل الصالات..." : "لا توجد صالات مسجّلة بعد. ستظهر الصالة هنا فور قبول طلب انضمامها."}
          </p>
        ) : (
          filteredHalls.map((hall) => {
            const isActive = hall.status === "active";
            return (
              <article
                key={hall.id}
                className="rounded-2xl border border-gray-200 bg-white p-4 shadow-sm transition hover:shadow-md dark:border-gray-800 dark:bg-gray-900"
              >
                <div className="flex items-center justify-between">
                  <span
                    className={`rounded-full px-2.5 py-0.5 text-[10px] font-bold ${
                      isActive
                        ? "bg-emerald-500/15 text-emerald-600 dark:text-emerald-400"
                        : "bg-red-500/15 text-red-600 dark:text-red-400"
                    }`}
                  >
                    {isActive ? "نشطة" : "معطّلة"}
                  </span>
                  <h3 className="flex items-center gap-1.5 text-sm font-extrabold text-gray-900 dark:text-white">
                    {hall.name}
                    <Building2 size={16} className="text-[#6B5478]" />
                  </h3>
                </div>

                <div className="mt-3 space-y-2.5 border-t border-gray-100 pt-3 dark:border-gray-800">
                  <InfoRow icon={MapPin} label="العنوان" value={hall.address} />
                  <InfoRow icon={Phone} label="الهاتف التجاري" value={hall.commercialPhone} ltr />
                  <InfoRow icon={Users} label="عدد الموظفين" value={hall.employeeCount} />
                  <InfoRow icon={User} label="مدير الصالة" value={hall.managerName} />
                </div>

                <div className="mt-3 flex items-center justify-between border-t border-gray-100 pt-3 dark:border-gray-800">
                  {hall.source === "api" ? (
                    <span className="text-[10px] font-bold text-gray-400">صالة مُفعّلة</span>
                  ) : (
                    <button
                      onClick={() => onArchive(hall)}
                      className="flex items-center gap-1.5 text-xs font-bold text-gray-500 transition hover:text-[#6B5478] dark:text-gray-400"
                    >
                      <Archive size={14} /> أرشفة
                    </button>
                  )}
                  <button
                    onClick={() => showHallDetails(hall)}
                    className="flex items-center gap-1.5 text-xs font-bold text-[#6B5478]"
                  >
                    <Eye size={14} /> عرض التفاصيل
                  </button>
                </div>
              </article>
            );
          })
        )}
      </div>

      <p className="mt-5 text-center text-[11px] text-gray-500 sm:text-right">
        عرض {filteredHalls.length} من {allHalls.length} صالة
      </p>
    </div>
  );
}
