import { useMemo } from "react";
import { Cell, Pie, PieChart, ResponsiveContainer, Tooltip } from "recharts";
import { useTheme } from "../../../shared/theme/useTheme";
import { overviewTooltipBox } from "../utils/financeOverviewHelpers";

function PackageUsageTooltip({ active, payload, isLight }) {
  if (!active || !payload?.length) return null;
  const row = payload[0]?.payload;
  if (!row) return null;

  return (
    <div style={overviewTooltipBox(isLight)}>
      <div style={{ fontWeight: 700, marginBottom: "0.35rem" }}>{row.name}</div>
      <div style={{ display: "flex", justifyContent: "space-between", gap: "1rem" }}>
        <span style={{ color: isLight ? "#4b5563" : "#94a3b8" }}>النسبة</span>
        <span style={{ fontWeight: 700 }}>{row.percentage}%</span>
      </div>
      <div style={{ display: "flex", justifyContent: "space-between", gap: "1rem", marginTop: "0.2rem" }}>
        <span style={{ color: isLight ? "#4b5563" : "#94a3b8" }}>الجلسات</span>
        <span style={{ fontWeight: 700 }}>{row.sessionsCount}</span>
      </div>
    </div>
  );
}

export default function PackageUsageChart({ packageUsage }) {
  const { theme } = useTheme();
  const isLight = theme === "light";
  const breakdown = packageUsage?.breakdown ?? [];
  const totalSessions = packageUsage?.totalSessions ?? 0;
  const periodLabel = packageUsage?.periodLabel ?? "—";

  const chartData = useMemo(
    () =>
      breakdown.map((row) => ({
        key: row.key,
        name: row.name,
        value: row.sessionsCount,
        sessionsCount: row.sessionsCount,
        percentage: row.percentage,
        color: row.color,
      })),
    [breakdown],
  );

  return (
    <section className="finance-package-usage">
      <div className="finance-package-usage__head">
        <div>
          <h2 className="finance-section__title finance-package-usage__title">استخدام الباقات</h2>
          <p className="finance-package-usage__subtitle">
            {totalSessions > 0
              ? `${totalSessions} جلسة مكتملة — ${periodLabel}`
              : `لا توجد جلسات مكتملة — ${periodLabel}`}
          </p>
        </div>
      </div>

      {chartData.length > 0 ? (
        <div className="finance-package-usage__body">
          <div className="finance-package-usage__chart">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={chartData}
                  dataKey="value"
                  nameKey="name"
                  cx="50%"
                  cy="50%"
                  innerRadius="48%"
                  outerRadius="78%"
                  paddingAngle={2}
                  stroke={isLight ? "#e5e7eb" : "rgba(6, 13, 41, 0.9)"}
                  strokeWidth={2}
                  isAnimationActive
                  animationDuration={520}
                >
                  {chartData.map((entry) => (
                    <Cell key={entry.key} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip content={<PackageUsageTooltip isLight={isLight} />} />
              </PieChart>
            </ResponsiveContainer>
          </div>
          <ul className="finance-package-usage__legend">
            {chartData.map((row) => (
              <li key={row.key} className="finance-package-usage__legend-item">
                <span className="finance-package-usage__legend-dot" style={{ background: row.color }} />
                <span className="finance-package-usage__legend-name">{row.name}</span>
                <span className="finance-package-usage__legend-meta">
                  {row.percentage}% · {row.sessionsCount} جلسة
                </span>
              </li>
            ))}
          </ul>
        </div>
      ) : (
        <div className="finance-package-usage__empty">لا توجد جلسات مكتملة في الفترة المحددة.</div>
      )}
    </section>
  );
}
