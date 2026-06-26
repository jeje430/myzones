<?php

namespace App\Events;

use App\Models\Tournament;
use App\Models\TournamentMatch;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class TournamentWinnerDeclared
{
    use Dispatchable, SerializesModels;

    public function __construct(
        public Tournament $tournament,
        public TournamentMatch $match,
    ) {}
}
