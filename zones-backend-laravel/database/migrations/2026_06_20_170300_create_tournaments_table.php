<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('tournaments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('station_id')->constrained('stations')->cascadeOnDelete();
            $table->string('title');
            $table->string('game_name');
            $table->string('game_emoji', 8)->default('🎮');
            $table->timestamp('start_date');
            $table->timestamp('end_date')->nullable();
            $table->string('prize_summary');
            $table->decimal('entry_fee', 8, 2)->default(0);
            $table->text('match_rules');
            $table->enum('status', ['upcoming', 'ongoing', 'completed', 'cancelled'])->default('upcoming');
            $table->unsignedTinyInteger('max_participants')->default(8);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::create('tournament_participants', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tournament_id')->constrained('tournaments')->cascadeOnDelete();
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('name');
            $table->string('avatar_url')->nullable();
            $table->timestamps();

            $table->unique(['tournament_id', 'user_id']);
        });

        Schema::create('tournament_matches', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tournament_id')->constrained('tournaments')->cascadeOnDelete();
            $table->enum('round', ['quarter_final', 'semi_final', 'final']);
            $table->foreignId('player1_id')->nullable()->constrained('tournament_participants')->nullOnDelete();
            $table->foreignId('player2_id')->nullable()->constrained('tournament_participants')->nullOnDelete();
            $table->unsignedTinyInteger('score1')->nullable();
            $table->unsignedTinyInteger('score2')->nullable();
            $table->timestamp('scheduled_at')->nullable();
            $table->enum('status', ['upcoming', 'live', 'completed'])->default('upcoming');
            $table->foreignId('winner_id')->nullable()->constrained('tournament_participants')->nullOnDelete();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('tournament_matches');
        Schema::dropIfExists('tournament_participants');
        Schema::dropIfExists('tournaments');
    }
};
