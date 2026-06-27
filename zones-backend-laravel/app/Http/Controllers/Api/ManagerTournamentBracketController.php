<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ResolvesManagerStation;
use App\Http\Controllers\Api\Concerns\ResolvesStaffStation;
use App\Http\Controllers\Controller;
use App\Http\Resources\TournamentMatchResource;
use App\Models\Tournament;
use App\Models\TournamentMatch;
use App\Services\TournamentBracketService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Validation\ValidationException;

class ManagerTournamentBracketController extends Controller
{
    use ResolvesManagerStation;
    use ResolvesStaffStation;

    public function __construct(
        private readonly TournamentBracketService $bracketService,
    ) {}

    protected function resolveTournamentStation(\App\Models\User $user): ?\App\Models\Station
    {
        if ($user->hasRole('manager')) {
            return $this->resolveManagerStation($user);
        }

        return $this->resolveStaffStation($user);
    }

    public function show(Request $request, Tournament $tournament): JsonResponse
    {
        $station = $this->resolveTournamentStation($request->user());
        if (! $station || (int) $tournament->station_id !== (int) $station->id) {
            abort(403);
        }

        $this->bracketService->ensureBracket($tournament);
        $bracket = $this->bracketService->buildReactBracket($tournament->fresh());

        return response()->json([
            'bracket' => $bracket,
        ]);
    }

    public function updateMatch(Request $request, Tournament $tournament, TournamentMatch $match): JsonResponse
    {
        $station = $this->resolveTournamentStation($request->user());
        if (! $station || (int) $tournament->station_id !== (int) $station->id) {
            abort(403);
        }

        if ((int) $match->tournament_id !== (int) $tournament->id) {
            abort(404);
        }

        $validated = $request->validate([
            'scheduled_at' => 'nullable|date',
            'winner_id' => 'nullable|integer|exists:tournament_participants,id',
            'score1' => 'required_with:winner_id|integer|min:0',
            'score2' => 'required_with:winner_id|integer|min:0',
            'team1_score' => 'sometimes|integer|min:0',
            'team2_score' => 'sometimes|integer|min:0',
        ]);

        if (isset($validated['team1_score']) && ! isset($validated['score1'])) {
            $validated['score1'] = $validated['team1_score'];
        }
        if (isset($validated['team2_score']) && ! isset($validated['score2'])) {
            $validated['score2'] = $validated['team2_score'];
        }

        if (empty($validated['scheduled_at']) && empty($validated['winner_id'])) {
            throw ValidationException::withMessages([
                'scheduled_at' => ['حدد موعداً أو فائزاً للتحديث.'],
            ]);
        }

        if (! empty($validated['scheduled_at'])) {
            $this->bracketService->scheduleMatch(
                $match,
                Carbon::parse($validated['scheduled_at']),
            );
        }

        $notificationQueued = false;

        if (! empty($validated['winner_id'])) {
            if (! isset($validated['score1'], $validated['score2'])) {
                throw ValidationException::withMessages([
                    'score1' => ['أدخل نتيجة كل لاعب عند اختيار الفائز.'],
                ]);
            }
            $result = $this->bracketService->declareWinner(
                $tournament,
                $match->fresh(),
                (int) $validated['winner_id'],
                isset($validated['score1']) ? (int) $validated['score1'] : null,
                isset($validated['score2']) ? (int) $validated['score2'] : null,
            );
            $match = $result['match'];
            $notificationQueued = $result['tournament_complete'];
        }

        $bracket = $this->bracketService->buildReactBracket($tournament->fresh());

        return response()->json([
            'message' => 'تم تحديث المباراة',
            'match' => (new TournamentMatchResource($match->fresh(['player1', 'player2', 'winner'])))->resolve(),
            'bracket' => $bracket,
            'notification_queued' => $notificationQueued,
        ]);
    }

    public function notifyWinner(Request $request, Tournament $tournament): JsonResponse
    {
        $station = $this->resolveManagerStation($request->user());
        if (! $station || (int) $tournament->station_id !== (int) $station->id) {
            abort(403);
        }

        $queued = $this->bracketService->queueWinnerNotification($tournament);

        if (! $queued) {
            throw ValidationException::withMessages([
                'tournament' => ['لا يوجد فائز في المباراة النهائية بعد.'],
            ]);
        }

        return response()->json([
            'message' => 'تم إرسال إشعار الفوز لجميع مستخدمي التطبيق.',
            'notification_queued' => true,
        ]);
    }
}
