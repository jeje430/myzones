import TournamentDetailsSection from "../../tournaments/components/TournamentDetailsSection";
import { useReceptionEmployeeRoutes } from "../data/receptionEmployeeRoutes";

export default function ReceptionTournamentDetailsPage() {
  const { routes } = useReceptionEmployeeRoutes();
  const tournamentRoutes = {
    tournaments: routes.tournaments,
    participants: (id) => routes.tournamentParticipants(id),
    bracket: (id) => routes.tournamentBracket(id),
  };
  return <TournamentDetailsSection routes={tournamentRoutes} readOnly />;
}
