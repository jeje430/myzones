import { useMemo } from "react";
import { Checkbox } from "@/components/ui/checkbox";
import TournamentRowActions from "./TournamentRowActions";
import StatusBadge from "./StatusBadge";
import {
  TableBulkActionBar,
  selectableRowClass,
} from "../../../shared/components/ui/TableSelection";
import { SELECT_COL_TD, SELECT_COL_TH } from "../../../shared/components/ui/tableActionStyles";
import { useTableSelection } from "../../../shared/hooks/useTableSelection";

const CHECKBOX_CLASS =
  "mx-auto ring-offset-[#0b0e14] data-[state=checked]:shadow-[0_0_0_2px_rgba(107,84,120,0.25)]";

export default function TournamentTable({ rows, searchQuery, onAction, onRowOpen, onBulkAction }) {
  const q = searchQuery.trim();
  const filtered = q
    ? rows.filter((r) => r.name.includes(q) || r.game.includes(q) || r.startDate.includes(q))
    : rows;

  const pageIds = useMemo(() => filtered.map((r) => r.id), [filtered]);
  const selection = useTableSelection({ items: filtered, pageIds });

  const handleBulkAction = () => {
    if (!onBulkAction || !selection.selectedIds.length) return;
    const targets = filtered.filter((r) => selection.selectedIds.includes(r.id));
    onBulkAction(targets);
    selection.clearSelection();
  };

  const bulkActions = onBulkAction
    ? [{ label: "تنفيذ على المحدد", onClick: handleBulkAction }]
    : [];

  return (
    <div className="tournaments-table-wrap no-scrollbar rounded-xl border border-slate-800/80" data-zones-table-wrap>
      <TableBulkActionBar
        count={selection.count}
        onClear={selection.clearSelection}
        actions={bulkActions}
      />
      <table className="w-full min-w-[720px] border-collapse text-sm">
        <thead>
          <tr className="border-b border-slate-800/90 bg-[#0b0e14]/70 text-xs font-medium uppercase tracking-wide text-slate-500">
            <th className={`${SELECT_COL_TH} text-center`}>
              <Checkbox
                checked={selection.masterChecked}
                onCheckedChange={selection.toggleSelectAll}
                aria-label="تحديد الكل"
                className={CHECKBOX_CLASS}
              />
            </th>
            <th className="px-3 py-3 text-end">اسم البطولة</th>
            <th className="px-3 py-3 text-end">اللعبة</th>
            <th className="px-3 py-3 text-end">عدد المشاركين</th>
            <th className="px-3 py-3 text-end">تاريخ البداية</th>
            <th className="px-3 py-3 text-end">الحالة</th>
            <th className="px-3 py-3 text-end">الإجراءات</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-slate-800/80">
          {filtered.map((row) => (
            <tr
              key={row.id}
              className={`bg-[#0f131a]/40 transition hover:bg-[#151a24]/80 ${onRowOpen ? "cursor-pointer" : ""} ${selectableRowClass(selection.isSelected(row.id), "")}`}
              onClick={() => onRowOpen?.(row)}
              role={onRowOpen ? "button" : undefined}
              tabIndex={onRowOpen ? 0 : undefined}
              onKeyDown={
                onRowOpen
                  ? (e) => {
                      if (e.key === "Enter" || e.key === " ") {
                        e.preventDefault();
                        onRowOpen(row);
                      }
                    }
                  : undefined
              }
              aria-label={onRowOpen ? `عرض تفاصيل ${row.name}` : undefined}
            >
              <td className={SELECT_COL_TD} onClick={(e) => e.stopPropagation()}>
                <Checkbox
                  checked={selection.isSelected(row.id)}
                  onCheckedChange={() => selection.toggleRow(row.id)}
                  aria-label={`تحديد ${row.name}`}
                  className={CHECKBOX_CLASS}
                />
              </td>
              <td className="px-3 py-3 text-end">
                <span className="tournament-row-name font-medium text-violet-200 underline-offset-2 hover:text-white hover:underline">
                  {row.name}
                </span>
              </td>
              <td className="px-3 py-3 text-end text-slate-300">{row.game}</td>
              <td className="px-3 py-3 text-end">
                <span className="inline-flex min-w-[2rem] items-center justify-center rounded-lg border border-slate-700/80 bg-[#0b0e14]/80 px-2 py-1 text-xs font-bold tabular-nums text-slate-200">
                  {row.participants}
                </span>
              </td>
              <td className="px-3 py-3 text-end tabular-nums text-slate-300">{row.startDate}</td>
              <td className="px-3 py-3 text-end">
                <StatusBadge status={row.status} />
              </td>
              <td className="px-3 py-3 text-end" onClick={(e) => e.stopPropagation()}>
                <TournamentRowActions row={row} onAction={onAction} />
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
