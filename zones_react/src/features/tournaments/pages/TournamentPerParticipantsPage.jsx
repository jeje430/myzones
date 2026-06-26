import ManagerLayout from "../../../shared/layouts/ManagerLayout";
import { useManagerPaths } from "../../../shared/tenant/ManagerWorkspaceProvider";
import TournamentPerParticipantsSection from "../components/TournamentPerParticipantsSection";
import { buildManagerTournamentRoutes } from "../managerTournamentRoutes";

export default function TournamentPerParticipantsPage() {
  const { routes } = useManagerPaths();
  const tournamentRoutes = buildManagerTournamentRoutes(routes);

  return (
    <ManagerLayout>
      <TournamentPerParticipantsSection routes={tournamentRoutes} />
    </ManagerLayout>
  );
}
