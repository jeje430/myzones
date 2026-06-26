import TournamentParticipantsSection from "../../tournaments/components/TournamentParticipantsSection";
import { useReceptionEmployeeRoutes } from "../data/receptionEmployeeRoutes";

export default function ReceptionTournamentParticipantsPage() {
  const { routes } = useReceptionEmployeeRoutes();
  return (
    <TournamentParticipantsSection
      getParticipantsPath={(id) => routes.tournamentParticipants(id)}
    />
  );
}
