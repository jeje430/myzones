<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (DB::getDriverName() === 'mysql') {
            DB::statement(
                "ALTER TABLE bookings MODIFY booking_status ENUM('pending', 'confirmed', 'cancelled', 'cancelled_maintenance', 'completed', 'expired') NOT NULL DEFAULT 'pending'"
            );
        }

        Schema::table('bookings', function (Blueprint $table) {
            $table->boolean('needs_refund_review')->default(false)->after('booking_status');
            $table->timestamp('cancelled_at')->nullable()->after('needs_refund_review');
        });

        Schema::table('customer_notifications', function (Blueprint $table) {
            $table->json('payload')->nullable()->after('body');
        });
    }

    public function down(): void
    {
        Schema::table('customer_notifications', function (Blueprint $table) {
            $table->dropColumn('payload');
        });

        Schema::table('bookings', function (Blueprint $table) {
            $table->dropColumn(['needs_refund_review', 'cancelled_at']);
        });

        if (DB::getDriverName() === 'mysql') {
            DB::table('bookings')
                ->where('booking_status', 'cancelled_maintenance')
                ->update(['booking_status' => 'cancelled']);

            DB::statement(
                "ALTER TABLE bookings MODIFY booking_status ENUM('pending', 'confirmed', 'cancelled', 'completed', 'expired') NOT NULL DEFAULT 'pending'"
            );
        }
    }
};
