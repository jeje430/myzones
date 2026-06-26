import { useCallback, useEffect, useMemo, useState } from "react";

/**
 * @param {{ items?: Array<{ id: number|string }>, pageIds?: Array<number|string> }} options
 */
export function useTableSelection({ items = [], pageIds = [] } = {}) {
  const [selectedIds, setSelectedIds] = useState([]);

  const validIds = useMemo(() => new Set(items.map((item) => item.id)), [items]);

  useEffect(() => {
    setSelectedIds((prev) => prev.filter((id) => validIds.has(id)));
  }, [validIds]);

  const allPageSelected = pageIds.length > 0 && pageIds.every((id) => selectedIds.includes(id));
  const somePageSelected = pageIds.some((id) => selectedIds.includes(id)) && !allPageSelected;
  const masterChecked = allPageSelected ? true : somePageSelected ? "indeterminate" : false;

  const isSelected = useCallback((id) => selectedIds.includes(id), [selectedIds]);

  const toggleRow = useCallback((id) => {
    setSelectedIds((prev) => (prev.includes(id) ? prev.filter((item) => item !== id) : [...prev, id]));
  }, []);

  const toggleSelectAll = useCallback(
    (checked) => {
      if (checked) {
        setSelectedIds((prev) => [...new Set([...prev, ...pageIds])]);
        return;
      }
      setSelectedIds([]);
    },
    [pageIds],
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
  };
}

export function resolveBulkActionIds(rowId, selectedIds) {
  if (!selectedIds?.length) return [rowId];
  if (selectedIds.length > 1) return [...selectedIds];
  if (selectedIds.includes(rowId)) return [...selectedIds];
  return [rowId];
}

export function filterItemsByIds(items, ids) {
  const idSet = new Set(ids);
  return items.filter((item) => idSet.has(item.id));
}
