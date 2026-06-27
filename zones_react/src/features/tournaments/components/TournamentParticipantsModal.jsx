import { useEffect, useState } from "react";
import AdminModal from "../../devices-packages/components/AdminModal";
import Button from "../../super-admin/components/ui/Button";
import { fetchTournamentParticipants } from "../data/managerTournamentsApi";

export default function TournamentParticipantsModal({ open, tournament, onClose }) {
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    if (!open || !tournament?.id) return;

    let cancelled = false;

    const load = async () => {
      setLoading(true);
      setError("");
      const result = await fetchTournamentParticipants(tournament.id);
      if (cancelled) return;
      if (!result.ok) {
        setError(result.error || "تعذر تحميل المشاركين.");
        setRows([]);
      } else {
        setRows(result.participants);
      }
      setLoading(false);
    };

    load();
    const poll = window.setInterval(load, 5000);

    return () => {
      cancelled = true;
      window.clearInterval(poll);
    };
  }, [open, tournament?.id]);

  return (
    <AdminModal
      open={open}
      onClose={onClose}
      title={`مشاركو البطولة — ${tournament?.name || ""}`}
      xl
    >
      <div className="mt-4" dir="rtl">
        {loading ? (
          <p className="py-8 text-center text-sm text-gray-500">جاري التحميل...</p>
        ) : error ? (
          <p className="py-4 text-center text-sm font-bold text-red-600">{error}</p>
        ) : rows.length === 0 ? (
          <p className="py-8 text-center text-sm text-gray-500">لا يوجد مشاركون بعد.</p>
        ) : (
          <div className="overflow-x-auto rounded-xl border border-gray-200 dark:border-gray-800">
            <table className="w-full min-w-[640px] text-right text-xs">
              <thead>
                <tr className="border-b border-gray-100 bg-gray-50/80 text-gray-500 dark:border-gray-800 dark:bg-gray-800/40">
                  <th className="px-3 py-2.5 font-bold">الاسم</th>
                  <th className="px-3 py-2.5 font-bold">البريد</th>
                  <th className="px-3 py-2.5 font-bold">وقت التسجيل</th>
                  <th className="px-3 py-2.5 font-bold">الحالة</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                {rows.map((row) => (
                  <tr key={row.id}>
                    <td className="px-3 py-3 font-bold text-gray-800 dark:text-gray-100">{row.name}</td>
                    <td className="px-3 py-3 text-gray-600 dark:text-gray-300" dir="ltr">
                      {row.email || "—"}
                    </td>
                    <td className="px-3 py-3 text-gray-600 dark:text-gray-300" dir="ltr">
                      {row.registered_at ? new Date(row.registered_at).toLocaleString("ar-LY") : "—"}
                    </td>
                    <td className="px-3 py-3">
                      <span
                        className={`rounded-full px-2.5 py-0.5 text-[11px] font-bold ${
                          row.status === "withdrawn"
                            ? "bg-red-500/10 text-red-600"
                            : "bg-emerald-500/10 text-emerald-600"
                        }`}
                      >
                        {row.status_label}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        <div className="mt-4 flex justify-end">
          <Button type="button" variant="outline" size="sm" onClick={onClose}>
            إغلاق
          </Button>
        </div>
      </div>
    </AdminModal>
  );
}
