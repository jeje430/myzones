<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('bookings', function (Blueprint $table) {
            $table->string('visitor_name')->nullable()->after('booking_number');
            $table->string('visitor_phone')->nullable()->after('visitor_name');
            $table->string('visitor_email')->nullable()->after('visitor_phone');
        });
    }

    public function down(): void
    {
        Schema::table('bookings', function (Blueprint $table) {
            $table->dropColumn(['visitor_name', 'visitor_phone', 'visitor_email']);
        });
    }
};
