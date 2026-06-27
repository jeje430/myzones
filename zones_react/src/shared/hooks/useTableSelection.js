import { useCallback, useEffect, useMemo, useState } from "react";

function sameId(a, b) {
  return a === b || String(a) === String(b);
}

/**
 * @param {{ items?: Array<{ id: number|string }>, pageIds?: Array<number|string>, allIds?: Array<number|string> }} options
 */
export function useTableSelection({ items = [], pageIds = [], allIds } = {}) {
  const [selectedIds, setSelectedIds] = useState([]);

  const validIds = useMemo(() => new Set(items.map((item) => item.id)), [items]);
  const scopeIds = allIds ?? pageIds;

  useEffect(() => {
    setSelectedIds((prev) => prev.filter((id) => validIds.has(id) || [...validIds].some((v) => sameId(v, id))));
  }, [validIds]);

  const allScopeSelected =
    scopeIds.length > 0 && scopeIds.every((id) => selectedIds.some((sid) => sameId(sid, id)));
  const someScopeSelected =
    scopeIds.some((id) => selectedIds.some((sid) => sameId(sid, id))) && !allScopeSelected;
  const masterChecked = allScopeSelected ? true : someScopeSelected ? "indeterminate" : false;

  const isSelected = useCallback(
    (id) => selectedIds.some((sid) => sameId(sid, id)),
    [selectedIds],
  );

  const toggleRow = useCallback((id) => {
    setSelectedIds((prev) => {
      if (prev.some((sid) => sameId(sid, id))) {
        return prev.filter((sid) => !sameId(sid, id));
      }
      return [...prev, id];
    });
  }, []);

  const toggleSelectAll = useCallback(
    (checked) => {
      if (checked) {
        setSelectedIds((prev) => {
          const next = [...prev];
          scopeIds.forEach((id) => {
            if (!next.some((sid) => sameId(sid, id))) next.push(id);
          });
          return next;
        });
        return;
      }
      setSelectedIds((prev) => prev.filter((id) => !scopeIds.some((sid) => sameId(sid, id))));
    },
    [scopeIds],
  );

  const clearSelection = useCallback(() => setSelectedIds([]), []);

  return {
    selectedIds,
    setSelectedIds,
    masterChecked,
    toggleRow,
    toggleSelectAll,
    clearSelection,
    isSelected,
    count: selectedIds.length,
    hasSelection: selectedIds.length > 0,
    scopeCount: scopeIds.length,
  };
}

export function resolveBulkActionIds(rowId, selectedIds) {
  if (!selectedIds?.length) return [rowId];
  if (selectedIds.length > 1) return [...selectedIds];
  if (selectedIds.some((sid) => sameId(sid, rowId))) return [...selectedIds];
  return [rowId];
}

export function filterItemsByIds(items, ids) {
  return items.filter((item) => ids.some((id) => sameId(id, item.id)));
}

/** @param {number} baseCols @param {boolean} selectionMode */
export function tableSelectColSpan(baseCols, selectionMode) {
  return selectionMode ? baseCols + 1 : baseCols;
}
