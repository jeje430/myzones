<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

/**
 * Optional demo catalog — NOT run by default.
 *
 * Lounges must be created by managers via the dashboard (stations table).
 * Run manually only for local testing: php artisan db:seed --class=CatalogSeeder
 */
class CatalogSeeder extends Seeder
{
    public function run(): void
    {
        // Intentionally empty — no demo lounges/offers/tournaments in production flow.
    }
}
