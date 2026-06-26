import TournamentPerParticipantsSection from "../../tournaments/components/TournamentPerParticipantsSection";
import { useReceptionEmployeeRoutes } from "../data/receptionEmployeeRoutes";

export default function ReceptionTournamentPerParticipantsPage() {
  const { routes } = useReceptionEmployeeRoutes();
  const tournamentRoutes = {
    tournaments: routes.tournaments,
    bracket: (id) => routes.tournamentBracket(id),
  };
  return <TournamentPerParticipantsSection routes={tournamentRoutes} readOnly />;
}
