import { useEffect, useRef, useState } from "react";
import {
  Bell,
  CheckCheck,
  Trash2,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { DASHBOARD_NOTIFICATION_BTN_CLS } from "../../../shared/components/dashboardTopBarUi";
import NotificationDropdownRow from "./NotificationDropdownRow";
import { useNotifications } from "../hooks/useNotifications";

export default function NotificationCenterBell({
  mode = "staff",
  audience = "reception",
  className = "",
}) {
  const rootRef = useRef(null);
  const [open, setOpen] = useState(false);
  const notifications = useNotifications({ mode, audience });

  const {
    items,
    unreadCount,
    selectedIds,
    selectionMode,
    setSelectionMode,
    busy,
    toggleSelected,
    selectAll,
    clearSelection,
    markItemRead,
    markAllRead,
    deleteItem,
    deleteSelected,
    deleteAll,
    openItem,
  } = notifications;

  useEffect(() => {
    if (!open) {
      clearSelection();
      return undefined;
    }
    const onDoc = (e) => {
      if (!rootRef.current?.contains(e.target)) setOpen(false);
    };
    document.addEventListener("mousedown", onDoc);
    return () => document.removeEventListener("mousedown", onDoc);
  }, [clearSelection, open]);

  const selectedCount = selectedIds.size;
  const hasUnread = unreadCount > 0;

  return (
    <div className={cn("relative", className)} ref={rootRef}>
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        className={DASHBOARD_NOTIFICATION_BTN_CLS}
        title="الإشعارات"
        aria-label="الإشعارات"
        aria-expanded={open}
      >
        <Bell size={18} />
        {unreadCount > 0 ? (
          <span className="absolute -top-1 -start-1 flex h-4 min-w-4 items-center justify-center rounded-full bg-red-500 px-1 text-[9px] font-bold text-white shadow-sm">
            {unreadCount > 9 ? "9+" : unreadCount}
          </span>
        ) : null}
      </button>

      {open ? (
        <>
          <button
            type="button"
            className="fixed inset-0 z-40 bg-black/20 backdrop-blur-[1px] dark:bg-black/40"
            onClick={() => setOpen(false)}
            aria-label="إغلاق الإشعارات"
          />
          <div className="absolute start-0 top-full z-50 mt-2 w-[min(28rem,calc(100vw-2rem))] overflow-hidden rounded-2xl border border-gray-200/90 bg-white shadow-2xl dark:border-gray-700/80 dark:bg-gray-950">
            <div className="border-b border-gray-100 px-4 py-3.5 dark:border-gray-800">
              <div className="flex items-center justify-between gap-2">
                <h3 className="text-xs font-extrabold text-gray-900 dark:text-white">الإشعارات</h3>
                <div className="flex items-center gap-1">
                  {hasUnread ? (
                    <button
                      type="button"
                      disabled={busy}
                      onClick={() => markAllRead()}
                      className="inline-flex items-center gap-1 rounded-lg px-2 py-1 text-[10px] font-bold text-[#6B5478] transition hover:bg-[#6B5478]/10 disabled:opacity-50 dark:text-[#c4b5d0] dark:hover:bg-[#6B5478]/15"
                    >
                      <CheckCheck size={12} />
                      تعليم الكل
                    </button>
                  ) : null}
                  <button
                    type="button"
                    onClick={() => {
                      if (selectionMode) clearSelection();
                      else setSelectionMode(true);
                    }}
                    className="rounded-lg px-2 py-1 text-[10px] font-bold text-gray-500 transition hover:bg-gray-100 dark:text-gray-400 dark:hover:bg-gray-800"
                  >
                    {selectionMode ? "إلغاء" : "تحديد"}
                  </button>
                </div>
              </div>

              {selectionMode ? (
                <div className="mt-2 flex items-center justify-between gap-2 rounded-xl bg-gray-50 px-2.5 py-2 dark:bg-gray-900/80">
                  <button
                    type="button"
                    onClick={selectAll}
                    className="text-[10px] font-bold text-[#6B5478] dark:text-[#c4b5d0]"
                  >
                    تحديد الكل ({items.length})
                  </button>
                  {selectedCount > 0 ? (
                    <button
                      type="button"
                      disabled={busy}
                      onClick={() => deleteSelected()}
                      className="inline-flex items-center gap-1 rounded-lg bg-red-500/10 px-2.5 py-1 text-[10px] font-bold text-red-600 transition hover:bg-red-500/15 disabled:opacity-50 dark:text-red-400"
                    >
                      <Trash2 size={12} />
                      حذف المحدد ({selectedCount})
                    </button>
                  ) : null}
                </div>
              ) : null}
            </div>

            <div className="max-h-[min(28rem,65vh)] overflow-y-auto overscroll-contain bg-gray-50/40 px-3 py-3 dark:bg-gray-950/60">
              {items.length === 0 ? (
                <div className="px-4 py-12 text-center">
                  <Bell size={32} className="mx-auto mb-3 text-gray-300 dark:text-gray-600" />
                  <p className="text-sm font-semibold text-gray-400 dark:text-gray-500">لا توجد إشعارات.</p>
                </div>
              ) : (
                <div className="space-y-2.5">
                  {items.map((item) => (
                    <NotificationDropdownRow
                      key={item.id}
                      item={item}
                      selectionMode={selectionMode}
                      selected={selectedIds.has(item.id)}
                      onToggleSelect={toggleSelected}
                      onOpen={(row) => {
                        openItem(row);
                        setOpen(false);
                      }}
                      onDelete={deleteItem}
                      onMarkRead={markItemRead}
                    />
                  ))}
                </div>
              )}
            </div>

            {items.length > 0 ? (
              <div className="border-t border-gray-100 px-4 py-4 dark:border-gray-800">
                <button
                  type="button"
                  disabled={busy}
                  onClick={() => deleteAll()}
                  className="flex w-full items-center justify-center gap-2 rounded-2xl border border-red-500/25 bg-red-500/8 py-3.5 text-sm font-extrabold text-red-600 transition hover:bg-red-500/12 disabled:opacity-50 dark:border-red-900/45 dark:bg-red-950/25 dark:text-red-400 dark:hover:bg-red-950/35"
                >
                  <Trash2 size={16} />
                  حذف الكل
                </button>
              </div>
            ) : null}
          </div>
        </>
      ) : null}
    </div>
  );
}
