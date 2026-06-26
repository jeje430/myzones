<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('bookings', function (Blueprint $table) {
            $table->timestamp('loyalty_points_awarded_at')->nullable()->after('loyalty_points_total');
            $table->unsignedInteger('loyalty_points_redeemed')->nullable()->after('loyalty_points_awarded_at');
        });

        if (Schema::getConnection()->getDriverName() !== 'sqlite') {
            DB::statement("ALTER TABLE bookings MODIFY COLUMN payment_method ENUM('cash', 'online', 'loyalty_reward') NOT NULL DEFAULT 'cash'");
        }
    }

    public function down(): void
    {
        Schema::table('bookings', function (Blueprint $table) {
            $table->dropColumn(['loyalty_points_awarded_at', 'loyalty_points_redeemed']);
        });

        if (Schema::getConnection()->getDriverName() !== 'sqlite') {
            DB::statement("ALTER TABLE bookings MODIFY COLUMN payment_method ENUM('cash', 'online') NOT NULL DEFAULT 'cash'");
        }
    }
};
