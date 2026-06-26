<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('tournaments', function (Blueprint $table) {
            $table->timestamp('registration_deadline')->nullable()->after('end_date');
            $table->string('cover_image')->nullable()->after('game_emoji');
            $table->unsignedSmallInteger('delay_minutes')->default(10)->after('match_rules');
            $table->string('withdrawal_rule')->nullable()->after('delay_minutes');
        });

        Schema::table('tournament_participants', function (Blueprint $table) {
            $table->string('status', 32)->default('registered')->after('avatar_url');
            $table->timestamp('registered_at')->nullable()->after('status');
            $table->timestamp('withdrawn_at')->nullable()->after('registered_at');
        });
    }

    public function down(): void
    {
        Schema::table('tournament_participants', function (Blueprint $table) {
            $table->dropColumn(['status', 'registered_at', 'withdrawn_at']);
        });

        Schema::table('tournaments', function (Blueprint $table) {
            $table->dropColumn(['registration_deadline', 'cover_image', 'delay_minutes', 'withdrawal_rule']);
        });
    }
};
