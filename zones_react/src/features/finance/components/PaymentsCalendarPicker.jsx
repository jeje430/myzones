import { useEffect, useLayoutEffect, useMemo, useRef, useState } from "react";
import { createPortal } from "react-dom";
import { CalendarDays, ChevronLeft, ChevronRight } from "lucide-react";
import {
  formatLocalIsoDate,
  localTodayIso,
  parseLocalIso,
} from "../../../shared/utils/localDateUtils";
import "./PaymentsCalendarPicker.css";

const WEEKDAYS_AR = ["أحد", "إثن", "ثلا", "أرب", "خمي", "جمع", "سبت"];

function formatMonthTitle(year, month) {
  return new Date(year, month, 1).toLocaleDateString("ar-LY", {
    month: "long",
    year: "numeric",
  });
}

function formatTriggerDate(iso) {
  return parseLocalIso(iso).toLocaleDateString("ar-LY", {
    weekday: "short",
    day: "numeric",
    month: "short",
    year: "numeric",
  });
}

function buildMonthGrid(year, month) {
  const first = new Date(year, month, 1);
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const startOffset = first.getDay();
  const cells = [];

  for (let i = 0; i < startOffset; i += 1) cells.push(null);
  for (let day = 1; day <= daysInMonth; day += 1) cells.push(day);

  return cells;
}

