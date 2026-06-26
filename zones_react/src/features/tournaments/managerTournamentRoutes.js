/**
 * مسارات البطولات داخل لوحة المدير — مبنية على getManagerRoutes(managerId).
 * @param {{ tournaments: string }} managerRoutes
 */
export function buildManagerTournamentRoutes(managerRoutes) {
  const base = managerRoutes.tournaments;
  return {
    tournaments: base,
    details: (id) => `${base}/${id}`,
    participants: (id) => `${base}/${id}/participants`,
    bracket: (id) => `${base}/${id}/bracket`,
  };
}
