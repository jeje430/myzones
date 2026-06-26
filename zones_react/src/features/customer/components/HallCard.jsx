import { Link } from "react-router-dom";
import { Clock, MapPin, Star } from "lucide-react";

export default function HallCard({ lounge, detailPath }) {
  const to = detailPath ?? `/app/halls/${lounge.id}`;

  return (
    <Link
      to={to}
      className="group overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-sm transition hover:-translate-y-0.5 hover:shadow-md dark:border-gray-800 dark:bg-gray-900"
    >
      {lounge.image ? (
        <img
          src={lounge.image}
          alt={lounge.name}
          className="h-36 w-full object-cover transition group-hover:scale-[1.02]"
        />
      ) : (
        <div className="flex h-36 w-full items-center justify-center bg-gray-100 text-xs text-gray-400 dark:bg-gray-800">
          لا توجد صورة
        </div>
      )}
      <div className="p-4">
        <div className="flex items-start justify-between gap-2">
          <h3 className="text-sm font-extrabold text-gray-900 dark:text-white">{lounge.name}</h3>
          {lounge.isOpen ? (
            <span className="rounded-full bg-emerald-500/15 px-2 py-0.5 text-[10px] font-bold text-emerald-600">
              مفتوحة
            </span>
          ) : (
            <span className="rounded-full bg-gray-500/15 px-2 py-0.5 text-[10px] font-bold text-gray-500">
              مغلقة
            </span>
          )}
        </div>
        <p className="mt-1 flex items-center gap-1 text-[11px] text-gray-500">
          <MapPin size={12} className="text-[#6B5478]" />
          {lounge.city || lounge.address || "—"}
        </p>
        <div className="mt-3 flex items-center justify-between text-[11px]">
          <span className="flex items-center gap-1 font-bold text-amber-600">
            <Star size={12} fill="currentColor" />
            {lounge.averageRating.toFixed(1)}
            <span className="text-gray-400">({lounge.reviewsCount})</span>
          </span>
          {lounge.opensAt && lounge.closesAt ? (
            <span className="flex items-center gap-1 text-gray-500">
              <Clock size={12} />
              {lounge.opensAt} – {lounge.closesAt}
            </span>
          ) : null}
        </div>
        {lounge.services?.length ? (
          <div className="mt-3 flex flex-wrap gap-1">
            {lounge.services.slice(0, 4).map((s) => (
              <span
                key={s.key}
                className="rounded-full bg-[#6B5478]/10 px-2 py-0.5 text-[10px] font-bold text-[#6B5478]"
              >
                {s.shortLabel || s.label}
              </span>
            ))}
          </div>
        ) : null}
      </div>
    </Link>
  );
}