export default function PaymentsCalendarPicker({
  value,
  showAll,
  disabled,
  onChange,
  onPrevDay,
  onNextDay,
  onShowAll,
}) {
  const [open, setOpen] = useState(false);
  const [popoverPos, setPopoverPos] = useState({ top: 0, left: 0, placement: "below" });
  const rootRef = useRef(null);
  const triggerRef = useRef(null);
  const selected = parseLocalIso(value);
  const [viewYear, setViewYear] = useState(selected.getFullYear());
  const [viewMonth, setViewMonth] = useState(selected.getMonth());

  useEffect(() => {
    const d = parseLocalIso(value);
    setViewYear(d.getFullYear());
    setViewMonth(d.getMonth());
  }, [value]);

  const updatePopoverPosition = () => {
    if (!triggerRef.current) return;

    const rect = triggerRef.current.getBoundingClientRect();
    const popoverHeight = 320;
    const gap = 8;
    const spaceBelow = window.innerHeight - rect.bottom;
    const placement = spaceBelow < popoverHeight && rect.top > popoverHeight ? "above" : "below";

    setPopoverPos({
      top: placement === "below" ? rect.bottom + gap : rect.top - gap,
      left: rect.left + rect.width / 2,
      placement,
    });
  };

  useLayoutEffect(() => {
    if (!open) return undefined;

    updatePopoverPosition();

    const onReflow = () => updatePopoverPosition();
    window.addEventListener("resize", onReflow);
    window.addEventListener("scroll", onReflow, true);

    return () => {
      window.removeEventListener("resize", onReflow);
      window.removeEventListener("scroll", onReflow, true);
    };
  }, [open, viewYear, viewMonth]);

  useEffect(() => {
    const onDoc = (e) => {
      if (rootRef.current && !rootRef.current.contains(e.target)) {
        const portal = document.getElementById("pay-cal-portal");
        if (portal && portal.contains(e.target)) return;
        setOpen(false);
      }
    };
    document.addEventListener("mousedown", onDoc);
    return () => document.removeEventListener("mousedown", onDoc);
  }, []);

  const grid = useMemo(() => buildMonthGrid(viewYear, viewMonth), [viewYear, viewMonth]);

  const shiftMonth = (delta) => {
    const d = new Date(viewYear, viewMonth + delta, 1);
    setViewYear(d.getFullYear());
    setViewMonth(d.getMonth());
  };

  const pickDay = (day) => {
    onChange(formatLocalIsoDate(new Date(viewYear, viewMonth, day)));
    setOpen(false);
  };

  const goToday = () => {
    const today = localTodayIso();
    onChange(today);
    const d = parseLocalIso(today);
    setViewYear(d.getFullYear());
    setViewMonth(d.getMonth());
    setOpen(false);
  };

  const isSelected = (day) =>
    day &&
    selected.getFullYear() === viewYear &&
    selected.getMonth() === viewMonth &&
    selected.getDate() === day;

  const isToday = (day) => {
    if (!day) return false;
    const now = new Date();
    return (
      now.getFullYear() === viewYear && now.getMonth() === viewMonth && now.getDate() === day
    );
  };

  const popover =
    open && !showAll
      ? createPortal(
          <div
            id="pay-cal-portal"
            className={`pay-cal-popover pay-cal-popover--${popoverPos.placement}`}
            style={{
              position: "fixed",
              top: popoverPos.top,
              left: popoverPos.left,
              transform:
                popoverPos.placement === "above"
                  ? "translate(-50%, -100%)"
                  : "translateX(-50%)",
              zIndex: 9999,
            }}
            role="dialog"
            aria-label="اختيار تاريخ المدفوعات"
          >
            <div className="pay-cal-popover-head">
              <button
                type="button"
                className="pay-cal-nav"
                onClick={() => shiftMonth(-1)}
                aria-label="الشهر السابق"
              >
                <ChevronRight size={15} />
              </button>
              <span className="pay-cal-month">{formatMonthTitle(viewYear, viewMonth)}</span>
              <button
                type="button"
                className="pay-cal-nav"
                onClick={() => shiftMonth(1)}
                aria-label="الشهر التالي"
              >
                <ChevronLeft size={15} />
              </button>
            </div>

            <div className="pay-cal-weekdays">
              {WEEKDAYS_AR.map((w) => (
                <span key={w}>{w}</span>
              ))}
            </div>

            <div className="pay-cal-grid">
              {grid.map((day, idx) => (
                <button
                  key={idx}
                  type="button"
                  disabled={!day}
                  className={`pay-cal-day ${isSelected(day) ? "is-selected" : ""} ${isToday(day) ? "is-today" : ""}`}
                  onClick={() => day && pickDay(day)}
                >
                  {day || ""}
                </button>
              ))}
            </div>

            <div className="pay-cal-footer">
              <button type="button" className="pay-cal-today-btn" onClick={goToday}>
                اليوم
              </button>
            </div>
          </div>,
          document.body,
        )
      : null;

  return (
    <div className="pay-cal" ref={rootRef}>
      <div className="pay-cal-wrap">
        <div className="pay-cal-toolbar">
          <button
            type="button"
            className="pay-cal-arrow"
            onClick={onPrevDay}
            disabled={disabled || showAll}
            aria-label="اليوم السابق"
          >
            <ChevronRight size={16} />
          </button>

          <button
            ref={triggerRef}
            type="button"
            className="pay-cal-trigger"
            onClick={() => {
              if (disabled || showAll) return;
              setOpen((o) => !o);
            }}
            disabled={disabled || showAll}
            aria-expanded={open}
            aria-haspopup="dialog"
          >
            <CalendarDays size={16} className="pay-cal-trigger-icon" />
            <span className="pay-cal-trigger-text">
              <span className="pay-cal-trigger-date">
                {showAll ? "كل الأيام" : formatTriggerDate(value)}
              </span>
              <span className="pay-cal-trigger-sub">
                {showAll ? "بدون فلتر تاريخ" : "اضغط لفتح التقويم"}
              </span>
            </span>
          </button>

          <button
            type="button"
            className="pay-cal-arrow"
            onClick={onNextDay}
            disabled={disabled || showAll}
            aria-label="اليوم التالي"
          >
            <ChevronLeft size={16} />
          </button>
        </div>

        <button
          type="button"
          className={`pay-cal-all-btn ${showAll ? "is-active" : ""}`}
          onClick={onShowAll}
        >
          {showAll ? "اليوم" : "الكل"}
        </button>
      </div>

      {popover}
    </div>
  );
}
