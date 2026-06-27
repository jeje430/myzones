import TournamentBracketSection from "../../tournaments/components/TournamentBracketSection";
import { useReceptionEmployeeRoutes } from "../data/receptionEmployeeRoutes";

export default function ReceptionTournamentBracketPage() {
  const { routes } = useReceptionEmployeeRoutes();
  const tournamentRoutes = {
    tournaments: routes.tournaments,
    details: (id) => routes.tournamentDetails(id),
    participants: (id) => routes.tournamentParticipants(id),
  };
  return <TournamentBracketSection routes={tournamentRoutes} receptionMode />;
}
