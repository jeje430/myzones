<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('platform_settings', function (Blueprint $table) {
            $table->decimal('platform_commission_rate', 5, 2)->default(10)->after('loyalty_minimum_points_required');
        });

        Schema::table('bookings', function (Blueprint $table) {
            $table->decimal('platform_commission_rate', 5, 2)->default(0)->after('platform_commission_amount');
        });
    }

    public function down(): void
    {
        Schema::table('bookings', function (Blueprint $table) {
            $table->dropColumn('platform_commission_rate');
        });

        Schema::table('platform_settings', function (Blueprint $table) {
            $table->dropColumn('platform_commission_rate');
        });
    }
};
