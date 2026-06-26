import { useEffect } from "react";
import PageHeader from "../../super-admin/components/ui/PageHeader";
import MaintenanceFaultsTableSection from "../components/MaintenanceFaultsTableSection";
import { syncMaintenanceStateFromApi } from "../../maintenance/data/maintenanceFaultsSync";
import { isApiStaffSession, getActiveStaffSession } from "../../devices-packages/data/hallCatalogSync";

export default function MaintenanceFaultsPage() {
  useEffect(() => {
    const session = getActiveStaffSession();
    if (!isApiStaffSession(session)) return;

    syncMaintenanceStateFromApi();

    const interval = window.setInterval(() => {
      syncMaintenanceStateFromApi();
    }, 5000);

    return () => window.clearInterval(interval);
  }, []);

  return (
    <div className="space-y-4" dir="rtl">
      <PageHeader title="الأعطال" />
      <MaintenanceFaultsTableSection mode="active" sectionTitle="الأعطال النشطة" />
    </div>
  );
}
