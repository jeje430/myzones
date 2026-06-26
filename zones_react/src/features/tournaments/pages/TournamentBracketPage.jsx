import ManagerLayout from "../../../shared/layouts/ManagerLayout";
import { useManagerPaths } from "../../../shared/tenant/ManagerWorkspaceProvider";
import TournamentBracketSection from "../components/TournamentBracketSection";
import { buildManagerTournamentRoutes } from "../managerTournamentRoutes";

export default function TournamentBracketPage() {
  const { routes } = useManagerPaths();
  const tournamentRoutes = buildManagerTournamentRoutes(routes);

  return (
    <ManagerLayout>
      <TournamentBracketSection routes={tournamentRoutes} />
    </ManagerLayout>
  );
}
