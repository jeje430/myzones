<?php

namespace App\Listeners;

use App\Events\TournamentWinnerDeclared;
use App\Jobs\SendGlobalWinnerPushJob;
use Illuminate\Contracts\Queue\ShouldQueue;

class SendGlobalWinnerNotification implements ShouldQueue
{
    public function handle(TournamentWinnerDeclared $event): void
    {
        $winnerName = $event->match->winner?->name ?? 'الفائز';
        $prizeDetails = $event->tournament->prize_summary ?: 'الجائزة';

        SendGlobalWinnerPushJob::dispatch(
            winnerName: $winnerName,
            prizeDetails: $prizeDetails,
            tournamentId: $event->tournament->id,
            tournamentTitle: $event->tournament->title ?? '',
        );
    }
}
