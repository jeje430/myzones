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
        Schema::create('devices', function (Blueprint $table) {

            $table->id();

            /*
            |--------------------------------------------------------------------------
            | Relations
            |--------------------------------------------------------------------------
            */

            $table->foreignId('station_id')
                ->constrained('stations')
                ->cascadeOnDelete();

            $table->foreignId('package_id')
                ->nullable()
                ->constrained('packages')
                ->nullOnDelete();

            /*
            |--------------------------------------------------------------------------
            | Device Information
            |--------------------------------------------------------------------------
            */

            $table->string('device_code');

            $table->string('display_name');

            $table->enum('device_type', [
                'ps5',
                'pc',
                'vr',
                'xbox',
                'simulator',
                'vip',
            ]);

            /*
            |--------------------------------------------------------------------------
            | Device Status
            |--------------------------------------------------------------------------
            */



            $table->enum('operational_status', [
                'active',
                'inactive',
            ])->default('active');

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

            $table->timestamp('last_maintenance_at')
                ->nullable();

            /*
            |--------------------------------------------------------------------------
            | Soft Deletes & Timestamps
            |--------------------------------------------------------------------------
            */

            $table->softDeletes();

            $table->timestamps();

            /*
            |--------------------------------------------------------------------------
            | Unique Device Code Per Station
            |--------------------------------------------------------------------------
            */

            $table->unique([
                'station_id',
                'device_code'
            ]);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('devices');
    }
};
