<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('tournament_matches', function (Blueprint $table) {
            $table->unsignedTinyInteger('round_index')->default(0)->after('tournament_id');
            $table->unsignedTinyInteger('match_index')->default(0)->after('round_index');
        });
    }

    public function down(): void
    {
        Schema::table('tournament_matches', function (Blueprint $table) {
            $table->dropColumn(['round_index', 'match_index']);
        });
    }
};
