import { useCallback, useState } from "react";
import { useTableSelection } from "./useTableSelection";

/**
 * Selection mode: checkboxes appear only after user clicks «تحديد».
 * @param {{ items?: Array<{ id: number|string }>, pageIds?: Array<number|string>, allIds?: Array<number|string> }} options
 */
export function useTableSelectionMode(options) {
  const [selectionMode, setSelectionMode] = useState(false);
  const selection = useTableSelection(options);

  const enterSelectionMode = useCallback(() => {
    setSelectionMode(true);
  }, []);

  const exitSelectionMode = useCallback(() => {
    setSelectionMode(false);
    selection.clearSelection();
  }, [selection.clearSelection]);

  return {
    ...selection,
    selectionMode,
    enterSelectionMode,
    exitSelectionMode,
  };
}
