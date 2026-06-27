import PageHeader from "../../super-admin/components/ui/PageHeader";
import MaintenanceFaultsTableSection from "../components/MaintenanceFaultsTableSection";

export default function ManagerArchivedFaultsPage() {
  return (
    <div className="space-y-4" dir="rtl">
        <PageHeader
          title="الأعطال المؤرشفة"
        />
        <MaintenanceFaultsTableSection
          mode="archived"
          readOnly
          showEmployeeColumn
          sectionTitle="الأرشيف"
        />
      </div>
  );
}
