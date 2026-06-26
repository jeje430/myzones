<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasColumn('bookings', 'hall_id')) {
            return;
        }

        if (Schema::hasColumn('bookings', 'station_id')) {
            return;
        }

        DB::statement(
            'ALTER TABLE `bookings` CHANGE `hall_id` `station_id` BIGINT UNSIGNED NOT NULL'
        );
    }

    public function down(): void
    {
        if (! Schema::hasColumn('bookings', 'station_id')) {
            return;
        }

        if (Schema::hasColumn('bookings', 'hall_id')) {
            return;
        }

        DB::statement(
            'ALTER TABLE `bookings` CHANGE `station_id` `hall_id` BIGINT UNSIGNED NOT NULL'
        );
    }
};
