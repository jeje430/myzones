<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::getConnection()->getDriverName() === 'mysql') {
            DB::statement('ALTER TABLE tournament_matches MODIFY round VARCHAR(32) NOT NULL DEFAULT \'quarter_final\'');
        } else {
            Schema::table('tournament_matches', function (Blueprint $table) {
                $table->string('round', 32)->default('quarter_final')->change();
            });
        }
    }

    public function down(): void
    {
        if (Schema::getConnection()->getDriverName() === 'mysql') {
            DB::statement('ALTER TABLE tournament_matches MODIFY round ENUM(\'quarter_final\', \'semi_final\', \'final\') NOT NULL DEFAULT \'quarter_final\'');
        }
    }
};
