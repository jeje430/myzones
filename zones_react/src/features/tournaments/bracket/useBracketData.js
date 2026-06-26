import { useCallback, useEffect, useRef, useState } from "react";
import {
  fetchManagerBracket,
  fetchManagerTournament,
  fetchTournamentParticipants,
} from "../data/managerTournamentsApi";
import {
  loadBracketState,
  saveBracketState,
  seedBracketFromParticipants,
} from "./bracketStorage";
import { normalizeBracketRounds } from "./bracketUtils";

/**
 * Dynamic bracket fetch state: isLoading, bracket, error, apiSync, bracketReady, tournament.
 */
export function useBracketData(tournamentId) {
  const numericId = Number(tournamentId);
  const [tournament, setTournament] = useState(null);
  const [participantNames, setParticipantNames] = useState([]);
  const [bracket, setBracket] = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);
  const [apiSync, setApiSync] = useState(false);
  const [bracketReady, setBracketReady] = useState(false);

  const load = useCallback(async (silent = false) => {
    if (!Number.isFinite(numericId)) {
      setIsLoading(false);
      setError("معرّف البطولة غير صالح.");
      return;
    }

    if (!silent) setIsLoading(true);
    setError(null);

    const tResult = await fetchManagerTournament(numericId);
    if (!tResult.ok) {
      setError(tResult.error || "تعذر تحميل البطولة.");
      setIsLoading(false);
      return;
    }

    const t = tResult.tournament;
    setTournament(t);

    const cap = t.participants ?? 0;
    const filled = t.registeredCount ?? 0;
    const ready = cap > 0 && filled >= cap;
    setBracketReady(ready);

    if (!ready) {
      setBracket(null);
      setParticipantNames([]);
      setApiSync(false);
      setIsLoading(false);
      return;
    }

    const pResult = await fetchTournamentParticipants(numericId);
    let names = [];
    if (pResult.ok) {
      names = pResult.participants
        .filter((p) => p.status === "registered")
        .sort((a, b) => new Date(a.registered_at || 0) - new Date(b.registered_at || 0))
        .map((p) => p.name)
        .filter(Boolean);
      setParticipantNames(names);
    }

    const bResult = await fetchManagerBracket(numericId);
    if (bResult.ok && bResult.bracket?.rounds?.length) {
      normalizeBracketRounds(bResult.bracket.rounds);
      saveBracketState(numericId, bResult.bracket);
      setBracket(bResult.bracket);
      setApiSync(true);
      setIsLoading(false);
      return;
    }

    const existing = loadBracketState(numericId);
    if (existing?.rounds?.length) {
      normalizeBracketRounds(existing.rounds);
      saveBracketState(numericId, existing);
      setBracket(existing);
      setApiSync(false);
      setIsLoading(false);
      return;
    }

    if (names.length >= cap) {
      const seeded = seedBracketFromParticipants(t, names);
      if (seeded) {
        setBracket(seeded);
        setApiSync(false);
        setIsLoading(false);
        return;
      }
    }

    setBracket(null);
    setApiSync(false);
    setIsLoading(false);
  }, [numericId]);

  useEffect(() => {
    let cancelled = false;

    const run = async () => {
      await load(false);
      if (cancelled) return;
    };

    run();
    const poll = window.setInterval(() => load(true), 12000);

    return () => {
      cancelled = true;
      window.clearInterval(poll);
    };
  }, [load]);

  const setBracketState = useCallback(
    (next) => {
      setBracket(next);
      if (Number.isFinite(numericId)) saveBracketState(numericId, next);
    },
    [numericId],
  );

  return {
    tournament,
    bracket,
    isLoading,
    error,
    apiSync,
    bracketReady,
    participantNames,
    setBracketState,
    reload: () => load(false),
  };
}
