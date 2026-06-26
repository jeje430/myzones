<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('bookings', function (Blueprint $table) {
            $table->enum('booking_type', ['regular', 'offer', 'loyalty'])
                ->default('regular')
                ->after('booking_number');

            $table->decimal('discount_percent', 5, 2)->nullable()->after('discount_amount');

            $table->string('loyalty_coupon_label')->nullable()->after('discount_percent');
            $table->string('loyalty_coupon_code')->nullable()->after('loyalty_coupon_label');
            $table->unsignedInteger('loyalty_points_per_session')->nullable()->after('loyalty_coupon_code');
            $table->unsignedInteger('loyalty_points_total')->nullable()->after('loyalty_points_per_session');
        });
    }

    public function down(): void
    {
        Schema::table('bookings', function (Blueprint $table) {
            $table->dropColumn([
                'booking_type',
                'discount_percent',
                'loyalty_coupon_label',
                'loyalty_coupon_code',
                'loyalty_points_per_session',
                'loyalty_points_total',
            ]);
        });
    }
};
