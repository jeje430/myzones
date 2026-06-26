import { getCachedExpenses, getCachedOverview } from "../data/financeApiCache";

export const MONTHS_AR = [
  "يناير",
  "فبراير",
  "مارس",
  "أبريل",
  "مايو",
  "يونيو",
  "يوليو",
  "أغسطس",
  "سبتمبر",
  "أكتوبر",
  "نوفمبر",
  "ديسمبر",
];

export const REVENUE_CATEGORIES = [
  { key: "bookings", label: "الحجوزات", color: "#22d3ee" },
  { key: "devices", label: "الأجهزة", color: "#a78bfa" },
  { key: "packages", label: "الباقات", color: "#34d399" },
  { key: "extras", label: "خدمات إضافية", color: "#fbbf24" },
];

export const EXPENSE_CATEGORIES = [
  { key: "salaries", label: "رواتب الموظفين", color: "#fb7185" },
  { key: "maintenance", label: "الصيانة", color: "#f97316" },
  { key: "purchases", label: "المشتريات", color: "#c084fc" },
  { key: "utilities", label: "المرافق والخدمات", color: "#38bdf8" },
  { key: "other", label: "أخرى", color: "#94a3b8" },
];

// بيانات مالية مبنية بالكامل على السجلات الحقيقية (لا أرقام وهمية)
export function daysInMonth(y, m) {
  return new Date(y, m, 0).getDate();
}

export function formatCurrency(value) {
  return `${new Intl.NumberFormat("ar-LY", { maximumFractionDigits: 0 }).format(Math.round(value))} د.ل`;
}

export function formatPct(value) {
  const sign = value > 0 ? "+" : "";
  return `${sign}${value.toFixed(1)}% عن الشهر السابق`;
}

export function yearOptions() {
  const y0 = new Date().getFullYear();
  return [y0 - 1, y0, y0 + 1];
}

function prevMonth(year, month) {
  if (month === 1) return { year: year - 1, month: 12 };
  return { year, month: month - 1 };
}

function emptyDailySeries(year, month, valueKey) {
  const days = daysInMonth(year, month);
  return Array.from({ length: days }, (_, index) => ({
    label: String(index + 1),
    [valueKey]: 0,
  }));
}

function overviewFor(year, month, granularity = "daily") {
  return getCachedOverview(year, month, granularity);
}

/** سلسلة إيرادات من الحجوزات المحققة في Laravel */
export function buildRevenueSeries(year, month, granularity) {
  const overview = overviewFor(year, month, granularity);
  if (overview?.revenueSeries?.length) {
    return overview.revenueSeries;
  }
  return emptyDailySeries(year, month, "revenue");
}

export function sumRevenueInMonth(year, month) {
  const overview = overviewFor(year, month, "daily");
  return overview?.summary?.revenue ?? 0;
}

export function deriveRevenueTotals(year, month) {
  const overview = overviewFor(year, month, "daily");
  if (overview?.summary) {
    return {
      total: overview.summary.revenue,
      revDelta: overview.summary.revenueDelta,
    };
  }

  return { total: 0, revDelta: 0 };
}

export function deriveRevenueInsights(series, granularity) {
  if (!series.length) {
    return {
      total: 0,
      dailyAvg: 0,
      highestLabel: "—",
      highestValue: 0,
      lowestLabel: "—",
      lowestValue: 0,
    };
  }

  let highest = series[0];
  let lowest = series[0];
  let sum = 0;
  for (const p of series) {
    sum += p.revenue;
    if (p.revenue > highest.revenue) highest = p;
    if (p.revenue < lowest.revenue) lowest = p;
  }

  const divisor =
    granularity === "daily" ? series.length : granularity === "weekly" ? series.length * 7 : 30;

  return {
    total: sum,
    dailyAvg: sum / Math.max(divisor, 1),
    highestLabel: highest.label,
    highestValue: highest.revenue,
    lowestLabel: lowest.label,
    lowestValue: lowest.revenue,
  };
}

/** توزيع الإيرادات حسب مصدر الحجز الفعلي */
export function buildCategoryBreakdown(year, month) {
  const overview = overviewFor(year, month, "daily");
  if (overview?.revenueBreakdown?.length) {
    return overview.revenueBreakdown;
  }

  return [
    { name: "تطبيق الزبون", key: "app", value: 0, color: "#a78bfa" },
    { name: "حجز يدوي", key: "manual", value: 0, color: "#fbbf24" },
  ];
}

export function buildExpenseSeries(year, month, granularity) {
  const overview = overviewFor(year, month, granularity);
  if (overview?.expenseSeries?.length) {
    return overview.expenseSeries;
  }
  return emptyDailySeries(year, month, "expenses");
}

function sumExpensesInMonth(year, month) {
  const overview = overviewFor(year, month, "daily");
  if (overview?.summary) {
    return {
      total: overview.summary.expenses,
      count: getCachedExpenses().filter((row) => expenseInMonth(row, year, month)).length,
      items: getCachedExpenses().filter((row) => expenseInMonth(row, year, month)),
    };
  }

  return { total: 0, count: 0, items: [] };
}

