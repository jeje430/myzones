import { useCallback, useEffect, useMemo, useState } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import { zonesConfirm, zonesToastError, zonesToastSuccess } from "../../../shared/utils/zonesAlerts";
import ManagerLayout from "../../../shared/layouts/ManagerLayout";
import { useManagerPaths } from "../../../shared/tenant/ManagerWorkspaceProvider";
import PageHeader from "../../super-admin/components/ui/PageHeader";
import TournamentsListTable from "../components/TournamentsListTable";
import CreateTournamentModal from "../components/CreateTournamentModal";
import {
  cancelManagerTournament,
  fetchManagerTournaments,
} from "../data/managerTournamentsApi";
import { buildManagerTournamentRoutes } from "../managerTournamentRoutes";

const PAGE_SIZE = 5;

export default function TournamentsPage() {
  const navigate = useNavigate();
  const { routes } = useManagerPaths();
  const tournamentRoutes = buildManagerTournamentRoutes(routes);
  const [searchParams, setSearchParams] = useSearchParams();
  const autoOpenAdd = searchParams.get("add") === "1";

  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState("");
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);
  const [createOpen, setCreateOpen] = useState(false);

  useEffect(() => {
    if (autoOpenAdd) {
      setCreateOpen(true);
      setSearchParams({}, { replace: true });
    }
  }, [autoOpenAdd, setSearchParams]);

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

  const handleCancel = async (row) => {
    const ok = await zonesConfirm({
      title: "إلغاء البطولة؟",
      text: `سيتم إلغاء «${row.name}» وإخفاؤها من تطبيق الزبون.`,
      icon: "warning",
      confirmText: "إلغاء البطولة",
      cancelText: "تراجع",
      danger: true,
    });
    if (!ok) return;

    const result = await cancelManagerTournament(row.id);
    if (!result.ok) {
      zonesToastError(result.error || "تعذر إلغاء البطولة.");
      return;
    }
    zonesToastSuccess("تم إلغاء البطولة");
    reload();
  };

  const handleBulkCancel = async (targets) => {
    const ok = await zonesConfirm({
      title: `إلغاء ${targets.length} بطولات؟`,
      text: `سيتم إلغاء ${targets.length} بطولات وإخفاؤها من تطبيق الزبون.`,
      icon: "warning",
      confirmText: "إلغاء البطولات",
      cancelText: "تراجع",
      danger: true,
    });
    if (!ok) return;

    let success = 0;
    for (const row of targets) {
      const result = await cancelManagerTournament(row.id);
      if (result.ok) success += 1;
    }

    if (!success) {
      zonesToastError("تعذر إلغاء البطولات المحددة.");
      return;
    }

    zonesToastSuccess(`تم إلغاء ${success} من ${targets.length} بطولات`);
    reload();
  };

  const canCancel = (row) => row.status !== "cancelled" && row.status !== "finished";

  return (
    <ManagerLayout>
      <PageHeader
        title="البطولات"
        description="إنشاء وإدارة البطولات — متزامنة مع تطبيق الزبون."
      />

      {loadError ? (
        <p className="mb-3 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-xs font-bold text-red-600 dark:border-red-900/40 dark:bg-red-950/20">
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
          onDetails={(row) => {
            navigate(tournamentRoutes.details(row.id), { state: { tournament: row, from: "list" } });
          }}
          onParticipants={(row) => {
            navigate(tournamentRoutes.participants(row.id), {
              state: { tournament: row, from: "list" },
            });
          }}
          onBracket={(row) => {
            navigate(tournamentRoutes.bracket(row.id), { state: { tournament: row, from: "list" } });
          }}
          onCancel={handleCancel}
          onBulkCancel={handleBulkCancel}
          canCancel={canCancel}
          actionsMode="manager"
          showAddButton
          onAdd={() => setCreateOpen(true)}
        />
      )}

      <CreateTournamentModal
        open={createOpen}
        onClose={() => setCreateOpen(false)}
        onSaved={() => reload()}
      />

    </ManagerLayout>
  );
}
