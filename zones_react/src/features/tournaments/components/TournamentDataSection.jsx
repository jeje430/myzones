import { useCallback, useEffect, useMemo, useState } from "react";
import PageHeader from "../../super-admin/components/ui/PageHeader";
import CreateTournamentModal from "./CreateTournamentModal";
import TournamentDetailsModal from "./TournamentDetailsModal";
import TournamentParticipantsModal from "./TournamentParticipantsModal";
import TournamentsListTable from "./TournamentsListTable";
import { fetchManagerTournaments } from "../data/managerTournamentsApi";

const PAGE_SIZE = 5;

export default function TournamentDataSection({
  showAddButton = false,
  autoOpenAdd = false,
}) {
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState("");
  const [createOpen, setCreateOpen] = useState(false);
  const [detailOpen, setDetailOpen] = useState(false);
  const [participantsOpen, setParticipantsOpen] = useState(false);
  const [detailRow, setDetailRow] = useState(null);
  const [participantsRow, setParticipantsRow] = useState(null);
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
    const onFocus = () => reload();
    window.addEventListener("focus", onFocus);
    const poll = window.setInterval(() => reload(), 8000);
    return () => {
      window.removeEventListener("focus", onFocus);
      window.clearInterval(poll);
    };
  }, [reload]);

  useEffect(() => {
    if (showAddButton && autoOpenAdd) setCreateOpen(true);
  }, [showAddButton, autoOpenAdd]);

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

  return (
    <>
      <PageHeader
        title="بيانات البطولة"
        description="إنشاء وإدارة البطولات — متزامنة مع تطبيق الزبون."
      />

      {loadError ? (
        <p className="mb-3 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-xs font-bold text-red-600 dark:border-red-900/40 dark:bg-red-950/20">
          {loadError}
        </p>
      ) : null}

      {loading ? (
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
          onDetails={(row) => {
            setDetailRow(row);
            setDetailOpen(true);
          }}
          onParticipants={(row) => {
            setParticipantsRow(row);
            setParticipantsOpen(true);
          }}
          actionsMode="details"
          showAddButton={showAddButton}
          onAdd={showAddButton ? () => setCreateOpen(true) : undefined}
        />
      )}

      <TournamentDetailsModal
        open={detailOpen}
        tournament={detailRow}
        onClose={() => {
          setDetailOpen(false);
          setDetailRow(null);
        }}
      />

      <TournamentParticipantsModal
        open={participantsOpen}
        tournament={participantsRow}
        onClose={() => {
          setParticipantsOpen(false);
          setParticipantsRow(null);
        }}
      />

      {showAddButton ? (
        <CreateTournamentModal
          open={createOpen}
          onClose={() => setCreateOpen(false)}
          onSaved={() => reload()}
        />
      ) : null}
    </>
  );
}
