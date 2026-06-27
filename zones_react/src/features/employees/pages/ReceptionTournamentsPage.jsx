import { useCallback, useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import PageHeader from "../../super-admin/components/ui/PageHeader";
import TournamentsListTable from "../../tournaments/components/TournamentsListTable";
import { fetchManagerTournaments } from "../../tournaments/data/managerTournamentsApi";
import { useReceptionEmployeeRoutes } from "../data/receptionEmployeeRoutes";

const PAGE_SIZE = 5;

export default function ReceptionTournamentsPage() {
  const navigate = useNavigate();
  const { routes } = useReceptionEmployeeRoutes();
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState("");
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);

  const reload = useCallback(async () => {
    setLoading(true);
    setLoadError("");
    const result = await fetchManagerTournaments();
    if (!result.ok) {
      setLoadError(result.error || "تعذر تحميل البطولات.");
      setRows([]);
    } else {
      setRows(result.tournaments);
    }
    setLoading(false);
  }, []);

  useEffect(() => {
    reload();
    const poll = window.setInterval(reload, 8000);
    const onFocus = () => reload();
    window.addEventListener("focus", onFocus);
    return () => {
      window.clearInterval(poll);
      window.removeEventListener("focus", onFocus);
    };
  }, [reload]);

  const filtered = useMemo(() => {
    const q = search.trim();
    if (!q) return rows;
    return rows.filter(
      (r) =>
        r.name?.includes(q) ||
        r.game?.includes(q) ||
        r.startDate?.includes(q) ||
        r.endDate?.includes(q),
    );
  }, [rows, search]);

  const totalPages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE));
  const paged = filtered.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE);

  useEffect(() => {
    if (page > totalPages) setPage(totalPages);
  }, [page, totalPages]);

  useEffect(() => {
    setPage(1);
  }, [search]);

  const openParticipants = (row) => {
    navigate(routes.tournamentParticipants(row.id), {
      state: { tournament: row, from: "list" },
    });
  };

  return (
    <div>
      <PageHeader title="عرض البطولات" />

      {loadError ? (
        <p className="mb-4 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm font-semibold text-red-700 dark:border-red-900/50 dark:bg-red-950/40 dark:text-red-300">
          {loadError}
        </p>
      ) : null}

      {loading && rows.length === 0 ? (
        <p className="py-10 text-center text-sm text-gray-500">جاري تحميل البطولات...</p>
      ) : (
        <TournamentsListTable
          rows={paged}
          allRows={filtered}
          search={search}
          onSearchChange={setSearch}
          page={page}
          totalPages={totalPages}
          totalItems={filtered.length}
          pageSize={PAGE_SIZE}
          onPageChange={setPage}
          onParticipants={openParticipants}
          actionsMode="viewOnly"
        />
      )}
    </div>
  );
}
