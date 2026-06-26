import { categoryLabel } from "./expenseMeta";
import {
  FINANCE_DATA_EVENT,
  ensureExpensesLoaded,
  getCachedExpenses,
  invalidateFinanceCache,
  setExpensesCache,
} from "./financeApiCache";
import {
  createManagerExpense,
  deleteManagerExpense,
  deleteManagerExpensesBulk,
  updateManagerExpense,
} from "./managerFinanceApi";

export { FINANCE_DATA_EVENT as EXPENSES_STORAGE_EVENT };

export function loadExpenses() {
  return getCachedExpenses();
}

export async function refreshExpenses() {
  return ensureExpensesLoaded(true);
}

export async function saveExpenseRow(patch, existingId = null) {
  const payload = {
    name: patch.name,
    amount: patch.amount,
    isPaid: patch.isPaid,
    addedAt: patch.addedAt,
    paidAt: patch.paidAt,
    notes: patch.notes,
  };

  const result = existingId
    ? await updateManagerExpense(existingId, payload)
    : await createManagerExpense(payload);

  if (!result.ok) {
    return result;
  }

  const rows = existingId
    ? getCachedExpenses().map((row) => (row.id === existingId ? result.expense : row))
    : [result.expense, ...getCachedExpenses()];

  await setExpensesCache(rows);
  invalidateFinanceCache();

  return result;
}

export async function removeExpenseRows(ids) {
  const uniqueIds = [...new Set(ids.filter(Boolean))];
  if (!uniqueIds.length) {
    return { ok: false, error: "لا توجد عناصر للحذف." };
  }

  const result =
    uniqueIds.length === 1
      ? await deleteManagerExpense(uniqueIds[0])
      : await deleteManagerExpensesBulk(uniqueIds);

  if (!result.ok) {
    return result;
  }

  const idSet = new Set(uniqueIds);
  await setExpensesCache(getCachedExpenses().filter((row) => !idSet.has(row.id)));
  invalidateFinanceCache();

  return { ok: true };
}

function normalizeExpenseRow(row) {
  const name =
    row.name?.trim() ||
    row.categoryLabel?.trim() ||
    categoryLabel(row.category) ||
    "—";
  const { category, categoryLabel: _legacyLabel, ...rest } = row;
  return { ...rest, name };
}

function parseIso(iso) {
  if (!iso || typeof iso !== "string") return null;
  const p = iso.split("-");
  if (p.length !== 3) return null;
  const y = Number(p[0]);
  const m = Number(p[1]);
  const d = Number(p[2]);
  if (!y || !m || !d) return null;
  return { y, m, d };
}

function countsTowardExpenses(row) {
  return Boolean(row.isPaid);
}

function expenseInMonth(row, year, month) {
  if (!countsTowardExpenses(row)) return false;
  const ref = parseIso(row.paidAt) || parseIso(row.addedAt);
  if (!ref) return false;
  return ref.y === year && ref.m === month;
}

export function filterExpensesInMonth(rows, year, month) {
  return rows.filter((r) => expenseInMonth(r, year, month));
}

export function sumExpensesInMonth(year, month, rows = loadExpenses()) {
  const list = filterExpensesInMonth(rows, year, month);
  const total = list.reduce((s, r) => s + (Number(r.amount) || 0), 0);
  return { total, count: list.length, items: list };
}

export function sumExpensesInPrevMonth(year, month, rows = loadExpenses()) {
  const prevM = month === 1 ? 12 : month - 1;
  const prevY = month === 1 ? year - 1 : year;
  return sumExpensesInMonth(prevY, prevM, rows);
}

export function buildStoredDailyExpenseSeries(year, month, rows = loadExpenses()) {
  const days = new Date(year, month, 0).getDate();
  const buckets = Array.from({ length: days }, (_, i) => ({ label: String(i + 1), expenses: 0 }));

  for (const row of rows) {
    if (!countsTowardExpenses(row)) continue;
    const refIso = row.paidAt || row.addedAt;
    const ref = parseIso(refIso);
    if (!ref || ref.y !== year || ref.m !== month) continue;
    const idx = ref.d - 1;
    if (idx >= 0 && idx < days) {
      buckets[idx].expenses += Number(row.amount) || 0;
    }
  }

  return buckets;
}

export function buildStoredCategoryBreakdown(year, month, rows = loadExpenses()) {
  const list = filterExpensesInMonth(rows, year, month);
  const map = {};
  for (const row of list) {
    const key = row.name?.trim() || "غير محدد";
    map[key] = (map[key] || 0) + (Number(row.amount) || 0);
  }
  const colors = ["#6B5478", "#3b82f6", "#f97316", "#eab308", "#22c55e", "#94a3b8", "#ec4899"];
  return Object.entries(map).map(([key, value], i) => ({
    key,
    name: key,
    value,
    color: colors[i % colors.length],
  }));
}
