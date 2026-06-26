<?php

namespace App\Services;

use App\Events\TournamentWinnerDeclared;
use App\Models\Tournament;
use App\Models\TournamentMatch;
use App\Models\TournamentParticipant;
use Illuminate\Support\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class TournamentBracketService
{
    public function nextPowerOfTwo(int $n): int
    {
        $x = max(2, $n);
        $p = 1;
        while ($p < $x) {
            $p <<= 1;
        }

        return $p;
    }

    public function roundTitleAtIndex(int $bracketSize, int $roundIndex): string
    {
        $teamsAtStart = $bracketSize / (2 ** $roundIndex);
        if ($teamsAtStart >= 16) {
            return 'دور الـ16';
        }
        if ($teamsAtStart === 8) {
            return 'ربع النهائي';
        }
        if ($teamsAtStart === 4) {
            return 'نصف النهائي';
        }
        if ($teamsAtStart === 2) {
            return 'النهائي';
        }

        return 'الدور '.($roundIndex + 1);
    }

    public function roundEnumForIndex(int $bracketSize, int $roundIndex): string
    {
        $teamsAtStart = $bracketSize / (2 ** $roundIndex);
        if ($teamsAtStart >= 16) {
            return 'round_of_16';
        }
        if ($teamsAtStart === 8) {
            return 'quarter_final';
        }
        if ($teamsAtStart === 4) {
            return 'semi_final';
        }

        return 'final';
    }

    public function isBracketReady(Tournament $tournament): bool
    {
        $registered = $tournament->participants()->where('status', 'registered')->count();

        return $registered >= (int) $tournament->max_participants;
    }

    public function ensureBracket(Tournament $tournament): void
    {
        if (! $this->isBracketReady($tournament)) {
            throw ValidationException::withMessages([
                'bracket' => ['لم يكتمل عدد المشاركين بعد.'],
            ]);
        }

        if ($tournament->matches()->exists()) {
            return;
        }

        DB::transaction(function () use ($tournament) {
            $this->seedBracket($tournament);
        });
    }

    public function seedBracket(Tournament $tournament): void
    {
        $participants = $tournament->participants()
            ->where('status', 'registered')
            ->orderBy('registered_at')
            ->orderBy('id')
            ->get();

        $count = (int) $tournament->max_participants;
        if ($participants->count() < $count) {
            throw ValidationException::withMessages([
                'bracket' => ['عدد المسجّلين أقل من سعة البطولة.'],
            ]);
        }

        $shuffled = $this->shuffleSeeded($participants->take($count), (int) $tournament->id);
        $bracketSize = $this->nextPowerOfTwo($count);
        $numRounds = (int) log($bracketSize, 2);

        for ($r = 0; $r < $numRounds; $r++) {
            $matchesInRound = $bracketSize / (2 ** ($r + 1));
            for ($m = 0; $m < $matchesInRound; $m++) {
                $player1 = null;
                $player2 = null;
                if ($r === 0) {
                    $player1 = $shuffled[$m * 2] ?? null;
                    $player2 = $shuffled[$m * 2 + 1] ?? null;
                }

                TournamentMatch::create([
                    'tournament_id' => $tournament->id,
                    'round_index' => $r,
                    'match_index' => $m,
                    'round' => $this->roundEnumForIndex($bracketSize, $r),
                    'player1_id' => $player1?->id,
                    'player2_id' => $player2?->id,
                    'status' => 'upcoming',
                ]);
            }
        }

        $tournament->load(['matches.player1', 'matches.player2', 'matches.winner']);
        $this->applyLiveStatus($tournament->matches);
    }

    /**
     * @param  Collection<int, TournamentParticipant>  $participants
     * @return Collection<int, TournamentParticipant>
     */
    private function shuffleSeeded(Collection $participants, int $seed): Collection
    {
        $items = $participants->values()->all();
        $rnd = $this->mulberry32($seed);

        for ($i = count($items) - 1; $i > 0; $i--) {
            $j = (int) floor($rnd() * ($i + 1));
            [$items[$i], $items[$j]] = [$items[$j], $items[$i]];
        }

        return collect($items);
    }

  private function mulberry32(int $seed): callable
  {
      $a = $seed;

      return function () use (&$a) {
          $a = ($a + 0x6d2b79f5) & 0xffffffff;
          $t = $a;
          $t = (($t ^ (($t >> 15) & 0xffffffff)) * ($t | 1)) & 0xffffffff;
          $t ^= ($t + (($t ^ (($t >> 7) & 0xffffffff)) * ($t | 61))) & 0xffffffff;

          return (($t ^ (($t >> 14) & 0xffffffff)) & 0xffffffff) / 4294967296;
      };
  }

    /**
     * @param  Collection<int, TournamentMatch>  $matches
     */
    public function applyLiveStatus(Collection $matches): void
    {
        $now = now();

        foreach ($matches as $match) {
            if ($match->status === 'completed' || $match->winner_id) {
                continue;
            }

            if ($match->scheduled_at) {
                if ($match->scheduled_at->gt($now)) {
                    if ($match->status !== 'upcoming') {
                        $match->status = 'upcoming';
                        $match->save();
                    }
                    continue;
                }

                if ($match->status !== 'live') {
                    $match->status = 'live';
                    $match->save();
                }
                continue;
            }

            if ($match->status === 'live') {
                $match->status = 'upcoming';
                $match->save();
            }
        }
    }

    public function buildReactBracket(Tournament $tournament): array
    {
        $matches = $tournament->matches()
            ->with(['player1', 'player2', 'winner'])
            ->orderBy('round_index')
            ->orderBy('match_index')
            ->get();

        if ($matches->isEmpty()) {
            return null;
        }

        $bracketSize = $this->nextPowerOfTwo((int) $tournament->max_participants);
        $numRounds = (int) log($bracketSize, 2);
        $rounds = [];

        for ($r = 0; $r < $numRounds; $r++) {
            $roundMatches = $matches->where('round_index', $r)->sortBy('match_index')->values();
            $mapped = [];
            foreach ($roundMatches as $match) {
                $mapped[] = $this->mapMatchToReact($match);
            }
            $rounds[] = [
                'roundIndex' => $r,
                'title' => $this->roundTitleAtIndex($bracketSize, $r),
                'matches' => $mapped,
            ];
        }

        $players = [];
        if ($rounds[0]['matches']) {
            foreach ($rounds[0]['matches'] as $m) {
                if ($m['playerA']) {
                    $players[] = $m['playerA'];
                }
                if ($m['playerB']) {
                    $players[] = $m['playerB'];
                }
            }
        }

        return [
            'bracketSize' => $bracketSize,
            'players' => $players,
            'rounds' => $rounds,
            'tournamentId' => (string) $tournament->id,
            'source' => 'api',
        ];
    }

    public function mapMatchToReact(TournamentMatch $match): array
    {
        $playerA = $match->player1?->name;
        $playerB = $match->player2?->name;
        $winner = $match->winner?->name;

        $uiStatus = 'upcoming';
        if ($match->status === 'completed' || $match->winner_id) {
            $uiStatus = 'finished';
        } elseif ($match->scheduled_at) {
            $uiStatus = $match->scheduled_at->lte(now()) ? 'live' : 'upcoming';
        }

        return [
            'id' => (string) $match->id,
            'dbId' => (int) $match->id,
            'r' => (int) $match->round_index,
            'm' => (int) $match->match_index,
            'playerA' => $playerA,
            'playerB' => $playerB,
            'playerAId' => $match->player1_id ? (string) $match->player1_id : null,
            'playerBId' => $match->player2_id ? (string) $match->player2_id : null,
            'winner' => $winner,
            'winnerId' => $match->winner_id ? (string) $match->winner_id : null,
            'scoreA' => $match->score1,
            'scoreB' => $match->score2,
            'status' => $uiStatus,
            'scheduledAt' => $match->scheduled_at?->toIso8601String(),
        ];
    }

    public function scheduleMatch(TournamentMatch $match, Carbon $scheduledAt): TournamentMatch
    {
        $status = $match->winner_id
            ? 'completed'
            : ($scheduledAt->lte(now()) ? 'live' : 'upcoming');

        $match->update([
            'scheduled_at' => $scheduledAt,
            'status' => $status,
        ]);

        return $match->fresh(['player1', 'player2', 'winner']);
    }

    public function declareWinner(
        Tournament $tournament,
        TournamentMatch $match,
        int $winnerParticipantId,
        ?int $score1 = null,
        ?int $score2 = null,
    ): array {
        if ($match->winner_id) {
            throw ValidationException::withMessages([
                'winner_id' => ['تم تسجيل فائز لهذه المباراة مسبقاً.'],
            ]);
        }

        if (! $match->player1_id || ! $match->player2_id) {
            throw ValidationException::withMessages([
                'winner_id' => ['لا يمكن اختيار الفائز قبل اكتمال اللاعبين.'],
            ]);
        }

        if (! $match->scheduled_at) {
            throw ValidationException::withMessages([
                'winner_id' => ['يجب جدولة المباراة قبل اختيار الفائز.'],
            ]);
        }

        $isLive = $match->scheduled_at && $match->scheduled_at->lte(now());
        if (! $isLive) {
            throw ValidationException::withMessages([
                'winner_id' => ['يمكن اختيار الفائز فقط للمباريات الجارية.'],
            ]);
        }

        if ($winnerParticipantId !== (int) $match->player1_id && $winnerParticipantId !== (int) $match->player2_id) {
            throw ValidationException::withMessages([
                'winner_id' => ['الفائز يجب أن يكون أحد المتنافسين في هذه المباراة.'],
            ]);
        }

        $sa = $score1;
        $sb = $score2;
        if ($sa !== null && $sb !== null) {
            if ($sa < 0 || $sb < 0 || $sa === $sb) {
                throw ValidationException::withMessages([
                    'score1' => ['أدخل نتيجة صحيحة لكل لاعب.'],
                ]);
            }
            $highId = $sa > $sb ? (int) $match->player1_id : (int) $match->player2_id;
            if ($highId !== $winnerParticipantId) {
                throw ValidationException::withMessages([
                    'winner_id' => ['الفائز يجب أن يكون صاحب النقاط الأعلى.'],
                ]);
            }
        } else {
            $sa = $winnerParticipantId === (int) $match->player1_id ? 1 : 0;
            $sb = $winnerParticipantId === (int) $match->player2_id ? 1 : 0;
        }

        DB::transaction(function () use ($tournament, $match, $winnerParticipantId, $sa, $sb) {
            $match->update([
                'winner_id' => $winnerParticipantId,
                'score1' => $sa,
                'score2' => $sb,
                'status' => 'completed',
            ]);

            $nextR = (int) $match->round_index + 1;
            $bracketSize = $this->nextPowerOfTwo((int) $tournament->max_participants);
            $numRounds = (int) log($bracketSize, 2);

            if ($nextR < $numRounds) {
                $nextM = (int) floor($match->match_index / 2);
                $nextMatch = $tournament->matches()
                    ->where('round_index', $nextR)
                    ->where('match_index', $nextM)
                    ->first();

                if ($nextMatch) {
                    $slot = $match->match_index % 2 === 0 ? 'player1_id' : 'player2_id';
                    $nextMatch->update([$slot => $winnerParticipantId]);
                }
            }

            $allMatches = $tournament->matches()->get();
            $this->applyLiveStatus($allMatches);
        });

        $bracketSize = $this->nextPowerOfTwo((int) $tournament->max_participants);
        $numRounds = (int) log($bracketSize, 2);
        $isFinalMatch = (int) $match->round_index === $numRounds - 1;

        $freshMatch = $match->fresh(['player1', 'player2', 'winner']);

        if ($isFinalMatch) {
            $freshTournament = $tournament->fresh();
            event(new TournamentWinnerDeclared($freshTournament, $freshMatch));
        }

        return [
            'match' => $freshMatch,
            'tournament_complete' => $isFinalMatch,
        ];
    }

    public function finalMatch(Tournament $tournament): ?TournamentMatch
    {
        $bracketSize = $this->nextPowerOfTwo((int) $tournament->max_participants);
        $numRounds = (int) log($bracketSize, 2);
        $finalRoundIndex = $numRounds - 1;

        return $tournament->matches()
            ->where('round_index', $finalRoundIndex)
            ->with(['winner', 'player1', 'player2'])
            ->first();
    }

    public function queueWinnerNotification(Tournament $tournament): bool
    {
        $finalMatch = $this->finalMatch($tournament);

        if (! $finalMatch || ! $finalMatch->winner_id) {
            return false;
        }

        event(new TournamentWinnerDeclared($tournament->fresh(), $finalMatch));

        return true;
    }
}
