import ManagerLayout from "../../../shared/layouts/ManagerLayout";
import { useManagerPaths } from "../../../shared/tenant/ManagerWorkspaceProvider";
import TournamentDetailsSection from "../components/TournamentDetailsSection";
import { buildManagerTournamentRoutes } from "../managerTournamentRoutes";

export default function TournamentDetailsPage() {
  const { routes } = useManagerPaths();
  const tournamentRoutes = buildManagerTournamentRoutes(routes);

  return (
    <ManagerLayout>
      <TournamentDetailsSection routes={tournamentRoutes} />
    </ManagerLayout>
  );
}