function sumExpensesInPrevMonth(year, month) {
  const prev = prevMonth(year, month);
  return sumExpensesInMonth(prev.year, prev.month);
}

function expenseInMonth(row, year, month) {
  if (!row.isPaid) return false;
  const ref = row.paidAt || row.addedAt;
  if (!ref) return false;
  const [y, m] = String(ref).split("-").map(Number);
  return y === year && m === month;
}

export function buildStoredCategoryBreakdown(year, month) {
  const overview = overviewFor(year, month, "daily");
  if (overview?.expenseBreakdown?.length) {
    return overview.expenseBreakdown;
  }
  return [];
}

export function deriveExpenseTotals(year, month) {
  const overview = overviewFor(year, month, "daily");
  if (overview?.summary) {
    return {
      total: overview.summary.expenses,
      expDelta: overview.summary.expenseDelta,
    };
  }

  const current = sumExpensesInMonth(year, month);
  const prev = sumExpensesInPrevMonth(year, month);
  const expDelta = prev.total > 0 ? ((current.total - prev.total) / prev.total) * 100 : 0;
  return { total: current.total, expDelta };
}

export function deriveExpenseInsights(series, granularity) {
  if (!series.length) {
    return {
      dailyAvg: 0,
      highestLabel: "—",
      highestValue: 0,
      lowestLabel: "—",
      lowestValue: 0,
    };
  }

  let highest = series[0];
  let lowest = series[0];
  let sum = 0;
  for (const p of series) {
    sum += p.expenses;
    if (p.expenses > highest.expenses) highest = p;
    if (p.expenses < lowest.expenses) lowest = p;
  }

  const divisor =
    granularity === "daily" ? series.length : granularity === "weekly" ? series.length * 7 : 30;

  return {
    dailyAvg: sum / Math.max(divisor, 1),
    highestLabel: highest.label,
    highestValue: highest.expenses,
    lowestLabel: lowest.label,
    lowestValue: lowest.expenses,
  };
}

/** سلسلة صافي الربح (إيرادات − مصروفات) */
export function buildNetProfitSeries(year, month, granularity) {
  const overview = overviewFor(year, month, granularity);
  if (overview?.profitSeries?.length) {
    return overview.profitSeries;
  }

  const revenueSeries = buildRevenueSeries(year, month, granularity);
  const expenseSeries = buildExpenseSeries(year, month, granularity);
  return revenueSeries.map((r, i) => ({
    label: r.label,
    netProfit: r.revenue - (expenseSeries[i]?.expenses ?? 0),
  }));
}

export function deriveNetProfitTotals(year, month) {
  const overview = overviewFor(year, month, "daily");
  if (overview?.summary) {
    return {
      total: overview.summary.netProfit,
      netDelta: overview.summary.profitDelta,
    };
  }

  const rev = deriveRevenueTotals(year, month);
  const exp = deriveExpenseTotals(year, month);
  const total = rev.total - exp.total;
  const prev = prevMonth(year, month);
  const prevRev = sumRevenueInMonth(prev.year, prev.month);
  const prevExp = sumExpensesInPrevMonth(year, month).total;
  const prevNet = prevRev - prevExp;
  const netDelta = ((total - prevNet) / Math.abs(prevNet || 1)) * 100;
  return { total, netDelta };
}

export function deriveNetProfitInsights(series, granularity) {
  if (!series.length) {
    return {
      dailyAvg: 0,
      highestLabel: "—",
      highestValue: 0,
      lowestLabel: "—",
      lowestValue: 0,
    };
  }

  let highest = series[0];
  let lowest = series[0];
  let sum = 0;
  for (const p of series) {
    sum += p.netProfit;
    if (p.netProfit > highest.netProfit) highest = p;
    if (p.netProfit < lowest.netProfit) lowest = p;
  }

  const divisor =
    granularity === "daily" ? series.length : granularity === "weekly" ? series.length * 7 : 30;

  return {
    dailyAvg: sum / Math.max(divisor, 1),
    highestLabel: highest.label,
    highestValue: highest.netProfit,
    lowestLabel: lowest.label,
    lowestValue: lowest.netProfit,
  };
}

export const PROFIT_CATEGORIES = [
  { key: "devices", label: "الأجهزة", color: "#22c55e" },
  { key: "packages", label: "الباقات", color: "#6B5478" },
  { key: "bookings", label: "الحجوزات", color: "#34d399" },
  { key: "offers", label: "العروض", color: "#a78bfa" },
];

/**
 * توزيع الأرباح حسب المصدر — مبني على إيرادات الحجوزات الفعلية.
 * لا توجد بيانات وهمية: عند غياب الأرباح تكون كل القيم صفراً.
 */
export function buildProfitCategoryBreakdown(year, month) {
  const totalProfit = deriveNetProfitTotals(year, month).total;
  const revenueBreakdown = buildCategoryBreakdown(year, month);
  const revenueSum = revenueBreakdown.reduce((a, b) => a + (b.value || 0), 0);

  if (totalProfit <= 0 || revenueSum <= 0) {
    return PROFIT_CATEGORIES.map((cat) => ({
      name: cat.label,
      key: cat.key,
      value: 0,
      color: cat.color,
    }));
  }

  // وزّع صافي الربح بنسبة مصادر الإيراد الفعلية
  return revenueBreakdown.map((row, i) => ({
    name: row.name,
    key: row.key,
    value: Math.round((row.value / revenueSum) * totalProfit),
    color: PROFIT_CATEGORIES[i % PROFIT_CATEGORIES.length].color,
  }));
}

