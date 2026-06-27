import { useEffect, useState } from "react";
import { Gamepad2, Users, Wallet } from "lucide-react";
import PageHeader from "../../super-admin/components/ui/PageHeader";
import KpiCard from "../../super-admin/components/ui/KpiCard";
import { getAuthSession } from "../../auth/data/mockUsersStorage";
import { loadManagerHall } from "../../lounge/data/managerHallStorage";
import ManagerWorkHoursChart from "../components/ManagerWorkHoursChart";
import { getWorkHoursCaption, getWorkHoursChartData } from "../data/workHoursData";
import HallServicesManagerPicker from "../../lounge/components/HallServicesManagerPicker";
import { getManagerDashboardKpis, MANAGER_DASHBOARD_EVENTS, refreshManagerDashboardFinance } from "../data/managerDashboardData";

export default function DashboardPage() {
  const session = getAuthSession();
  const hall = loadManagerHall();
  const [kpis, setKpis] = useState(getManagerDashboardKpis);

  useEffect(() => {
    const refresh = async () => {
      await refreshManagerDashboardFinance();
      setKpis(getManagerDashboardKpis());
    };
    refresh();
    for (const eventName of MANAGER_DASHBOARD_EVENTS) {
      window.addEventListener(eventName, refresh);
    }
    window.addEventListener("focus", refresh);
    return () => {
      for (const eventName of MANAGER_DASHBOARD_EVENTS) {
        window.removeEventListener(eventName, refresh);
      }
      window.removeEventListener("focus", refresh);
    };
  }, []);

  const hallLabel = hall.hallName?.trim()
    ? `صالة ${hall.hallName}`
    : session?.stationName
      ? `صالة ${session.stationName}`
      : "أكمل إعداد صالتك من إدارة الصالة";

  return (
    <>
      <PageHeader
        title="لوحة التحكم"
        description={`مرحباً ${session?.fullName || "مدير الصالة"} — ${hallLabel}`}
      />

      <div className="mb-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <KpiCard
          label="الأجهزة المتاحة (اليوم)"
          value={String(kpis.availableDevices)}
          hint={kpis.devicesHint}
          icon={Gamepad2}
          tone="green"
        />
        <KpiCard
          label="إيرادات اليوم"
          value={kpis.todayRevenueLabel}
          hint={kpis.revenueHint}
          icon={Wallet}
        />
        <KpiCard
          label="عدد الموظفين"
          value={String(kpis.employees)}
          hint={kpis.employeesHint}
          icon={Users}
          tone="amber"
        />
      </div>

      <ManagerWorkHoursChart data={getWorkHoursChartData()} caption={getWorkHoursCaption()} />

      <div className="mt-6">
        <HallServicesManagerPicker compact />
      </div>
    </>
  );
}
