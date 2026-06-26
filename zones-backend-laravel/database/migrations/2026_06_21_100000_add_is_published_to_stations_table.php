<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('stations', function (Blueprint $table) {
            $table->boolean('is_published')->default(false)->after('bookings_enabled');
            $table->timestamp('published_at')->nullable()->after('is_published');
            $table->timestamp('setup_completed_at')->nullable()->after('published_at');
        });

        // Hide all existing stations until managers complete setup via Save Changes.
        DB::table('stations')->update([
            'is_published' => false,
            'is_active' => false,
            'bookings_enabled' => false,
            'published_at' => null,
            'setup_completed_at' => null,
        ]);
    }

    public function down(): void
    {
        Schema::table('stations', function (Blueprint $table) {
            $table->dropColumn(['is_published', 'published_at', 'setup_completed_at']);
        });
    }
};