export function derivePackageUsage(year, month, packagePeriod = "monthly", granularity = "daily") {
  const overview = getCachedOverview(year, month, granularity, packagePeriod);
  if (overview?.packageUsage) {
    return overview.packageUsage;
  }

  return {
    period: packagePeriod,
    periodLabel: "—",
    totalSessions: 0,
    breakdown: [],
  };
}

const REPORT_TYPE_LABELS = {
  full: "تقرير شامل",
  revenue: "الإيرادات",
  expenses: "المصروفات",
  net: "صافي الأرباح",
};

export function resolveReportPeriod(period, customFrom, customTo) {
  const now = new Date();
  let from = new Date(now);
  let to = new Date(now);
  to.setHours(23, 59, 59, 999);

  if (period === "week") {
    from = new Date(now);
    from.setDate(now.getDate() - 6);
    from.setHours(0, 0, 0, 0);
  } else if (period === "month") {
    from = new Date(now.getFullYear(), now.getMonth(), 1);
    from.setHours(0, 0, 0, 0);
  } else if (period === "year") {
    from = new Date(now.getFullYear(), 0, 1);
    from.setHours(0, 0, 0, 0);
  } else if (period === "custom" && customFrom && customTo) {
    from = new Date(customFrom);
    from.setHours(0, 0, 0, 0);
    to = new Date(customTo);
    to.setHours(23, 59, 59, 999);
  } else {
    from.setHours(0, 0, 0, 0);
  }

  return { from, to };
}

function formatPeriodLabel(from, to) {
  const opts = { year: "numeric", month: "short", day: "numeric" };
  return `${from.toLocaleDateString("ar-LY", opts)} — ${to.toLocaleDateString("ar-LY", opts)}`;
}

function scaleByDays(value, daySpan, year, month) {
  const monthDays = daysInMonth(year, month);
  const factor = Math.min(Math.max(daySpan / monthDays, 0.25), 3);
  return Math.round(value * factor);
}

/** بيانات التقرير المالي للـ PDF */
export function buildReportPayload(reportType, from, to) {
  const year = to.getFullYear();
  const month = to.getMonth() + 1;
  const daySpan = Math.max(1, Math.ceil((to.getTime() - from.getTime()) / 86400000));

  const rev = deriveRevenueTotals(year, month);
  const exp = deriveExpenseTotals(year, month);
  const net = deriveNetProfitTotals(year, month);

  const revenueSeries = buildRevenueSeries(year, month, "daily")
    .slice(0, Math.min(daySpan, 31))
    .map((d) => ({ label: d.label, value: d.revenue }));
  const expenseSeries = buildExpenseSeries(year, month, "daily")
    .slice(0, Math.min(daySpan, 31))
    .map((d) => ({ label: d.label, value: d.expenses }));
  const profitSeries = buildNetProfitSeries(year, month, "daily")
    .slice(0, Math.min(daySpan, 31))
    .map((d) => ({ label: d.label, value: d.netProfit }));

  const profitSeriesRaw = buildNetProfitSeries(year, month, "daily").slice(0, Math.min(daySpan, 31));
  const insights = deriveNetProfitInsights(profitSeriesRaw, "daily");
  const packageUsage = derivePackageUsage(year, month, "monthly", "daily");

  const loungeName =
    (typeof localStorage !== "undefined" && localStorage.getItem("zones-lounge-name")) ||
    "ZONES Gaming Center";

  return {
    loungeName,
    createdAt: new Date().toLocaleString("ar-LY", {
      dateStyle: "medium",
      timeStyle: "short",
    }),
    periodLabel: formatPeriodLabel(from, to),
    reportType,
    reportTypeLabel: REPORT_TYPE_LABELS[reportType] ?? REPORT_TYPE_LABELS.full,
    summary: {
      revenue: scaleByDays(rev.total, daySpan, year, month),
      expenses: scaleByDays(exp.total, daySpan, year, month),
      net: scaleByDays(net.total, daySpan, year, month),
    },
    charts: {
      profit: profitSeries,
      revenue: revenueSeries,
      expenses: expenseSeries,
    },
    stats: {
      totalSessions: packageUsage.totalSessions,
      packageUsageBreakdown: packageUsage.breakdown,
      bestProfitDay: insights.bestLabel,
      bestProfitValue: insights.bestProfit,
    },
  };
}

export function buildExpenseCategoryBreakdown(year, month) {
  const stored = buildStoredCategoryBreakdown(year, month);
  if (stored.length > 0) return stored;

  // لا مصروفات مسجّلة — حالة فارغة بدون أرقام وهمية
  return EXPENSE_CATEGORIES.map((cat) => ({
    name: cat.label,
    key: cat.key,
    value: 0,
    color: cat.color,
  }));
}
