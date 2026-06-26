import { apiClient, mapApiErrorMessage } from "../../../shared/api/apiClient";

function mapApiExpense(row) {
  return {
    id: row.id,
    name: row.name || "",
    amount: Number(row.amount) || 0,
    isPaid: Boolean(row.is_paid),
    addedAt: row.added_at || "",
    paidAt: row.paid_at || null,
    notes: row.notes || "",
    category: row.category || null,
    deviceFaultId: row.device_fault_id ?? null,
    createdBy: row.created_by ?? null,
  };
}

function mapOverview(data) {
  if (!data) return null;

  return {
    year: data.year,
    month: data.month,
    granularity: data.granularity,
    summary: {
      revenue: Number(data.summary?.revenue) || 0,
      grossRevenue: Number(data.summary?.gross_revenue) || 0,
      platformCommission: Number(data.summary?.platform_commission) || 0,
      revenueDelta: Number(data.summary?.revenue_delta) || 0,
      expenses: Number(data.summary?.expenses) || 0,
      expenseDelta: Number(data.summary?.expense_delta) || 0,
      netProfit: Number(data.summary?.net_profit) || 0,
      profitDelta: Number(data.summary?.profit_delta) || 0,
    },
    revenueSeries: (data.revenue_series || []).map((row) => ({
      label: row.label,
      revenue: Number(row.revenue) || 0,
    })),
    expenseSeries: (data.expense_series || []).map((row) => ({
      label: row.label,
      expenses: Number(row.expenses) || 0,
    })),
    profitSeries: (data.profit_series || []).map((row) => ({
      label: row.label,
      netProfit: Number(row.net_profit) || 0,
    })),
    revenueBreakdown: (data.revenue_breakdown || []).map((row) => ({
      name: row.name,
      key: row.key,
      value: Number(row.value) || 0,
      color: row.color,
    })),
    expenseBreakdown: (data.expense_breakdown || []).map((row) => ({
      name: row.name,
      key: row.key,
      value: Number(row.value) || 0,
      color: row.color,
    })),
    packageUsage: {
      period: data.package_usage?.period || "monthly",
      periodLabel: data.package_usage?.period_label || "—",
      totalSessions: Number(data.package_usage?.total_sessions) || 0,
      breakdown: (data.package_usage?.breakdown || []).map((row) => ({
        packageId: row.package_id ?? null,
        key: row.key,
        name: row.name,
        sessionsCount: Number(row.sessions_count) || 0,
        percentage: Number(row.percentage) || 0,
        color: row.color,
      })),
    },
    sessionsCount: Number(data.sessions_count) || 0,
  };
}

export async function fetchManagerFinanceOverview(
  year,
  month,
  granularity = "daily",
  packagePeriod = "monthly",
) {
  try {
    const { data } = await apiClient.get("/manager/finance/overview", {
      params: { year, month, granularity, package_period: packagePeriod },
    });
    return { ok: true, overview: mapOverview(data) };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error), overview: null };
  }
}

export async function fetchManagerFinanceSummary(year, month) {
  try {
    const { data } = await apiClient.get("/manager/finance/summary", {
      params: { year, month },
    });
    return {
      ok: true,
      summary: {
        revenue: Number(data.summary?.revenue) || 0,
        grossRevenue: Number(data.summary?.gross_revenue) || 0,
        platformCommission: Number(data.summary?.platform_commission) || 0,
        revenueDelta: Number(data.summary?.revenue_delta) || 0,
        expenses: Number(data.summary?.expenses) || 0,
        expenseDelta: Number(data.summary?.expense_delta) || 0,
        netProfit: Number(data.summary?.net_profit) || 0,
        profitDelta: Number(data.summary?.profit_delta) || 0,
      },
      sessionsCount: Number(data.sessions_count) || 0,
    };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error), summary: null };
  }
}

export async function fetchTodayRevenue() {
  try {
    const { data } = await apiClient.get("/manager/finance/revenue/today");
    return {
      ok: true,
      todayTotal: Number(data.today_total) || 0,
      yesterdayTotal: Number(data.yesterday_total) || 0,
      deltaPct: Number(data.delta_pct) || 0,
    };
  } catch (error) {
    return {
      ok: false,
      error: mapApiErrorMessage(error),
      todayTotal: 0,
      yesterdayTotal: 0,
      deltaPct: 0,
    };
  }
}

export async function fetchManagerExpenses() {
  try {
    const { data } = await apiClient.get("/manager/expenses");
    return {
      ok: true,
      expenses: (data.expenses || []).map(mapApiExpense),
    };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error), expenses: [] };
  }
}

export async function createManagerExpense(payload) {
  try {
    const { data } = await apiClient.post("/manager/expenses", {
      name: payload.name,
      amount: payload.amount,
      is_paid: payload.isPaid,
      added_at: payload.addedAt,
      paid_at: payload.paidAt,
      notes: payload.notes,
    });
    return { ok: true, expense: mapApiExpense(data.expense) };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}

export async function updateManagerExpense(id, payload) {
  try {
    const { data } = await apiClient.put(`/manager/expenses/${id}`, {
      name: payload.name,
      amount: payload.amount,
      is_paid: payload.isPaid,
      added_at: payload.addedAt,
      paid_at: payload.paidAt,
      notes: payload.notes,
    });
    return { ok: true, expense: mapApiExpense(data.expense) };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}

export async function deleteManagerExpense(id) {
  try {
    await apiClient.delete(`/manager/expenses/${id}`);
    return { ok: true };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}

export async function deleteManagerExpensesBulk(ids) {
  try {
    await apiClient.delete("/manager/expenses/bulk", { data: { ids } });
    return { ok: true };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}
