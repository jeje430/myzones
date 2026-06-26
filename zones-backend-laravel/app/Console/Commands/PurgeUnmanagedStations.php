<?php

namespace App\Console\Commands;

use App\Models\Station;
use Illuminate\Console\Command;

class PurgeUnmanagedStations extends Command
{
    protected $signature = 'stations:purge-unmanaged {--force : Skip confirmation}';

    protected $description = 'Remove demo/unlinked stations (no manager_id) from the catalog database';

    public function handle(): int
    {
        $count = Station::query()->whereNull('manager_id')->count();

        if ($count === 0) {
            $this->info('No unmanaged stations found.');

            return self::SUCCESS;
        }

        if (! $this->option('force') && ! $this->confirm("Delete {$count} station(s) without a manager?", false)) {
            $this->warn('Cancelled.');

            return self::FAILURE;
        }

        Station::query()->whereNull('manager_id')->each(fn (Station $station) => $station->forceDelete());

        $this->info("Removed {$count} unmanaged station(s).");

        return self::SUCCESS;
    }
}
