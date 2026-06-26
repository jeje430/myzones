import {
  TableBulkActionBar,
  TableSelectHeaderCell,
  TableSelectRowCell,
  selectableRowClass,
} from "../../../../shared/components/ui/TableSelection";

export default function DataTable({
  columns,
  children,
  minWidth = "720px",
  empty,
  selection,
  bulkActions,
}) {
  const hasRows = Array.isArray(children) ? children.length > 0 : Boolean(children);
  const colSpan = columns.length + (selection ? 1 : 0);

  return (
    <div className="overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-sm dark:border-gray-800 dark:bg-gray-900">
      {selection && bulkActions?.length ? (
        <TableBulkActionBar count={selection.count} onClear={selection.clearSelection} actions={bulkActions} />
      ) : null}
      <div className="overflow-x-auto">
        <table className="w-full text-right text-xs" style={{ minWidth }}>
          <thead>
            <tr className="border-b border-gray-200 bg-gray-50 dark:border-gray-800 dark:bg-gray-800/60">
              {selection ? <TableSelectHeaderCell {...selection} /> : null}
              {columns.map((col) => (
                <th
                  key={col}
                  className="whitespace-nowrap px-4 py-3 font-extrabold text-gray-600 dark:text-gray-300"
                >
                  {col}
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
            {hasRows ? (
              children
            ) : (
              <tr>
                <td colSpan={colSpan} className="px-4 py-10 text-center text-gray-400">
                  {empty || "لا توجد بيانات لعرضها."}
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

export function Td({ children, bold, ltr, className = "" }) {
  return (
    <td
      className={`px-4 py-3 align-middle text-gray-700 dark:text-gray-200 ${bold ? "font-bold" : ""} ${className}`}
      dir={ltr ? "ltr" : undefined}
    >
      {children}
    </td>
  );
}

export function Tr({ children, selection, rowId, className = "" }) {
  const selected = selection && rowId != null ? selection.isSelected(rowId) : false;
  return (
    <tr
      className={
        selection && rowId != null
          ? selectableRowClass(selected, `transition hover:bg-[#6B5478]/5 dark:hover:bg-[#6B5478]/10 ${className}`)
          : `transition hover:bg-[#6B5478]/5 dark:hover:bg-[#6B5478]/10 ${className}`
      }
    >
      {selection && rowId != null ? (
        <TableSelectRowCell id={rowId} ariaLabel={`تحديد الصف ${rowId}`} {...selection} />
      ) : null}
      {children}
    </tr>
  );
}
