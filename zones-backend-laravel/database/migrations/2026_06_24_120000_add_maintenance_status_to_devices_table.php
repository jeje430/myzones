<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        if (DB::getDriverName() !== 'mysql') {
            return;
        }

        DB::statement(
            "ALTER TABLE devices MODIFY operational_status ENUM('active', 'maintenance', 'inactive') NOT NULL DEFAULT 'active'"
        );
    }

    public function down(): void
    {
        if (DB::getDriverName() !== 'mysql') {
            return;
        }

        DB::table('devices')
            ->where('operational_status', 'maintenance')
            ->update(['operational_status' => 'inactive']);

        DB::statement(
            "ALTER TABLE devices MODIFY operational_status ENUM('active', 'inactive') NOT NULL DEFAULT 'active'"
        );
    }
};
