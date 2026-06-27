import { useCallback, useEffect, useState } from "react";
import { Link, useNavigate, useParams, useLocation } from "react-router-dom";
import PageHeader from "../../super-admin/components/ui/PageHeader";
import { zonesToastSuccess } from "../../../shared/utils/zonesAlerts";
import { TournamentBreadcrumb } from "./TournamentDetailUi";
import EditTournamentForm from "./EditTournamentForm";
import { fetchManagerTournament } from "../data/managerTournamentsApi";

/**
 * @param {object} props
 * @param {object} props.routes
 * @param {string} props.routes.tournaments
 */
export default function TournamentDetailsSection({ routes, readOnly = false }) {
  const { id } = useParams();
  const navigate = useNavigate();
  const location = useLocation();
  const numericId = Number(id);

  const [tournament, setTournament] = useState(location.state?.tournament ?? null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const reload = useCallback(async () => {
    if (!Number.isFinite(numericId)) return;

    setError("");
    const result = await fetchManagerTournament(numericId);
    if (result.ok) {
      setTournament(result.tournament);
    } else {
      setError(result.error || "تعذر تحميل البطولة.");
    }
    setLoading(false);
  }, [numericId]);

  useEffect(() => {
    reload();
  }, [reload]);

  const goBack = () => {
    if (location.state?.from === "bracket" && routes.bracket) {
      navigate(routes.bracket(numericId), {
        state: { tournament, from: "details" },
      });
      return;
    }
    navigate(routes.tournaments);
  };

  if (!Number.isFinite(numericId)) {
    return (
      <>
        <PageHeader title="تفاصيل البطولة" onBack={goBack} backLabel="رجوع للبطولات" />
        <p className="text-sm text-gray-500">معرّف غير صالح.</p>
      </>
    );
  }

  if (loading && !tournament) {
    return (
      <>
        <PageHeader title="تفاصيل البطولة" onBack={goBack} backLabel="رجوع للبطولات" />
        <p className="py-10 text-center text-sm text-gray-500">جاري تحميل البطولة...</p>
      </>
    );
  }

  if (!tournament) {
    return (
      <>
        <PageHeader title="تفاصيل البطولة" onBack={goBack} backLabel="رجوع للبطولات" />
        <div className="rounded-2xl border border-gray-200 bg-white p-8 text-center shadow-sm dark:border-gray-800 dark:bg-gray-900">
          <p className="text-sm font-bold text-gray-600 dark:text-gray-300">
            {error || "لم يتم العثور على هذه البطولة."}
          </p>
          <Link
            to={routes.tournaments}
            className="mt-4 inline-flex rounded-xl border border-[#6B5478]/30 bg-[#6B5478]/10 px-4 py-2 text-xs font-bold text-[#6B5478]"
          >
            العودة للبطولات
          </Link>
        </div>
      </>
    );
  }

  return (
    <>
      <PageHeader
        title="تفاصيل البطولة"
        description={tournament.name}
        onBack={goBack}
        backLabel="رجوع للبطولات"
      />

      <section className="space-y-4">
        <TournamentBreadcrumb tournamentName={tournament.name} view="details" />

        <div className="overflow-hidden rounded-2xl border border-gray-200 bg-white p-5 shadow-sm dark:border-gray-800 dark:bg-gray-900 sm:p-6">
          <EditTournamentForm
            key={`${tournament.id}-${tournament.coverImage || ""}-${tournament.name}`}
            tournament={tournament}
            showCancel={false}
            readOnly={readOnly}
            submitLabel="حفظ التغييرات"
            onSaved={(updated) => {
              if (readOnly) return;
              setTournament(updated);
              zonesToastSuccess("تم حفظ التعديلات");
            }}
          />
        </div>
      </section>
    </>
  );
}
