import AdminModal from "../../devices-packages/components/AdminModal";
import Button from "../../super-admin/components/ui/Button";
import { TournamentDetailCell } from "./TournamentDetailUi";
import { tournamentCoverImage, tournamentStatusLabel } from "../data/tournamentMeta";

export default function TournamentDetailsModal({ open, tournament, onClose }) {
  if (!open || !tournament) return null;

  const capacity = Number(tournament.participants) || 8;
  const filled = Number(tournament.registeredCount ?? 0);
  const delayM = tournament.delayMinutes ?? "—";

  return (
    <AdminModal open={open} onClose={onClose} title="تفاصيل البطولة" wide>
      <div className="mt-4 space-y-4" dir="rtl">
        <img
          src={tournamentCoverImage(tournament)}
          alt={tournament.name}
          className="h-40 w-full rounded-xl object-cover sm:h-48"
        />

        <div className="rounded-xl border border-[#6B5478]/15 bg-[#6B5478]/5 px-4 py-3 dark:border-[#6B5478]/25 dark:bg-[#6B5478]/10">
          <p className="text-base font-extrabold text-gray-900 dark:text-white">{tournament.name}</p>
          <p className="mt-1 text-[11px] font-semibold text-gray-500">
            {tournament.game} · {filled}/{capacity} مشترك
          </p>
        </div>

        <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
          <TournamentDetailCell label="اسم البطولة" value={tournament.name} />
          <TournamentDetailCell label="اللعبة" value={tournament.game} />
          <TournamentDetailCell label="عدد المشاركين" value={String(capacity)} />
          <TournamentDetailCell label="المسجلون حالياً" value={`${filled}/${capacity}`} />
          <TournamentDetailCell label="تاريخ البداية" value={tournament.startDate} />
          <TournamentDetailCell label="تاريخ النهاية" value={tournament.endDate || "—"} />
          <TournamentDetailCell
            label="تاريخ انتهاء مهلة المشاركة"
            value={tournament.registrationDeadline || "—"}
          />
          <TournamentDetailCell label="الجائزة" value={tournament.prize || "—"} />
          <TournamentDetailCell label="حالة البطولة" value={tournamentStatusLabel(tournament.status)} />
          <TournamentDetailCell label="في حالة الانسحاب (داخلي)" value={tournament.withdrawal || "—"} />
          <TournamentDetailCell
            label="مدة التأخير قبل احتساب الخسارة"
            value={delayM === "—" ? "—" : `${delayM} دقيقة`}
          />
        </div>

        {tournament.matchRules ? (
          <div className="rounded-xl border border-gray-100 bg-gray-50/80 p-4 dark:border-gray-800 dark:bg-gray-800/40">
            <p className="mb-2 text-xs font-bold text-gray-500">قواعد البطولة</p>
            <pre className="whitespace-pre-wrap font-sans text-xs leading-relaxed text-gray-700 dark:text-gray-300">
              {tournament.matchRules}
            </pre>
          </div>
        ) : null}

        <div className="flex justify-end border-t border-gray-100 pt-4 dark:border-gray-800">
          <Button variant="outline" size="sm" onClick={onClose}>
            إغلاق
          </Button>
        </div>
      </div>
    </AdminModal>
  );
}
