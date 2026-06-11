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
        Schema::create('packages', function (Blueprint $table) {

            $table->id();

            /*
            |--------------------------------------------------------------------------
            | Relations
            |--------------------------------------------------------------------------
            */

            $table->foreignId('station_id')
                ->constrained('stations')
                ->cascadeOnDelete();

            /*
            |--------------------------------------------------------------------------
            | Package Information
            |--------------------------------------------------------------------------
            */

            $table->string('name');

            $table->string('slug')
                ->unique();

            $table->enum('package_type', [
                'ps5',
                'pc',
                'vr',
                'xbox',
                'simulator',
                'vip',
            ]);

            /*
            |--------------------------------------------------------------------------
            | Pricing
            |--------------------------------------------------------------------------
            */

            $table->decimal('hourly_price', 8, 2);

            $table->integer('minimum_hours')
                ->default(1);

            $table->integer('maximum_hours')
                ->default(3);

            /*
            |--------------------------------------------------------------------------
            | Package Details
            |--------------------------------------------------------------------------
            */

            $table->text('description')
                ->nullable();

            $table->string('thumbnail')
                ->nullable();

            /*
            |--------------------------------------------------------------------------
            | Package Status
            |--------------------------------------------------------------------------
            */

            $table->boolean('is_active')
                ->default(true);

            /*
            |--------------------------------------------------------------------------
            | Ratings
            |--------------------------------------------------------------------------
            */

            $table->decimal('average_rating', 3, 2)
                ->default(0);

            $table->integer('ratings_count')
                ->default(0);

            /*
            |--------------------------------------------------------------------------
            | Extra Information
            |--------------------------------------------------------------------------
            */

            $table->text('notes')
                ->nullable();

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
        Schema::dropIfExists('packages');
    }
};
