<?php

namespace App\Console\Commands;

use App\Models\Tournament;
use App\Services\TournamentBracketService;
use Illuminate\Console\Command;

class NotifyTournamentWinnerCommand extends Command
{
    protected $signature = 'tournaments:notify-winner {tournament : Tournament ID}';

    protected $description = 'Queue a global push notification for an already-crowned tournament winner';

    public function handle(TournamentBracketService $bracketService): int
    {
        $tournament = Tournament::query()->find($this->argument('tournament'));

        if (! $tournament) {
            $this->error('Tournament not found.');

            return self::FAILURE;
        }

        $finalMatch = $bracketService->finalMatch($tournament);

        if (! $finalMatch || ! $finalMatch->winner_id) {
            $this->error('No winner on the final match yet. Crown the final match first.');

            return self::FAILURE;
        }

        $bracketService->queueWinnerNotification($tournament);

        $winnerName = $finalMatch->winner?->name ?? 'الفائز';
        $tokenCount = \App\Models\DeviceToken::query()->count();

        $this->info("Notification queued for winner: {$winnerName}");
        $this->line("Registered device tokens: {$tokenCount}");

        if ($tokenCount === 0) {
            $this->warn('No device tokens yet — log in on the Flutter app as a customer first.');
        }

        $this->line('Run php artisan queue:work to process the job.');

        return self::SUCCESS;
    }
}
