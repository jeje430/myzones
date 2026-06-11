<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('stations', function (Blueprint $table) {

            $table->id();

            /*
            |--------------------------------------------------------------------------
            | Station Manager
            |--------------------------------------------------------------------------
            */

            $table->foreignId('manager_id')
                ->nullable()
                ->constrained('users')
                ->nullOnDelete();

            /*
            |--------------------------------------------------------------------------
            | Basic Information
            |--------------------------------------------------------------------------
            */

            $table->string('name');

            $table->string('slug')
                ->unique();

            $table->string('cover_image')
                ->nullable();

            $table->string('phone')
                ->nullable();

            $table->string('email')
                ->nullable();

            /*
            |--------------------------------------------------------------------------
            | Location
            |--------------------------------------------------------------------------
            */

            $table->string('city')
                ->default('Tripoli');

            $table->string('address')
                ->nullable();

            $table->decimal('latitude', 10, 7)
                ->nullable();

            $table->decimal('longitude', 10, 7)
                ->nullable();

            /*
            |--------------------------------------------------------------------------
            | Working Time
            |--------------------------------------------------------------------------
            */

            $table->json('working_days')
                ->nullable();

            $table->time('opens_at')
                ->nullable();

            $table->time('closes_at')
                ->nullable();

            /*
            |--------------------------------------------------------------------------
            | Ratings
            |--------------------------------------------------------------------------
            */

            $table->decimal('average_rating', 3, 2)
                ->default(0);

            $table->unsignedInteger('reviews_count')
                ->default(0);

            /*
            |--------------------------------------------------------------------------
            | Station Status
            |--------------------------------------------------------------------------
            */

            $table->boolean('is_active')
                ->default(true);

            $table->boolean('bookings_enabled')
                ->default(true);

            /*
            |--------------------------------------------------------------------------
            | Soft Deletes & Timestamps
            |--------------------------------------------------------------------------
            */

            $table->softDeletes();

            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('stations');
    }
};
