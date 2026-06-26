<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('device_ratings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('package_id')->constrained('packages')->cascadeOnDelete();
            $table->unsignedTinyInteger('rating_value');
            $table->text('comment')->nullable();
            $table->timestamps();

            $table->unique(['user_id', 'package_id']);
            $table->index(['package_id', 'rating_value']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('device_ratings');
    }
};
